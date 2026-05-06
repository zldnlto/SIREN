import uuid
from datetime import datetime

from app.schemas.detection import DEFECT_CLASSES, DefectItem, DetectionResult


def run_detection(inspection_id: str) -> DetectionResult:
    mock_defects = [
        DefectItem(
            class_name=DEFECT_CLASSES[0],
            confidence=0.92,
            bbox=[10.0, 20.0, 100.0, 80.0],
        ),
        DefectItem(
            class_name=DEFECT_CLASSES[1],
            confidence=0.78,
            bbox=[50.0, 60.0, 200.0, 150.0],
        ),
    ]
    return DetectionResult(
        id=str(uuid.uuid4()),
        inspection_id=inspection_id,
        defects=mock_defects,
        confidence=0.85,
        detected_at=datetime.now(),
    )
