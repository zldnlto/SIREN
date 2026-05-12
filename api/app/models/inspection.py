import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Inspection(Base):
    __tablename__ = "inspections"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    # TODO(ERD-PENDING): ship_name을 별도 ships 테이블로 분리할지 여부 확정 필요
    ship_name: Mapped[str] = mapped_column(String(100), nullable=False)
    # TODO(ERD-PENDING): tank_id 형식 확정 필요 (예: "TANK-A" 문자열 vs 정수 코드)
    tank_id: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, default="pending")
    inspector_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    image_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    thumbnail_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    gradcam_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()"), onupdate=datetime.utcnow
    )

    defect_items: Mapped[list["DefectItem"]] = relationship(  # noqa: F821
        back_populates="inspection", cascade="all, delete-orphan"
    )
