"""align_schema_to_erd

Revision ID: 0003
Revises: 0002
Create Date: 2026-05-12
"""

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision = "0003"
down_revision = "0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── users ────────────────────────────────────────────────────────────────
    # employee_id: 기존 행에 고유값 부여 후 NOT NULL 확정
    op.add_column("users", sa.Column("employee_id", sa.String(50), nullable=True))
    op.execute(
        "UPDATE users SET employee_id = 'EMP-' || SUBSTRING(id::text, 1, 8) "
        "WHERE employee_id IS NULL"
    )
    op.alter_column("users", "employee_id", nullable=False)
    op.create_unique_constraint("uq_users_employee_id", "users", ["employee_id"])

    op.add_column("users", sa.Column("name", sa.String(100), nullable=True))
    op.execute("UPDATE users SET name = 'Unknown' WHERE name IS NULL")
    op.alter_column("users", "name", nullable=False)

    op.add_column("users", sa.Column("role", sa.String(20), nullable=True))
    op.execute("UPDATE users SET role = 'INSPECTOR' WHERE role IS NULL")
    op.alter_column("users", "role", nullable=False)

    op.add_column("users", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column(
        "users",
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )
    op.add_column(
        "users",
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
    )

    op.alter_column("users", "hashed_password", new_column_name="password_hash")
    op.drop_column("users", "username")
    op.drop_column("users", "email")
    op.drop_column("users", "is_active")

    # ── inspections ──────────────────────────────────────────────────────────
    op.add_column("inspections", sa.Column("domain", sa.String(50), nullable=True))
    op.execute("UPDATE inspections SET domain = '표면처리' WHERE domain IS NULL")
    op.alter_column("inspections", "domain", nullable=False)

    op.add_column("inspections", sa.Column("error_message", sa.Text(), nullable=True))
    op.add_column(
        "inspections",
        sa.Column("report_flagged", sa.Boolean(), server_default=sa.text("false"), nullable=False),
    )
    op.add_column("inspections", sa.Column("report_number", sa.String(50), nullable=True))
    op.add_column(
        "inspections",
        sa.Column("model_version", sa.String(50), server_default="mock-v0", nullable=False),
    )
    op.add_column(
        "inspections",
        sa.Column("rag_version", sa.String(50), server_default="mock-v0", nullable=False),
    )

    op.drop_column("inspections", "ship_name")
    op.drop_column("inspections", "tank_id")
    op.drop_column("inspections", "notes")
    op.drop_column("inspections", "gradcam_key")

    # ── defect_items ─────────────────────────────────────────────────────────
    op.alter_column("defect_items", "confidence", new_column_name="confidence_score")
    op.alter_column("defect_items", "detected_at", new_column_name="created_at")

    op.add_column("defect_items", sa.Column("defect_name", sa.String(100), nullable=True))
    op.execute("UPDATE defect_items SET defect_name = '알 수 없음' WHERE defect_name IS NULL")
    op.alter_column("defect_items", "defect_name", nullable=False)

    op.add_column("defect_items", sa.Column("part_name", sa.String(100), nullable=True))
    op.add_column("defect_items", sa.Column("gradcam_key", sa.String(512), nullable=True))
    op.drop_column("defect_items", "notes")

    # ── inspection_reports ───────────────────────────────────────────────────
    # inspection_id의 unique 제약 해제 (1 inspection → 복수 report 허용)
    op.drop_constraint("inspection_reports_inspection_id_key", "inspection_reports", type_="unique")

    op.add_column(
        "inspection_reports",
        sa.Column("defect_item_id", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_inspection_reports_defect_item",
        "inspection_reports",
        "defect_items",
        ["defect_item_id"],
        ["id"],
    )

    op.add_column(
        "inspection_reports",
        sa.Column("reported_by", postgresql.UUID(as_uuid=True), nullable=True),
    )
    op.create_foreign_key(
        "fk_inspection_reports_reported_by",
        "inspection_reports",
        "users",
        ["reported_by"],
        ["id"],
    )

    op.add_column(
        "inspection_reports",
        sa.Column("feedback_type", sa.String(30), nullable=True),
    )
    op.execute("UPDATE inspection_reports SET feedback_type = 'MISSED' WHERE feedback_type IS NULL")
    op.alter_column("inspection_reports", "feedback_type", nullable=False)

    op.add_column("inspection_reports", sa.Column("actual_defect", sa.String(100), nullable=True))

    op.drop_column("inspection_reports", "report_number")
    op.drop_column("inspection_reports", "summary")


def downgrade() -> None:
    # ── inspection_reports ───────────────────────────────────────────────────
    op.add_column("inspection_reports", sa.Column("report_number", sa.String(50), nullable=True))
    op.add_column("inspection_reports", sa.Column("summary", sa.Text(), nullable=True))
    op.drop_column("inspection_reports", "actual_defect")
    op.drop_column("inspection_reports", "feedback_type")
    op.drop_constraint("fk_inspection_reports_reported_by", "inspection_reports", type_="foreignkey")
    op.drop_column("inspection_reports", "reported_by")
    op.drop_constraint("fk_inspection_reports_defect_item", "inspection_reports", type_="foreignkey")
    op.drop_column("inspection_reports", "defect_item_id")
    op.create_unique_constraint(
        "inspection_reports_inspection_id_key", "inspection_reports", ["inspection_id"]
    )

    # ── defect_items ─────────────────────────────────────────────────────────
    op.drop_column("defect_items", "gradcam_key")
    op.drop_column("defect_items", "part_name")
    op.drop_column("defect_items", "defect_name")
    op.add_column("defect_items", sa.Column("notes", sa.Text(), nullable=True))
    op.alter_column("defect_items", "created_at", new_column_name="detected_at")
    op.alter_column("defect_items", "confidence_score", new_column_name="confidence")

    # ── inspections ──────────────────────────────────────────────────────────
    op.drop_column("inspections", "rag_version")
    op.drop_column("inspections", "model_version")
    op.drop_column("inspections", "report_number")
    op.drop_column("inspections", "report_flagged")
    op.drop_column("inspections", "error_message")
    op.drop_column("inspections", "domain")
    op.add_column("inspections", sa.Column("gradcam_key", sa.String(512), nullable=True))
    op.add_column("inspections", sa.Column("notes", sa.Text(), nullable=True))
    op.add_column("inspections", sa.Column("tank_id", sa.String(50), nullable=True))
    op.add_column("inspections", sa.Column("ship_name", sa.String(100), nullable=True))

    # ── users ────────────────────────────────────────────────────────────────
    op.add_column("users", sa.Column("is_active", sa.Boolean(), server_default=sa.text("true"), nullable=False))
    op.add_column("users", sa.Column("email", sa.String(255), nullable=True))
    op.add_column("users", sa.Column("username", sa.String(50), nullable=True))
    op.alter_column("users", "password_hash", new_column_name="hashed_password")
    op.drop_column("users", "updated_at")
    op.drop_column("users", "created_at")
    op.drop_column("users", "deleted_at")
    op.drop_column("users", "role")
    op.drop_column("users", "name")
    op.drop_constraint("uq_users_employee_id", "users", type_="unique")
    op.drop_column("users", "employee_id")
