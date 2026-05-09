"""
Extract keypoint + velocity sequences from RWF-2000 and SCVD datasets.

What this script does:
  For every video → run YOLO26-pose on every frame → extract 17 keypoints
  per person → normalize coordinates → compute velocity (how fast joints move)
  → slide a 30-frame window → save as numpy arrays for training.

Preprocessing applied:
  1. Coordinate normalization: x/width, y/height → [0,1]
  2. Sort people by size (largest first)
  3. Zero-pad if fewer than 2 people
  4. Velocity: dx = x_now - x_prev, dy = y_now - y_prev per keypoint

Output per frame: 170 features = 102 (position) + 68 (velocity)

Files produced:
  train_sequences.npy / train_labels.npy   — RWF-2000 train (700+700) + SCVD train combined
  val_sequences.npy   / val_labels.npy     — RWF-2000 val (200+200, official split)
  test_sequences.npy  / test_labels.npy    — RWF-2000 test (100+100, held out from train)
  scvd_test_sequences.npy / scvd_test_labels.npy — SCVD Test folder (second unseen test)

Usage:
    # RWF-2000 only
    python extract_dataset.py --dataset data/RWF-2000

    # RWF-2000 + SCVD (recommended)
    python extract_dataset.py --dataset data/RWF-2000 --scvd data/SCVD/SCVD_converted
"""

import argparse
import random
import numpy as np
import cv2
from pathlib import Path
from tqdm import tqdm
from ultralytics import YOLO

from detector import (
    extract_positions, build_frame_features,
    WINDOW_SIZE, INPUT_SIZE, POS_SIZE, YOLO_MODEL
)

SUPPORTED = {".avi", ".mp4", ".mov", ".mkv"}


# ── Core extraction ───────────────────────────────────────────────────────────

def extract_sequences(video_path: Path, yolo: YOLO, stride: int = 15) -> list[np.ndarray]:
    """
    Process one video → list of (30, 170) windows.

    stride=15 on 30fps → 50% overlap → more windows per video.
    """
    cap = cv2.VideoCapture(str(video_path))
    if not cap.isOpened():
        print(f"  [WARN] Cannot open {video_path.name}, skipping.")
        return []

    all_features: list[np.ndarray] = []
    prev_pos = np.zeros(POS_SIZE, dtype=np.float32)

    while True:
        ok, frame = cap.read()
        if not ok:
            break
        results  = yolo(frame, verbose=False)
        curr_pos = extract_positions(results[0])
        features = build_frame_features(curr_pos, prev_pos)
        prev_pos = curr_pos.copy()
        all_features.append(features)

    cap.release()

    sequences: list[np.ndarray] = []
    frame_buffer: list[np.ndarray] = []
    for feat in all_features:
        frame_buffer.append(feat)
        if len(frame_buffer) == WINDOW_SIZE:
            sequences.append(np.stack(frame_buffer, axis=0))
            frame_buffer = frame_buffer[stride:]

    return sequences


# ── Video list processor ──────────────────────────────────────────────────────

def process_video_list(fight_videos: list, nofight_videos: list,
                       yolo: YOLO, stride: int,
                       split_name: str, out_dir: Path) -> tuple[np.ndarray, np.ndarray]:
    """
    Extract sequences from explicit lists, save .npy files, return (X, y).
    fight_videos → label 1,  nofight_videos → label 0
    """
    all_seqs:   list[np.ndarray] = []
    all_labels: list[int]        = []

    for label, videos, class_name in [(1, fight_videos, "Fight/Violence"),
                                       (0, nofight_videos, "NonFight/Normal")]:
        print(f"\n  [{split_name}] {class_name}: {len(videos)} videos")
        for video in tqdm(videos, desc=f"    {class_name}"):
            seqs = extract_sequences(video, yolo, stride)
            all_seqs.extend(seqs)
            all_labels.extend([label] * len(seqs))

    X = np.stack(all_seqs, axis=0).astype(np.float32)
    y = np.array(all_labels, dtype=np.int64)

    np.save(out_dir / f"{split_name}_sequences.npy", X)
    np.save(out_dir / f"{split_name}_labels.npy",    y)
    print(f"\n  [{split_name}] Done — {len(y)} sequences "
          f"(fight={int(y.sum())}, no-fight={int((y==0).sum())})")
    return X, y


def process_split(split_dir: Path, yolo: YOLO, stride: int,
                  split_name: str, out_dir: Path) -> tuple[np.ndarray, np.ndarray]:
    """Process a RWF-2000 style Fight/NonFight directory."""
    fight_videos   = sorted([p for p in (split_dir / "Fight").iterdir()
                              if p.suffix.lower() in SUPPORTED])
    nofight_videos = sorted([p for p in (split_dir / "NonFight").iterdir()
                              if p.suffix.lower() in SUPPORTED])
    return process_video_list(fight_videos, nofight_videos, yolo, stride, split_name, out_dir)


# ── RWF-2000 ──────────────────────────────────────────────────────────────────

