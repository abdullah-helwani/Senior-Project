"""
Balance metrics — measures how fairly students are distributed.

Key metric: one-way ANOVA p-value.
  p > 0.05 → class means are NOT significantly different → fair distribution ✓
  p < 0.05 → one class is measurably stronger/weaker than others ✗
"""

import numpy as np
from scipy import stats


def compute_metrics(class_scores: dict[str, list[float]]) -> dict:
    """
    Given scores per class, return balance statistics.

    Returns:
        {
          "per_class": {
            "Class 1": { "mean", "std", "min", "max", "count",
                         "distribution": {"high", "medium", "low"} }
          },
          "overall_mean":        float,
          "mean_score_variance": float,   # variance of class means (lower = better)
          "balance_score":       float,   # 0–1, 1 = perfect balance
          "anova_p_value":       float,   # > 0.05 means fair
          "is_balanced":         bool,
          "explanation":         str,
        }
    """
    groups = list(class_scores.values())
    names  = list(class_scores.keys())

    # Per-class stats
    all_scores = np.concatenate(groups)
    overall_mean = float(np.mean(all_scores))

    per_class = {}
    class_means = []
    for name, scores in zip(names, groups):
        arr  = np.array(scores, dtype=float)
        mean = float(np.mean(arr))
        class_means.append(mean)

        # Categorise into high / medium / low based on overall tertiles
        p33, p66 = np.percentile(all_scores, [33, 66])
        high   = int(np.sum(arr >= p66))
        low    = int(np.sum(arr <= p33))
        medium = len(arr) - high - low

        per_class[name] = {
            "mean":  round(mean, 2),
            "std":   round(float(np.std(arr)), 2),
            "min":   round(float(np.min(arr)), 2),
            "max":   round(float(np.max(arr)), 2),
            "count": len(arr),
            "distribution": {"high": high, "medium": medium, "low": low},
        }

    # ANOVA (requires at least 2 groups with >1 member each)
    try:
        _, p_value = stats.f_oneway(*groups)
        p_value = float(p_value) if not np.isnan(p_value) else 1.0
    except Exception:
        p_value = 1.0

    mean_variance = float(np.var(class_means))

    # Balance score: 1 when all class means are identical, approaches 0 as divergence grows
    max_possible_var = (overall_mean ** 2) / 4  # rough normaliser
    balance_score = max(0.0, 1.0 - mean_variance / (max_possible_var + 1e-9))
    balance_score = round(min(balance_score, 1.0), 4)

    is_balanced = p_value > 0.05

    explanation = (
        f"Classes were distributed using a Stratified Snake Draft. "
        f"One-way ANOVA gives p={p_value:.3f} "
        f"({'no significant difference between classes — fair ✓' if is_balanced else 'significant difference detected — consider re-running ✗'})."
    )

    return {
        "per_class":           per_class,
        "overall_mean":        round(overall_mean, 2),
        "mean_score_variance": round(mean_variance, 4),
        "balance_score":       balance_score,
        "anova_p_value":       round(p_value, 4),
        "is_balanced":         is_balanced,
        "explanation":         explanation,
    }
