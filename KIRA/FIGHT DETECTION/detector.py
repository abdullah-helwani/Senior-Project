"""
Fight detector: YOLO26-pose extracts keypoints, mLSTM (xLSTM 2024) classifies sequences.

Architecture: YOLO26-pose + velocity features + mLSTM
- YOLO26-pose: extracts 17 body keypoints per person per frame
- Velocity features: dx,dy per keypoint captures HOW FAST joints move
- mLSTM: matrix memory LSTM with exponential gates, captures joint-joint relationships
"""

import cv2
import numpy as np
from typing import Optional
import torch
import torch.nn as nn
from collections import deque
from ultralytics import YOLO
from pathlib import Path

# ── Constants ────────────────────────────────────────────────────────────────

WINDOW_SIZE   = 30    # frames in one classification window
MAX_PEOPLE    = 2     # max people tracked per frame
N_KEYPOINTS   = 17    # YOLO26-pose keypoints (same COCO format as v8)
FEAT_PER_KP   = 3     # x, y, confidence  (position features)
VEL_PER_KP    = 2     # dx, dy            (velocity features)

# Total per frame:
#   position: MAX_PEOPLE × N_KEYPOINTS × FEAT_PER_KP = 2 × 17 × 3 = 102
#   velocity: MAX_PEOPLE × N_KEYPOINTS × VEL_PER_KP  = 2 × 17 × 2 = 68
#   total:    170
POS_SIZE   = MAX_PEOPLE * N_KEYPOINTS * FEAT_PER_KP   # 102
VEL_SIZE   = MAX_PEOPLE * N_KEYPOINTS * VEL_PER_KP    # 68
INPUT_SIZE = POS_SIZE + VEL_SIZE                       # 170

YOLO_MODEL   = "yolo26n-pose.pt"
LSTM_MODEL_PATH = Path(__file__).parent / "fight_mlstm_81pct_final.pt"
FIGHT_THRESHOLD = 0.60   # confidence required to trigger alert


# ── mLSTM cell (xLSTM 2024) ───────────────────────────────────────────────────

