"""add_ontology_id_to_defect_items

Revision ID: 0005
Revises: 0004
Create Date: 2026-05-26
"""

import sqlalchemy as sa
from alembic import op

revision = "0005"
down_revision = "0004"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "defect_items",
        sa.Column("ontology_id", sa.String(100), nullable=True),
    )
    op.execute(
        """
        UPDATE defect_items
        SET ontology_id = 'unknown'
        WHERE ontology_id IS NULL
        """
    )
    op.alter_column("defect_items", "ontology_id", nullable=False)


def downgrade() -> None:
    op.drop_column("defect_items", "ontology_id")
