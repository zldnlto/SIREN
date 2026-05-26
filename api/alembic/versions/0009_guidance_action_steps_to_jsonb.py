"""guidance_action_steps_to_jsonb

Revision ID: 0009
Revises: 0008
Create Date: 2026-05-26
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0009"
down_revision = "0008"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.execute("ALTER TABLE guidance ALTER COLUMN action_steps DROP DEFAULT")
    op.alter_column(
        "guidance",
        "action_steps",
        type_=postgresql.JSONB(),
        postgresql_using="array_to_json(action_steps)",
    )
    op.execute("ALTER TABLE guidance ALTER COLUMN action_steps SET DEFAULT '[]'::jsonb")


def downgrade() -> None:
    op.execute("ALTER TABLE guidance ALTER COLUMN action_steps DROP DEFAULT")
    op.alter_column(
        "guidance",
        "action_steps",
        type_=postgresql.ARRAY(sa.Text()),
        postgresql_using="ARRAY(SELECT jsonb_array_elements_text(action_steps))",
    )
    op.execute("ALTER TABLE guidance ALTER COLUMN action_steps SET DEFAULT '{}'::text[]")
