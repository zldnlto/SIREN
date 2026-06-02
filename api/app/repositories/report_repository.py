import uuid
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.report import Report


async def create(
    db: AsyncSession,
    inspection_id: uuid.UUID,
    status: str,
    action_checks: list[bool] | None,
    note: str | None,
    resolver_id: uuid.UUID | None = None,
) -> Report:
    report = Report(
        inspection_id=inspection_id,
        status=status,
        action_checks=action_checks,
        note=note,
        resolver_id=resolver_id,
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)
    return report


async def get_by_id(db: AsyncSession, report_id: uuid.UUID) -> Report | None:
    result = await db.execute(select(Report).where(Report.id == report_id))
    return result.scalar_one_or_none()
