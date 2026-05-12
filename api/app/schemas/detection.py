from datetime import datetime

from pydantic import BaseModel

DEFECT_CLASSES = [
    "균열",
    "스크래치",
    "도장흐름",
    "도막떨어짐",
    "도막분리",
    "보온재손상",
    "탱크클리닝불량",
    "표면양품",
]

# class_code 6, 7 은 분류(is_cls=True) — bbox 없음
CLS_ONLY_CODES = {6, 7}


def confidence_to_severity(confidence: float) -> str:
    if confidence >= 0.8:
        return "HIGH"
    if confidence >= 0.6:
        return "MEDIUM"
    return "LOW"


class DefectItem(BaseModel):
    class_name: str
    confidence: float
    bbox: list[float] | None = None


class DetectionResult(BaseModel):
    id: str
    inspection_id: str
    defects: list[DefectItem]
    confidence: float
    detected_at: datetime
