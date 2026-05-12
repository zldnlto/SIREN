import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.defect_item import DefectItem


async def create_many(db: AsyncSession, items: list[dict]) -> list[DefectItem]:
    db_items = [DefectItem(**item) for item in items]
    db.add_all(db_items)
    await db.flush()
    for item in db_items:
        await db.refresh(item)
    return db_items


async def list_by_inspection(
    db: AsyncSession, inspection_id: uuid.UUID
) -> list[DefectItem]:
    result = await db.execute(
        select(DefectItem).where(DefectItem.inspection_id == inspection_id)
    )
    return list(result.scalars().all())
