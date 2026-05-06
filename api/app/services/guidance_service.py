from app.schemas.detection import DEFECT_CLASSES
from app.schemas.guidance import GuidanceResponse


def get_guidance(inspection_id: str) -> GuidanceResponse:
    return GuidanceResponse(
        inspection_id=inspection_id,
        defect_class=DEFECT_CLASSES[0],
        action_steps=[
            "해당 구역 접근을 즉시 통제한다.",
            "안전 담당자에게 보고한다.",
            "균열 범위를 측정하고 기록한다.",
            "승인된 보수 절차에 따라 처리한다.",
        ],
        severity="HIGH",
        referenced_doc="SIGTTO-LNG-TANK-INSPECTION-V3.pdf",
    )
