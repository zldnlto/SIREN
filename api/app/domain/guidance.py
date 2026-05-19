from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal


@dataclass(frozen=True)
class GuidancePlan:
    ontology_id: str
    display_label: str
    quality_state: Literal["good", "defect"]
    cause: str
    action_steps: list[str] = field(default_factory=list)
    reinspection_criteria: str = ""
    disclaimer: str = ""
    referenced_doc: str | None = None