def build_rwf(dataset_root: Path, yolo: YOLO, stride: int,
              test_holdout: int, out_dir: Path):
    """Extract RWF-2000 train/val/test splits."""
    train_dir = dataset_root / "train"
    if train_dir.exists():
        fight_all   = sorted([p for p in (train_dir / "Fight").iterdir()
                               if p.suffix.lower() in SUPPORTED])
        nofight_all = sorted([p for p in (train_dir / "NonFight").iterdir()
                               if p.suffix.lower() in SUPPORTED])

        random.seed(42)
        test_fight   = random.sample(fight_all,   test_holdout)
        test_nofight = random.sample(nofight_all, test_holdout)
        test_set     = set(test_fight) | set(test_nofight)
        train_fight   = [v for v in fight_all   if v not in test_set]
        train_nofight = [v for v in nofight_all if v not in test_set]

        print(f"\n{'='*50}")
        print(f"RWF-2000 Train: {len(train_fight)} fight + {len(train_nofight)} non-fight")
        print(f"RWF-2000 Test:  {len(test_fight)} fight + {len(test_nofight)} non-fight (held out)")
        process_video_list(train_fight,  train_nofight,  yolo, stride, "rwf_train", out_dir)
        process_video_list(test_fight,   test_nofight,   yolo, stride, "test",      out_dir)

    val_dir = dataset_root / "val"
    if val_dir.exists():
        print(f"\n{'='*50}\nRWF-2000 Val")
        process_split(val_dir, yolo, stride, "val", out_dir)


# ── SCVD ──────────────────────────────────────────────────────────────────────

def build_scvd(scvd_converted: Path, yolo: YOLO, stride: int, out_dir: Path):
    """
    Extract SCVD_converted dataset.
    Folder structure: Train/Test → Normal / Violence / Weaponized (skipped)
    Normal   → label 0   |   Violence → label 1   |   Weaponized → ignored
    """
    for split_name, folder in [("scvd_train", "Train"), ("scvd_test", "Test")]:
        split_dir = scvd_converted / folder
        if not split_dir.exists():
            print(f"[WARN] Not found: {split_dir}, skipping.")
            continue

        violence_videos = sorted([p for p in (split_dir / "Violence").iterdir()
                                   if p.suffix.lower() in SUPPORTED])
        normal_videos   = sorted([p for p in (split_dir / "Normal").iterdir()
                                   if p.suffix.lower() in SUPPORTED])

        print(f"\n{'='*50}")
        print(f"SCVD {folder}: {len(violence_videos)} violence + {len(normal_videos)} normal "
              f"(Weaponized skipped)")
        process_video_list(violence_videos, normal_videos, yolo, stride, split_name, out_dir)


# ── Merge RWF train + SCVD train ─────────────────────────────────────────────

def merge_train(out_dir: Path):
    """
    Combine rwf_train + scvd_train into train_sequences/labels.npy.
    If SCVD was not extracted, just rename rwf_train → train.
    """
    rwf_x = np.load(out_dir / "rwf_train_sequences.npy")
    rwf_y = np.load(out_dir / "rwf_train_labels.npy")

    scvd_path = out_dir / "scvd_train_sequences.npy"
    if scvd_path.exists():
        scvd_x = np.load(scvd_path)
        scvd_y = np.load(out_dir / "scvd_train_labels.npy")
        X = np.concatenate([rwf_x, scvd_x], axis=0)
        y = np.concatenate([rwf_y, scvd_y], axis=0)
        print(f"\nMerged train: RWF-2000 ({len(rwf_y)}) + SCVD ({len(scvd_y)}) "
              f"= {len(y)} sequences")
    else:
        X, y = rwf_x, rwf_y
        print(f"\nTrain: {len(y)} sequences (RWF-2000 only)")

    np.save(out_dir / "train_sequences.npy", X)
    np.save(out_dir / "train_labels.npy",    y)
    print(f"  fight={int(y.sum())}, no-fight={int((y==0).sum())}")


# ── Entry point ───────────────────────────────────────────────────────────────

def build_dataset(dataset_root: str, scvd_converted: str | None,
                  output_dir: str, stride: int, test_holdout: int):
    out_dir = Path(output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    import torch
    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Loading {YOLO_MODEL} on {device}...")
    yolo = YOLO(YOLO_MODEL)
    yolo.to(device)

    # 1. RWF-2000
    build_rwf(Path(dataset_root), yolo, stride, test_holdout, out_dir)

    # 2. SCVD (optional)
    if scvd_converted:
        build_scvd(Path(scvd_converted), yolo, stride, out_dir)

    # 3. Merge RWF train + SCVD train → train_sequences.npy
    merge_train(out_dir)

    print("\nAll done! Files saved:")
    for f in sorted(out_dir.glob("*.npy")):
        print(f"  {f.name}  ({f.stat().st_size / 1024 / 1024:.1f} MB)")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--dataset",      default="data/RWF-2000",
                        help="Path to RWF-2000 root (contains train/ and val/)")
    parser.add_argument("--scvd",         default=None,
                        help="Path to SCVD_converted folder (optional)")
    parser.add_argument("--output",       default="data")
    parser.add_argument("--stride",       type=int, default=15)
    parser.add_argument("--test_holdout", type=int, default=100,
                        help="Videos per class held out from RWF-2000 train as unseen test")
    args = parser.parse_args()
    build_dataset(args.dataset, args.scvd, args.output, args.stride, args.test_holdout)
