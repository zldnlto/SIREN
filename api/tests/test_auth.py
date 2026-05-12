import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.security import hash_password
from app.main import app
from app.models.user import User

client = TestClient(app)

_PLAIN_PW = "secret1234"
_USER = User(
    id=uuid.uuid4(),
    employee_id="EMP-001",
    name="Test Inspector",
    password_hash=hash_password(_PLAIN_PW),
    role="INSPECTOR",
)


def _mock_get_by_employee_id(db, employee_id: str):
    return _USER if employee_id == _USER.employee_id else None


@pytest.mark.asyncio
async def test_login_success():
    with patch(
        "app.repositories.user_repository.get_by_employee_id",
        new=AsyncMock(side_effect=_mock_get_by_employee_id),
    ):
        resp = client.post(
            "/api/v1/auth/login",
            json={"employee_id": _USER.employee_id, "password": _PLAIN_PW},
        )
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body
    assert body["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_wrong_password():
    with patch(
        "app.repositories.user_repository.get_by_employee_id",
        new=AsyncMock(side_effect=_mock_get_by_employee_id),
    ):
        resp = client.post(
            "/api/v1/auth/login",
            json={"employee_id": _USER.employee_id, "password": "wrongpassword"},
        )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_unknown_employee_id():
    with patch(
        "app.repositories.user_repository.get_by_employee_id",
        new=AsyncMock(return_value=None),
    ):
        resp = client.post(
            "/api/v1/auth/login",
            json={"employee_id": "EMP-999", "password": _PLAIN_PW},
        )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_deleted_user():
    deleted = User(
        id=uuid.uuid4(),
        employee_id="EMP-DEL",
        name="Deleted User",
        password_hash=hash_password(_PLAIN_PW),
        role="INSPECTOR",
        deleted_at=datetime.now(timezone.utc),
    )
    with patch(
        "app.repositories.user_repository.get_by_employee_id",
        new=AsyncMock(return_value=deleted),
    ):
        resp = client.post(
            "/api/v1/auth/login",
            json={"employee_id": deleted.employee_id, "password": _PLAIN_PW},
        )
    assert resp.status_code == 401
