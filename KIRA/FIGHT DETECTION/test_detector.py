"""
Quick smoke-test: run the detector on a video file (or webcam)
and display the annotated output with YOLO26-pose + mLSTM classification.
Video files play slower than real-time — that is normal, inference takes
~30-80ms per frame. On a live camera the detector just processes the latest frame.

Usage:
    python test_detector.py                    # webcam
    python test_detector.py --video fight.mp4  # video file
"""

import argparse
import cv2
from detector import FightDetector


def run(source: str | int = 0):
    detector = FightDetector()
    cap      = cv2.VideoCapture(source)

    if not cap.isOpened():
        print(f"Cannot open: {source}")
        return

    print("Press Q to quit.")
    while True:
        ok, frame = cap.read()
        if not ok:
            break

        result = detector.process_frame(frame)

        status = (
            f"FIGHT {result['confidence']:.0%}" if result["fight"]
            else f"OK  (buffer: {len(detector.buffer)}/30)"
        )
        print(f"\r{status}   ", end="", flush=True)

        cv2.imshow("Fight Detector", result["annotated_frame"])
        if cv2.waitKey(1) & 0xFF == ord("q"):
            break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--video", default=None,
                        help="Path to video file (omit for webcam)")
    args = parser.parse_args()

    source = args.video if args.video else 0
    run(source)
