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
    annotation_domain="surface_treatment",
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
            canonical_class_name="crack_paint",
            ontology_id="surface_treatment.crack.paint",
            display_label="균열 (도장)",
            annotation_domain="surface_treatment",
            quality_state="defect",
            confidence_score=0.92,
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
    from unittest.mock import AsyncMock, patch
    from app.schemas.guidance import GuidanceResponse

    mock_response = GuidanceResponse(
        ontology_id="surface_treatment.crack.paint",
        display_label="균열 (도장)",
        quality_state="defect",
        cause="반복 하중으로 인한 균열",
        action_steps=["작업 중단", "관리자 보고"],
        reinspection_criteria="보수 후 재검사",
        disclaimer="참고용입니다.",
    )
    with patch(
        "app.services.guidance_service.get_guidance",
        new=AsyncMock(return_value=mock_response),
    ):
        resp = client.get("/api/v1/guidance?ontology_id=surface_treatment.crack.paint")
    assert resp.status_code == 200
    assert "action_steps" in resp.json()


@pytest.mark.asyncio
async def test_get_upload_url():
    _key = f"inspections/{_INSPECTION.id}/uploads/some-uuid.jpg"
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
    assert f"inspections/{_INSPECTION.id}/uploads/" in body["key"]
    assert body["expires_in"] == 900
    assert "upload_url" in body


@pytest.mark.asyncio
async def test_upload_url_keys_are_unique():
    """동일 inspection에 복수 upload-url 요청 시 서로 다른 key 반환."""
    from unittest.mock import AsyncMock as AM

    import app.services.inspection_service as svc

    with (
        patch(
            "app.repositories.inspection_repository.get_by_id",
            new=AM(return_value=_INSPECTION),
        ),
        patch(
            "app.core.s3.generate_presigned_put_url",
            new=AM(return_value="https://fake-url"),
        ),
    ):
        result1 = await svc.get_upload_url(None, str(_INSPECTION.id), _USER.id)
        result2 = await svc.get_upload_url(None, str(_INSPECTION.id), _USER.id)

    assert result1["key"] != result2["key"]
    assert result1["key"].startswith(f"inspections/{_INSPECTION.id}/uploads/")
    assert result2["key"].startswith(f"inspections/{_INSPECTION.id}/uploads/")


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
async def test_get_upload_url_forbidden():
    from fastapi import HTTPException, status

    with patch(
        "app.services.inspection_service.get_upload_url",
        new=AsyncMock(side_effect=HTTPException(status_code=status.HTTP_403_FORBIDDEN)),
    ):
        resp = client.post(f"/api/v1/inspections/{_INSPECTION.id}/upload-url")
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_confirm_upload_success():
    updated = Inspection(
        id=_INSPECTION.id,
        annotation_domain=_INSPECTION.annotation_domain,
        status=_INSPECTION.status,
        inspector_id=_INSPECTION.inspector_id,
        image_key=f"inspections/{_INSPECTION.id}/image.jpg",
        thumbnail_key=None,
        report_flagged=False,
        model_version="mock-v0",
        rag_version="mock-v0",
        created_at=_INSPECTION.created_at,
        updated_at=_INSPECTION.updated_at,
    )
    _session_key = f"inspections/{_INSPECTION.id}/uploads/test-uuid.jpg"
    updated.image_key = _session_key
    with patch(
        "app.services.inspection_service.confirm_upload",
        new=AsyncMock(return_value=updated),
    ):
        resp = client.post(
            f"/api/v1/inspections/{_INSPECTION.id}/confirm-upload",
            json={"key": _session_key, "etag": "abc123"},
        )
    assert resp.status_code == 200
    assert resp.json()["image_key"] == _session_key


@pytest.mark.asyncio
async def test_confirm_upload_s3_not_found():
    from fastapi import HTTPException, status

    with patch(
        "app.services.inspection_service.confirm_upload",
        new=AsyncMock(
            side_effect=HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="S3에 업로드된 이미지를 찾을 수 없습니다. 먼저 이미지를 업로드해 주세요.",
            )
        ),
    ):
        resp = client.post(
            f"/api/v1/inspections/{_INSPECTION.id}/confirm-upload",
            json={
                "key": f"inspections/{_INSPECTION.id}/uploads/x.jpg",
                "etag": "abc123",
            },
        )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_confirm_upload_not_found():
    from fastapi import HTTPException, status

    with patch(
        "app.services.inspection_service.confirm_upload",
        new=AsyncMock(side_effect=HTTPException(status_code=status.HTTP_404_NOT_FOUND)),
    ):
        resp = client.post(
            f"/api/v1/inspections/{uuid.uuid4()}/confirm-upload",
            json={"key": f"inspections/{uuid.uuid4()}/uploads/x.jpg", "etag": "abc123"},
        )
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_upload_image():
    updated = Inspection(
        id=_INSPECTION.id,
        annotation_domain=_INSPECTION.annotation_domain,
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


@pytest.mark.asyncio
async def test_upload_image_unsupported_mime_type():
    from fastapi import HTTPException, status

    with patch(
        "app.services.inspection_service.upload_image",
        new=AsyncMock(
            side_effect=HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE
            )
        ),
    ):
        resp = client.post(
            f"/api/v1/inspections/{_INSPECTION.id}/upload",
            files={"file": ("test.gif", b"fake", "image/gif")},
        )
    assert resp.status_code == 415


@pytest.mark.asyncio
async def test_upload_image_too_large():
    from fastapi import HTTPException, status

    with patch(
        "app.services.inspection_service.upload_image",
        new=AsyncMock(
            side_effect=HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE
            )
        ),
    ):
        resp = client.post(
            f"/api/v1/inspections/{_INSPECTION.id}/upload",
            files={"file": ("big.jpg", b"x" * 100, "image/jpeg")},
        )
    assert resp.status_code == 413
