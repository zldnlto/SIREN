from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.guidance import GuidancePlan
from app.repositories.guidance_repository import get_by_ontology_id


async def get_guidance(db: AsyncSession, ontology_id: str) -> GuidancePlan | None:
    record = await get_by_ontology_id(db, ontology_id)
    if record is None:
        return None
    return GuidancePlan(
        ontology_id=record.ontology_id,
        display_label=record.display_label,
        quality_state=record.quality_state,
        cause=record.cause,
        action_steps=list(record.action_steps),
        reinspection_criteria=record.reinspection_criteria,
        disclaimer=record.disclaimer,
        referenced_doc=record.referenced_doc,
    )
