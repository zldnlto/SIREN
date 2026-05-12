from __future__ import annotations

from app.domain.guidance import GuidancePlan, default_guidance


def get_guidance(inspection_id: str) -> GuidancePlan:
    return default_guidance(inspection_id)

