from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.guidance import Guidance


async def get_by_ontology_id(db: AsyncSession, ontology_id: str) -> Guidance | None:
    result = await db.execute(
        select(Guidance).where(Guidance.ontology_id == ontology_id)
    )
    return result.scalar_one_or_none()
