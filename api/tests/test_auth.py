import uuid
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
    email="inspector@siren.io",
    username="inspector",
    hashed_password=hash_password(_PLAIN_PW),
    is_active=True,
)


def _mock_get_by_email(db, email: str):
    return _USER if email == _USER.email else None


@pytest.mark.asyncio
async def test_login_success():
    with patch(
        "app.repositories.user_repository.get_by_email",
        new=AsyncMock(side_effect=_mock_get_by_email),
    ):
        resp = client.post(
            "/api/v1/auth/login",
            json={"email": _USER.email, "password": _PLAIN_PW},
        )
    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body
    assert body["token_type"] == "bearer"


@pytest.mark.asyncio
async def test_login_wrong_password():
    with patch(
        "app.repositories.user_repository.get_by_email",
        new=AsyncMock(side_effect=_mock_get_by_email),
    ):
        resp = client.post(
            "/api/v1/auth/login",
            json={"email": _USER.email, "password": "wrongpassword"},
        )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_unknown_email():
    with patch(
        "app.repositories.user_repository.get_by_email",
        new=AsyncMock(return_value=None),
    ):
        resp = client.post(
            "/api/v1/auth/login",
            json={"email": "nobody@siren.io", "password": _PLAIN_PW},
        )
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_inactive_user():
    inactive = User(
        id=uuid.uuid4(),
        email="inactive@siren.io",
        username="inactive",
        hashed_password=hash_password(_PLAIN_PW),
        is_active=False,
    )
    with patch(
        "app.repositories.user_repository.get_by_email",
        new=AsyncMock(return_value=inactive),
    ):
        resp = client.post(
            "/api/v1/auth/login",
            json={"email": inactive.email, "password": _PLAIN_PW},
        )
    assert resp.status_code == 403
