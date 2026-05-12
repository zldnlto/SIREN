from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.detection import DetectionResult
from app.schemas.guidance import GuidanceResponse
from app.schemas.inspection import (
    InspectionCreate,
    InspectionResponse,
    UploadUrlResponse,
)
from app.services import detection_service, guidance_service, inspection_service

router = APIRouter()


@router.post("/inspections", response_model=InspectionResponse)
async def create_inspection(
    data: InspectionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await inspection_service.create_inspection(db, data, current_user.id)


@router.get("/inspections/{inspection_id}", response_model=InspectionResponse)
async def get_inspection(
    inspection_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await inspection_service.get_inspection(db, inspection_id)


@router.post("/inspections/{inspection_id}/detect", response_model=DetectionResult)
async def detect(
    inspection_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await detection_service.run_detection(db, inspection_id)


@router.post(
    "/inspections/{inspection_id}/upload-url", response_model=UploadUrlResponse
)
async def get_upload_url(
    inspection_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await inspection_service.get_upload_url(db, inspection_id, current_user.id)


@router.post(
    "/inspections/{inspection_id}/confirm-upload", response_model=InspectionResponse
)
async def confirm_upload(
    inspection_id: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await inspection_service.confirm_upload(db, inspection_id, current_user.id)


@router.post(
    "/inspections/{inspection_id}/upload",
    response_model=InspectionResponse,
    deprecated=True,
)
async def upload_image(
    inspection_id: str,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return await inspection_service.upload_image(db, inspection_id, file)


@router.get("/inspections/{inspection_id}/guidance", response_model=GuidanceResponse)
async def get_guidance(
    inspection_id: str,
    current_user: User = Depends(get_current_user),
):
    return guidance_service.get_guidance(inspection_id)
