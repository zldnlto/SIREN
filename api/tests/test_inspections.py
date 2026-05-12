import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.dependencies import get_current_user
from app.main import app
from app.models.inspection import Inspection
from app.models.user import User
from app.schemas.detection import DefectItem, DetectionResult

_USER = User(
    id=uuid.uuid4(),
    employee_id="EMP-001",
    name="Test Inspector",
    password_hash="hashed",
    role="INSPECTOR",
)

_INSPECTION = Inspection(
    id=uuid.uuid4(),
    domain="표면처리",
    status="pending",
    inspector_id=_USER.id,
    image_key=None,
    thumbnail_key=None,
    report_flagged=False,
    model_version="mock-v0",
    rag_version="mock-v0",
    created_at=datetime.now(timezone.utc),
    updated_at=datetime.now(timezone.utc),
)

_DETECTION_RESULT = DetectionResult(
    id=str(uuid.uuid4()),
    inspection_id=str(_INSPECTION.id),
    defects=[
        DefectItem(
            defect_name="균열",
            confidence_score=0.92,
            severity="HIGH",
            bbox=[10.0, 20.0, 100.0, 80.0],
        )
    ],
    confidence=0.85,
    detected_at=datetime.now(timezone.utc),
)


async def _override_get_current_user():
    return _USER


async def _override_get_db():
    yield None


app.dependency_overrides[get_current_user] = _override_get_current_user
app.dependency_overrides[get_db] = _override_get_db

client = TestClient(app)


@pytest.mark.asyncio
async def test_create_inspection():
    with patch(
        "app.services.inspection_service.create_inspection",
        new=AsyncMock(return_value=_INSPECTION),
    ):
        resp = client.post("/api/v1/inspections", json={"domain": "표면처리"})
    assert resp.status_code == 200
    assert resp.json()["status"] == "pending"


@pytest.mark.asyncio
async def test_get_inspection():
    with patch(
        "app.services.inspection_service.get_inspection",
        new=AsyncMock(return_value=_INSPECTION),
    ):
        resp = client.get(f"/api/v1/inspections/{_INSPECTION.id}")
    assert resp.status_code == 200
    assert resp.json()["id"] == str(_INSPECTION.id)


@pytest.mark.asyncio
async def test_detect():
    with patch(
        "app.services.detection_service.run_detection",
        new=AsyncMock(return_value=_DETECTION_RESULT),
    ):
        resp = client.post(f"/api/v1/inspections/{_INSPECTION.id}/detect")
    assert resp.status_code == 200
    data = resp.json()
    assert "defects" in data
    assert len(data["defects"]) > 0


@pytest.mark.asyncio
async def test_guidance():
    resp = client.get(f"/api/v1/inspections/{_INSPECTION.id}/guidance")
    assert resp.status_code == 200
    assert "action_steps" in resp.json()


@pytest.mark.asyncio
async def test_get_upload_url():
    _key = f"inspections/{_INSPECTION.id}/image.jpg"
    _url_result = {
        "upload_url": "https://s3.amazonaws.com/siren-inspections/fake-signed",
        "key": _key,
        "expires_in": 900,
    }
    with patch(
        "app.services.inspection_service.get_upload_url",
        new=AsyncMock(return_value=_url_result),
    ):
        resp = client.post(f"/api/v1/inspections/{_INSPECTION.id}/upload-url")
    assert resp.status_code == 200
    body = resp.json()
    assert body["key"] == _key
    assert body["expires_in"] == 900
    assert "upload_url" in body


@pytest.mark.asyncio
async def test_get_upload_url_not_found():
    from fastapi import HTTPException, status

    with patch(
        "app.services.inspection_service.get_upload_url",
        new=AsyncMock(side_effect=HTTPException(status_code=status.HTTP_404_NOT_FOUND)),
    ):
        resp = client.post(f"/api/v1/inspections/{uuid.uuid4()}/upload-url")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_upload_image():
    updated = Inspection(
        id=_INSPECTION.id,
        domain=_INSPECTION.domain,
        status=_INSPECTION.status,
        inspector_id=_INSPECTION.inspector_id,
        image_key="inspections/test/image.jpg",
        thumbnail_key=None,
        report_flagged=False,
        model_version="mock-v0",
        rag_version="mock-v0",
        created_at=_INSPECTION.created_at,
        updated_at=_INSPECTION.updated_at,
    )
    with patch(
        "app.services.inspection_service.upload_image",
        new=AsyncMock(return_value=updated),
    ):
        resp = client.post(
            f"/api/v1/inspections/{_INSPECTION.id}/upload",
            files={"file": ("test.jpg", b"fake", "image/jpeg")},
        )
    assert resp.status_code == 200
    assert resp.json()["image_key"] == "inspections/test/image.jpg"
