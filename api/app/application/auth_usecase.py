from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.errors import InvalidCredentialsError
from app.domain.auth import is_active_user
from app.ports.auth import CreateAccessTokenFn, VerifyPasswordFn
from app.ports.repositories import GetUserByEmployeeIdFn


async def login(
    db: AsyncSession,
    *,
    employee_id: str,
    password: str,
    get_by_employee_id_fn: GetUserByEmployeeIdFn,
    verify_password_fn: VerifyPasswordFn,
    create_access_token_fn: CreateAccessTokenFn,
    is_active_user_fn=is_active_user,
) -> str:
    user = await get_by_employee_id_fn(db, employee_id)
    if user is None or not verify_password_fn(password, user.password_hash):
        raise InvalidCredentialsError
    if not is_active_user_fn(user):
        raise InvalidCredentialsError
    return create_access_token_fn(subject=str(user.id))
