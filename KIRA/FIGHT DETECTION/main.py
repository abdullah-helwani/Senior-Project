"""
Fight Detection microservice — FastAPI app.

Run:
    uvicorn main:app --host 0.0.0.0 --port 8001 --reload

Environment variables:
    LARAVEL_WEBHOOK_URL   URL of Laravel's fight-alert endpoint
    LARAVEL_API_KEY       Shared secret for X-API-Key header
    AI_API_KEY            Secret this service accepts from Laravel
"""

import os
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.responses import JSONResponse
from pydantic import BaseModel

load_dotenv()

from alert_sender import AlertSender
from camera_manager import CameraManager

# ── App setup ──────────────────────────────────────────────────────────────────

app = FastAPI(
    title="Fight Detection Service",
    version="1.0.0",
    description="YOLO26-pose + mLSTM (xLSTM 2024) real-time fight detection for school cameras.",
)

AI_API_KEY = os.getenv("AI_API_KEY", "change-me-shared-secret")

alert_sender    = AlertSender()
camera_manager  = CameraManager(alert_sender)


# ── Auth dependency ────────────────────────────────────────────────────────────

async def verify_key(request: Request):
    key = request.headers.get("X-API-Key", "")
    if key != AI_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key.")


# ── Schemas ────────────────────────────────────────────────────────────────────

class StartStreamRequest(BaseModel):
    camera_url: str     # "rtsp://..." or "0" for webcam
    camera_id:  str     # human label like "hallway-cam-01"

class StopStreamRequest(BaseModel):
    stream_id: str


# ── Routes ─────────────────────────────────────────────────────────────────────

@app.get("/health")
def health():
    """Laravel pings this to confirm the service is alive."""
    return {"status": "ok", "service": "fight-detection"}


@app.post("/stream/start", dependencies=[Depends(verify_key)])
def start_stream(body: StartStreamRequest):
    """Start monitoring a camera stream."""
    stream_id = camera_manager.start_stream(body.camera_url, body.camera_id)
    return {
        "status":    "started",
        "stream_id": stream_id,
        "camera_id": body.camera_id,
    }


@app.post("/stream/stop", dependencies=[Depends(verify_key)])
def stop_stream(body: StopStreamRequest):
    """Stop a running camera stream."""
    ok = camera_manager.stop_stream(body.stream_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Stream not found.")
    return {"status": "stopped", "stream_id": body.stream_id}


@app.get("/stream/list", dependencies=[Depends(verify_key)])
def list_streams():
    """List all active camera streams and their stats."""
    return {"streams": camera_manager.list_streams()}


# ── Dev helpers ────────────────────────────────────────────────────────────────

@app.post("/dev/test-alert", dependencies=[Depends(verify_key)])
def test_alert(camera_id: str = "test-cam"):
    """
    Fire a fake alert to Laravel — useful for testing the integration
    before real camera is set up.
    """
    ok = alert_sender.send(camera_id, confidence=0.99)
    return {"sent": ok, "camera_id": camera_id}
