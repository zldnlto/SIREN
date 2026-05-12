from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.auth_usecase import login as login_usecase
from app.application.errors import InvalidCredentialsError
from app.core.security import create_access_token, verify_password
from app.repositories import user_repository
from app.schemas.auth import LoginRequest, TokenResponse

_INVALID_CREDENTIALS = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="사번 또는 비밀번호가 올바르지 않습니다.",
    headers={"WWW-Authenticate": "Bearer"},
)


async def login(db: AsyncSession, req: LoginRequest) -> TokenResponse:
    try:
        token = await login_usecase(
            db,
            employee_id=req.employee_id,
            password=req.password,
            get_by_employee_id_fn=user_repository.get_by_employee_id,
            verify_password_fn=verify_password,
            create_access_token_fn=create_access_token,
        )
    except InvalidCredentialsError:
        raise _INVALID_CREDENTIALS
    return TokenResponse(access_token=token)
