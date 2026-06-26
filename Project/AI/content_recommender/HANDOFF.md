# Content Recommender — Full Session Handoff

## Project Location
```
C:\Users\abdul\OneDrive\Desktop\Senior Project\Project\AI\content_recommender\
```

## What This Service Does
FastAPI microservice (port 8005) for an Arabic K-12 school management system.
Teacher writes Arabic text → system finds relevant videos, PDFs, articles, images.

Pipeline:
1. Ollama (command-r7b-arabic 7B) → extracts Arabic+English keywords from teacher input
2. ScienceClassifier-Ar → classifies query into school subject (Physics, Biology, etc.)
3. 4 sources searched in parallel: DuckDuckGo, OpenAlex, Wikimedia, YouTube (yt-dlp)
4. EduRanker-Ar v3 (fine-tuned MiniLM) → ranks results by semantic similarity
5. Returns top 15 results as JSON

---

## How to Run the Service

### Terminal 1 — Ollama
```bash
C:\Users\abdul\AppData\Local\Programs\Ollama\ollama.exe serve
```

### Terminal 2 — FastAPI service
```bash
cd "C:\Users\abdul\OneDrive\Desktop\Senior Project\Project\AI\content_recommender"
python -m uvicorn main:app --host 0.0.0.0 --port 8005 --reload
```

### Test URL: http://localhost:8005/docs
API Key: `change-me-shared-secret`

### Test Body
```json
{
  "query": "اريد فيديو لشرح الكهرباء والتيار الكهربائي كيف يتحرك داخل الاسلاك",
  "content_types": ["video", "article", "pdf", "image"],
  "language_preference": "both",
  "max_results": 15
}
```

---

## File Structure
```
content_recommender/
├── main.py                          # FastAPI app, routes, auth
├── config.py                        # Env vars + model paths
├── models.py                        # Pydantic schemas
├── intent_extractor.py              # Ollama Arabic LLM → keywords
├── ranker.py                        # Semantic similarity ranking
├── searcher.py                      # Async parallel search orchestrator
├── HANDOFF.md                       # This file
├── requirements.txt                 # Runtime dependencies
├── sources/
│   ├── youtube_source.py
│   ├── ddg_source.py
│   ├── openalex.py
│   ├── wikimedia_source.py
│   └── _util.py
└── training/
    ├── train_ranker.py              # Fine-tune EduRanker-Ar v3
    ├── train_science_classifier.py  # Fine-tune ScienceClassifier-Ar (AraBERT)
    └── checkpoints/
        ├── edu_ranker_ar_v3/        # DONE — fine-tuned ranker
        └── science_classifier_ar/  # DONE — fine-tuned AraBERT classifier
```

---

## config.py — Current State
```python
AI_API_KEY   = "change-me-shared-secret"
OLLAMA_URL   = "http://localhost:11434"
OLLAMA_MODEL = "command-r7b-arabic"
EMBED_MODEL  = r"C:\Users\abdul\OneDrive\Desktop\Senior Project\Project\AI\content_recommender\training\checkpoints\edu_ranker_ar_v3"
MAX_RESULTS_PER_SOURCE = 10
FINAL_RESULTS_COUNT    = 15
```

---

## Trained Models

---

### Model 1 — EduRanker-Ar v3

**Purpose:** Ranks Arabic educational content by semantic similarity to teacher query.
**File:** `training/train_ranker.py`
**Checkpoint:** `training/checkpoints/edu_ranker_ar_v3/`
**Status:** DONE. Plugged into config.py.

#### Architecture
| Property | Value |
|---|---|
| Base model | `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2` |
| Loss | `MultipleNegativesRankingLoss` (contrastive) |
| Epochs | 12 |
| Batch size | 32 |
| Learning rate | 2e-5 |
| Warmup steps | 50 (not warmup_ratio — deprecated in transformers v5+) |
| Training time | ~12 min (RTX 5060) |

#### Datasets
| Dataset | HF ID | Pairs | Notes |
|---|---|---|---|
| TyDi QA Arabic | `tydiqa` secondary_task | 14,805 | filter rows where id starts with "arabic" |
| XQuAD Arabic | `xquad/xquad.ar` | 1,190 | validation split only |
| ARCD | `arbml/arcd` | 0 | FAILED — dataset no longer exists on HF Hub |
| **Total** | | **15,995** | |

