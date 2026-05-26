import uuid

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inspection import Inspection


async def create(
    db: AsyncSession,
    annotation_domain: str,
    inspector_id: uuid.UUID,
) -> Inspection:
    inspection = Inspection(
        annotation_domain=annotation_domain, inspector_id=inspector_id
    )
    db.add(inspection)
    await db.commit()
    await db.refresh(inspection)
    return inspection


async def get_by_id(db: AsyncSession, inspection_id: uuid.UUID) -> Inspection | None:
    result = await db.execute(select(Inspection).where(Inspection.id == inspection_id))
    return result.scalar_one_or_none()


async def update_image_keys(
    db: AsyncSession,
    inspection: Inspection,
    image_key: str | None = None,
    thumbnail_key: str | None = None,
) -> Inspection:
    if image_key is not None:
        inspection.image_key = image_key
    if thumbnail_key is not None:
        inspection.thumbnail_key = thumbnail_key
    await db.commit()
    await db.refresh(inspection)
    return inspection
