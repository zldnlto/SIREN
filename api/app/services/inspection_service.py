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
        domain=data.domain,
        inspector_id=inspector_id,
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


async def get_upload_url(
    db: AsyncSession, inspection_id: str, requester_id: uuid.UUID
) -> dict:
    inspection = await get_inspection(db, inspection_id)
    if inspection.inspector_id != requester_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="본인의 검사 건에만 이미지를 업로드할 수 있습니다.",
        )
    key = f"inspections/{inspection_id}/image.jpg"
    upload_url = await s3.generate_presigned_put_url(key)
    return {"upload_url": upload_url, "key": key, "expires_in": 900}


async def confirm_upload(
    db: AsyncSession, inspection_id: str, requester_id: uuid.UUID, client_etag: str
):
    inspection = await get_inspection(db, inspection_id)
    if inspection.inspector_id != requester_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="본인의 검사 건에만 업로드 확인을 할 수 있습니다.",
        )
    key = f"inspections/{inspection_id}/image.jpg"
    server_etag = await s3.get_object_etag(key)
    if server_etag is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="S3에 업로드된 이미지를 찾을 수 없습니다. 먼저 이미지를 업로드해 주세요.",
        )
    # ETag 대조로 TOCTOU 경쟁 조건 방지: 클라이언트가 업로드한 객체와 동일한지 검증
    if server_etag != client_etag.strip('"'):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="업로드 검증 실패: ETag가 일치하지 않습니다.",
        )
    return await inspection_repository.update_image_keys(db, inspection, image_key=key)


async def upload_image(db: AsyncSession, inspection_id: str, file: UploadFile):
    inspection = await get_inspection(db, inspection_id)
    content = await file.read()
    ext = (
        file.filename.rsplit(".", 1)[-1]
        if file.filename and "." in file.filename
        else "jpg"
    )
    key = f"inspections/{inspection_id}/image.{ext}"

    await s3.upload_file(content, key, file.content_type or "image/jpeg")
    try:
        return await inspection_repository.update_image_keys(
            db, inspection, image_key=key
        )
    except Exception:
        await s3.delete_file(key)
        raise
