from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase


def ensure_asyncpg_url(url: str) -> str:
    """postgresql:// → postgresql+asyncpg:// 로 보정."""
    if url.startswith("postgresql://") or url.startswith("postgres://"):
        return url.replace("://", "+asyncpg://", 1)
    return url


class Base(DeclarativeBase):
    pass


def _make_engine(url: str, debug: bool):
    return create_async_engine(url, echo=debug)


def _make_session_factory(url: str, debug: bool):
    return async_sessionmaker(_make_engine(url, debug), expire_on_commit=False)


_session_factory = None


def get_session_factory():
    global _session_factory
    if _session_factory is None:
        from app.core.config import settings

        _session_factory = _make_session_factory(
            ensure_asyncpg_url(settings.DATABASE_URL), settings.DEBUG
        )
    return _session_factory


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with get_session_factory()() as session:
        yield session
