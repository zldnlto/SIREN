import uuid
from datetime import datetime

from pydantic import BaseModel, ConfigDict


class InspectionCreate(BaseModel):
    annotation_domain: str = "surface_treatment"


class InspectionUpdate(BaseModel):
    annotation_domain: str | None = None
    report_flagged: bool | None = None



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
    inspector_id: uuid.UUID
    image_key: str | None = None
    thumbnail_key: str | None = None
    report_flagged: bool
    created_at: datetime


class DetectionJobResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: uuid.UUID
    inspection_id: uuid.UUID
    model_version: str
    rag_version: str
    status: str
    error_message: str | None = None
    started_at: datetime | None = None
    completed_at: datetime | None = None
    created_at: datetime
