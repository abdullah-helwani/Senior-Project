"""
Train the FightmLSTM classifier on extracted keypoint + velocity sequences.

Improvements over baseline:
  - Focal Loss: focuses on hard examples instead of easy ones (+2-3% expected)
  - Keypoint augmentation: Gaussian noise + random horizontal flip
  - Bigger model: hidden=384, layers=3 (better for RTX 5060 with more VRAM)
  - Multi-dataset: trains on RWF-2000 + SCVD combined if available
  - Two unseen test sets: RWF-2000 holdout + SCVD Test

Usage:
    # Standard (RTX 2060, same as before)
    python train.py --epochs 80 --batch 32

    # Bigger model on RTX 5060 (recommended for paper)
    python train.py --epochs 80 --batch 64 --hidden 384 --layers 3 --heads 6

Saves best model to models/fight_mlstm.pt (includes architecture config).
"""

import argparse
import numpy as np
import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader, TensorDataset, WeightedRandomSampler
from sklearn.metrics import classification_report, confusion_matrix
from pathlib import Path

from detector import FightmLSTM

DATA_DIR   = Path("data")
MODELS_DIR = Path("models")
MODELS_DIR.mkdir(exist_ok=True)
MODEL_PATH = MODELS_DIR / "fight_mlstm.pt"


# ── Focal Loss ────────────────────────────────────────────────────────────────

class FocalLoss(nn.Module):
    """
    Focal Loss (Lin et al., RetinaNet 2017).

    Down-weights easy, well-classified examples so the model focuses
    training effort on the hard misclassified ones.

    gamma=0 → identical to CrossEntropyLoss
    gamma=2 → hard examples get ~4× more weight than easy ones
    """
    def __init__(self, gamma: float = 2.0):
        super().__init__()
        self.gamma = gamma

    def forward(self, logits: torch.Tensor, targets: torch.Tensor) -> torch.Tensor:
        ce = F.cross_entropy(logits, targets, reduction="none")
        pt = torch.exp(-ce)                           # probability of correct class
        return ((1 - pt) ** self.gamma * ce).mean()  # down-weight easy (high pt)


# ── Augmentation ──────────────────────────────────────────────────────────────

# Feature layout (170 total):
#   Position [0–101]:  person0 kp0(x,y,c) kp1(x,y,c) ... kp16(x,y,c)  ← 51 values
#                      person1 kp0(x,y,c) kp1(x,y,c) ... kp16(x,y,c)  ← 51 values
#   Velocity [102–169]: person0 kp0(dx,dy) kp1(dx,dy) ... kp16(dx,dy)  ← 34 values
#                       person1 kp0(dx,dy) kp1(dx,dy) ... kp16(dx,dy)  ← 34 values
_N_KP      = 17
_POS_X_IDX = ([kp * 3       for kp in range(_N_KP)] +   # person 0 x coords
              [51 + kp * 3  for kp in range(_N_KP)])     # person 1 x coords
_VEL_DX_IDX = ([102 + kp * 2      for kp in range(_N_KP)] +   # person 0 dx
               [102 + 34 + kp * 2 for kp in range(_N_KP)])    # person 1 dx


def augment_batch(X: torch.Tensor) -> torch.Tensor:
    """
    Apply two augmentations to a training batch (B, T, 170):

    1. Gaussian noise (std=0.02) on position x,y coords — simulates
       slight camera angle/distance differences between deployments.

    2. Random horizontal flip (50% probability per sample) — fight from
       left-to-right and right-to-left are the same fight.
       x → 1-x for position coords, dx → -dx for velocity.
    """
    X = X.clone()
    B = X.shape[0]

    # 1. Gaussian noise on position x,y (not confidence, not velocity)
    for idx in _POS_X_IDX:       # x coords
        X[:, :, idx] += torch.randn(B, X.shape[1], device=X.device) * 0.02
    for idx in _POS_X_IDX:       # y coords (next index after each x)
        y_idx = idx + 1
        if y_idx < 102:           # stay within position block
            X[:, :, y_idx] += torch.randn(B, X.shape[1], device=X.device) * 0.02

    # 2. Random horizontal flip
    flip = torch.rand(B) < 0.5
    if flip.any():
        X[flip][:, :, _POS_X_IDX]  = 1.0 - X[flip][:, :, _POS_X_IDX]   # x → 1-x
        X[flip][:, :, _VEL_DX_IDX] = -X[flip][:, :, _VEL_DX_IDX]       # dx → -dx

    return X


