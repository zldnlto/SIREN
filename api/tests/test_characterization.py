import uuid
from datetime import datetime, timezone
from io import BytesIO
from unittest.mock import AsyncMock, patch

import pytest
from fastapi import HTTPException
from starlette.datastructures import Headers, UploadFile

from app.core.security import hash_password
from app.models.inspection import Inspection
from app.models.user import User
from app.schemas.auth import LoginRequest
from app.schemas.detection import DetectionResult
from app.services import auth_service, detection_service
from app.services import inspection_service

_USER = User(
    id=uuid.uuid4(),
    employee_id="EMP-001",
    name="Test Inspector",
    password_hash=hash_password("secret1234"),
    role="INSPECTOR",
)

_INSPECTION = Inspection(
    id=uuid.uuid4(),
    annotation_domain="surface_treatment",
    inspector_id=_USER.id,
    image_key="inspections/test-image.jpg",
    thumbnail_key=None,
    report_flagged=False,
    created_at=datetime.now(timezone.utc),
    updated_at=datetime.now(timezone.utc),
)

_MOCK_DETECTIONS = [
    {"class_code": 0, "confidence": 0.92, "bbox": [10.0, 20.0, 100.0, 80.0]},
    {"class_code": 1, "confidence": 0.78, "bbox": [50.0, 60.0, 200.0, 150.0]},
]


@pytest.mark.asyncio
async def test_login_rejects_deleted_user():
    deleted = User(
        id=uuid.uuid4(),
        employee_id="EMP-DEL",
        name="Deleted User",
        password_hash=hash_password("secret1234"),
        role="INSPECTOR",
        deleted_at=datetime.now(timezone.utc),
    )

    with patch(
        "app.repositories.user_repository.get_by_employee_id",
        new=AsyncMock(return_value=deleted),
    ):
        with pytest.raises(HTTPException) as exc_info:
            await auth_service.login(
                None,
                LoginRequest(employee_id=deleted.employee_id, password="secret1234"),
            )

    assert exc_info.value.status_code == 401


@pytest.mark.asyncio
async def test_get_inspection_rejects_invalid_uuid():
    with pytest.raises(HTTPException) as exc_info:
        await inspection_service.get_inspection(None, "not-a-uuid")

    assert exc_info.value.status_code == 404


@pytest.mark.asyncio
async def test_get_upload_url_requires_owner():
    other_user = User(
        id=uuid.uuid4(),
        employee_id="EMP-002",
        name="Other Inspector",
        password_hash="hashed",
        role="INSPECTOR",
    )
    other_inspection = Inspection(
        id=_INSPECTION.id,
        annotation_domain=_INSPECTION.annotation_domain,
        inspector_id=other_user.id,
        image_key=None,
        thumbnail_key=None,
        report_flagged=False,
        created_at=_INSPECTION.created_at,
        updated_at=_INSPECTION.updated_at,
    )

    with patch(
        "app.application.inspection_usecase.get_inspection",
        new=AsyncMock(return_value=other_inspection),
    ):
        with pytest.raises(HTTPException) as exc_info:
            await inspection_service.get_upload_url(None, str(_INSPECTION.id), _USER.id)

    assert exc_info.value.status_code == 403


@pytest.mark.asyncio
async def test_confirm_upload_rejects_invalid_key_prefix():
    with patch(
        "app.application.inspection_usecase.get_inspection",
        new=AsyncMock(return_value=_INSPECTION),
    ):
        with pytest.raises(HTTPException) as exc_info:
            await inspection_service.confirm_upload(
                None,
                str(_INSPECTION.id),
                _USER.id,
                "uploads/not-allowed.jpg",
                "abc123",
            )

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_confirm_upload_rejects_etag_mismatch():
    with (
        patch(
            "app.application.inspection_usecase.get_inspection",
            new=AsyncMock(return_value=_INSPECTION),
        ),
        patch(
            "app.core.s3.get_object_etag",
            new=AsyncMock(return_value="abc123"),
        ),
    ):
        with pytest.raises(HTTPException) as exc_info:
            await inspection_service.confirm_upload(
                None,
                str(_INSPECTION.id),
                _USER.id,
                f"inspections/{_INSPECTION.id}/uploads/test.jpg",
                "different",
            )

    assert exc_info.value.status_code == 422


@pytest.mark.asyncio
async def test_upload_image_rejects_unsupported_media_type():
    upload = UploadFile(
        file=BytesIO(b"hello"),
        filename="note.txt",
        headers=Headers({"content-type": "text/plain"}),
    )

    with pytest.raises(HTTPException) as exc_info:
        await inspection_service.upload_image(None, str(_INSPECTION.id), upload)

    assert exc_info.value.status_code == 415


@pytest.mark.asyncio
async def test_upload_image_rejects_large_payload():
    upload = UploadFile(
        file=BytesIO(b"x" * (20 * 1024 * 1024 + 1)),
        filename="image.jpg",
        headers=Headers({"content-type": "image/jpeg"}),
    )

    with patch(
        "app.application.inspection_usecase.get_inspection",
        new=AsyncMock(return_value=_INSPECTION),
    ):
        with pytest.raises(HTTPException) as exc_info:
            await inspection_service.upload_image(None, str(_INSPECTION.id), upload)

    assert exc_info.value.status_code == 413


@pytest.mark.asyncio
async def test_run_detection_persists_mock_detections():
    class DummyDB:
        def __init__(self):
            self.commit = AsyncMock()

    db = DummyDB()

    import uuid as _uuid

    _job_id = _uuid.uuid4()

    class _FakeJob:
        id = _job_id

    with (
        patch(
            "app.repositories.inspection_repository.get_by_id",
            new=AsyncMock(return_value=_INSPECTION),
        ),
        patch(
            "app.repositories.detection_job_repository.get_active",
            new=AsyncMock(return_value=None),
        ),
        patch(
            "app.repositories.detection_job_repository.create",
            new=AsyncMock(return_value=_FakeJob()),
        ),
        patch(
            "app.repositories.detection_job_repository.update_status",
            new=AsyncMock(return_value=_FakeJob()),
        ) as update_job_status,
        patch(
            "app.repositories.defect_repository.create_many",
            new=AsyncMock(return_value=[]),
        ) as create_many,
        patch(
            "app.services.detection_service._call_ml_server",
            new=AsyncMock(return_value=_MOCK_DETECTIONS),
        ),
    ):
        result = await detection_service.run_detection(db, str(_INSPECTION.id))

    assert isinstance(result, DetectionResult)
    assert result.inspection_id == str(_INSPECTION.id)
    assert result.detection_job_id == str(_job_id)
    assert len(result.defects) == 2
    assert result.defects[0].quality_state == "defect"
    assert result.defects[1].quality_state == "defect"
    assert result.defects[0].bbox == [10.0, 20.0, 100.0, 80.0]
    create_many.assert_awaited_once()
    saved_items = create_many.await_args.args[1]
    assert saved_items[0]["canonical_class_name"] == "coating_drop_paint"
    assert saved_items[0]["ontology_id"] == "surface_treatment.coating_drop.paint"
    assert saved_items[0]["detection_job_id"] == _job_id
    assert saved_items[0]["quality_state"] == "defect"
    assert saved_items[0]["bbox"] == {
        "x_min": 10.0,
        "y_min": 20.0,
        "x_max": 100.0,
        "y_max": 80.0,
    }
    assert saved_items[1]["canonical_class_name"] == "coating_separation_paint"
    assert saved_items[1]["ontology_id"] == "surface_treatment.coating_separation.paint"
    assert update_job_status.await_count == 2  # processing → completed
    db.commit.assert_awaited_once()
