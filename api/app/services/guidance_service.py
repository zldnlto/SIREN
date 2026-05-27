from chromadb import Collection
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.guidance_usecase import get_guidance as get_guidance_usecase
from app.repositories import sop_repository
from app.repositories.guidance_repository import get_by_ontology_id
from app.schemas.guidance import GuidanceResponse, SopChunk


async def get_guidance(
    db: AsyncSession,
    ontology_id: str,
    chroma_collection: Collection | None = None,
) -> GuidanceResponse | None:
    get_sop_chunks_fn = None
    if chroma_collection is not None:
        get_sop_chunks_fn = lambda oid, qt: sop_repository.get_by_ontology_id(
            chroma_collection, oid, query_text=qt
        )

    plan = await get_guidance_usecase(
        db,
        ontology_id,
        get_by_ontology_id_fn=get_by_ontology_id,
        get_sop_chunks_fn=get_sop_chunks_fn,
    )
    if plan is None:
        return None

    sop_excerpt = None
    if plan.sop_excerpt:
        sop_excerpt = [SopChunk(**chunk) for chunk in plan.sop_excerpt]

    return GuidanceResponse(
        ontology_id=plan.ontology_id,
        display_label=plan.display_label,
        quality_state=plan.quality_state,
        cause=plan.cause,
        action_steps=plan.action_steps,
        reinspection_criteria=plan.reinspection_criteria,
        disclaimer=plan.disclaimer,
        referenced_doc=plan.referenced_doc,
        sop_excerpt=sop_excerpt,
    )
