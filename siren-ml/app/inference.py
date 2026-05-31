from __future__ import annotations

import io
from pathlib import Path

import numpy as np
from PIL import Image
from ultralytics import YOLO

from app.config import settings

_model: YOLO | None = None


def get_model() -> YOLO:
    global _model
    if _model is None:
        path = Path(settings.MODEL_PATH)
        if not path.exists():
            raise FileNotFoundError(f"모델 파일 없음: {path}")
        _model = YOLO(str(path))
    return _model


def run_inference(image_bytes: bytes) -> list[dict]:
    model = get_model()
    image = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img_array = np.array(image)

    results = model.predict(
        img_array,
        conf=settings.CONFIDENCE_THRESHOLD,
        verbose=False,
    )

    detections = []
    for result in results:
        if result.boxes is None:
            continue
        for box in result.boxes:
            x1, y1, x2, y2 = box.xyxy[0].tolist()
            cls_id = int(box.cls[0].item())
            detections.append(
                {
                    "class_code": cls_id,
                    "class_name": model.names[cls_id],
                    "confidence": round(float(box.conf[0].item()), 4),
                    "bbox": [x1, y1, x2, y2],
                }
            )
    return detections
