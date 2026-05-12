import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class InspectionCreate(BaseModel):
    ship_name: str = "LNG-CARRIER-01"
    tank_id: str = "TANK-A"
    notes: str | None = None


class InspectionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    ship_name: str
    tank_id: str
    status: str
    inspector_id: uuid.UUID
    notes: str | None
    image_key: str | None = None
    thumbnail_key: str | None = None
    gradcam_key: str | None = None
    created_at: datetime
