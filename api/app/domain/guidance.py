from __future__ import annotations

from dataclasses import dataclass

DEFAULT_GUIDANCE_STEPS = [
    "해당 구역 접근을 즉시 통제한다.",
    "안전 담당자에게 보고한다.",
    "균열 범위를 측정하고 기록한다.",
    "승인된 보수 절차에 따라 처리한다.",
]


@dataclass(frozen=True)
class GuidancePlan:
    inspection_id: str
    defect_class: str
    action_steps: list[str]
    severity: str
    referenced_doc: str


def default_guidance(inspection_id: str, defect_class: str = "균열") -> GuidancePlan:
    return GuidancePlan(
        inspection_id=inspection_id,
        defect_class=defect_class,
        action_steps=list(DEFAULT_GUIDANCE_STEPS),
        severity="HIGH",
        referenced_doc="SIGTTO-LNG-TANK-INSPECTION-V3.pdf",
    )

