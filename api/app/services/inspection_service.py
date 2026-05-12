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
    session_id = uuid.uuid4()
    key = f"inspections/{inspection_id}/uploads/{session_id}.jpg"
    upload_url = await s3.generate_presigned_put_url(key)
    return {"upload_url": upload_url, "key": key, "expires_in": 900}


async def confirm_upload(
    db: AsyncSession,
    inspection_id: str,
    requester_id: uuid.UUID,
    client_key: str,
    client_etag: str,
):
    inspection = await get_inspection(db, inspection_id)
    if inspection.inspector_id != requester_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="본인의 검사 건에만 업로드 확인을 할 수 있습니다.",
        )
    expected_prefix = f"inspections/{inspection_id}/uploads/"
    if not client_key.startswith(expected_prefix):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="유효하지 않은 업로드 key입니다.",
        )
    server_etag = await s3.get_object_etag(client_key)
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
    return await inspection_repository.update_image_keys(
        db, inspection, image_key=client_key
    )


_ALLOWED_MIME_TYPES: dict[str, str] = {
    "image/jpeg": "jpg",
    "image/png": "png",
}
_MAX_FILE_SIZE = 20 * 1024 * 1024  # 20MB


async def upload_image(db: AsyncSession, inspection_id: str, file: UploadFile):
    content_type = file.content_type or ""
    if content_type not in _ALLOWED_MIME_TYPES:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"허용되지 않는 파일 형식입니다. 허용: {', '.join(_ALLOWED_MIME_TYPES)}",
        )

    inspection = await get_inspection(db, inspection_id)
    content = await file.read()

    if len(content) > _MAX_FILE_SIZE:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"파일 크기가 제한({_MAX_FILE_SIZE // 1024 // 1024}MB)을 초과했습니다.",
        )

    ext = _ALLOWED_MIME_TYPES[content_type]
    key = f"inspections/{inspection_id}/image.{ext}"

    await s3.upload_file(content, key, content_type)
    try:
        return await inspection_repository.update_image_keys(
            db, inspection, image_key=key
        )
    except Exception:
        await s3.delete_file(key)
        raise
