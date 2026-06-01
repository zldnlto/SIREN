import uuid
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.dependencies import get_current_user
from app.repositories import dashboard_repository
from app.schemas.dashboard import (
    AnalyticsResponse,
    DashboardSummary,
    InspectionDetail,
    InspectionListResponse,
)

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/summary", response_model=DashboardSummary)
async def get_summary(
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_user),
):
    return await dashboard_repository.get_summary(db)


@router.get("/inspections", response_model=InspectionListResponse)
async def list_inspections(
    status: str | None = Query(None),
    quality_state: str | None = Query(None),
    annotation_domain: str | None = Query(None),
    from_: datetime | None = Query(None, alias="from"),
    to: datetime | None = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_user),
):
    items, total = await dashboard_repository.list_inspections(
        db,
        status=status,
        quality_state=quality_state,
        annotation_domain=annotation_domain,
        from_date=from_,
        to_date=to,
        page=page,
        limit=limit,
    )
    return InspectionListResponse(items=items, total=total)


@router.get("/inspections/{inspection_id}", response_model=InspectionDetail)
async def get_inspection_detail(
    inspection_id: uuid.UUID,
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_user),
):
    detail = await dashboard_repository.get_inspection_detail(db, inspection_id)
    if detail is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="inspection을 찾을 수 없습니다.",
        )
    return detail


@router.get("/analytics", response_model=AnalyticsResponse)
async def get_analytics(
    db: AsyncSession = Depends(get_db),
    _=Depends(get_current_user),
):
    return await dashboard_repository.get_analytics(db)
