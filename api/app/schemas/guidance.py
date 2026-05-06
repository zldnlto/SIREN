from pydantic import BaseModel


class GuidanceResponse(BaseModel):
    inspection_id: str
    defect_class: str
    action_steps: list[str]
    severity: str
    referenced_doc: str
