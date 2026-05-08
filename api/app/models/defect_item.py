import uuid
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, SmallInteger, String, Text, text
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
    # TODO(ERD-PENDING): domain_code 값 범위 및 enum 매핑 확정 필요
    # 현재 가정: 표면처리=0 (domain_label_map.json 기준 유일 도메인)
    domain_code: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    # TODO(ERD-PENDING): class_code ↔ 클래스명 매핑 테이블 or 코드 내 enum 확정 필요
    # 현재 가정: 균열=0, 스크래치=1, 도장흐름=2, 도막떨어짐=3, 도막분리=4,
    #           보온재손상=5, 탱크클리닝불량=6, 표면양품=7
    class_code: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    confidence: Mapped[float] = mapped_column(nullable=False)
    # bbox: [x_min, y_min, x_max, y_max] — segmentation도 지원하도록 JSONB 유지
    # TODO(ERD-PENDING): 탱크클리닝불량/표면양품은 bbox 없음(is_cls=True) — null 허용 확정
    bbox: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    # TODO(ERD-PENDING): 표면양품(class_code=7)을 defect_item으로 저장할지 여부 확정 필요
    # 현재: 저장하되 class_code로 필터링하는 방식으로 처리
    action_card: Mapped[dict | None] = mapped_column(JSONB, nullable=True)
    severity: Mapped[str | None] = mapped_column(String(20), nullable=True)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)
    detected_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=text("now()")
    )

    inspection: Mapped["Inspection"] = relationship(  # noqa: F821
        back_populates="defect_items"
    )
