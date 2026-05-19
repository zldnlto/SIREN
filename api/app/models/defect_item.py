import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, SmallInteger, String, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.database import Base


class DefectItem(Base):
    __tablename__ = "defect_items"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    inspection_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("inspections.id"), nullable=False
    )
    domain_code: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    class_code: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    canonical_class_name: Mapped[str] = mapped_column(String(100), nullable=False)
    quality_state: Mapped[str] = mapped_column(String(10), nullable=False)
    confidence_score: Mapped[float] = mapped_column(nullable=False)
    bbox: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    gradcam_key: Mapped[str | None] = mapped_column(String(512), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )

    inspection: Mapped["Inspection"] = relationship(  # noqa: F821
        back_populates="defect_items"
    )
