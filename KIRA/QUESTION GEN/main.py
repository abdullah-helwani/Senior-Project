"""
Question Generator microservice — FastAPI app.

Run:
    uvicorn main:app --host 0.0.0.0 --port 8002 --reload

Environment variables:
    AI_API_KEY       Shared secret for X-API-Key header (between this service and Laravel)
    OLLAMA_URL       Ollama base URL (default: http://localhost:11434)
    OLLAMA_MODEL     Model to use   (default: command-r7b-arabic)

Requires Ollama running locally:
    ollama serve
    ollama pull command-r7b-arabic
"""

import os
import uuid
from typing import Literal
from fastapi import FastAPI, HTTPException, Request, Depends, UploadFile, File
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field

from pdf_parser     import PDFParser
from embedder       import Embedder
from question_engine import QuestionEngine

# ── App setup ──────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Question Generator Service",
    version="1.0.0",
    description="AI-powered exam question generator. Supports Arabic and English PDFs.",
)

AI_API_KEY = os.getenv("AI_API_KEY", "change-me-shared-secret")

pdf_parser = PDFParser()
embedder   = Embedder(persist_dir="./chroma_store")
engine     = None   # lazy-init so startup doesn't fail if key missing

def get_engine() -> QuestionEngine:
    global engine
    if engine is None:
        engine = QuestionEngine(embedder)
    return engine


# ── Auth ───────────────────────────────────────────────────────────────────────

async def verify_key(request: Request):
    key = request.headers.get("X-API-Key", "")
    if key != AI_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key.")


# ── In-memory document registry ───────────────────────────────────────────────
# In production this would be in the DB, but for the project this is fine.

_documents: dict[str, dict] = {}   # document_id → metadata


# ── Schemas ────────────────────────────────────────────────────────────────────

QuestionType  = Literal["mcq", "true_false", "short_answer", "fill_blank", "essay"]
BloomLevel    = Literal["remember", "understand", "apply", "analyze", "evaluate", "create"]
Difficulty    = Literal["easy", "medium", "hard"]
Language      = Literal["ar", "en", "auto"]


class GenerateRequest(BaseModel):
    document_id:     str

    # ── Option A: specific count per type (recommended) ──────────────────────
    # e.g. {"mcq": 5, "short_answer": 3, "true_false": 2}
    question_counts: dict[QuestionType, int] | None = Field(
        default=None,
        description="Exact count per question type. e.g. {\"mcq\": 5, \"short_answer\": 3}"
    )

    # ── Option B: legacy — total count + cycling types ────────────────────────
    num_questions:   int        = Field(5, ge=1, le=50)
    question_types:  list[QuestionType] = Field(
        default=["mcq"],
        description="Used only when question_counts is not provided. Cycled evenly."
    )

    bloom_levels:    list[BloomLevel] = Field(
        default=["remember", "understand"],
        description="Bloom's taxonomy levels. Cycled across all questions."
    )
    difficulty:      Difficulty = "medium"
    language:        Language   = "auto"
    topic_hint:      str        = Field(
        default="",
        description="Optional topic focus (e.g. 'photosynthesis', 'chapter 3')"
    )

    def resolve_question_list(self) -> list[str]:
        """Returns the full ordered list of question types to generate."""
        if self.question_counts:
            # Expand counts into a flat list: {"mcq":2,"tf":1} → ["mcq","mcq","tf"]
            result = []
            for q_type, count in self.question_counts.items():
                result.extend([q_type] * max(1, count))
            return result
        # Legacy: cycle question_types up to num_questions
        return [
            self.question_types[i % len(self.question_types)]
            for i in range(self.num_questions)
        ]


# ── Routes ─────────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok", "service": "question-generator"}


