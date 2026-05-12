import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class InspectionReport(Base):
    __tablename__ = "inspection_reports"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    inspection_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("inspections.id"), nullable=False
    )
    defect_item_id: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("defect_items.id"), nullable=True
    )
    reported_by: Mapped[uuid.UUID | None] = mapped_column(
        ForeignKey("users.id"), nullable=True
    )
    feedback_type: Mapped[str] = mapped_column(
        String(30), nullable=False
    )  # MISSED / WRONG_CLASS / FALSE_POSITIVE
    actual_defect: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
