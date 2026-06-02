import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.dependencies import get_current_user
from app.main import app
from app.models.report import Report
from app.models.user import User
from app.schemas.report import ReportResponse

_USER = User(
    id=uuid.uuid4(),
    employee_id="EMP-001",
    name="Test Inspector",
    password_hash="hashed",
    role="INSPECTOR",
)

_REPORT = Report(
    id=uuid.uuid4(),
    inspection_id=uuid.uuid4(),
    status="pending",
    action_checks=[True, False, True],
    resolver_id=_USER.id,
    resolved_at=None,
    note="조치 이행 완료했습니다.",
    created_at=datetime.now(timezone.utc),
)

_REPORT_RESPONSE = ReportResponse(
    id=_REPORT.id,
    inspection_id=_REPORT.inspection_id,
    status=_REPORT.status,
    action_checks=_REPORT.action_checks,
    resolver_id=_REPORT.resolver_id,
    resolved_at=None,
    note=_REPORT.note,
    created_at=_REPORT.created_at,
)


async def _override_get_current_user():
    return _USER


async def _override_get_db():
    yield None


app.dependency_overrides[get_current_user] = _override_get_current_user
app.dependency_overrides[get_db] = _override_get_db

client = TestClient(app)


@pytest.mark.asyncio
async def test_create_report_success():
    with patch(
        "app.services.report_service.create_report",
        new=AsyncMock(return_value=_REPORT_RESPONSE),
    ):
        resp = client.post(
            "/api/v1/reports",
            json={
                "inspection_id": str(_REPORT.inspection_id),
                "status": "pending",
                "action_checks": [True, False, True],
                "note": "조치 이행 완료했습니다.",
            },
        )
    assert resp.status_code == 201
    data = resp.json()
    assert data["id"] == str(_REPORT.id)
    assert data["inspection_id"] == str(_REPORT.inspection_id)
    assert data["action_checks"] == [True, False, True]
    assert data["note"] == "조치 이행 완료했습니다."


@pytest.mark.asyncio
async def test_create_report_inspection_not_found():
    from fastapi import HTTPException, status

    with patch(
        "app.services.report_service.create_report",
        new=AsyncMock(
            side_effect=HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="해당 검사(inspection)를 찾을 수 없습니다.",
            )
        ),
    ):
        resp = client.post(
            "/api/v1/reports",
            json={
                "inspection_id": str(uuid.uuid4()),
                "status": "pending",
                "action_checks": [True],
                "note": "Not found test",
            },
        )
    assert resp.status_code == 404
    assert resp.json()["detail"] == "해당 검사(inspection)를 찾을 수 없습니다."


@pytest.mark.asyncio
async def test_create_report_forbidden():
    from fastapi import HTTPException, status

    with patch(
        "app.services.report_service.create_report",
        new=AsyncMock(
            side_effect=HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="본인의 검사 건에만 리포트를 작성할 수 있습니다.",
            )
        ),
    ):
        resp = client.post(
            "/api/v1/reports",
            json={
                "inspection_id": str(uuid.uuid4()),
                "status": "pending",
                "action_checks": [True],
                "note": "Forbidden test",
            },
        )
    assert resp.status_code == 403
    assert resp.json()["detail"] == "본인의 검사 건에만 리포트를 작성할 수 있습니다."
