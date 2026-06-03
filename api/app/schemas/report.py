import uuid
from datetime import datetime
from pydantic import BaseModel, ConfigDict


class ReportBase(BaseModel):
    inspection_id: uuid.UUID
    status: str = "pending"
    action_checks: list[bool] | None = None
    note: str | None = None


class ReportCreate(ReportBase):
    pass


class ReportResponse(ReportBase):
    id: uuid.UUID
    resolver_id: uuid.UUID | None = None
    resolved_at: datetime | None = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