# ── Data loading ──────────────────────────────────────────────────────────────

def load_data(data_dir: Path = DATA_DIR):
    # Main training data (RWF-2000 + SCVD merged by extract_dataset.py)
    X_train = np.load(data_dir / "train_sequences.npy")
    y_train = np.load(data_dir / "train_labels.npy")

    # Validation (RWF-2000 official val split)
    X_val = np.load(data_dir / "val_sequences.npy")
    y_val = np.load(data_dir / "val_labels.npy")

    print(f"Train: X={X_train.shape}  "
          f"(fight={int(y_train.sum())}, no-fight={int((y_train==0).sum())})")
    print(f"Val:   X={X_val.shape}    "
          f"(fight={int(y_val.sum())},   no-fight={int((y_val==0).sum())})")

    # RWF-2000 holdout test
    X_test, y_test = None, None
    if (data_dir / "test_sequences.npy").exists():
        X_test = np.load(data_dir / "test_sequences.npy")
        y_test = np.load(data_dir / "test_labels.npy")
        print(f"Test (RWF-2000 unseen): X={X_test.shape}  "
              f"(fight={int(y_test.sum())}, no-fight={int((y_test==0).sum())})")

    # SCVD holdout test (second independent test set)
    X_scvd, y_scvd = None, None
    if (data_dir / "scvd_test_sequences.npy").exists():
        X_scvd = np.load(data_dir / "scvd_test_sequences.npy")
        y_scvd = np.load(data_dir / "scvd_test_labels.npy")
        print(f"Test (SCVD unseen):     X={X_scvd.shape}  "
              f"(fight={int(y_scvd.sum())}, no-fight={int((y_scvd==0).sum())})")

    return X_train, y_train, X_val, y_val, X_test, y_test, X_scvd, y_scvd


def make_loaders(X_train, y_train, X_val, y_val, batch_size: int):
    X_tr = torch.tensor(X_train, dtype=torch.float32)
    y_tr = torch.tensor(y_train, dtype=torch.long)
    X_vl = torch.tensor(X_val,   dtype=torch.float32)
    y_vl = torch.tensor(y_val,   dtype=torch.long)

    # Weighted sampler keeps class balance even when SCVD makes it uneven
    class_counts = np.bincount(y_train)
    weights      = 1.0 / class_counts[y_train]
    sampler      = WeightedRandomSampler(weights, num_samples=len(weights), replacement=True)

    train_loader = DataLoader(TensorDataset(X_tr, y_tr), batch_size=batch_size, sampler=sampler)
    val_loader   = DataLoader(TensorDataset(X_vl, y_vl), batch_size=batch_size, shuffle=False)
    return train_loader, val_loader


# ── Evaluation helper ─────────────────────────────────────────────────────────

def evaluate(model, X: np.ndarray, y: np.ndarray,
             device: str, batch_size: int, label: str):
    """Run model on a numpy test set and print full report."""
    print(f"\n── {label} ──")
    loader = DataLoader(
        TensorDataset(torch.tensor(X, dtype=torch.float32),
                      torch.tensor(y, dtype=torch.long)),
        batch_size=batch_size, shuffle=False,
    )
    preds, labels = [], []
    model.eval()
    with torch.no_grad():
        for Xb, yb in loader:
            preds.extend(model(Xb.to(device)).argmax(1).cpu().numpy())
            labels.extend(yb.numpy())
    print(classification_report(labels, preds, target_names=["NoFight", "Fight"]))
    print("Confusion matrix:\n", confusion_matrix(labels, preds))


# ── Training ──────────────────────────────────────────────────────────────────

