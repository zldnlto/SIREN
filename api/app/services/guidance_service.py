from app.application.guidance_usecase import get_guidance as get_guidance_usecase
from app.schemas.guidance import GuidanceResponse


def get_guidance(inspection_id: str) -> GuidanceResponse:
    plan = get_guidance_usecase(inspection_id)
    return GuidanceResponse(
        inspection_id=plan.inspection_id,
        defect_class=plan.defect_class,
        action_steps=plan.action_steps,
        severity=plan.severity,
        referenced_doc=plan.referenced_doc,
    )
