import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class DetectionJob(Base):
    __tablename__ = "detection_jobs"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    inspection_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("inspections.id"), nullable=False
    )
    model_version: Mapped[str] = mapped_column(String(50), nullable=False)
    rag_version: Mapped[str] = mapped_column(String(50), nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), nullable=False, default="pending"
    )  # pending / processing / completed / failed
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )

    inspection: Mapped["Inspection"] = relationship(  # noqa: F821
        back_populates="detection_jobs"
    )
    defect_items: Mapped[list["DefectItem"]] = relationship(  # noqa: F821
        back_populates="detection_job", cascade="all, delete-orphan"
    )
