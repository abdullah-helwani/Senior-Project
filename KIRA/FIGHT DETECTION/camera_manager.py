"""
Manages multiple concurrent camera streams.

Footage storage:
  A circular buffer keeps the last PRE_BUFFER_SECONDS of raw frames in memory.
  When a fight is detected, we dump the pre-fight buffer to disk and keep
  recording for POST_BUFFER_SECONDS more. The result is a video clip that
  shows what happened before, during, and after the fight — usable as evidence.
"""

import cv2
import time
import uuid
import threading
import numpy as np
from collections import deque
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Dict, List

from detector import FightDetector
from alert_sender import AlertSender

# ── Footage settings ──────────────────────────────────────────────────────────
PRE_BUFFER_SECONDS  = 10   # seconds to keep before fight detection
POST_BUFFER_SECONDS = 10   # seconds to record after fight detection
FOOTAGE_DIR = Path("footage")
FOOTAGE_DIR.mkdir(exist_ok=True)

ALERT_COOLDOWN = 15.0      # minimum seconds between alerts per camera


@dataclass
class StreamInfo:
    stream_id:   str
    camera_id:   str
    camera_url:  str
    thread:      threading.Thread
    stop_event:  threading.Event
    detector:    FightDetector
    started_at:  str = field(default_factory=lambda: datetime.now(timezone.utc).isoformat())
    last_alert:  float = 0.0
    alert_count: int   = 0
    frame_count: int   = 0
    running:     bool  = True


class FootageWriter:
    """
    Saves fight footage as MJPEG AVI: PRE_BUFFER + POST_BUFFER seconds.
    MJPEG is natively supported by OpenCV on every platform with no extra
    codecs — the resulting .avi can be opened by VLC / Windows Media Player.
    """
    def __init__(self, camera_id: str, fps: float, frame_size: tuple):
        self.camera_id  = camera_id
        self.fps        = max(int(fps / 2), 1)   # halved: USB webcams over-report FPS
        self.frame_size = frame_size              # (width, height)
        self._writer:   Optional[cv2.VideoWriter] = None
        self._filepath         = ""
        self._frames_remaining = 0
        self._lock = threading.Lock()

    def start(self, pre_buffer: list) -> str:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filepath  = str(FOOTAGE_DIR / f"{self.camera_id}_{timestamp}.avi")

        writer = cv2.VideoWriter(
            filepath,
            cv2.VideoWriter_fourcc(*"MJPG"),
            self.fps,
            self.frame_size,
        )

        with self._lock:
            self._writer           = writer
            self._filepath         = filepath
            self._frames_remaining = int(POST_BUFFER_SECONDS * self.fps)

        for frame in pre_buffer:
            writer.write(frame)

        print(f"[Footage] Recording → {filepath}")
        return filepath

    def write(self, frame) -> bool:
        """Write one post-fight frame. Returns False when done."""
        with self._lock:
            if self._frames_remaining <= 0 or self._writer is None:
                self._finish()
                return False
            self._writer.write(frame)
            self._frames_remaining -= 1
            if self._frames_remaining <= 0:
                self._finish()
            return True

    def _finish(self):
        if self._writer:
            self._writer.release()
            self._writer = None
            print(f"[Footage] Saved → {self._filepath}")

    @property
    def is_recording(self) -> bool:
        with self._lock:
            return self._writer is not None and self._frames_remaining > 0


