"""action_card_schema

Revision ID: 0004
Revises: 0003
Create Date: 2026-05-19
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0004"
down_revision = "0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── defect_items ─────────────────────────────────────────────────────────
    op.drop_column("defect_items", "defect_name")
    op.drop_column("defect_items", "part_name")
    op.drop_column("defect_items", "severity")
    op.drop_column("defect_items", "action_card")

    op.add_column(
        "defect_items",
        sa.Column(
            "canonical_class_name",
            sa.String(100),
            nullable=False,
            server_default="unknown",
        ),
    )
    op.add_column(
        "defect_items",
        sa.Column(
            "quality_state",
            sa.String(10),
            nullable=False,
            server_default="defect",
        ),
    )
    op.alter_column(
        "defect_items",
        "canonical_class_name",
        nullable=False,
        server_default=None,
    )
    op.alter_column(
        "defect_items",
        "quality_state",
        nullable=False,
        server_default=None,
    )

    # ── inspections ──────────────────────────────────────────────────────────
    op.alter_column("inspections", "domain", new_column_name="annotation_domain")

    # ── guidance (신규) ───────────────────────────────────────────────────────
    op.create_table(
        "guidance",
        sa.Column("ontology_id", sa.String(100), primary_key=True),
        sa.Column("canonical_class_name", sa.String(100), nullable=False),
        sa.Column("display_label", sa.String(100), nullable=False),
        sa.Column("quality_state", sa.String(10), nullable=False),
        sa.Column("cause", sa.Text(), nullable=False),
        sa.Column("action_steps", postgresql.ARRAY(sa.Text()), nullable=False),
        sa.Column("reinspection_criteria", sa.Text(), nullable=False),
        sa.Column("disclaimer", sa.Text(), nullable=False),
        sa.Column("referenced_doc", sa.String(200), nullable=True),
    )
    op.create_index(
        "ix_guidance_canonical_class_name",
        "guidance",
        ["canonical_class_name"],
    )


def downgrade() -> None:
    # ── guidance ──────────────────────────────────────────────────────────────
    op.drop_index("ix_guidance_canonical_class_name", table_name="guidance")
    op.drop_table("guidance")

    # ── inspections ──────────────────────────────────────────────────────────
    op.alter_column("inspections", "annotation_domain", new_column_name="domain")

    # ── defect_items ─────────────────────────────────────────────────────────
    op.drop_column("defect_items", "quality_state")
    op.drop_column("defect_items", "canonical_class_name")

    op.add_column(
        "defect_items",
        sa.Column("action_card", postgresql.JSONB(astext_type=sa.Text()), nullable=True),
    )
    op.add_column(
        "defect_items",
        sa.Column("severity", sa.String(20), nullable=True),
    )
    op.add_column(
        "defect_items",
        sa.Column("part_name", sa.String(100), nullable=True),
    )
    op.add_column(
        "defect_items",
        sa.Column("defect_name", sa.String(100), nullable=False, server_default="unknown"),
    )
    op.alter_column("defect_items", "defect_name", server_default=None)
