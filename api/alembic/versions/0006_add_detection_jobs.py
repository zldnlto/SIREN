"""add_detection_jobs

Revision ID: 0006
Revises: 0005
Create Date: 2026-05-26
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0006"
down_revision = "0005"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "detection_jobs",
        sa.Column(
            "id",
            postgresql.UUID(as_uuid=True),
            primary_key=True,
            server_default=sa.text("gen_random_uuid()"),
        ),
        sa.Column(
            "inspection_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("inspections.id"),
            nullable=False,
        ),
        sa.Column("model_version", sa.String(50), nullable=False),
        sa.Column("rag_version", sa.String(50), nullable=False),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("error_message", sa.Text(), nullable=True),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("completed_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.execute(
        "CREATE UNIQUE INDEX ix_detection_jobs_active "
        "ON detection_jobs (inspection_id) "
        "WHERE status IN ('pending', 'processing')"
    )


def downgrade() -> None:
    op.execute("DROP INDEX IF EXISTS ix_detection_jobs_active")
    op.drop_table("detection_jobs")
