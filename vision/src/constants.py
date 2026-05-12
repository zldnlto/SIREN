"""Shared constants for the vision pipeline."""

from __future__ import annotations

from pathlib import Path

DEFAULT_CLASS_NAMES: tuple[str, ...] = (
    "균열",
    "스크래치",
    "도장흐름",
    "도막떨어짐",
    "도막분리",
    "보온재손상",
    "탱크클리닝불량",
    "표면양품",
)

# YOLOv8n-seg baseline은 640 입력을 기준으로 맞춘다.
DEFAULT_IMAGE_SIZE = 640
DEFAULT_BATCH_SIZE = 16
DEFAULT_EPOCHS = 50
DEFAULT_CONFIDENCE_THRESHOLD = 0.5
DEFAULT_DEVICE = "cpu"
DEFAULT_YOLO_MODEL = "yolov8n-seg.pt"

# Colab에서 Drive를 마운트했을 때 결과를 모아두는 기본 위치다.
DEFAULT_COLAB_DRIVE_RUN_ROOT = Path("/content/drive/MyDrive/siren/runs")

