"""
Stratified Snake Draft — fairly distributes students into classes.

Steps:
  1. Compute a composite score per student from weighted criteria.
  2. Sort students high → low by composite score.
  3. Divide into N performance bands (one band per class × round).
  4. Within each band, shuffle randomly for variety.
  5. Assign using snake (zigzag) order across classes.
"""

import random
import numpy as np
from dataclasses import dataclass


@dataclass
class Student:
    student_id:      str
    academic_score:  float          # e.g. GPA or average marks (0–100)
    behavior_score:  float = 75.0   # teacher rating (0–100)
    attendance_rate: float = 1.0    # 0.0 – 1.0


def compute_composite(
    student: Student,
    weights: dict[str, float],
) -> float:
    """
    Weighted composite score in the range [0, 100].
    weights keys: "academic", "behavior", "attendance"
    """
    w_ac = weights.get("academic",   0.6)
    w_bh = weights.get("behavior",   0.3)
    w_at = weights.get("attendance", 0.1)

    # Normalise weights so they always sum to 1
    total = w_ac + w_bh + w_at
    w_ac /= total
    w_bh /= total
    w_at /= total

    return (
        w_ac * student.academic_score
        + w_bh * student.behavior_score
        + w_at * (student.attendance_rate * 100)
    )


def snake_draft(
    students: list[Student],
    num_classes: int,
    weights: dict[str, float] | None = None,
    seed: int = 42,
) -> dict[str, list[str]]:
    """
    Distribute students into `num_classes` classes using snake draft.

    Returns:
        { "Class 1": [student_id, ...], "Class 2": [...], ... }
    """
    if weights is None:
        weights = {"academic": 0.6, "behavior": 0.3, "attendance": 0.1}

    random.seed(seed)

    # 1. Compute composite scores
    scored = [(s, compute_composite(s, weights)) for s in students]

    # 2. Sort high → low
    scored.sort(key=lambda x: x[1], reverse=True)

    # 3. Split into bands of size `num_classes`
    #    Each band will be distributed one student to each class.
    bands: list[list[tuple[Student, float]]] = []
    for i in range(0, len(scored), num_classes):
        band = scored[i : i + num_classes]
        random.shuffle(band)   # shuffle within band for variety
        bands.append(band)

    # 4. Snake draft assignment
    class_names = [f"Class {i+1}" for i in range(num_classes)]
    classes: dict[str, list[str]] = {name: [] for name in class_names}

    for band_index, band in enumerate(bands):
        # Even bands go left→right, odd bands go right→left (snake)
        if band_index % 2 == 0:
            order = list(range(num_classes))
        else:
            order = list(range(num_classes - 1, -1, -1))

        for slot, student_tuple in enumerate(band):
            if slot >= len(order):
                break
            class_index = order[slot]
            classes[class_names[class_index]].append(student_tuple[0].student_id)

    return classes


def get_class_scores(
    classes: dict[str, list[str]],
    students: list[Student],
    weights: dict[str, float] | None = None,
) -> dict[str, list[float]]:
    """Return composite scores for each student in each class."""
    if weights is None:
        weights = {"academic": 0.6, "behavior": 0.3, "attendance": 0.1}

    id_to_student = {s.student_id: s for s in students}
    return {
        class_name: [
            compute_composite(id_to_student[sid], weights)
            for sid in ids
        ]
        for class_name, ids in classes.items()
    }
