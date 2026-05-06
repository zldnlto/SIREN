from datetime import datetime

from pydantic import BaseModel

# 결함 클래스 목록 (domain_label_map.json 기준, 표면처리 도메인)
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


class DefectItem(BaseModel):
    class_name: str
    confidence: float
    bbox: list[float]


class DetectionResult(BaseModel):
    id: str
    inspection_id: str
    defects: list[DefectItem]
    confidence: float
    detected_at: datetime
