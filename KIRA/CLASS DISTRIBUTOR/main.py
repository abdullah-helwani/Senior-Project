"""
Class Distributor microservice — FastAPI app.

Run:
    uvicorn main:app --host 0.0.0.0 --port 8003 --reload

Environment variables:
    AI_API_KEY    Shared secret expected in X-API-Key header
"""

import os
from fastapi import FastAPI, HTTPException, Request, Depends
from pydantic import BaseModel, Field

from snake_draft import Student, snake_draft, get_class_scores
from metrics import compute_metrics

app = FastAPI(
    title="Class Distributor Service",
    version="1.0.0",
    description="Fairly distributes students into balanced classes using Stratified Snake Draft.",
)

AI_API_KEY = os.getenv("AI_API_KEY", "change-me-shared-secret")


# ── Auth ───────────────────────────────────────────────────────────────────────

async def verify_key(request: Request):
    key = request.headers.get("X-API-Key", "")
    if key != AI_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key.")


# ── Schemas ────────────────────────────────────────────────────────────────────

class StudentInput(BaseModel):
    student_id:      str
    academic_score:  float = Field(..., ge=0, le=100)
    behavior_score:  float = Field(75.0,  ge=0, le=100)
    attendance_rate: float = Field(1.0,   ge=0, le=1)


class DistributeRequest(BaseModel):
    students:    list[StudentInput]
    num_classes: int = Field(..., ge=2, le=20)
    criteria_weights: dict[str, float] = Field(
        default={"academic": 0.6, "behavior": 0.3, "attendance": 0.1}
    )
    seed: int = Field(42, description="Random seed — change to get a different valid distribution")


# ── Routes ─────────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {"status": "ok", "service": "class-distributor"}


@app.post("/distribute", dependencies=[Depends(verify_key)])
def distribute(body: DistributeRequest):
    """
    Distribute students into balanced classes.

    Returns class assignments + balance metrics (including ANOVA p-value).
    """
    if len(body.students) < body.num_classes:
        raise HTTPException(
            status_code=400,
            detail=f"Need at least {body.num_classes} students to fill {body.num_classes} classes."
        )

    students = [
        Student(
            student_id=s.student_id,
            academic_score=s.academic_score,
            behavior_score=s.behavior_score,
            attendance_rate=s.attendance_rate,
        )
        for s in body.students
    ]

    classes      = snake_draft(students, body.num_classes, body.criteria_weights, body.seed)
    class_scores = get_class_scores(classes, students, body.criteria_weights)
    balance      = compute_metrics(class_scores)

    return {
        "classes":         classes,
        "balance_metrics": balance,
        "algorithm":       "Stratified Snake Draft",
        "total_students":  len(students),
        "num_classes":     body.num_classes,
    }


@app.post("/distribute/preview", dependencies=[Depends(verify_key)])
def distribute_preview(body: DistributeRequest):
    """
    Same as /distribute but only returns statistics — useful for
    comparing different weight configurations before committing.
    """
    result = distribute(body)
    # Return metrics only, not the full assignment list
    return {
        "balance_metrics": result["balance_metrics"],
        "algorithm":       result["algorithm"],
        "total_students":  result["total_students"],
        "num_classes":     result["num_classes"],
    }
