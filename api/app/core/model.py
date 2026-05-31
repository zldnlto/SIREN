from __future__ import annotations

from pathlib import Path

from ultralytics import YOLO

from app.core.config import settings

_model: YOLO | None = None


def get_model() -> YOLO:
    global _model
    if _model is None:
        path = Path(settings.MODEL_PATH)
        if not path.exists():
            raise FileNotFoundError(f"YOLO 모델 파일 없음: {path}")
        _model = YOLO(str(path))
    return _model
