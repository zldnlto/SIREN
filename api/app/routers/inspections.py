from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.dependencies import get_current_user
from app.schemas.detection import DetectionResult
from app.schemas.guidance import GuidanceResponse
from app.schemas.inspection import (
    ConfirmUploadRequest,
    DetectionJobResponse,
    InspectionCreate,
    InspectionResponse,
    UploadUrlResponse,
)
from app.repositories import detection_job_repository
from app.services import detection_service, guidance_service, inspection_service

router = APIRouter()


@router.post("/inspections", response_model=InspectionResponse)
async def create_inspection(
    data: InspectionCreate,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await inspection_service.create_inspection(db, data, current_user.id)


@router.get("/inspections/{inspection_id}", response_model=InspectionResponse)
async def get_inspection(
    inspection_id: str,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await inspection_service.get_inspection(db, inspection_id)


@router.post("/inspections/{inspection_id}/detect", response_model=DetectionResult)
async def detect(
    inspection_id: str,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await detection_service.run_detection(db, inspection_id)


@router.post(
    "/inspections/{inspection_id}/upload-url", response_model=UploadUrlResponse
)
async def get_upload_url(
    inspection_id: str,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await inspection_service.get_upload_url(db, inspection_id, current_user.id)


@router.post(
    "/inspections/{inspection_id}/confirm-upload", response_model=InspectionResponse
)
async def confirm_upload(
    inspection_id: str,
    data: ConfirmUploadRequest,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await inspection_service.confirm_upload(
        db, inspection_id, current_user.id, data.key, data.etag
    )


@router.post(
    "/inspections/{inspection_id}/upload",
    response_model=InspectionResponse,
    deprecated=True,
)
async def upload_image(
    inspection_id: str,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    return await inspection_service.upload_image(db, inspection_id, file)


@router.get(
    "/inspections/{inspection_id}/jobs", response_model=list[DetectionJobResponse]
)
async def list_detection_jobs(
    inspection_id: str,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    try:
        uid = __import__("uuid").UUID(inspection_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="inspection_id가 유효한 UUID 형식이 아닙니다.",
        )
    return await detection_job_repository.list_by_inspection(db, uid)


@router.get("/guidance", response_model=GuidanceResponse)
async def get_guidance(
    ontology_id: str,
    db: AsyncSession = Depends(get_db),
    current_user=Depends(get_current_user),
):
    result = await guidance_service.get_guidance(db, ontology_id)
    if result is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"guidance not found: {ontology_id}",
        )
    return result
