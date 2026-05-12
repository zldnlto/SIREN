import uuid

from fastapi import HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import s3
from app.repositories import inspection_repository
from app.schemas.inspection import InspectionCreate


async def create_inspection(
    db: AsyncSession, data: InspectionCreate, inspector_id: uuid.UUID
):
    return await inspection_repository.create(
        db,
        ship_name=data.ship_name,
        tank_id=data.tank_id,
        inspector_id=inspector_id,
        notes=data.notes,
    )


async def get_inspection(db: AsyncSession, inspection_id: str):
    try:
        uid = uuid.UUID(inspection_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )

    inspection = await inspection_repository.get_by_id(db, uid)
    if inspection is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )
    return inspection


async def upload_image(db: AsyncSession, inspection_id: str, file: UploadFile):
    inspection = await get_inspection(db, inspection_id)
    content = await file.read()
    ext = (
        file.filename.rsplit(".", 1)[-1]
        if file.filename and "." in file.filename
        else "jpg"
    )
    key = f"inspections/{inspection_id}/image.{ext}"

    # S3 업로드 먼저, DB 실패 시 S3 오브젝트 삭제로 보상
    await s3.upload_file(content, key, file.content_type or "image/jpeg")
    try:
        return await inspection_repository.update_image_keys(
            db, inspection, image_key=key
        )
    except Exception:
        await s3.delete_file(key)
        raise