@app.post("/documents/upload", dependencies=[Depends(verify_key)])
async def upload_document(
    file:       UploadFile = File(...),
    page_start: int | None = None,
    page_end:   int | None = None,
):
    """
    Upload a PDF file. Returns document_id to use in /questions/generate.
    Supports Arabic and English PDFs.

    Optional page range (1-based, inclusive):
      - page_start: first page to include (default: 1)
      - page_end:   last page to include  (default: last page)

    Example: page_start=10&page_end=25 → only pages 10–25 are indexed.
    """
    if not file.filename.lower().endswith(".pdf"):
        raise HTTPException(status_code=400, detail="Only PDF files are supported.")

    contents = await file.read()
    if len(contents) > 200 * 1024 * 1024:   # 200MB limit
        raise HTTPException(status_code=400, detail="File too large. Max 200MB.")

    try:
        parsed = pdf_parser.parse(contents, file.filename, page_start, page_end)
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

    if not parsed["chunks"]:
        raise HTTPException(
            status_code=422,
            detail=(
                f"No text could be extracted from pages {page_start or 1}–{page_end or parsed['pages']}. "
                "These pages may be scanned images. Try different page numbers or a text-based PDF."
            )
        )

    document_id = str(uuid.uuid4())[:12]

    # Store chunks in vector DB
    embedder.add_document(
        document_id=document_id,
        chunks=parsed["chunks"],
        metadata={
            "filename": file.filename,
            "language": parsed["language"],
            "pages":    parsed["pages"],
        },
    )

    # Save metadata
    _documents[document_id] = {
        "document_id": document_id,
        "filename":    file.filename,
        "pages":       parsed["pages"],
        "pages_used":  parsed["pages_used"],
        "page_start":  page_start or 1,
        "page_end":    page_end   or parsed["pages"],
        "chunks":      len(parsed["chunks"]),
        "language":    parsed["language"],
        "ocr_pages":   parsed["ocr_pages"],
    }

    return _documents[document_id]


@app.post("/questions/generate", dependencies=[Depends(verify_key)])
def generate_questions(body: GenerateRequest):
    """
    Generate exam questions from a previously uploaded document.

    - Choose question types: mcq, true_false, short_answer, fill_blank, essay
    - Choose Bloom's levels: remember, understand, apply, analyze, evaluate, create
    - Choose difficulty: easy, medium, hard
    - Language is auto-detected from the PDF, or set manually to "ar" or "en"
    """
    if not embedder.document_exists(body.document_id):
        raise HTTPException(
            status_code=404,
            detail=f"Document '{body.document_id}' not found. Upload it first."
        )

    # Resolve language
    language = body.language
    if language == "auto":
        meta     = _documents.get(body.document_id, {})
        language = meta.get("language", "en")
        if language == "mixed":
            language = "ar"   # default to Arabic for mixed docs

    try:
        eng = get_engine()
    except EnvironmentError as e:
        raise HTTPException(status_code=500, detail=str(e))

    question_list = body.resolve_question_list()

    questions = eng.generate(
        document_id=body.document_id,
        num_questions=len(question_list),
        question_types=question_list,
        bloom_levels=body.bloom_levels,
        difficulty=body.difficulty,
        language=language,
        topic_hint=body.topic_hint,
    )

    if not questions:
        raise HTTPException(
            status_code=500,
            detail="Failed to generate questions. Make sure Ollama is running (ollama serve) and the model is pulled (ollama pull command-r7b-arabic)."
        )

    return {
        "document_id":    body.document_id,
        "language":       language,
        "num_requested":  len(question_list),
        "num_generated":  len(questions),
        "difficulty":     body.difficulty,
        "questions":      questions,
    }


@app.get("/documents", dependencies=[Depends(verify_key)])
def list_documents():
    """List all uploaded documents."""
    return {"documents": list(_documents.values())}


@app.get("/documents/{document_id}", dependencies=[Depends(verify_key)])
def get_document(document_id: str):
    """Get metadata for a specific document."""
    doc = _documents.get(document_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found.")
    return doc


@app.delete("/documents/{document_id}", dependencies=[Depends(verify_key)])
def delete_document(document_id: str):
    """Delete a document and its stored embeddings."""
    if document_id not in _documents:
        raise HTTPException(status_code=404, detail="Document not found.")
    embedder.delete_document(document_id)
    _documents.pop(document_id)
    return {"status": "deleted", "document_id": document_id}


# ── Question type reference ───────────────────────────────────────────────────

@app.get("/reference/types")
def question_types_reference():
    """Returns all supported question types, Bloom's levels, and difficulty options."""
    return {
        "question_types": {
            "mcq":          "Multiple Choice (4 options, 1 correct)",
            "true_false":   "True or False statement",
            "short_answer": "1-3 sentence answer",
            "fill_blank":   "Fill in the blank",
            "essay":        "Open-ended essay question",
        },
        "bloom_levels": [
            "remember", "understand", "apply", "analyze", "evaluate", "create"
        ],
        "difficulty": ["easy", "medium", "hard"],
        "languages":  ["ar", "en", "auto"],
    }
