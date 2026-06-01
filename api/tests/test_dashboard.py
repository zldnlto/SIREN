import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, patch

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.dependencies import get_current_user
from app.main import app
from app.models.user import User
from app.schemas.dashboard import (
    AnalyticsResponse,
    DashboardSummary,
    DefectTypeDistributionItem,
    DomainDistributionItem,
    GuidanceDetail,
    InspectionDetail,
    InspectionListItem,
    InspectionListResponse,
    QualityStateDistributionItem,
)

_USER = User(
    id=uuid.uuid4(),
    employee_id="EMP-001",
    name="Test Inspector",
    password_hash="hashed",
    role="INSPECTOR",
)

_INSPECTION_ID = uuid.uuid4()

_SUMMARY = DashboardSummary(
    total_inspections=10,
    defect_count=4,
    normal_count=5,
    unknown_count=0,
    failed_count=1,
    average_confidence=0.87,
)

_LIST_ITEM = InspectionListItem(
    inspection_id=_INSPECTION_ID,
    inspector_id=_USER.id,
    created_at=datetime.now(timezone.utc),
    completed_at=datetime.now(timezone.utc),
    status="completed",
    quality_state="defect",
    annotation_domain="surface_treatment",
    canonical_class_name="scratch_paint",
    ontology_id="surface_treatment.scratch.paint",
    confidence_score=0.91,
)

_DETAIL = InspectionDetail(
    inspection_id=_INSPECTION_ID,
    inspector_id=_USER.id,
    image_url=None,
    overlay_image_url=None,
    status="completed",
    quality_state="defect",
    annotation_domain="surface_treatment",
    canonical_class_name="scratch_paint",
    ontology_id="surface_treatment.scratch.paint",
    confidence_score=0.91,
    guidance=GuidanceDetail(
        cause="도장면에 물리적 접촉이 발생했습니다.",
        action=["손상 부위를 확인합니다.", "재도장을 진행합니다."],
        reinspection="보수 후 동일 영역을 재촬영합니다.",
        caution="AI 조치 가이드는 참고용입니다.",
    ),
    created_at=datetime.now(timezone.utc),
    completed_at=datetime.now(timezone.utc),
    error_message=None,
)

_ANALYTICS = AnalyticsResponse(
    domain_distribution=[
        DomainDistributionItem(annotation_domain="surface_treatment", count=8),
        DomainDistributionItem(annotation_domain="welding", count=2),
    ],
    defect_type_distribution=[
        DefectTypeDistributionItem(
            ontology_id="surface_treatment.scratch.paint",
            canonical_class_name="scratch_paint",
            count=5,
        )
    ],
    quality_state_distribution=[
        QualityStateDistributionItem(label="defect", count=4),
        QualityStateDistributionItem(label="normal", count=5),
        QualityStateDistributionItem(label="unknown", count=1),
    ],
)


async def _override_get_current_user():
    return _USER


async def _override_get_db():
    yield None


app.dependency_overrides[get_current_user] = _override_get_current_user
app.dependency_overrides[get_db] = _override_get_db


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


def test_get_summary(client: TestClient):
    with patch(
        "app.repositories.dashboard_repository.get_summary",
        new_callable=AsyncMock,
        return_value=_SUMMARY,
    ):
        resp = client.get("/api/v1/dashboard/summary")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_inspections"] == 10
    assert data["defect_count"] == 4
    assert data["normal_count"] == 5
    assert data["failed_count"] == 1
    assert data["average_confidence"] == pytest.approx(0.87)


def test_list_inspections(client: TestClient):
    with patch(
        "app.repositories.dashboard_repository.list_inspections",
        new_callable=AsyncMock,
        return_value=([_LIST_ITEM], 1),
    ):
        resp = client.get("/api/v1/dashboard/inspections")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total"] == 1
    assert len(data["items"]) == 1
    assert data["items"][0]["status"] == "completed"
    assert data["items"][0]["quality_state"] == "defect"


def test_list_inspections_with_filter(client: TestClient):
    with patch(
        "app.repositories.dashboard_repository.list_inspections",
        new_callable=AsyncMock,
        return_value=([], 0),
    ):
        resp = client.get(
            "/api/v1/dashboard/inspections",
            params={"status": "failed", "annotation_domain": "welding"},
        )
    assert resp.status_code == 200
    assert resp.json()["total"] == 0


def test_get_inspection_detail(client: TestClient):
    with patch(
        "app.repositories.dashboard_repository.get_inspection_detail",
        new_callable=AsyncMock,
        return_value=_DETAIL,
    ):
        resp = client.get(f"/api/v1/dashboard/inspections/{_INSPECTION_ID}")
    assert resp.status_code == 200
    data = resp.json()
    assert data["ontology_id"] == "surface_treatment.scratch.paint"
    assert data["guidance"] is not None
    assert data["guidance"]["cause"] == "도장면에 물리적 접촉이 발생했습니다."


def test_get_inspection_detail_not_found(client: TestClient):
    with patch(
        "app.repositories.dashboard_repository.get_inspection_detail",
        new_callable=AsyncMock,
        return_value=None,
    ):
        resp = client.get(f"/api/v1/dashboard/inspections/{uuid.uuid4()}")
    assert resp.status_code == 404


def test_get_analytics(client: TestClient):
    with patch(
        "app.repositories.dashboard_repository.get_analytics",
        new_callable=AsyncMock,
        return_value=_ANALYTICS,
    ):
        resp = client.get("/api/v1/dashboard/analytics")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["domain_distribution"]) == 2
    assert len(data["defect_type_distribution"]) == 1
    assert len(data["quality_state_distribution"]) == 3
