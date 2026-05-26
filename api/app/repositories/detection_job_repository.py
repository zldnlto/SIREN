import uuid
from datetime import datetime, timezone
from typing import Literal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.detection_job import DetectionJob

JobStatus = Literal["pending", "processing", "completed", "failed"]


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
    new_status: JobStatus,
    *,
    error_message: str | None = None,
) -> DetectionJob:
    job.status = new_status
    if new_status == "processing":
        job.started_at = datetime.now(timezone.utc)
    elif new_status in ("completed", "failed"):
        job.completed_at = datetime.now(timezone.utc)
    if error_message is not None:
        job.error_message = error_message
    await db.flush()
    return job
