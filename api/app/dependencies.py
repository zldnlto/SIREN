import uuid

from typing import Any

from chromadb import Collection
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.chroma import get_sop_collection
from app.core.database import get_db
from app.core.security import decode_access_token
from app.repositories import user_repository

_bearer = HTTPBearer(auto_error=False)

_UNAUTHORIZED = HTTPException(
    status_code=status.HTTP_401_UNAUTHORIZED,
    detail="인증 정보가 유효하지 않습니다.",
    headers={"WWW-Authenticate": "Bearer"},
)


def get_chroma_collection() -> Collection:
    return get_sop_collection()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: AsyncSession = Depends(get_db),
) -> Any:
    if credentials is None:
        raise _UNAUTHORIZED
    try:
        user_id = decode_access_token(credentials.credentials)
        user_uuid = uuid.UUID(user_id)
    except (JWTError, ValueError):
        raise _UNAUTHORIZED

    user = await user_repository.get_by_id(db, user_uuid)
    if user is None or user.deleted_at is not None:
        raise _UNAUTHORIZED
    return user
