# Google drive 업로드 용 
# Drive Mount, 경로 상수

import os
from pathlib import Path

# ── Drive 경로 ──────────────────────────────────────────
DRIVE_ROOT     = Path("/content/drive/MyDrive/siren")
DRIVE_DATA     = DRIVE_ROOT / "data"

OLD_IMAGES     = DRIVE_DATA / "resized"          # 마이그레이션 전 원본

NEW_IMAGES     = DRIVE_DATA / "images"
NEW_LABELS_SEG = DRIVE_DATA / "labels" / "segmentation"
NEW_LABELS_DET = DRIVE_DATA / "labels" / "detection"
MANIFESTS      = DRIVE_DATA / "manifests"
METADATA       = DRIVE_DATA / "metadata"

# ── Colab 로컬 경로 (ephemeral) ─────────────────────────
LOCAL_DATA     = Path("/content/datasets")
LOCAL_IMAGES   = LOCAL_DATA / "images"
CACHE_DIR      = LOCAL_DATA / "cache"            # Drive 밖 고정

# ── 디렉토리 초기화 ─────────────────────────────────────
INIT_DIRS = [
    NEW_IMAGES, NEW_LABELS_SEG, NEW_LABELS_DET,
    MANIFESTS, METADATA,
    LOCAL_DATA, CACHE_DIR,
]

def setup():
    for d in INIT_DIRS:
        d.mkdir(parents=True, exist_ok=True)
    print("[setup] 디렉토리 초기화 완료")
    print(f"  CACHE_DIR  : {CACHE_DIR}")
    print(f"  NEW_IMAGES : {NEW_IMAGES}")

if __name__ == "__main__":
    setup()