Wikipedia title→intro pairs were intentionally removed — titles are weak queries and diluted QA signal.

#### Train/Eval Split
- Method: split by **unique passage** (not random pair split)
- Random pair splits cause leakage because the same passage appears in both train and eval
- Train: 13,599 pairs | Eval: 2,396 pairs (1,626 unique passages)

#### Evaluation — InformationRetrievalEvaluator
Real IR metrics (not eval_loss, which is batch-composition noise):
| Metric | Epoch 1 | Epoch 12 (Best) |
|---|---|---|
| nDCG@10 | 0.8408 | **0.8672** |
| MRR@10 | 0.8166 | **0.8432** |
| Accuracy@1 | 76.2% | **78.9%** |
| Recall@10 | 91.6% | **94.1%** |
| MAP@100 | 0.8194 | **0.8454** |

#### Key design decisions made this session
- **Previous version (v1)** used `eval_loss` as best-model metric — this is wrong because
  MultipleNegativesRankingLoss depends on in-batch negatives, making loss a function of batch
  composition, not ranking quality. Replaced with `InformationRetrievalEvaluator`.
- **Previous version** used a random pair split → passage leakage → artificially low loss.
  Fixed to split by unique passage.
- **Previous version** ran 20 epochs → overfitting (eval bottomed at ~epoch 18). Reduced to 12.
- `metric_for_best_model` correct key is `"eval_cosine_ndcg@10"` (not `eval_eval_cosine_ndcg@10`).
- `processing_class=tokenizer` in Trainer (not `tokenizer=` — renamed in newer transformers).

---

### Model 2 — ScienceClassifier-Ar

**Purpose:** Classifies Arabic teacher query into K-12 school science subject.
**File:** `training/train_science_classifier.py`
**Checkpoint:** `training/checkpoints/science_classifier_ar/`
**Status:** DONE. Not yet integrated into main.py (see Pending Work).

#### Architecture
| Property | Value |
|---|---|
| Base model | `aubmindlab/bert-base-arabertv02` |
| Type | BERT-base + classification head (fine-tuned, not from scratch) |
| Epochs | 10 (early stopping patience=3) |
| Batch size | 32 |
| Learning rate | 2e-5 |
| Weight decay | 0.01 |
| Max token length | 128 |
| Training time | ~5 min (RTX 5060) |

#### Why AraBERT instead of from scratch
Previous version trained a 4-layer transformer from scratch on Wikipedia API scrapes.
Problems with that approach:
1. Wikipedia API rate-limited (429 errors) → some categories got 0 examples
2. Only ~300–900 total examples → too small for 7-class from-scratch training
3. Noisy labels — Wikipedia category membership includes biographies, awards, history articles
4. Wrong register — encyclopedic Arabic ≠ K-12 textbook language
5. Non-reproducible — same script gave different data each run depending on rate limits

AraBERT is pre-trained on 77GB of Arabic text and already understands Arabic deeply.
Fine-tuning it on clean exam questions took 5 minutes and jumped accuracy from 75% → 95%.

#### Dataset — ArabicMMLU (MBZUAI)
- Paper: https://arxiv.org/abs/2402.12840 (ACL Findings 2024) ← cite this in your report
- HuggingFace: `MBZUAI/ArabicMMLU` (CC-BY-NC-4.0)
- Content: Authentic Arabic school exam questions from 8 countries, tagged by subject and level

| Label | Category (AR) | ArabicMMLU Config(s) | Examples |
|---|---|---|---|
| 0 | الفيزياء (Physics) | `Physics (High School)` | 258 |
| 1 | الأحياء (Biology) | `Biology (High School)` | 600 |
| 2 | الرياضيات (Mathematics) | `Math (Primary School)` | 405 |
| 3 | علوم الحاسوب (Computer Science) | `Computer Science (Primary/Middle/High/University)` | 554 |
| 4 | العلوم الطبيعية (Natural Science) | `Natural Science (Primary/Middle School)` | 584 |
| | **Total** | | **2,401** |

