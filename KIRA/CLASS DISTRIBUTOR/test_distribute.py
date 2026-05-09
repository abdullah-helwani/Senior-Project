"""
Quick test — no API needed, runs the algorithm directly.

Usage:
    python test_distribute.py
"""

import random
from snake_draft import Student, snake_draft, get_class_scores
from metrics import compute_metrics


def make_fake_students(n: int = 30) -> list[Student]:
    random.seed(0)
    return [
        Student(
            student_id=f"S{i+1:03d}",
            academic_score=random.uniform(40, 100),
            behavior_score=random.uniform(50, 100),
            attendance_rate=random.uniform(0.6, 1.0),
        )
        for i in range(n)
    ]


def main():
    students    = make_fake_students(30)
    num_classes = 3
    weights     = {"academic": 0.6, "behavior": 0.3, "attendance": 0.1}

    print(f"Distributing {len(students)} students into {num_classes} classes...\n")

    classes      = snake_draft(students, num_classes, weights)
    class_scores = get_class_scores(classes, students, weights)
    metrics      = compute_metrics(class_scores)

    # Print assignments
    for class_name, student_ids in classes.items():
        stats = metrics["per_class"][class_name]
        print(f"{class_name} ({len(student_ids)} students) — "
              f"mean={stats['mean']:.1f}  std={stats['std']:.1f}  "
              f"[high={stats['distribution']['high']}  "
              f"mid={stats['distribution']['medium']}  "
              f"low={stats['distribution']['low']}]")
        print(f"  Students: {', '.join(student_ids)}\n")

    # Print balance
    print("─" * 50)
    print(f"Overall mean     : {metrics['overall_mean']}")
    print(f"Balance score    : {metrics['balance_score']} / 1.0")
    print(f"ANOVA p-value    : {metrics['anova_p_value']}")
    print(f"Is balanced      : {'YES ✓' if metrics['is_balanced'] else 'NO ✗'}")
    print(f"\n{metrics['explanation']}")


if __name__ == "__main__":
    main()