class CameraManager:
    def __init__(self, alert_sender: AlertSender):
        self.alert_sender = alert_sender
        self._streams: Dict[str, StreamInfo] = {}
        self._lock = threading.Lock()

    # ── Public API ─────────────────────────────────────────────────────────────

    def start_stream(self, camera_url: str, camera_id: str) -> str:
        url = int(camera_url) if camera_url.isdigit() else camera_url

        stream_id  = str(uuid.uuid4())
        stop_event = threading.Event()
        detector   = FightDetector()

        t = threading.Thread(
            target=self._run_stream,
            args=(stream_id, camera_id, url, stop_event, detector),
            daemon=True, name=f"stream-{camera_id}",
        )
        with self._lock:
            self._streams[stream_id] = StreamInfo(
                stream_id=stream_id, camera_id=camera_id,
                camera_url=camera_url, thread=t,
                stop_event=stop_event, detector=detector,
            )
        t.start()
        return stream_id

    def stop_stream(self, stream_id: str) -> bool:
        with self._lock:
            info = self._streams.get(stream_id)
        if not info:
            return False
        info.stop_event.set()
        info.thread.join(timeout=5)
        with self._lock:
            self._streams.pop(stream_id, None)
        return True

    def list_streams(self) -> List[dict]:
        with self._lock:
            return [
                {
                    "stream_id":   s.stream_id,
                    "camera_id":   s.camera_id,
                    "started_at":  s.started_at,
                    "frame_count": s.frame_count,
                    "alert_count": s.alert_count,
                    "running":     s.running,
                }
                for s in self._streams.values()
            ]

    # ── Stream worker ──────────────────────────────────────────────────────────

    def _run_stream(self, stream_id, camera_id, url, stop_event, detector):
        cap = cv2.VideoCapture(url)
        if not cap.isOpened():
            print(f"[CameraManager] Cannot open: {url}")
            self._mark_stopped(stream_id)
            return

        # Measure actual FPS by timing 10 real frames — USB webcams on Windows
        # often report 0 or wrong values from CAP_PROP_FPS
        frame_w    = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        frame_h    = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        reported   = cap.get(cv2.CAP_PROP_FPS)
        if reported and reported > 1:
            fps = reported
        else:
            t0 = time.time()
            for _ in range(10):
                cap.read()
            fps = round(10 / max(time.time() - t0, 0.1))
            fps = max(fps, 10)   # floor at 10 to avoid absurd values
        print(f"[CameraManager] Detected FPS: {fps:.0f}")
        pre_maxlen = int(PRE_BUFFER_SECONDS * fps)

        # Rolling circular buffer — always holds the last 10s of frames
        pre_buffer: deque = deque(maxlen=pre_maxlen)
        footage_writer: Optional[FootageWriter] = None

        print(f"[CameraManager] Stream '{camera_id}' started ({fps:.0f} fps)")

        while not stop_event.is_set():
            ok, frame = cap.read()
            if not ok:
                time.sleep(1)
                cap.release()
                cap = cv2.VideoCapture(url)
                continue

            pre_buffer.append(frame.copy())   # keep rolling buffer

            result = detector.process_frame(frame)

            with self._lock:
                info = self._streams.get(stream_id)
                if info:
                    info.frame_count += 1

            # Continue writing post-fight footage if active (raw frame, no overlay)
            if footage_writer and footage_writer.is_recording:
                footage_writer.write(frame)

            # Fight detected — trigger alert + footage
            if result["fight"]:
                now = time.time()
                with self._lock:
                    info = self._streams.get(stream_id)
                    do_alert = (info is not None and
                                now - info.last_alert >= ALERT_COOLDOWN)
                    if do_alert and info:
                        info.last_alert   = now
                        info.alert_count += 1

                if do_alert:
                    footage_writer = FootageWriter(camera_id, fps, (frame_w, frame_h))
                    footage_path   = footage_writer.start(list(pre_buffer))

                    self.alert_sender.send(
                        camera_id    = camera_id,
                        confidence   = result["confidence"],
                        footage_path = footage_path,
                    )
                    print(f"[CameraManager] FIGHT on '{camera_id}' "
                          f"conf={result['confidence']:.0%}")

        cap.release()
        self._mark_stopped(stream_id)
        print(f"[CameraManager] Stream '{camera_id}' stopped.")

    def _mark_stopped(self, stream_id):
        with self._lock:
            info = self._streams.get(stream_id)
            if info:
                info.running = False
