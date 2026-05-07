import uuid
from datetime import datetime

from app.schemas.inspection import InspectionCreate, InspectionResponse


def create_inspection(data: InspectionCreate) -> InspectionResponse:
    return InspectionResponse(
        id=str(uuid.uuid4()),
        ship_name=data.ship_name,
        tank_id=data.tank_id,
        status="pending",
        created_at=datetime.now(),
    )


def get_inspection(inspection_id: str) -> InspectionResponse:
    return InspectionResponse(
        id=inspection_id,
        ship_name="LNG-CARRIER-01",
        tank_id="TANK-A",
        status="completed",
        created_at=datetime.now(),
    )
