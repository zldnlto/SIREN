import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text, text
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class InspectionReport(Base):
    __tablename__ = "inspection_reports"

    id: Mapped[uuid.UUID] = mapped_column(
        primary_key=True, server_default=text("gen_random_uuid()")
    )
    inspection_id: Mapped[uuid.UUID] = mapped_column(
        ForeignKey("inspections.id"), nullable=False, unique=True
    )
    # TODO(ERD-PENDING): report_number 형식 확정 필요 (예: "RPT-2026-001" 또는 자동증가 정수)
    report_number: Mapped[str | None] = mapped_column(String(50), nullable=True)
    # TODO(ERD-PENDING): PDF 생성 여부 및 pdf_key(S3 경로) 컬럼 필요 여부 확정 필요
    summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )
