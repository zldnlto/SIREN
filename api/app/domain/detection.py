from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

CANONICAL_TO_ONTOLOGY: dict[str, str] = {
    # surface_treatment — vision/src/constants.py DEFAULT_CLASS_NAMES 기준
    "crack_paint": "surface_treatment.crack.paint",
    "paint_peel_paint": "surface_treatment.coating_drop.paint",
    "paint_separation_paint": "surface_treatment.coating_separation.paint",
    "paint_flow_paint": "surface_treatment.paint_run.paint",
    "insulation_damage_insulation": "surface_treatment.insulation_damage.insulation",
    "scratch_paint": "surface_treatment.scratch.paint",
    "scratch_base": "surface_treatment.scratch.base_material",
    "scratch_insulation": "surface_treatment.scratch.insulation",
    # other domains (future)
    "weld_defect_joint": "welding.weld_defect.joint",
    "weld_blowhole_joint": "welding.weld_blowhole.joint",
    "cut_defect_base_material": "cutting.cut_defect.base_material",
    "cut_defect_insulation": "cutting.cut_defect.insulation",
    "binding_defect_cable_tie": "cable.binding_defect.cable_tie",
    "cable_install_defect_cable_gland": "cable.cable_install_defect.cable_gland",
    "cable_damage_cable": "cable.cable_damage.cable",
    "bolt_defect_pipe": "pipe.bolt_defect.pipe",
    "foam_spray_defect_urethane_foam": "foam_spray.foam_spray_defect.urethane_foam",
    "background": "background",
}

CANONICAL_TO_DISPLAY_LABEL: dict[str, str] = {
    # surface_treatment
    "crack_paint": "균열 (도장)",
    "paint_peel_paint": "도막떨어짐 (도장)",
    "paint_separation_paint": "도막분리 (도장)",
    "paint_flow_paint": "도장흐름 (도장)",
    "insulation_damage_insulation": "보온재손상 (보온재)",
    "scratch_paint": "스크래치 (도장)",
    "scratch_base": "스크래치 (모재)",
    "scratch_insulation": "스크래치 (보온재)",
    # other domains (future)
    "weld_defect_joint": "용접불량 (조인트)",
    "weld_blowhole_joint": "용접블로우홀 (조인트)",
    "cut_defect_base_material": "절단불량 (모재)",
    "cut_defect_insulation": "절단불량 (보온재)",
    "binding_defect_cable_tie": "바인딩불량 (케이블타이)",
    "cable_install_defect_cable_gland": "케이블설치불량 (케이블그랜드)",
    "cable_damage_cable": "케이블손상 (케이블)",
    "bolt_defect_pipe": "볼트체결불량 (파이프)",
    "foam_spray_defect_urethane_foam": "폼스프레이불량 (우레탄폼)",
    "background": "양호",
}

# class_code → canonical_class_name (vision/src/constants.py DEFAULT_CLASS_NAMES 순서와 동일)
CLASS_CODE_MAP: dict[int, str] = {
    0: "crack_paint",
    1: "paint_peel_paint",
    2: "paint_separation_paint",
    3: "paint_flow_paint",
    4: "insulation_damage_insulation",
    5: "scratch_paint",
    6: "scratch_base",
    7: "scratch_insulation",
}

CLS_ONLY_CODES: set[int] = set()


def quality_state_for(canonical_class_name: str) -> Literal["defect", "good"]:
    return "good" if canonical_class_name == "background" else "defect"


def ontology_id_for(canonical_class_name: str) -> str:
    return CANONICAL_TO_ONTOLOGY.get(canonical_class_name, "unknown")


def display_label_for(canonical_class_name: str) -> str:
    return CANONICAL_TO_DISPLAY_LABEL.get(canonical_class_name, canonical_class_name)


def annotation_domain_for(ontology_id: str) -> str | None:
    segments = ontology_id.split(".")
    return segments[0] if len(segments) >= 2 else None


def canonical_class_for(class_code: int) -> str:
    return CLASS_CODE_MAP.get(class_code, "background")


def bbox_for_class(class_code: int, bbox_raw: list[float]) -> dict | None:
    if class_code in CLS_ONLY_CODES:
        return None
    return {
        "x_min": bbox_raw[0],
        "y_min": bbox_raw[1],
        "x_max": bbox_raw[2],
        "y_max": bbox_raw[3],
    }


@dataclass(frozen=True)
class DetectionItemCore:
    canonical_class_name: str
    ontology_id: str
    display_label: str
    annotation_domain: str | None
    quality_state: Literal["defect", "good"]
    confidence_score: float
    bbox: list[float] | None = None
    gradcam_key: str | None = None


def build_detection_item(
    class_code: int, confidence: float, bbox_raw: list[float]
) -> DetectionItemCore:
    canonical = canonical_class_for(class_code)
    oid = ontology_id_for(canonical)
    return DetectionItemCore(
        canonical_class_name=canonical,
        ontology_id=oid,
        display_label=display_label_for(canonical),
        annotation_domain=annotation_domain_for(oid),
        quality_state=quality_state_for(canonical),
        confidence_score=confidence,
        bbox=None if class_code in CLS_ONLY_CODES else bbox_raw,
    )


def build_persisted_defect(
    inspection_id,
    detection_job_id,
    domain_code: int,
    class_code: int,
    confidence: float,
    bbox_raw: list[float],
) -> dict:
    canonical = canonical_class_for(class_code)
    return {
        "inspection_id": inspection_id,
        "detection_job_id": detection_job_id,
        "domain_code": domain_code,
        "class_code": class_code,
        "canonical_class_name": canonical,
        "ontology_id": ontology_id_for(canonical),
        "quality_state": quality_state_for(canonical),
        "confidence_score": confidence,
        "bbox": bbox_for_class(class_code, bbox_raw),
    }


def average_confidence(confidences: list[float]) -> float:
    if not confidences:
        return 0.0
    return sum(confidences) / len(confidences)
