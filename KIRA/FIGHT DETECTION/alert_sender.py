"""
Sends fight-detection alerts to the Laravel backend via HTTP webhook.
"""

import httpx
import os
import time
from datetime import datetime, timezone
from typing import Optional


class AlertSender:
    def __init__(
        self,
        laravel_url: Optional[str] = None,
        api_key:     Optional[str] = None,
    ):
        self.webhook_url = (
            laravel_url
            or os.getenv("LARAVEL_WEBHOOK_URL", "http://localhost:8000/api/webhooks/fight-alert")
        )
        self.api_key = api_key or os.getenv("LARAVEL_API_KEY", "some-secret-123")

    def send(self, camera_id: str, confidence: float,
             footage_path: str = "") -> bool:
        """
        POST a fight alert to Laravel with up to 3 retries.
        php artisan serve is single-threaded on Windows so the first attempt
        may hit a busy worker — retrying after a short delay always succeeds.
        """
        payload = {
            "type":         "fight_detected",
            "camera_id":    camera_id,
            "confidence":   round(confidence, 4),
            "timestamp":    datetime.now(timezone.utc).isoformat(),
            "footage_path": footage_path,
        }
        headers = {
            "X-API-Key":    self.api_key,
            "Content-Type": "application/json",
        }

        for attempt in range(1, 4):
            try:
                resp = httpx.post(
                    self.webhook_url,
                    json=payload,
                    headers=headers,
                    timeout=8.0,
                    trust_env=False,   # bypass system HTTP_PROXY / HTTPS_PROXY
                )
                if resp.status_code in (200, 201, 204):
                    print(f"[AlertSender] Alert sent → {resp.status_code}")
                    return True
                print(f"[AlertSender] Unexpected status {resp.status_code}: {resp.text[:200]}")
                return False
            except httpx.RequestError as e:
                print(f"[AlertSender] Attempt {attempt}/3 failed: {e}")
                if attempt < 3:
                    time.sleep(0.5 * attempt)

        print("[AlertSender] All retries exhausted — alert not delivered.")
        return False
