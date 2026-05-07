from app.schemas.detection import DetectionResult
from app.schemas.guidance import GuidanceResponse
from app.schemas.inspection import InspectionCreate, InspectionResponse
from app.services import (detection_service, guidance_service,
                          inspection_service)
from fastapi import APIRouter

router = APIRouter()


@router.post("/inspections", response_model=InspectionResponse)
def create_inspection(data: InspectionCreate):
    return inspection_service.create_inspection(data)


@router.get("/inspections/{inspection_id}", response_model=InspectionResponse)
def get_inspection(inspection_id: str):
    return inspection_service.get_inspection(inspection_id)


@router.post("/inspections/{inspection_id}/detect", response_model=DetectionResult)
def detect(inspection_id: str):
    return detection_service.run_detection(inspection_id)


@router.get("/inspections/{inspection_id}/guidance", response_model=GuidanceResponse)
def get_guidance(inspection_id: str):
    return guidance_service.get_guidance(inspection_id)
