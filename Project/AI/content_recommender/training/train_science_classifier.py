"""
Train ScienceClassifier-Ar — Arabic K-12 science subject classifier.
Fine-tunes AraBERT (aubmindlab/bert-base-arabertv02) with a classification head.

Data source: ArabicMMLU (MBZUAI) — authentic Arabic school exam questions.
  Paper:   https://arxiv.org/abs/2402.12840  (ACL Findings 2024)
  Dataset: https://huggingface.co/datasets/MBZUAI/ArabicMMLU  (CC-BY-NC-4.0)

Base model: aubmindlab/bert-base-arabertv02
  - Pre-trained on 77GB of Arabic text (Wikipedia, news, books, web)
  - Fine-tuning only the classification head on top of learned representations
  - Expected accuracy: 85-95% vs 75% from scratch

Categories:
  0 - Physics          (الفيزياء)
  1 - Biology          (الأحياء)
  2 - Mathematics      (الرياضيات)
  3 - Computer Science (علوم الحاسوب)
  4 - Natural Science  (العلوم الطبيعية)

Hardware: RTX GPU recommended, ~5 min total
"""

import json
import random
from collections import defaultdict
from pathlib import Path

import numpy as np
import torch
from datasets import load_dataset, Dataset as HFDataset
from transformers import (
    AutoTokenizer,
    AutoModelForSequenceClassification,
    TrainingArguments,
    Trainer,
    DataCollatorWithPadding,
    EarlyStoppingCallback,
)
import evaluate

# ── Config ────────────────────────────────────────────────────────────────────
BASE_MODEL   = "aubmindlab/bert-base-arabertv02"
OUTPUT_DIR   = Path(__file__).parent / "checkpoints" / "science_classifier_ar"
MAX_PER_CAT  = 600
MAX_LEN      = 128
BATCH_SIZE   = 32
EPOCHS       = 10
LR           = 2e-5
WARMUP_RATIO = 0.1
SEED         = 42

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# ── ArabicMMLU subject → category mapping ────────────────────────────────────
HF_DATASET = "MBZUAI/ArabicMMLU"

CATEGORIES = {
    "physics":         ["Physics (High School)"],
    "biology":         ["Biology (High School)"],
    "mathematics":     ["Math (Primary School)"],
    "computer_science": [
        "Computer Science (Primary School)",
        "Computer Science (Middle School)",
        "Computer Science (High School)",
        "Computer Science (University)",
    ],
    "natural_science": [
        "Natural Science (Primary School)",
        "Natural Science (Middle School)",
    ],
}

CATEGORIES_AR_DISPLAY = {
    "physics":         "الفيزياء",
    "biology":         "الأحياء",
    "mathematics":     "الرياضيات",
    "computer_science": "علوم الحاسوب",
    "natural_science": "العلوم الطبيعية",
}

LABEL_NAMES = list(CATEGORIES.keys())
ID2LABEL = {i: CATEGORIES_AR_DISPLAY[cat] for i, cat in enumerate(LABEL_NAMES)}
LABEL2ID = {cat: i for i, cat in enumerate(LABEL_NAMES)}


# ── Data loading ─────────────────────────────────────────────────────────────

def example_to_text(row: dict) -> str:
    """Build classification input from an ArabicMMLU MCQ row."""
    parts = [(row.get("Question") or "").strip()]
    for k in ("Option 1", "Option 2", "Option 3", "Option 4", "Option 5"):
        opt = row.get(k)
        if isinstance(opt, str) and opt.strip():
            parts.append(opt.strip())
    return " ".join(p for p in parts if p)[:400]


def build_dataset() -> tuple[list[str], list[int]]:
    """Load exam questions from ArabicMMLU for each science category."""
    rng = random.Random(SEED)
    texts, labels = [], []

    for cat_en, configs in CATEGORIES.items():
        label = LABEL2ID[cat_en]
        cat_ar = CATEGORIES_AR_DISPLAY[cat_en]
        print(f"  [mmlu] Loading {cat_ar} from {len(configs)} config(s)...")

        seen: set[str] = set()
        cat_texts: list[str] = []
        for cfg in configs:
            ds = load_dataset(HF_DATASET, cfg)
            for split in ds:
                for row in ds[split]:
                    text = example_to_text(row)
                    if len(text) >= 20 and text not in seen:
                        seen.add(text)
                        cat_texts.append(text)

        rng.shuffle(cat_texts)
        cat_texts = cat_texts[:MAX_PER_CAT]
        texts.extend(cat_texts)
        labels.extend([label] * len(cat_texts))
        print(f"  [mmlu]   -> {cat_ar}: {len(cat_texts)} examples")

    print(f"\n[dataset] Total: {len(texts)} examples across {len(CATEGORIES)} categories")
    for cat_en, i in LABEL2ID.items():
        count = labels.count(i)
        print(f"  {i}  {CATEGORIES_AR_DISPLAY[cat_en]:<20} -> {count}")

    return texts, labels


