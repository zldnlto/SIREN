from sqlalchemy import String, Text
from sqlalchemy.dialects.postgresql import ARRAY as PG_ARRAY
from sqlalchemy.orm import Mapped, mapped_column

from app.core.database import Base


class Guidance(Base):
    __tablename__ = "guidance"

    ontology_id: Mapped[str] = mapped_column(String(100), primary_key=True)
    canonical_class_name: Mapped[str] = mapped_column(
        String(100), nullable=False, index=True
    )
    display_label: Mapped[str] = mapped_column(String(100), nullable=False)
    quality_state: Mapped[str] = mapped_column(String(10), nullable=False)
    cause: Mapped[str] = mapped_column(Text, nullable=False)
    action_steps: Mapped[list[str]] = mapped_column(PG_ARRAY(String), nullable=False)
    reinspection_criteria: Mapped[str] = mapped_column(Text, nullable=False)
    disclaimer: Mapped[str] = mapped_column(Text, nullable=False)
    referenced_doc: Mapped[str | None] = mapped_column(String(200), nullable=True)
