from datetime import datetime
from typing import Literal

from pydantic import BaseModel


class DefectItem(BaseModel):
    canonical_class_name: str
    ontology_id: str
    display_label: str
    annotation_domain: str | None
    quality_state: Literal["defect", "good"]
    confidence_score: float
    bbox: list[float] | None = None
    gradcam_key: str | None = None


class DetectionResult(BaseModel):
    id: str
    inspection_id: str
    detection_job_id: str
    defects: list[DefectItem]
    confidence: float
    detected_at: datetime