Note: Original taxonomy had 7 categories (including Chemistry, Earth Science, Engineering).
ArabicMMLU does not have clean standalone configs for those — they fall under Natural Science.
Taxonomy was reduced to 5 well-supported categories. Add AraSTEM later for Chemistry if/when
it gets a public HuggingFace release (paper: https://arxiv.org/abs/2501.00559).

#### Train/Eval Split
- Method: stratified split — guarantees every class is represented in eval
- Train: 2,159 | Eval: 242

#### Input format
Each example = question text + answer options concatenated, max 400 chars:
```
"ما هي وحدة قياس القوة؟ نيوتن كيلوغرام متر ثانية"
```

#### Evaluation
| Metric | Old (scratch + Wikipedia) | New (AraBERT + ArabicMMLU) |
|---|---|---|
| Accuracy | 75.2% | **95.45%** |
| Eval samples | 242 | 242 |
| Data reproducible | No (rate-limited) | Yes (HF cached) |
| Data citable | No | Yes (ACL 2024 paper) |

#### Inference
```python
from transformers import pipeline

clf = pipeline(
    "text-classification",
    model=r"C:\Users\abdul\OneDrive\Desktop\Senior Project\Project\AI\content_recommender\training\checkpoints\science_classifier_ar",
    device=0  # GPU, or -1 for CPU
)

result = clf("ما هي قوة الجاذبية؟")
# → [{'label': 'الفيزياء', 'score': 0.98}]
```

Label map is saved at `checkpoints/science_classifier_ar/label_map.json`.

---

## Pending Work

### 1. Integrate ScienceClassifier into main.py (NOT DONE)
The classifier is trained and saved but not wired into the service yet.
Planned flow:
- At request time, run classifier on teacher query
- Append detected subject label to search keywords
- Optionally boost/filter results by subject match

### 2. Source Status
| Source | Status | Notes |
|---|---|---|
| DuckDuckGo | ✅ Working | Main workhorse |
| OpenAlex | ✅ Working | Academic papers |
| Wikimedia | ✅ Working | Images |
| YouTube (yt-dlp) | ⚠️ Returns 0 | DDG already covers YouTube results |

---

## Test Results (confirmed working)
Query: "اريد فيديو لشرح الكهرباء والتيار الكهربائي كيف يتحرك داخل الاسلاك"
- Top result: 0.884 — Arabic YouTube video about electric current
- Khan Academy video: 0.844
- LSU Electricity PDF: 0.843
- Saudi K-12 curriculum: 0.822
- All 15 results were genuinely relevant
- Response time: ~28s first call, ~5-8s subsequent calls

---

## Known Bugs Fixed This Session

| Bug | Fix |
|---|---|
| `tokenizer=` arg in Trainer | Renamed to `processing_class=` in newer transformers |
| `warmup_ratio` deprecation warning | Changed to `warmup_steps=50` |
| `score_functions` lambda in IRE caused shape mismatch | Removed custom lambda; use built-in cosine |
| `metric_for_best_model` KeyError | Correct key is `"eval_cosine_ndcg@10"` not `"eval_eval_cosine_ndcg@10"` |
| Unicode crash on Windows console | Run with `python -X utf8 ...` |
| ARCD dataset missing from HF Hub | Removed from loader; tydiqa+xquad sufficient |

---

## Hardware & Environment
- GPU: NVIDIA RTX 5060 8GB VRAM (CUDA 12.0)
- Python: 3.14
- uvicorn not on PATH → always use: `python -m uvicorn ...`
- ollama not on PATH → always use: `C:\Users\abdul\AppData\Local\Programs\Ollama\ollama.exe ...`

## Dependencies
Runtime:
```
pip install fastapi uvicorn pydantic sentence-transformers numpy yt-dlp ddgs transformers
```
Training:
```
pip install datasets torch transformers accelerate scikit-learn tokenizers evaluate
```

---

## Re-training from Scratch (if needed)

### Ranker
```bash
python -X utf8 training/train_ranker.py
# ~12 min, saves to checkpoints/edu_ranker_ar_v3/
```

### Science Classifier
```bash
python -X utf8 training/train_science_classifier.py
# ~5 min, saves to checkpoints/science_classifier_ar/
# Data auto-downloads from MBZUAI/ArabicMMLU (HF cache)
```
