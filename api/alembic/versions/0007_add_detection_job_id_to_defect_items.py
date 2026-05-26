"""add_detection_job_id_to_defect_items

Revision ID: 0007
Revises: 0006
Create Date: 2026-05-26
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0007"
down_revision = "0006"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # 1. detection_job_id 컬럼 추가 (nullable 먼저)
    op.add_column(
        "defect_items",
        sa.Column(
            "detection_job_id",
            postgresql.UUID(as_uuid=True),
            nullable=True,
        ),
    )

    # 2. 기존 defect_items backfill: inspection_id별 detection_jobs row 생성 후 연결
    op.execute(
        """
        INSERT INTO detection_jobs (id, inspection_id, model_version, rag_version, status, created_at)
        SELECT gen_random_uuid(), sub.inspection_id, 'mock-v0', 'mock-v0', 'completed', now()
        FROM (SELECT DISTINCT inspection_id FROM defect_items) sub
        ON CONFLICT DO NOTHING
        """
    )
    op.execute(
        """
        UPDATE defect_items di
        SET detection_job_id = dj.id
        FROM detection_jobs dj
        WHERE di.inspection_id = dj.inspection_id
        AND di.detection_job_id IS NULL
        """
    )

    # 3. FK 제약 및 NOT NULL 확정
    op.create_foreign_key(
        "fk_defect_items_detection_job",
        "defect_items",
        "detection_jobs",
        ["detection_job_id"],
        ["id"],
    )
    op.alter_column("defect_items", "detection_job_id", nullable=False)


def downgrade() -> None:
    op.drop_constraint("fk_defect_items_detection_job", "defect_items", type_="foreignkey")
    op.drop_column("defect_items", "detection_job_id")
