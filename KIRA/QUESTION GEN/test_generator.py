"""
Quick test — creates a small PDF and generates questions using Ollama locally.

Usage:
    # Make sure Ollama is running first:
    #   ollama serve
    #   ollama pull command-r7b-arabic

    python test_generator.py
"""

import os
import io
import sys
import fitz   # PyMuPDF

# Force UTF-8 output so Arabic and box-drawing characters print correctly on Windows
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
from embedder        import Embedder
from question_engine import QuestionEngine


def make_sample_pdf(text: str) -> bytes:
    """Create a tiny in-memory PDF from plain text."""
    doc  = fitz.open()
    page = doc.new_page()
    page.insert_text((50, 50), text, fontsize=11)
    buf = io.BytesIO()
    doc.save(buf)
    doc.close()
    return buf.getvalue()


SAMPLE_TEXT_EN = """
Photosynthesis is the process by which green plants, algae, and some bacteria convert
light energy into chemical energy stored in glucose. This process takes place mainly
in the chloroplasts, which contain the green pigment chlorophyll.

The overall equation for photosynthesis is:
6CO2 + 6H2O + light energy → C6H12O6 + 6O2

Photosynthesis has two main stages:
1. The light-dependent reactions occur in the thylakoid membranes. They capture light
   energy and use it to produce ATP and NADPH, releasing oxygen as a byproduct.
2. The Calvin cycle (light-independent reactions) occurs in the stroma. It uses ATP and
   NADPH to convert carbon dioxide into glucose.

Factors that affect the rate of photosynthesis include light intensity, carbon dioxide
concentration, temperature, and water availability.
"""

SAMPLE_TEXT_AR = """
التمثيل الضوئي هو العملية التي تستخدمها النباتات الخضراء والطحالب وبعض البكتيريا
لتحويل الطاقة الضوئية إلى طاقة كيميائية مخزنة في الجلوكوز.
تحدث هذه العملية بشكل رئيسي في البلاستيدات الخضراء التي تحتوي على صبغة الكلوروفيل.

المعادلة الإجمالية للتمثيل الضوئي:
ثاني أكسيد الكربون (6) + الماء (6) + طاقة ضوئية ← جلوكوز + أكسجين (6)

للتمثيل الضوئي مرحلتان رئيسيتان:
1. التفاعلات الضوئية: تحدث في أغشية الثايلاكويد، وتلتقط طاقة الضوء لإنتاج ATP وNADPH.
2. دورة كالفن: تحدث في السدى، وتستخدم ATP وNADPH لتحويل ثاني أكسيد الكربون إلى جلوكوز.

العوامل المؤثرة في معدل التمثيل الضوئي: شدة الضوء، تركيز ثاني أكسيد الكربون،
درجة الحرارة، وتوفر الماء.
"""


def run_test(language: str):
    print(f"\n{'='*55}")
    print(f"Testing with {'Arabic' if language == 'ar' else 'English'} content")
    print('='*55)

    sample_text = SAMPLE_TEXT_AR if language == "ar" else SAMPLE_TEXT_EN
    pdf_bytes   = make_sample_pdf(sample_text)

    embedder = Embedder(persist_dir="./test_chroma")
    engine   = QuestionEngine(embedder)

    doc_id = f"test_{language}"
    # Re-add every run for simplicity
    embedder.delete_document(doc_id)

    from pdf_parser import PDFParser
    parser = PDFParser()
    parsed = parser.parse(pdf_bytes, f"test_{language}.pdf")
    embedder.add_document(doc_id, parsed["chunks"])

    questions = engine.generate(
        document_id=doc_id,
        num_questions=3,
        question_types=["mcq", "true_false", "short_answer"],
        bloom_levels=["remember", "understand", "apply"],
        difficulty="medium",
        language=language,
    )

    for i, q in enumerate(questions, 1):
        print(f"\n── Question {i} ({q.get('type','?')} | {q.get('bloom_level','?')} | {q.get('difficulty','?')}) ──")
        print(f"Q: {q.get('question', q.get('statement', ''))}")
        if "options" in q:
            for letter, opt in q["options"].items():
                marker = "✓" if letter == q.get("correct_answer") else " "
                print(f"  {marker} {letter}) {opt}")
        if "correct_answer" in q:
            print(f"Answer: {q['correct_answer']}")
        if "explanation" in q:
            print(f"Explanation: {q['explanation']}")
        if "model_answer" in q:
            print(f"Model answer: {q['model_answer']}")
        if "key_points" in q:
            print(f"Key points: {q['key_points']}")


if __name__ == "__main__":
    print("Make sure Ollama is running:  ollama serve")
    print("Make sure model is pulled:    ollama pull command-r7b-arabic\n")
    run_test("en")
    run_test("ar")
