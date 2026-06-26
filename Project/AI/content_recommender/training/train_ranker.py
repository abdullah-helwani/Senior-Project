"""
Train EduRanker-Ar — fine-tune a multilingual sentence transformer on Arabic
query-passage pairs for better educational content ranking.

Base model : sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2
Datasets   : tydiqa (Arabic) + arbml/arcd + xquad (Arabic)
             All standard Parquet — no legacy dataset scripts required.
Loss       : MultipleNegativesRankingLoss  (contrastive learning)
Eval       : InformationRetrievalEvaluator — nDCG@10, MRR@10, Recall@10
             (real IR metrics; not eval_loss which is batch-composition noise)
Output     : ./checkpoints/edu_ranker_ar_v3/

Changes vs previous run:
  - Proper IR eval via InformationRetrievalEvaluator (nDCG@10 / MRR@10)
  - Leak-free train/eval split on unique passages (not random pair split)
  - Epochs reduced 20→3 (contrastive fine-tuning converges in 1-3 epochs)
  - Wikipedia title→intro pairs removed (titles are poor queries; diluted QA signal)
  - Best model selected on nDCG@10, not eval_loss

Hardware   : RTX GPU recommended, ~5-10 min
"""

import random
import warnings
warnings.filterwarnings("ignore", category=DeprecationWarning)

from pathlib import Path

import torch
from datasets import load_dataset, Dataset as HFDataset
from sentence_transformers import SentenceTransformer
from sentence_transformers.losses import MultipleNegativesRankingLoss
from sentence_transformers.evaluation import InformationRetrievalEvaluator
from sentence_transformers import (
    SentenceTransformerTrainer,
    SentenceTransformerTrainingArguments,
)

# ── Config ────────────────────────────────────────────────────────────────────
BASE_MODEL   = "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
OUTPUT_DIR   = Path(__file__).parent / "checkpoints" / "edu_ranker_ar_v3"
EPOCHS       = 12
BATCH_SIZE   = 32
WARMUP_RATIO = 0.1
LR           = 2e-5
EVAL_PASSAGE_FRAC = 0.15   # fraction of unique passages held out for eval
SEED         = 42


# ── Dataset loaders ───────────────────────────────────────────────────────────

def load_tydiqa_arabic() -> list[tuple[str, str]]:
    """TyDi QA secondary task — Arabic (question, passage) pairs."""
    print("  [dataset] Loading tydiqa Arabic...")
    try:
        ds = load_dataset("tydiqa", "secondary_task", split="train")
        pairs = []
        for row in ds:
            if not (row.get("id") or "").startswith("arabic"):
                continue
            q   = (row.get("question") or row.get("question_text") or "").strip()
            ctx = (row.get("context") or row.get("document_plaintext") or "").strip()[:1000]
            if q and ctx:
                pairs.append((q, ctx))
        print(f"  [dataset] tydiqa Arabic: {len(pairs)} pairs")
        return pairs
    except Exception as e:
        print(f"  [dataset] tydiqa failed: {e}")
        return []


def load_arcd() -> list[tuple[str, str]]:
    """ARCD — Arabic Reading Comprehension Dataset (question, context) pairs."""
    print("  [dataset] Loading arbml/arcd...")
    try:
        ds = load_dataset("arbml/arcd", split="train")
        pairs = []
        for row in ds:
            q   = (row.get("question") or "").strip()
            ctx = (row.get("context")  or "").strip()
            if q and ctx:
                pairs.append((q, ctx))
        print(f"  [dataset] arcd: {len(pairs)} pairs")
        return pairs
    except Exception as e:
        print(f"  [dataset] arcd failed: {e}")
        return []


def load_xquad_arabic() -> list[tuple[str, str]]:
    """XQuAD Arabic split — (question, context) pairs."""
    print("  [dataset] Loading xquad Arabic...")
    try:
        ds = load_dataset("xquad", "xquad.ar", split="validation")
        pairs = []
        for row in ds:
            q   = (row.get("question") or "").strip()
            ctx = (row.get("context")  or "").strip()
            if q and ctx:
                pairs.append((q, ctx))
        print(f"  [dataset] xquad Arabic: {len(pairs)} pairs")
        return pairs
    except Exception as e:
        print(f"  [dataset] xquad failed: {e}")
        return []


