"""
PDF / text extraction with Arabic and English support.
Supports both text-based PDFs (fast) and scanned/image PDFs (OCR via easyocr).

Arabic PDFs often have issues:
  - Text comes out reversed or fragmented
  - Words are out of order due to RTL encoding
  - Sometimes stored as images (not extractable as text)

We handle all of this here.
"""

import re
import numpy as np
import fitz   # PyMuPDF
from langdetect import detect


# ── Arabic text fixing ────────────────────────────────────────────────────────

def _is_arabic(text: str) -> bool:
    arabic_chars = len(re.findall(r'[\u0600-\u06FF]', text))
    return arabic_chars / max(len(text), 1) > 0.3


def _fix_arabic_line(line: str) -> str:
    """
    PyMuPDF sometimes extracts Arabic words in reversed order within a line.
    This reverses the word order for RTL lines while keeping word integrity.
    """
    if not _is_arabic(line):
        return line
    words = line.split()
    return " ".join(reversed(words))


def _clean_text(text: str) -> str:
    lines   = text.splitlines()
    cleaned = []
    for line in lines:
        line = line.strip()
        if not line:
            continue
        line = _fix_arabic_line(line)
        cleaned.append(line)
    result = "\n".join(cleaned)
    result = re.sub(r'\n{3,}', '\n\n', result)
    return result.strip()


# ── Chunking ──────────────────────────────────────────────────────────────────

def _chunk_text(
    text: str,
    chunk_size: int = 500,
    overlap:    int = 80,
) -> list[str]:
    """Split text into overlapping chunks by word count."""
    words  = text.split()
    chunks = []
    start  = 0
    while start < len(words):
        end   = min(start + chunk_size, len(words))
        chunk = " ".join(words[start:end])
        if len(chunk.strip()) > 30:
            chunks.append(chunk)
        start += chunk_size - overlap
    return chunks


# ── OCR (lazy-loaded so it only initialises when needed) ─────────────────────

_ocr_reader = None

def _get_ocr_reader():
    """Lazy-init easyocr reader with Arabic + English, GPU if available."""
    global _ocr_reader
    if _ocr_reader is None:
        import easyocr
        print("[PDFParser] Loading OCR model (first time only, may take a minute)...")
        _ocr_reader = easyocr.Reader(['ar', 'en'], gpu=False, verbose=False)
        print("[PDFParser] OCR model ready.")
    return _ocr_reader


def _ocr_page(page: fitz.Page) -> str:
    """Run easyocr on a single PyMuPDF page and return extracted text."""
    # Render page to image at 2× scale for better OCR accuracy
    mat = fitz.Matrix(2.0, 2.0)
    pix = page.get_pixmap(matrix=mat, colorspace=fitz.csRGB)
    img = np.frombuffer(pix.samples, dtype=np.uint8).reshape(pix.height, pix.width, 3)

    reader  = _get_ocr_reader()
    results = reader.readtext(img, detail=0, paragraph=True)
    return " ".join(results)


# ── Main extractor ────────────────────────────────────────────────────────────

# Pages with fewer than this many words are treated as image pages → OCR
_TEXT_WORD_THRESHOLD = 20


class PDFParser:
    def parse(
        self,
        file_bytes: bytes,
        filename:   str = "",
        page_start: int | None = None,   # 1-based, inclusive
        page_end:   int | None = None,   # 1-based, inclusive
        use_ocr:    bool = True,          # OCR fallback for image pages
    ) -> dict:
        """
        Extract text from a PDF file, optionally limited to a page range.

        page_start / page_end are 1-based (like humans count pages).
        Leave both as None to parse the whole document.
        Set use_ocr=False to skip OCR (faster, text-only PDFs).

        Returns:
            {
              "full_text":  str,
              "chunks":     list[str],
              "pages":      int,         # total pages in PDF
              "pages_used": int,         # pages actually parsed
              "language":   "ar" | "en" | "mixed" | "unknown",
              "filename":   str,
              "ocr_pages":  int,         # how many pages needed OCR
            }
        """
        doc         = fitz.open(stream=file_bytes, filetype="pdf")
        total_pages = len(doc)

        # Convert 1-based user input to 0-based PyMuPDF indices
        start_idx = (page_start - 1) if page_start else 0
        end_idx   = (page_end)       if page_end   else total_pages
        start_idx = max(0, min(start_idx, total_pages - 1))
        end_idx   = max(start_idx + 1, min(end_idx, total_pages))

        page_texts = []
        ocr_count  = 0

        for page_num in range(start_idx, end_idx):
            page = doc[page_num]
            text = page.get_text("text", flags=fitz.TEXT_PRESERVE_LIGATURES)
            words = len(text.split())

            if words < _TEXT_WORD_THRESHOLD:
                if use_ocr:
                    print(f"[PDFParser] Page {page_num + 1}: image detected, running OCR...")
                    text = _ocr_page(page)
                    ocr_count += 1
                else:
                    text = ""   # skip image page

            page_texts.append(text)

        doc.close()

        full_text = "\n\n".join(page_texts)
        full_text = _clean_text(full_text)

        if not full_text.strip():
            raise ValueError(
                "Could not extract text from the selected pages. "
                "If these are scanned images, make sure use_ocr is enabled."
            )

        language = self._detect_language(full_text)
        chunks   = _chunk_text(full_text)

        return {
            "full_text":  full_text,
            "chunks":     chunks,
            "pages":      total_pages,
            "pages_used": len(page_texts),
            "language":   language,
            "filename":   filename,
            "ocr_pages":  ocr_count,
        }

    def _detect_language(self, text: str) -> str:
        sample        = text[:2000]
        arabic_ratio  = len(re.findall(r'[\u0600-\u06FF]', sample)) / max(len(sample), 1)
        english_ratio = len(re.findall(r'[a-zA-Z]', sample))        / max(len(sample), 1)

        if arabic_ratio > 0.3 and english_ratio > 0.2:
            return "mixed"
        if arabic_ratio > 0.2:
            return "ar"
        if english_ratio > 0.2:
            return "en"
        try:
            return detect(text[:1000])
        except Exception:
            return "unknown"
