from sqlalchemy.ext.asyncio import AsyncSession

from app.application.guidance_usecase import get_guidance as get_guidance_usecase
from app.repositories.guidance_repository import get_by_ontology_id
from app.schemas.guidance import GuidanceResponse


async def get_guidance(db: AsyncSession, ontology_id: str) -> GuidanceResponse | None:
    plan = await get_guidance_usecase(
        db,
        ontology_id,
        get_by_ontology_id_fn=get_by_ontology_id,
    )
    if plan is None:
        return None
    return GuidanceResponse(
        ontology_id=plan.ontology_id,
        display_label=plan.display_label,
        quality_state=plan.quality_state,
        cause=plan.cause,
        action_steps=plan.action_steps,
        reinspection_criteria=plan.reinspection_criteria,
        disclaimer=plan.disclaimer,
        referenced_doc=plan.referenced_doc,
    )
