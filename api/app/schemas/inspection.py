from datetime import datetime

from pydantic import BaseModel


class InspectionCreate(BaseModel):
    ship_name: str = "LNG-CARRIER-01"
    tank_id: str = "TANK-A"


class InspectionResponse(BaseModel):
    id: str
    ship_name: str
    tank_id: str
    status: str
    created_at: datetime
