"""add_image_keys_to_inspections

Revision ID: 0002
Revises: 0001
Create Date: 2026-05-12
"""

import sqlalchemy as sa
from alembic import op

revision = "0002"
down_revision = "0001"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("inspections", sa.Column("image_key", sa.String(512), nullable=True))
    op.add_column("inspections", sa.Column("thumbnail_key", sa.String(512), nullable=True))
    op.add_column("inspections", sa.Column("gradcam_key", sa.String(512), nullable=True))


def downgrade() -> None:
    op.drop_column("inspections", "gradcam_key")
    op.drop_column("inspections", "thumbnail_key")
    op.drop_column("inspections", "image_key")
