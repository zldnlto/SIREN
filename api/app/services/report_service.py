import uuid
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application import report_usecase
from app.application.errors import NotFoundError, ForbiddenError
from app.repositories import inspection_repository, report_repository
from app.schemas.report import ReportCreate, ReportResponse


async def create_report(
    db: AsyncSession,
    data: ReportCreate,
    resolver_id: uuid.UUID,
) -> ReportResponse:
    try:
        report = await report_usecase.create_report(
            db,
            inspection_id=data.inspection_id,
            status=data.status,
            action_checks=data.action_checks,
            note=data.note,
            resolver_id=resolver_id,
            get_inspection_fn=inspection_repository.get_by_id,
            create_report_fn=report_repository.create,
        )
        return ReportResponse.model_validate(report)
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="해당 검사(inspection)를 찾을 수 없습니다.",
        )
    except ForbiddenError as exc:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=str(exc),
        )
