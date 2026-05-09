"""
Scans a PDF and shows which pages have extractable text vs scanned images.
Usage: python scan_pages.py "D:\path\to\file.pdf"
"""
import sys
import fitz

pdf_path = sys.argv[1] if len(sys.argv) > 1 else input("PDF path: ").strip().strip('"')

doc = fitz.open(pdf_path)
print(f"\nTotal pages: {len(doc)}")
print(f"{'Page':<6} {'Words':<8} {'Status'}")
print("-" * 30)

for i, page in enumerate(doc, 1):
    text = page.get_text("text", flags=fitz.TEXT_PRESERVE_LIGATURES).strip()
    words = len(text.split())
    status = "✓ text" if words > 20 else ("⚠ very little" if words > 0 else "✗ image/empty")
    print(f"{i:<6} {words:<8} {status}")

doc.close()
