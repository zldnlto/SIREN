from __future__ import annotations

from dataclasses import dataclass

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


@dataclass(frozen=True)
class DetectionItemCore:
    defect_name: str
    confidence_score: float
    severity: str
    bbox: list[float] | None = None


def confidence_to_severity(confidence: float) -> str:
    if confidence >= 0.8:
        return "HIGH"
    if confidence >= 0.6:
        return "MEDIUM"
    return "LOW"


def domain_code_for(domain: str) -> int:
    return DOMAIN_CODES.get(domain, 25)


def defect_name_for(class_code: int) -> str:
    return DEFECT_CLASSES[class_code]


def bbox_for_class(class_code: int, bbox_raw: list[float]) -> dict | None:
    if class_code in CLS_ONLY_CODES:
        return None
    return {
        "x_min": bbox_raw[0],
        "y_min": bbox_raw[1],
        "x_max": bbox_raw[2],
        "y_max": bbox_raw[3],
    }


def build_detection_item(class_code: int, confidence: float, bbox_raw: list[float]) -> DetectionItemCore:
    return DetectionItemCore(
        defect_name=defect_name_for(class_code),
        confidence_score=confidence,
        severity=confidence_to_severity(confidence),
        bbox=None if class_code in CLS_ONLY_CODES else bbox_raw,
    )


def build_persisted_defect(
    inspection_id,
    domain_code: int,
    class_code: int,
    confidence: float,
    bbox_raw: list[float],
) -> dict:
    return {
        "inspection_id": inspection_id,
        "domain_code": domain_code,
        "class_code": class_code,
        "defect_name": defect_name_for(class_code),
        "confidence_score": confidence,
        "bbox": bbox_for_class(class_code, bbox_raw),
        "severity": confidence_to_severity(confidence),
    }


def average_confidence(confidences: list[float]) -> float:
    if not confidences:
        return 0.0
    return sum(confidences) / len(confidences)

