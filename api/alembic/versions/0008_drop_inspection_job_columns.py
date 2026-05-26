"""drop_inspection_job_columns

Revision ID: 0008
Revises: 0007
Create Date: 2026-05-26
"""

import sqlalchemy as sa
from alembic import op

revision = "0008"
down_revision = "0007"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.drop_column("inspections", "status")
    op.drop_column("inspections", "error_message")
    op.drop_column("inspections", "model_version")
    op.drop_column("inspections", "rag_version")


def downgrade() -> None:
    op.add_column(
        "inspections",
        sa.Column(
            "rag_version",
            sa.String(50),
            nullable=False,
            server_default="mock-v0",
        ),
    )
    op.add_column(
        "inspections",
        sa.Column(
            "model_version",
            sa.String(50),
            nullable=False,
            server_default="mock-v0",
        ),
    )
    op.add_column(
        "inspections",
        sa.Column("error_message", sa.Text(), nullable=True),
    )
    op.add_column(
        "inspections",
        sa.Column(
            "status",
            sa.String(20),
            nullable=False,
            server_default="pending",
        ),
    )
