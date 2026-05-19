from __future__ import annotations

from dataclasses import dataclass
from typing import Literal

CANONICAL_TO_ONTOLOGY: dict[str, str] = {
    "crack_paint": "surface_treatment.crack.paint",
    "coating_drop_paint": "surface_treatment.coating_drop.paint",
    "coating_separation_paint": "surface_treatment.coating_separation.paint",
    "paint_run_paint": "surface_treatment.paint_run.paint",
    "insulation_damage_insulation": "surface_treatment.insulation_damage.insulation",
    "scratch_paint": "surface_treatment.scratch.paint",
    "scratch_base_material": "surface_treatment.scratch.base_material",
    "scratch_insulation": "surface_treatment.scratch.insulation",
    "tank_cleaning_defect_base_material": "surface_treatment.tank_cleaning_defect.base_material",
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

# class_code → canonical_class_name (surface_treatment 도메인 기준 mock)
CLASS_CODE_MAP: dict[int, str] = {
    0: "crack_paint",
    1: "scratch_paint",
    2: "paint_run_paint",
    3: "coating_drop_paint",
    4: "coating_separation_paint",
    5: "insulation_damage_insulation",
    6: "tank_cleaning_defect_base_material",
    7: "background",
}

CLS_ONLY_CODES = {6, 7}


def quality_state_for(canonical_class_name: str) -> Literal["defect", "good"]:
    return "good" if canonical_class_name == "background" else "defect"


def ontology_id_for(canonical_class_name: str) -> str:
    return CANONICAL_TO_ONTOLOGY.get(canonical_class_name, "unknown")


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
    quality_state: Literal["defect", "good"]
    confidence_score: float
    bbox: list[float] | None = None
    gradcam_key: str | None = None


def build_detection_item(
    class_code: int, confidence: float, bbox_raw: list[float]
) -> DetectionItemCore:
    canonical = canonical_class_for(class_code)
    return DetectionItemCore(
        canonical_class_name=canonical,
        quality_state=quality_state_for(canonical),
        confidence_score=confidence,
        bbox=None if class_code in CLS_ONLY_CODES else bbox_raw,
    )


def build_persisted_defect(
    inspection_id,
    domain_code: int,
    class_code: int,
    confidence: float,
    bbox_raw: list[float],
) -> dict:
    canonical = canonical_class_for(class_code)
    return {
        "inspection_id": inspection_id,
        "domain_code": domain_code,
        "class_code": class_code,
        "canonical_class_name": canonical,
        "quality_state": quality_state_for(canonical),
        "confidence_score": confidence,
        "bbox": bbox_for_class(class_code, bbox_raw),
    }


def average_confidence(confidences: list[float]) -> float:
    if not confidences:
        return 0.0
    return sum(confidences) / len(confidences)