def train(epochs: int = 80, batch_size: int = 32, lr: float = 5e-4,
          patience: int = 15, hidden: int = 384, layers: int = 3,
          heads: int = 6, focal_gamma: float = 2.0, augment: bool = True):

    device = "cuda" if torch.cuda.is_available() else "cpu"
    print(f"Training on: {device}")
    print(f"Model: hidden={hidden}, layers={layers}, heads={heads}")

    X_train, y_train, X_val, y_val, X_test, y_test, X_scvd, y_scvd = load_data()
    train_loader, val_loader = make_loaders(X_train, y_train, X_val, y_val, batch_size)

    model     = FightmLSTM(hidden_size=hidden, num_layers=layers,
                            num_heads=heads).to(device)
    optimizer = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=1e-4)
    criterion = FocalLoss(gamma=focal_gamma)
    scheduler = torch.optim.lr_scheduler.ReduceLROnPlateau(optimizer, patience=4, factor=0.5)

    best_val_acc = 0.0
    no_improve   = 0

    for epoch in range(1, epochs + 1):
        # ── Train ──────────────────────────────────────────────────────────────
        model.train()
        train_loss = 0.0
        for Xb, yb in train_loader:
            Xb, yb = Xb.to(device), yb.to(device)
            if augment:
                Xb = augment_batch(Xb)
            optimizer.zero_grad()
            loss = criterion(model(Xb), yb)
            loss.backward()
            nn.utils.clip_grad_norm_(model.parameters(), 1.0)
            optimizer.step()
            train_loss += loss.item() * len(Xb)
        train_loss /= len(train_loader.dataset)

        # ── Validate ───────────────────────────────────────────────────────────
        model.eval()
        val_loss  = 0.0
        all_preds, all_labels = [], []
        with torch.no_grad():
            for Xb, yb in val_loader:
                Xb, yb  = Xb.to(device), yb.to(device)
                logits   = model(Xb)
                val_loss += criterion(logits, yb).item() * len(Xb)
                all_preds.extend(logits.argmax(1).cpu().numpy())
                all_labels.extend(yb.cpu().numpy())
        val_loss /= len(val_loader.dataset)

        acc = (np.array(all_preds) == np.array(all_labels)).mean()
        scheduler.step(val_loss)
        print(f"Epoch {epoch:3d}/{epochs} | "
              f"train_loss={train_loss:.4f}  val_loss={val_loss:.4f}  val_acc={acc:.3f}")

        # Save on best val_acc
        if acc > best_val_acc:
            best_val_acc = acc
            no_improve   = 0
            # Save config alongside weights so any model size loads correctly
            torch.save({
                "config": {
                    "hidden_size": hidden,
                    "num_layers":  layers,
                    "num_heads":   heads,
                },
                "state_dict": model.state_dict(),
            }, MODEL_PATH)
            print(f"  ✓ Saved best model (val_acc={acc:.3f})")
        else:
            no_improve += 1
            if no_improve >= patience:
                print(f"Early stopping at epoch {epoch}.")
                break

    # ── Final evaluation ───────────────────────────────────────────────────────
    checkpoint = torch.load(MODEL_PATH, map_location=device)
    model.load_state_dict(checkpoint["state_dict"])

    evaluate(model, X_val,   y_val,   device, batch_size,
             "Final Validation (RWF-2000 val)")

    if X_test is not None:
        evaluate(model, X_test, y_test, device, batch_size,
                 "Test Set — RWF-2000 Unseen (held out from train)")

    if X_scvd is not None:
        evaluate(model, X_scvd, y_scvd, device, batch_size,
                 "Test Set — SCVD Unseen (real CCTV, never trained on)")

    print(f"\nModel saved to: {MODEL_PATH}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--epochs",   type=int,   default=80)
    parser.add_argument("--batch",    type=int,   default=32,
                        help="32 for RTX 2060, 64 for RTX 5060")
    parser.add_argument("--lr",       type=float, default=5e-4)
    parser.add_argument("--patience", type=int,   default=15)
    parser.add_argument("--hidden",   type=int,   default=384,
                        help="mLSTM hidden size (256=small, 384=medium, 512=large)")
    parser.add_argument("--layers",   type=int,   default=3,
                        help="Number of mLSTM layers")
    parser.add_argument("--heads",    type=int,   default=6,
                        help="Number of attention heads (hidden must be divisible by heads)")
    parser.add_argument("--gamma",    type=float, default=2.0,
                        help="Focal loss gamma (0=CrossEntropy, 2=standard focal)")
    parser.add_argument("--no-augment", action="store_true",
                        help="Disable keypoint augmentation")
    args = parser.parse_args()
    train(args.epochs, args.batch, args.lr, args.patience,
          args.hidden, args.layers, args.heads, args.gamma,
          augment=not args.no_augment)
