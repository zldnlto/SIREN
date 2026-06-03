import uuid

from fastapi import HTTPException, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application import inspection_usecase
from app.application.errors import (
    ForbiddenError,
    InvalidUploadKeyError,
    NotFoundError,
    PayloadTooLargeError,
    UnsupportedMediaTypeError,
    UploadVerificationError,
)
from app.core import s3
from app.domain.inspection import ALLOWED_MIME_TYPES, MAX_FILE_SIZE
from app.repositories import inspection_repository
from app.schemas.inspection import InspectionCreate, InspectionUpdate


async def create_inspection(
    db: AsyncSession, data: InspectionCreate, inspector_id: uuid.UUID
):
    return await inspection_usecase.create_inspection(
        db,
        annotation_domain=data.annotation_domain,
        inspector_id=inspector_id,
        create_fn=inspection_repository.create,
    )


async def get_inspection(db: AsyncSession, inspection_id: str):
    try:
        return await inspection_usecase.get_inspection(
            db,
            inspection_id,
            get_by_id_fn=inspection_repository.get_by_id,
        )
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )


async def get_upload_url(
    db: AsyncSession, inspection_id: str, requester_id: uuid.UUID
) -> dict:
    try:
        return await inspection_usecase.get_upload_url(
            db,
            inspection_id,
            requester_id,
            get_inspection_fn=inspection_repository.get_by_id,
            generate_presigned_put_url_fn=s3.generate_presigned_put_url,
        )
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )
    except ForbiddenError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="본인의 검사 건에만 이미지를 업로드할 수 있습니다.",
        )


async def confirm_upload(
    db: AsyncSession,
    inspection_id: str,
    requester_id: uuid.UUID,
    client_key: str,
    client_etag: str,
):
    try:
        return await inspection_usecase.confirm_upload(
            db,
            inspection_id,
            requester_id,
            client_key,
            client_etag,
            get_inspection_fn=inspection_repository.get_by_id,
            get_object_etag_fn=s3.get_object_etag,
            update_image_keys_fn=inspection_repository.update_image_keys,
        )
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )
    except ForbiddenError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="본인의 검사 건에만 업로드 확인을 할 수 있습니다.",
        )
    except InvalidUploadKeyError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="유효하지 않은 업로드 key입니다.",
        )
    except UploadVerificationError as exc:
        if str(exc) == "missing":
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="S3에 업로드된 이미지를 찾을 수 없습니다. 먼저 이미지를 업로드해 주세요.",
            )
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="업로드 검증 실패: ETag가 일치하지 않습니다.",
        )


_ALLOWED_MIME_TYPES: dict[str, str] = {
    **ALLOWED_MIME_TYPES,
}


async def upload_image(db: AsyncSession, inspection_id: str, file: UploadFile):
    try:
        content = await file.read()
        return await inspection_usecase.upload_image(
            db,
            inspection_id,
            content_type=file.content_type or "",
            content=content,
            get_inspection_fn=inspection_repository.get_by_id,
            upload_file_fn=s3.upload_file,
            delete_file_fn=s3.delete_file,
            update_image_keys_fn=inspection_repository.update_image_keys,
        )
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )
    except UnsupportedMediaTypeError:
        raise HTTPException(
            status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
            detail=f"허용되지 않는 파일 형식입니다. 허용: {', '.join(_ALLOWED_MIME_TYPES)}",
        )
    except PayloadTooLargeError:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"파일 크기가 제한({MAX_FILE_SIZE // 1024 // 1024}MB)을 초과했습니다.",
        )


async def update_inspection(
    db: AsyncSession,
    inspection_id: str,
    requester_id: uuid.UUID,
    data: InspectionUpdate,
):
    try:
        return await inspection_usecase.update_inspection(
            db,
            inspection_id,
            requester_id,
            annotation_domain=data.annotation_domain,
            report_flagged=data.report_flagged,
            get_inspection_fn=inspection_repository.get_by_id,
            update_fn=inspection_repository.update,
        )
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )
    except ForbiddenError:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="본인의 검사 건만 수정할 수 있습니다.",
        )