def stratified_split(texts, labels, eval_frac=0.1):
    """Stratified split so every class is represented in eval."""
    rng = random.Random(SEED)
    by_label = defaultdict(list)
    for i, lb in enumerate(labels):
        by_label[lb].append(i)

    train_idx, eval_idx = [], []
    for lb, idxs in by_label.items():
        rng.shuffle(idxs)
        cut = max(1, int(len(idxs) * (1 - eval_frac)))
        train_idx += idxs[:cut]
        eval_idx  += idxs[cut:]

    rng.shuffle(train_idx)
    train_texts  = [texts[i] for i in train_idx]
    train_labels = [labels[i] for i in train_idx]
    eval_texts   = [texts[i] for i in eval_idx]
    eval_labels  = [labels[i] for i in eval_idx]
    return train_texts, train_labels, eval_texts, eval_labels


# ── Metrics ───────────────────────────────────────────────────────────────────

accuracy_metric = evaluate.load("accuracy")
f1_metric       = evaluate.load("f1")

def compute_metrics(eval_pred):
    logits, labels = eval_pred
    preds = np.argmax(logits, axis=-1)
    acc = accuracy_metric.compute(predictions=preds, references=labels)["accuracy"]
    f1  = f1_metric.compute(predictions=preds, references=labels, average="macro")["f1"]
    return {"accuracy": acc, "f1_macro": f1}


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    random.seed(SEED)
    torch.manual_seed(SEED)
    print(f"[science_classifier] Device: {DEVICE}")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 1. Load data
    print(f"\n[science_classifier] Loading from {HF_DATASET}...")
    texts, labels = build_dataset()

    # 2. Stratified split
    train_texts, train_labels, eval_texts, eval_labels = stratified_split(texts, labels)
    print(f"\n[science_classifier] Train: {len(train_texts)} | Eval: {len(eval_texts)}")

    # 3. Tokenizer
    print(f"\n[science_classifier] Loading tokenizer: {BASE_MODEL}")
    tokenizer = AutoTokenizer.from_pretrained(BASE_MODEL)

    def tokenize(batch):
        return tokenizer(batch["text"], truncation=True, max_length=MAX_LEN)

    train_hf = HFDataset.from_dict({"text": train_texts, "label": train_labels})
    eval_hf  = HFDataset.from_dict({"text": eval_texts,  "label": eval_labels})
    train_hf = train_hf.map(tokenize, batched=True, remove_columns=["text"])
    eval_hf  = eval_hf.map(tokenize,  batched=True, remove_columns=["text"])

    # 4. Model
    print(f"[science_classifier] Loading model: {BASE_MODEL}")
    model = AutoModelForSequenceClassification.from_pretrained(
        BASE_MODEL,
        num_labels=len(CATEGORIES),
        id2label=ID2LABEL,
        label2id={v: k for k, v in ID2LABEL.items()},
        ignore_mismatched_sizes=True,
    )

    # 5. Training args
    args = TrainingArguments(
        output_dir=str(OUTPUT_DIR),
        num_train_epochs=EPOCHS,
        per_device_train_batch_size=BATCH_SIZE,
        per_device_eval_batch_size=BATCH_SIZE,
        warmup_steps=50,
        learning_rate=LR,
        weight_decay=0.01,
        fp16=torch.cuda.is_available(),
        eval_strategy="epoch",
        save_strategy="epoch",
        load_best_model_at_end=True,
        metric_for_best_model="accuracy",
        greater_is_better=True,
        logging_steps=50,
        seed=SEED,
        report_to="none",
    )

    # 6. Trainer
    trainer = Trainer(
        model=model,
        args=args,
        train_dataset=train_hf,
        eval_dataset=eval_hf,
        processing_class=tokenizer,
        data_collator=DataCollatorWithPadding(tokenizer),
        compute_metrics=compute_metrics,
        callbacks=[EarlyStoppingCallback(early_stopping_patience=3)],
    )

    print(f"[science_classifier] Fine-tuning {BASE_MODEL} for {EPOCHS} epochs...")
    trainer.train()

    # 7. Save final model + tokenizer
    model.save_pretrained(str(OUTPUT_DIR))
    tokenizer.save_pretrained(str(OUTPUT_DIR))

    # Save label map for inference
    with open(OUTPUT_DIR / "label_map.json", "w", encoding="utf-8") as f:
        json.dump({
            "id2label":       ID2LABEL,
            "label2id":       LABEL2ID,
            "categories_ar":  CATEGORIES_AR_DISPLAY,
        }, f, ensure_ascii=False, indent=2)

    best = trainer.state.best_metric
    print(f"\n[science_classifier] Done. Best accuracy: {best:.4f}")
    print(f"[science_classifier] Model saved -> {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
