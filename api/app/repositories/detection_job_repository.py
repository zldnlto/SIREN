import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.detection_job import DetectionJob


async def create(
    db: AsyncSession,
    inspection_id: uuid.UUID,
    model_version: str,
    rag_version: str,
) -> DetectionJob:
    job = DetectionJob(
        inspection_id=inspection_id,
        model_version=model_version,
        rag_version=rag_version,
        status="pending",
    )
    db.add(job)
    await db.flush()
    await db.refresh(job)
    return job


async def get_active(db: AsyncSession, inspection_id: uuid.UUID) -> DetectionJob | None:
    result = await db.execute(
        select(DetectionJob).where(
            DetectionJob.inspection_id == inspection_id,
            DetectionJob.status.in_(["pending", "processing"]),
        )
    )
    return result.scalars().first()


async def get_latest_completed(
    db: AsyncSession, inspection_id: uuid.UUID
) -> DetectionJob | None:
    result = await db.execute(
        select(DetectionJob)
        .where(
            DetectionJob.inspection_id == inspection_id,
            DetectionJob.status == "completed",
        )
        .order_by(DetectionJob.created_at.desc())
        .limit(1)
    )
    return result.scalars().first()


async def list_by_inspection(
    db: AsyncSession, inspection_id: uuid.UUID
) -> list[DetectionJob]:
    result = await db.execute(
        select(DetectionJob)
        .where(DetectionJob.inspection_id == inspection_id)
        .order_by(DetectionJob.created_at.desc())
    )
    return list(result.scalars().all())


async def update_status(
    db: AsyncSession,
    job: DetectionJob,
    status: str,
    *,
    error_message: str | None = None,
) -> DetectionJob:
    job.status = status
    if status == "processing":
        job.started_at = datetime.now(timezone.utc)
    elif status in ("completed", "failed"):
        job.completed_at = datetime.now(timezone.utc)
    if error_message is not None:
        job.error_message = error_message
    await db.flush()
    return job
