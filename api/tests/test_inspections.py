from app.main import app
from fastapi.testclient import TestClient

client = TestClient(app)

MOCK_ID = "mock-id-001"


def test_create_inspection():
    response = client.post("/api/v1/inspections", json={})
    assert response.status_code == 200
    data = response.json()
    assert "id" in data
    assert data["status"] == "pending"


def test_get_inspection():
    response = client.get(f"/api/v1/inspections/{MOCK_ID}")
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == MOCK_ID


def test_detect():
    response = client.post(f"/api/v1/inspections/{MOCK_ID}/detect")
    assert response.status_code == 200
    data = response.json()
    assert "defects" in data
    assert len(data["defects"]) > 0


def test_guidance():
    response = client.get(f"/api/v1/inspections/{MOCK_ID}/guidance")
    assert response.status_code == 200
    data = response.json()
    assert "action_steps" in data
    assert len(data["action_steps"]) > 0