class mLSTMLayer(nn.Module):
    """
    Optimized mLSTM layer from xLSTM (Hochreiter et al., 2024).

    How it differs from regular LSTM:
      Regular LSTM: scalar memory vector, sigmoid gates, sequential only
      mLSTM:        MATRIX memory, exponential gates, pre-computes all
                    projections in one GPU call then only loops the
                    memory update — much faster than naive cell-by-cell

    Key components:
      - Query/Key/Value: attention-style projections (like a Transformer)
      - Input gate (i): EXPONENTIAL — rapidly amplifies important events
      - Forget gate (f): EXPONENTIAL — rapidly drops irrelevant history
      - Output gate (o): sigmoid — controls what memory exposes
      - Matrix memory (C): stores joint-joint relationships across time
      - Normalizer (n) + Stabilizer (m): numerical safety for exp gates

    Speed trick:
      All Q, K, V, gate projections computed for ALL 30 frames at once
      on GPU (parallelizable). Only the sequential memory update loops.
      ~5-8× faster than computing projections inside the time loop.
    """
    def __init__(self, input_size: int, head_size: int = 64, num_heads: int = 4,
                 dropout: float = 0.0):
        super().__init__()
        self.H  = num_heads
        self.D  = head_size
        hidden  = head_size * num_heads   # 256

        # All projections computed for the full sequence at once
        self.W_q = nn.Linear(input_size, hidden, bias=False)
        self.W_k = nn.Linear(input_size, hidden, bias=False)
        self.W_v = nn.Linear(input_size, hidden, bias=False)
        self.W_o = nn.Linear(input_size, hidden)
        self.w_i = nn.Linear(input_size, num_heads)   # input gate
        self.w_f = nn.Linear(input_size, num_heads)   # forget gate

        self.norm    = nn.LayerNorm(hidden)
        self.dropout = nn.Dropout(dropout)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        x: (batch, seq_len, input_size)
        Returns: (batch, seq_len, hidden_size)
        """
        B, T, _ = x.shape
        H, D    = self.H, self.D

        # ── Pre-compute ALL projections for all T frames at once (GPU parallel) ──
        q     = self.W_q(x).view(B, T, H, D) / (D ** 0.5)   # (B,T,H,D)
        k     = self.W_k(x).view(B, T, H, D)                 # (B,T,H,D)
        v     = self.W_v(x).view(B, T, H, D)                 # (B,T,H,D)
        o     = torch.sigmoid(self.W_o(x)).view(B, T, H, D)  # (B,T,H,D)
        i_raw = self.w_i(x)                                   # (B,T,H)
        f_raw = self.w_f(x)                                   # (B,T,H)

        # ── Sequential memory update (only this part loops over time) ──────────
        C = torch.zeros(B, H, D, D, device=x.device, dtype=x.dtype)
        n = torch.zeros(B, H, D,    device=x.device, dtype=x.dtype)
        m = torch.zeros(B, H,       device=x.device, dtype=x.dtype)
        outputs = []

        for t in range(T):
            # Stabilizer: compute m_t from OLD m before updating it
            m_t = torch.maximum(f_raw[:, t] + m, i_raw[:, t])        # (B,H)
            f_g = torch.exp(f_raw[:, t] + m - m_t).view(B, H, 1, 1) # forget gate (B,H,1,1)
            i_g = torch.exp(i_raw[:, t]     - m_t).view(B, H, 1, 1) # input  gate (B,H,1,1)
            m   = m_t                                                  # now update stabilizer

            # Matrix memory update: C = f*C + i*(v⊗k)
            vk = torch.einsum('bhd,bhe->bhde', v[:, t], k[:, t])
            C  = f_g * C + i_g * vk                                   # (B,H,D,D)

            # Normalizer update
            n  = f_g.squeeze(-1) * n + i_g.squeeze(-1) * k[:, t]    # (B,H,D)

            # Read: h = o ⊙ (C·q / max(|n·q|, 1))
            Cq = torch.einsum('bhde,bhd->bhe', C, q[:, t])           # (B,H,D)
            nq = (n * q[:, t]).sum(-1, keepdim=True).abs().clamp(min=1.0)
            h  = o[:, t] * (Cq / nq)                                 # (B,H,D)
            outputs.append(h.reshape(B, H * D))

        out = torch.stack(outputs, dim=1)    # (B, T, hidden)
        return self.dropout(self.norm(out))


# ── Full mLSTM sequence model ─────────────────────────────────────────────────

class FightmLSTM(nn.Module):
    """
    Stacked mLSTM layers for fight detection.

    Input:  (batch, 30, 170)   — 30 frames, 170 features each
    Output: (batch, 2)         — [no_fight, fight]
    """
    def __init__(self, input_size: int = INPUT_SIZE,
                 hidden_size: int = 256,
                 num_layers:  int = 2,
                 num_heads:   int = 4,
                 dropout:     float = 0.4):
        super().__init__()
        head_size = hidden_size // num_heads   # 64

        self.input_proj = nn.Linear(input_size, hidden_size)

        self.layers = nn.ModuleList([
            mLSTMLayer(hidden_size, head_size, num_heads,
                       dropout=dropout if i < num_layers - 1 else 0.0)
            for i in range(num_layers)
        ])

        self.head = nn.Sequential(
            nn.Linear(hidden_size, 128),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(128, 2),
        )

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        x = self.input_proj(x)          # (B, T, hidden)
        for layer in self.layers:
            x = layer(x)               # (B, T, hidden)
        return self.head(x[:, -1, :])  # classify from last frame


# ── Keypoint extraction ───────────────────────────────────────────────────────

def _empty_position() -> np.ndarray:
    """Zero vector for one person's position (51 values)."""
    return np.zeros(N_KEYPOINTS * FEAT_PER_KP, dtype=np.float32)

def _empty_velocity() -> np.ndarray:
    """Zero vector for one person's velocity (34 values)."""
    return np.zeros(N_KEYPOINTS * VEL_PER_KP, dtype=np.float32)


def extract_positions(result) -> np.ndarray:
    """
    Extract normalized (x, y, conf) keypoints for up to MAX_PEOPLE.

    Preprocessing applied here:
      1. Coordinates normalized to [0,1] (x/width, y/height)
      2. People sorted by bounding-box area (largest first)
      3. Missing people zero-padded

    Returns flat array of shape (POS_SIZE,) = (102,)
    """
    frame_h, frame_w = result.orig_shape
    all_kps: list[np.ndarray] = []

    if result.keypoints is not None and len(result.keypoints) > 0:
        kps_data = result.keypoints.data   # (N_people, 17, 3)

        # Sort by bounding-box area → largest/closest person first
        boxes = result.boxes
        if boxes is not None and len(boxes) > 0:
            areas = (boxes.xyxy[:, 2] - boxes.xyxy[:, 0]) * \
                    (boxes.xyxy[:, 3] - boxes.xyxy[:, 1])
            order    = torch.argsort(areas, descending=True)
            kps_data = kps_data[order]

        for i in range(min(MAX_PEOPLE, len(kps_data))):
            kp = kps_data[i].cpu().numpy()   # (17, 3)
            kp[:, 0] /= frame_w              # normalize x → [0,1]
            kp[:, 1] /= frame_h              # normalize y → [0,1]
            all_kps.append(kp.flatten())     # 51 values

    while len(all_kps) < MAX_PEOPLE:
        all_kps.append(_empty_position())

    return np.concatenate(all_kps[:MAX_PEOPLE]).astype(np.float32)


