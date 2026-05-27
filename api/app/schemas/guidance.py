from typing import Literal

from pydantic import BaseModel


class SopChunk(BaseModel):
    section: str
    content: str
    chunk_index: int


class GuidanceResponse(BaseModel):
    ontology_id: str
    display_label: str
    quality_state: Literal["good", "defect"]
    cause: str
    action_steps: list[str]
    reinspection_criteria: str
    disclaimer: str
    referenced_doc: str | None = None
    sop_excerpt: list[SopChunk] | None = None
