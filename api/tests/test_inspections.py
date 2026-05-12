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
    email="test@siren.io",
    username="tester",
    hashed_password="hashed",
    is_active=True,
)

_INSPECTION = Inspection(
    id=uuid.uuid4(),
    ship_name="LNG-CARRIER-01",
    tank_id="TANK-A",
    status="pending",
    inspector_id=_USER.id,
    notes=None,
    image_key=None,
    thumbnail_key=None,
    gradcam_key=None,
    created_at=datetime.now(timezone.utc),
    updated_at=datetime.now(timezone.utc),
)

_DETECTION_RESULT = DetectionResult(
    id=str(uuid.uuid4()),
    inspection_id=str(_INSPECTION.id),
    defects=[
        DefectItem(class_name="균열", confidence=0.92, bbox=[10.0, 20.0, 100.0, 80.0])
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
        resp = client.post("/api/v1/inspections", json={})
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
async def test_upload_image():
    updated = Inspection(
        id=_INSPECTION.id,
        ship_name=_INSPECTION.ship_name,
        tank_id=_INSPECTION.tank_id,
        status=_INSPECTION.status,
        inspector_id=_INSPECTION.inspector_id,
        notes=None,
        image_key="inspections/test/image.jpg",
        thumbnail_key=None,
        gradcam_key=None,
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