def compute_velocity(curr_pos: np.ndarray, prev_pos: np.ndarray) -> np.ndarray:
    """
    Compute velocity (dx, dy) per keypoint per person.

    Why this matters:
      Position tells the model WHERE joints are.
      Velocity tells the model HOW FAST they're moving.
      Fights have fast, erratic, large-magnitude movements.
      Walking or standing still has slow, regular movements.
      Velocity makes this difference explicit and camera-angle independent.

    curr_pos, prev_pos: shape (POS_SIZE,) = (102,)
    Returns: shape (VEL_SIZE,) = (68,)
    """
    velocities: list[np.ndarray] = []

    for person_idx in range(MAX_PEOPLE):
        start = person_idx * N_KEYPOINTS * FEAT_PER_KP
        curr_person = curr_pos[start:start + N_KEYPOINTS * FEAT_PER_KP]
        prev_person = prev_pos[start:start + N_KEYPOINTS * FEAT_PER_KP]

        curr_xy = curr_person.reshape(N_KEYPOINTS, FEAT_PER_KP)[:, :2]  # (17, 2)
        prev_xy = prev_person.reshape(N_KEYPOINTS, FEAT_PER_KP)[:, :2]  # (17, 2)

        vel = (curr_xy - prev_xy).flatten()   # (34,) = 17 × (dx, dy)
        velocities.append(vel)

    return np.concatenate(velocities).astype(np.float32)   # (68,)


def build_frame_features(curr_pos: np.ndarray, prev_pos: np.ndarray) -> np.ndarray:
    """
    Combine position + velocity into one feature vector per frame.
    Returns shape (INPUT_SIZE,) = (170,)
    """
    vel = compute_velocity(curr_pos, prev_pos)
    return np.concatenate([curr_pos, vel])   # (102 + 68) = (170,)


# ── Main detector class ───────────────────────────────────────────────────────

class FightDetector:
    def __init__(self, device: Optional[str] = None):
        self.device = device or ("cuda" if torch.cuda.is_available() else "cpu")
        print(f"[FightDetector] Using device: {self.device}")

        # YOLO26-pose (downloads automatically on first run)
        self.yolo = YOLO(YOLO_MODEL)
        self.yolo.to(self.device)

        # Sliding window buffer: deque of shape-(170,) feature vectors
        self.buffer: deque[np.ndarray] = deque(maxlen=WINDOW_SIZE)

        # Previous position (for velocity computation)
        self.prev_pos: np.ndarray = np.zeros(POS_SIZE, dtype=np.float32)

        # mLSTM classifier
        self.mlstm: Optional[FightmLSTM] = None
        if LSTM_MODEL_PATH.exists():
            self.load_model()

    def load_model(self):
        checkpoint = torch.load(LSTM_MODEL_PATH, map_location=self.device)
        # New format: {'config': {...}, 'state_dict': {...}}
        # Old format: raw state_dict (backward compat)
        if isinstance(checkpoint, dict) and "config" in checkpoint:
            config = checkpoint["config"]
            state  = checkpoint["state_dict"]
        else:
            config = {}   # use FightmLSTM defaults
            state  = checkpoint
        self.mlstm = FightmLSTM(**config).to(self.device)
        self.mlstm.load_state_dict(state)
        self.mlstm.eval()
        print(f"[FightDetector] mLSTM loaded "
              f"(hidden={config.get('hidden_size', 256)}, "
              f"layers={config.get('num_layers', 2)})")

    def process_frame(self, frame: np.ndarray) -> dict:
        """
        Process one BGR frame. Returns detection result + annotated frame.
        """
        results   = self.yolo(frame, verbose=False)
        result    = results[0]
        annotated = result.plot()

        # Extract position + compute velocity
        curr_pos  = extract_positions(result)
        features  = build_frame_features(curr_pos, self.prev_pos)
        self.prev_pos = curr_pos.copy()

        self.buffer.append(features)

        if len(self.buffer) < WINDOW_SIZE or self.mlstm is None:
            return {
                "fight":           False,
                "confidence":      0.0,
                "keypoints_ready": len(self.buffer) >= WINDOW_SIZE,
                "annotated_frame": annotated,
            }

        # Build (1, 30, 170) tensor and classify
        seq    = np.stack(list(self.buffer), axis=0)            # (30, 170)
        tensor = torch.tensor(seq, dtype=torch.float32) \
                      .unsqueeze(0).to(self.device)             # (1, 30, 170)

        with torch.no_grad():
            logits     = self.mlstm(tensor)
            probs      = torch.softmax(logits, dim=1)
            fight_conf = probs[0, 1].item()

        is_fight = fight_conf >= FIGHT_THRESHOLD

        label = f"FIGHT {fight_conf:.0%}" if is_fight else f"OK {1 - fight_conf:.0%}"
        color = (0, 0, 255) if is_fight else (0, 200, 0)
        cv2.putText(annotated, label, (10, 40),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.2, color, 3)

        return {
            "fight":           is_fight,
            "confidence":      fight_conf,
            "keypoints_ready": True,
            "annotated_frame": annotated,
        }

    def reset_buffer(self):
        self.buffer.clear()
        self.prev_pos = np.zeros(POS_SIZE, dtype=np.float32)