def split_by_passage(
    pairs: list[tuple[str, str]],
    eval_frac: float,
    seed: int,
) -> tuple[list[tuple[str, str]], list[tuple[str, str]]]:
    """Split (query, passage) pairs so eval passages never appear in train.

    A random pair split leaks because the same passage text is reused across
    many questions. This groups pairs by unique passage first, then assigns
    whole passage groups to train or eval.
    """
    rng = random.Random(seed)
    from collections import defaultdict
    by_passage: dict[str, list[str]] = defaultdict(list)
    for q, p in pairs:
        by_passage[p].append(q)

    unique_passages = list(by_passage.keys())
    rng.shuffle(unique_passages)
    cut = max(1, int(len(unique_passages) * eval_frac))
    eval_passages = set(unique_passages[:cut])

    train_pairs, eval_pairs = [], []
    for p, qs in by_passage.items():
        for q in qs:
            if p in eval_passages:
                eval_pairs.append((q, p))
            else:
                train_pairs.append((q, p))

    rng.shuffle(train_pairs)
    return train_pairs, eval_pairs


def build_ir_evaluator(eval_pairs: list[tuple[str, str]], name: str = "eval") -> InformationRetrievalEvaluator:
    """Build an InformationRetrievalEvaluator from (query, relevant_passage) pairs.

    Maps each unique passage to a corpus ID, each query to a query ID, then
    specifies the single relevant document for each query. Returns nDCG@10,
    MRR@10, Recall@10 — real ranking metrics instead of batch-noisy loss.
    """
    queries:    dict[str, str] = {}
    corpus:     dict[str, str] = {}
    relevant:   dict[str, set[str]] = {}

    passage_to_id: dict[str, str] = {}

    for i, (q, p) in enumerate(eval_pairs):
        qid = f"q{i}"
        if p not in passage_to_id:
            pid = f"p{len(passage_to_id)}"
            passage_to_id[p] = pid
            corpus[pid] = p
        pid = passage_to_id[p]
        queries[qid] = q
        relevant.setdefault(qid, set()).add(pid)

    print(f"  [eval] IR evaluator: {len(queries)} queries | {len(corpus)} passages")
    return InformationRetrievalEvaluator(
        queries=queries,
        corpus=corpus,
        relevant_docs=relevant,
        name=name,
        show_progress_bar=False,
    )


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    random.seed(SEED)
    torch.manual_seed(SEED)

    print(f"[train_ranker] CUDA  : {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"[train_ranker] Device: {torch.cuda.get_device_name(0)}")

    # 1. Collect QA pairs (no Wikipedia title→intro noise)
    print("[train_ranker] Loading Arabic QA datasets...")
    all_pairs: list[tuple[str, str]] = []
    all_pairs += load_tydiqa_arabic()
    all_pairs += load_arcd()
    all_pairs += load_xquad_arabic()

    if not all_pairs:
        print("[train_ranker] ERROR: No pairs loaded.")
        return

    print(f"[train_ranker] Total pairs: {len(all_pairs)}")

    # 2. Leak-free split by unique passage
    train_pairs, eval_pairs = split_by_passage(all_pairs, EVAL_PASSAGE_FRAC, SEED)
    print(f"[train_ranker] Train: {len(train_pairs)} pairs | Eval: {len(eval_pairs)} pairs")

    train_hf = HFDataset.from_dict({
        "anchor":   [p[0] for p in train_pairs],
        "positive": [p[1] for p in train_pairs],
    })

    # 3. Build IR evaluator (nDCG@10, MRR@10, Recall@10)
    evaluator = build_ir_evaluator(eval_pairs)

    # 4. Load base model
    print(f"\n[train_ranker] Loading base model: {BASE_MODEL}")
    model = SentenceTransformer(BASE_MODEL)

    # 5. Loss + training args
    loss = MultipleNegativesRankingLoss(model)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    args = SentenceTransformerTrainingArguments(
        output_dir=str(OUTPUT_DIR),
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        warmup_ratio=WARMUP_RATIO,
        learning_rate=LR,
        fp16=torch.cuda.is_available(),
        bf16=False,
        eval_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="eval_cosine_ndcg@10",
        greater_is_better=True,
        logging_steps=50,
        seed=SEED,
    )

    # 6. Train
    trainer = SentenceTransformerTrainer(
        model=model,
        args=args,
        train_dataset=train_hf,
        loss=loss,
        evaluator=evaluator,
    )

    print(f"[train_ranker] Training {EPOCHS} epochs | batch={BATCH_SIZE} | lr={LR}")
    trainer.train()

    # 7. Save
    model.save_pretrained(str(OUTPUT_DIR))
    print(f"\n[train_ranker] Done. Model saved -> {OUTPUT_DIR}")
    print(f"[train_ranker] Update config.py: EMBED_MODEL = r\"{OUTPUT_DIR}\"")


if __name__ == "__main__":
    main()
