import uuid
from typing import Callable, Coroutine, Any
from sqlalchemy.ext.asyncio import AsyncSession
from app.application.errors import NotFoundError, ForbiddenError


async def create_report(
    db: AsyncSession,
    inspection_id: uuid.UUID,
    status: str,
    action_checks: list[bool] | None,
    note: str | None,
    resolver_id: uuid.UUID,
    get_inspection_fn: Callable[[AsyncSession, uuid.UUID], Coroutine[Any, Any, Any]],
    create_report_fn: Callable[
        [AsyncSession, uuid.UUID, str, list[bool] | None, str | None, uuid.UUID | None],
        Coroutine[Any, Any, Any],
    ],
) -> Any:
    # 1. 검사 건 존재 여부 확인
    inspection = await get_inspection_fn(db, inspection_id)
    if inspection is None:
        raise NotFoundError("Inspection not found")

    # 2. 본인의 검사 건에 대해서만 리포트를 작성할 수 있도록 권한 검사
    if inspection.inspector_id != resolver_id:
        raise ForbiddenError("본인의 검사 건에만 리포트를 작성할 수 있습니다.")

    # 3. 리포트 생성
    return await create_report_fn(
        db,
        inspection_id,
        status,
        action_checks,
        note,
        resolver_id,
    )
