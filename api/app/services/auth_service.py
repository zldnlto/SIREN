from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, verify_password
from app.repositories import user_repository
from app.schemas.auth import LoginRequest, TokenResponse

_INVALID_CREDENTIALS = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="사번 또는 비밀번호가 올바르지 않습니다.",
    headers={"WWW-Authenticate": "Bearer"},
)


async def login(db: AsyncSession, req: LoginRequest) -> TokenResponse:
    user = await user_repository.get_by_employee_id(db, req.employee_id)
    if user is None or not verify_password(req.password, user.password_hash):
        raise _INVALID_CREDENTIALS
    # 탈퇴(소프트 딜리트)된 계정은 자격증명 오류와 동일 응답으로 처리
    if user.deleted_at is not None:
        raise _INVALID_CREDENTIALS
    token = create_access_token(subject=str(user.id))
    return TokenResponse(access_token=token)
