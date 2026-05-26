import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class Inspection(Base):
    __tablename__ = "inspections"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    inspector_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    annotation_domain: Mapped[str] = mapped_column(String(50), nullable=False)
    image_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    thumbnail_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    report_flagged: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    report_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()"), onupdate=datetime.utcnow
    )

    defect_items: Mapped[list["DefectItem"]] = relationship(  # noqa: F821
        back_populates="inspection", cascade="all, delete-orphan"
    )
    detection_jobs: Mapped[list["DetectionJob"]] = relationship(  # noqa: F821
        back_populates="inspection"
    )
