import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class InspectionCreate(BaseModel):
    domain: str = "표면처리"


class InspectionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    domain: str
    status: str
    inspector_id: uuid.UUID
    image_key: str | None = None
    thumbnail_key: str | None = None
    report_flagged: bool
    model_version: str
    rag_version: str
    created_at: datetime
