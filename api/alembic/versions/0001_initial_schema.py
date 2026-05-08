"""initial_schema

Revision ID: 0001
Revises:
Create Date: 2026-05-08

# TODO(ERD-PENDING): 아래 항목은 grill-with-docs ERD 확정 후 수정 필요
#   - users.role 컬럼 추가 여부 (inspector / admin)
#   - inspections.ship_name → ships 테이블 분리 여부
#   - inspections.tank_id 형식 (문자열 vs 정수)
#   - defect_items.bbox nullable 여부 (탱크클리닝불량/표면양품은 bbox 없음)
#   - defect_items 표면양품(class_code=7) 저장 여부
#   - inspection_reports.report_number 형식
#   - inspection_reports.pdf_key(S3) 컬럼 필요 여부
#   - inspections의 image_key / thumbnail_key / gradcam_key → Sub-issue 5에서 추가
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            primary_key=True,
        ),
        # TODO(ERD-PENDING): username vs email 로그인 식별자 확정 후 unique 조건 재검토
        sa.Column("username", sa.String(50), nullable=False, unique=True),
        sa.Column("email", sa.String(255), nullable=False, unique=True),
        sa.Column("hashed_password", sa.String(255), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default="true"),
    )

    op.create_table(
        "inspections",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            primary_key=True,
        ),
        # TODO(ERD-PENDING): ship_name 별도 테이블 분리 여부 결정 전 문자열로 유지
        sa.Column("ship_name", sa.String(100), nullable=False),
        # TODO(ERD-PENDING): tank_id 형식 확정 필요
        sa.Column("tank_id", sa.String(50), nullable=False),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column(
            "inspector_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id"),
            nullable=False,
        ),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )

    op.create_table(
        "defect_items",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            primary_key=True,
        ),
        sa.Column(
            "inspection_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("inspections.id"),
            nullable=False,
        ),
        # TODO(ERD-PENDING): domain_code enum 범위 확정 (현재: 표면처리=0만 존재)
        sa.Column("domain_code", sa.SmallInteger(), nullable=False),
        # TODO(ERD-PENDING): class_code enum 확정 (0=균열 … 7=표면양품)
        sa.Column("class_code", sa.SmallInteger(), nullable=False),
        sa.Column("confidence", sa.Float(), nullable=False),
        # TODO(ERD-PENDING): is_cls=True 클래스(탱크클리닝불량, 표면양품)는 bbox 없음 — nullable 유지
        sa.Column("bbox", postgresql.JSONB(), nullable=True),
        sa.Column("action_card", postgresql.JSONB(), nullable=True),
        sa.Column("severity", sa.String(20), nullable=True),
        sa.Column("notes", sa.Text(), nullable=True),
        sa.Column(
            "detected_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )

    op.create_table(
        "inspection_reports",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            server_default=sa.text("gen_random_uuid()"),
            primary_key=True,
        ),
        sa.Column(
            "inspection_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("inspections.id"),
            nullable=False,
            unique=True,
        ),
        # TODO(ERD-PENDING): report_number 형식 확정 필요 (예: "RPT-2026-001" vs 자동증가 정수)
        sa.Column("report_number", sa.String(50), nullable=True),
        # TODO(ERD-PENDING): pdf_key(S3 경로) 컬럼 필요 여부 확정 후 추가
        sa.Column("summary", sa.Text(), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )


def downgrade() -> None:
    op.drop_table("inspection_reports")
    op.drop_table("defect_items")
    op.drop_table("inspections")
    op.drop_table("users")
