# Question Generator — Session Handoff

**Date:** 2026-05-05
**Project:** SmartSchool — Question Generator microservice
**Status:** Working end-to-end. Ready for Laravel/frontend integration.

---

## 1. What This Service Does

FastAPI microservice on **port 8002** that:
1. Accepts PDF uploads (Arabic or English, text or scanned)
2. Chunks + embeds them into ChromaDB
3. Generates exam questions via local Ollama LLM (`command-r7b-arabic`)
4. Returns structured JSON questions with English keys + Arabic/English content

Runs locally — no external APIs. Auth via shared `X-API-Key` header.

---

## 2. Architecture

```
PDF upload  ─►  PyMuPDF text extract  ─►  easyocr fallback (CPU)  ─►  chunk
                                                                         │
                                                                         ▼
                                       ChromaDB ◄─── sentence-transformers
                                          │            (multilingual-MiniLM)
                                          ▼
        Generate request  ─►  retrieve top-k chunks  ─►  Ollama (GPU)  ─►  JSON
```

**Files:**
- `main.py` — FastAPI routes, schemas, auth
- `pdf_parser.py` — PyMuPDF extraction + easyocr fallback + Arabic line fixing
- `embedder.py` — ChromaDB wrapper
- `question_engine.py` — Ollama HTTP client + RAG retrieval
- `prompts.py` — Bilingual prompt templates (Arabic content, English JSON keys)
- `scan_pages.py` — Diagnostic: shows which PDF pages have text vs images
- `body.json` — Test payload for manual curl testing

---

## 3. Endpoints (API contract for frontend/backend)

All endpoints except `/health` and `/reference/types` require header:
```
X-API-Key: change-me-shared-secret
```
(Override via `AI_API_KEY` env var.)

### `POST /documents/upload`
Multipart form upload.

**Form fields:**
- `file` — PDF (max 200MB)

**Query params (optional):**
- `page_start` (int, 1-based) — first page
- `page_end` (int, 1-based) — last page

**Response:**
```json
{
  "document_id": "e71f105a-ea1",
  "filename": "book.pdf",
  "pages": 175,
  "pages_used": 50,
  "page_start": 10,
  "page_end": 60,
  "chunks": 87,
  "language": "ar",
  "ocr_pages": 0
}
```

### `POST /questions/generate`
**Body (recommended — granular counts):**
```json
{
  "document_id": "e71f105a-ea1",
  "question_counts": {
    "mcq": 5,
    "short_answer": 2,
    "true_false": 3,
    "fill_blank": 2
  },
  "bloom_levels": ["remember", "understand", "apply"],
  "difficulty": "medium",
  "language": "ar",
  "topic_hint": ""
}
```

**Body (legacy — total count):**
```json
{
  "document_id": "e71f105a-ea1",
  "num_questions": 5,
  "question_types": ["mcq"],
  "bloom_levels": ["remember"],
  "difficulty": "medium",
  "language": "auto"
}
```

**Response:**
```json
{
  "document_id": "...",
  "language": "ar",
  "num_requested": 12,
  "num_generated": 12,
  "difficulty": "medium",
  "questions": [
    {
      "type": "mcq",
      "bloom_level": "remember",
      "difficulty": "medium",
      "question": "ما هو ...",
      "options": {"A": "...", "B": "...", "C": "...", "D": "..."},
      "correct_answer": "B",
      "explanation": "..."
    },
    ...
  ]
}
```

**JSON keys are always English.** Question content is in the document's language.

### Other endpoints
- `GET /health`
- `GET /documents` — list all uploaded
- `GET /documents/{id}` — metadata
- `DELETE /documents/{id}` — remove from store
- `GET /reference/types` — enum reference

---

## 4. Question Types & Bloom Levels

**Types:** `mcq`, `true_false`, `short_answer`, `fill_blank`, `essay`
**Bloom:** `remember`, `understand`, `apply`, `analyze`, `evaluate`, `create`
**Difficulty:** `easy`, `medium`, `hard`
**Language:** `ar`, `en`, `auto`

---

## 5. Running It

