from datetime import datetime
from uuid import UUID

from pydantic import BaseModel


class DashboardSummary(BaseModel):
    total_inspections: int
    defect_count: int
    normal_count: int
    unknown_count: int
    failed_count: int
    average_confidence: float | None


class InspectionListItem(BaseModel):
    inspection_id: UUID
    inspector_id: UUID
    created_at: datetime
    completed_at: datetime | None = None
    status: str | None = None
    quality_state: str | None = None
    annotation_domain: str
    canonical_class_name: str | None = None
    ontology_id: str | None = None
    confidence_score: float | None = None


class InspectionListResponse(BaseModel):
    items: list[InspectionListItem]
    total: int


class GuidanceDetail(BaseModel):
    cause: str
    action: list[str]
    reinspection: str
    caution: str


class InspectionDetail(BaseModel):
    inspection_id: UUID
    inspector_id: UUID
    image_url: str | None = None
    overlay_image_url: str | None = None
    status: str | None = None
    quality_state: str | None = None
    annotation_domain: str
    canonical_class_name: str | None = None
    ontology_id: str | None = None
    confidence_score: float | None = None
    guidance: GuidanceDetail | None = None
    created_at: datetime
    completed_at: datetime | None = None
    error_message: str | None = None


class DomainDistributionItem(BaseModel):
    annotation_domain: str
    count: int


class DefectTypeDistributionItem(BaseModel):
    ontology_id: str
    canonical_class_name: str
    count: int


class QualityStateDistributionItem(BaseModel):
    label: str
    count: int


class AnalyticsResponse(BaseModel):
    domain_distribution: list[DomainDistributionItem]
    defect_type_distribution: list[DefectTypeDistributionItem]
    quality_state_distribution: list[QualityStateDistributionItem]
