from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import create_access_token, verify_password
from app.repositories import user_repository
from app.schemas.auth import LoginRequest, TokenResponse


async def login(db: AsyncSession, req: LoginRequest) -> TokenResponse:
    user = await user_repository.get_by_email(db, req.email)
    if user is None or not verify_password(req.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="이메일 또는 비밀번호가 올바르지 않습니다.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="비활성화된 계정입니다.",
        )
    token = create_access_token(subject=str(user.id))
    return TokenResponse(access_token=token)