### Prerequisites
- Python 3.12 (NOT 3.14 — packages won't be installed there)
- Ollama running: `ollama serve`
- Model pulled: `ollama pull command-r7b-arabic`
- NVIDIA GPU recommended (RTX 2060 6GB tested)

### Start the service
```powershell
C:\Users\Hussin\AppData\Local\Programs\Python\Python312\python.exe -m uvicorn main:app --host 0.0.0.0 --port 8002 --reload
```

### Test upload
```powershell
curl -X POST "http://localhost:8002/documents/upload?page_start=1&page_end=20" `
  -H "X-API-Key: change-me-shared-secret" `
  -F "file=@D:\path\to\book.pdf"
```

### Test generate
```powershell
curl -X POST "http://localhost:8002/questions/generate" `
  -H "X-API-Key: change-me-shared-secret" `
  -H "Content-Type: application/json" `
  -d "@D:\Senior\question-generator\body.json"
```
(Use `body.json` file to avoid PowerShell JSON escaping headaches.)

---

## 6. Known Issues + Fixes Already Applied

| Problem | Cause | Fix |
|--------|-------|-----|
| First 1-2 requests after cold start return HTTP 500 | Ollama loading 4.7GB model into VRAM takes >120s; client times out | Timeout raised to 300s in `question_engine.py`. May still fail occasionally on first run — retry. |
| OCR + LLM crash simultaneously | Both fight for RTX 2060's 6GB VRAM | `easyocr.Reader(..., gpu=False)` — OCR pinned to CPU. **Do not change this.** |
| LLM returned Arabic JSON keys (السؤال, الخيارات) | Original Arabic system prompt | System prompt rewritten in English with explicit "All keys must be in English" rule. **Do not translate prompts.py system messages back to Arabic.** |
| Empty chunks crash ChromaDB | Scanned PDF, OCR off, no text extractable | Guard added in `main.py` before `embedder.add_document()` with descriptive 422 error |
| `ContentTooShortError` during OCR init | Partial easyocr model download | Delete `C:\Users\Hussin\.EasyOCR\model\temp.zip` and retry upload |
| `ModuleNotFoundError: fitz` | VS Code defaulted to Python 3.14 | Use full Python 3.12 path explicitly |
| PowerShell mangles inline curl JSON | `-d "{\"key\":...}"` escaping | Use `-d "@body.json"` instead |

---

## 7. Pending Work

### Tomorrow (school visit)
- [ ] Create Google Forms from drafted student + teacher surveys
- [ ] Generate QR codes pointing to form URLs
- [ ] Connect Forms → Google Sheets via Responses tab → "Link to Sheets"

### Integration
- [ ] **Laravel backend (friend's task):** call `/documents/upload` and `/questions/generate`. Store `document_id` per uploaded file. Forward auth header.
- [ ] **Frontend (friend's task):** upload screen (PDF + page range + question type counts) → generate screen → display questions. Use the JSON contract above.
- [ ] **Class Distributor microservice:** port 8003 — not started yet.

### Nice-to-have
- [ ] Ollama warmup ping on FastAPI startup (eliminates first-request 500)
- [ ] `language="both"` for bilingual question generation
- [ ] PaddleOCR — better Arabic OCR than easyocr
- [ ] Frontend-side HTML→PDF question export

---

## 8. Critical Don'ts

1. **Don't enable GPU on easyocr.** Will crash Ollama.
2. **Don't translate the Arabic system prompt.** Laravel needs English JSON keys.
3. **Don't use Python 3.14.** Stick to 3.12.
4. **Don't lower the 300s timeout.** Ollama cold start needs it.
5. **Don't `git add -A`** if `chroma_store/` or `.EasyOCR/` ever get into the repo path — they're huge.

---

## 9. File Locations Reference

```
D:\Senior\question-generator\
  main.py
  pdf_parser.py
  embedder.py
  question_engine.py
  prompts.py
  scan_pages.py
  body.json
  chroma_store/          (vector DB — gitignore this)

C:\Users\Hussin\.EasyOCR\model\          (OCR models, ~200MB)
C:\Users\Hussin\AppData\Local\Ollama\    (LLM models + server.log)
```

**Ollama log (for debugging 500 errors):**
`C:\Users\Hussin\AppData\Local\Ollama\server.log`

---

## 10. Quick Sanity Check

If something breaks, run in this order:

1. `ollama list` — model still pulled?
2. `ollama serve` — daemon running?
3. `python scan_pages.py "D:\path\to\test.pdf"` — PDF has text?
4. `curl http://localhost:8002/health` — service alive?
5. Check `server.log` last 50 lines if Ollama 500s.
