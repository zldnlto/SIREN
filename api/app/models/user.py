import uuid

from sqlalchemy import String, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    # TODO(ERD-PENDING): username vs email 로그인 식별자 확정 필요
    username: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    # TODO(ERD-PENDING): role 컬럼 필요 여부 (inspector / admin) 확정 필요
    is_active: Mapped[bool] = mapped_column(default=True, nullable=False)
