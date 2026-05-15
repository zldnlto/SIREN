"""Shared constants for the vision pipeline."""

from __future__ import annotations

from pathlib import Path

# canonical_class_name 기준 (defect × part_name, ontology_id 정렬)
# 양품(normal)·탱크클리닝불량(classification-only)은 detection 대상 제외
# → ADR-001, ADR-002 참고
DEFAULT_CLASS_NAMES: tuple[str, ...] = (
    "crack_paint",
    "paint_peel_paint",
    "paint_separation_paint",
    "paint_flow_paint",
    "insulation_damage_insulation",
    "scratch_paint",
    "scratch_base",
    "scratch_insulation",
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
