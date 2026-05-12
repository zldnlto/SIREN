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

# domain 이름 → domain_code 매핑 (ERD 주석 기준)
DOMAIN_CODES: dict[str, int] = {
    "표면처리": 25,
    "용접": 11,
    "절단": 12,
    "케이블": 13,
    "파이프": 14,
    "폼스프레이": 15,
}


def confidence_to_severity(confidence: float) -> str:
    if confidence >= 0.8:
        return "HIGH"
    if confidence >= 0.6:
        return "MEDIUM"
    return "LOW"


class DefectItem(BaseModel):
    defect_name: str
    confidence_score: float
    severity: str
    bbox: list[float] | None = None
    part_name: str | None = None
    gradcam_key: str | None = None


class DetectionResult(BaseModel):
    id: str
    inspection_id: str
    defects: list[DefectItem]
    confidence: float
    detected_at: datetime
