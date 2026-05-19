import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class InspectionCreate(BaseModel):
    annotation_domain: str = "surface_treatment"


class UploadUrlResponse(BaseModel):
    upload_url: str
    key: str
    expires_in: int


class ConfirmUploadRequest(BaseModel):
    key: str
    etag: str


class InspectionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    annotation_domain: str
    status: str
    inspector_id: uuid.UUID
    image_key: str | None = None
    thumbnail_key: str | None = None
    report_flagged: bool
    model_version: str
    rag_version: str
    created_at: datetime
