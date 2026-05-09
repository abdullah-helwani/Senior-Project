"""
Sends fight-detection alerts to the Laravel backend via HTTP webhook.
"""

import httpx
import os
from datetime import datetime, timezone


class AlertSender:
    def __init__(
        self,
        laravel_url: str | None = None,
        api_key:     str | None = None,
    ):
        self.webhook_url = (
            laravel_url
            or os.getenv("LARAVEL_WEBHOOK_URL", "http://localhost:8000/api/webhooks/fight-alert")
        )
        self.api_key = api_key or os.getenv("LARAVEL_API_KEY", "change-me-shared-secret")

    def send(self, camera_id: str, confidence: float,
             footage_path: str = "") -> bool:
        """
        POST a fight alert to Laravel (includes footage file path).
        Returns True on success, False on failure (non-blocking).
        """
        payload = {
            "type":         "fight_detected",
            "camera_id":    camera_id,
            "confidence":   round(confidence, 4),
            "timestamp":    datetime.now(timezone.utc).isoformat(),
            "footage_path": footage_path,   # path to saved video clip
        }
        headers = {
            "X-API-Key":    self.api_key,
            "Content-Type": "application/json",
        }
        try:
            resp = httpx.post(
                self.webhook_url,
                json=payload,
                headers=headers,
                timeout=5.0,
            )
            if resp.status_code in (200, 201, 204):
                print(f"[AlertSender] Alert sent → {resp.status_code}")
                return True
            print(f"[AlertSender] Unexpected status {resp.status_code}: {resp.text[:200]}")
        except httpx.RequestError as e:
            print(f"[AlertSender] Failed to reach Laravel: {e}")
        return False
