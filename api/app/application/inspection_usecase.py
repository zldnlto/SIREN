from __future__ import annotations

import uuid

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.errors import (
    ForbiddenError,
    InvalidUploadKeyError,
    NotFoundError,
    PayloadTooLargeError,
    UnsupportedMediaTypeError,
    UploadVerificationError,
)
from app.domain.inspection import (
    MAX_FILE_SIZE,
    UPLOAD_URL_EXPIRES_IN,
    build_image_key,
    build_upload_key,
    is_allowed_content_type,
    is_valid_upload_key,
)
from app.ports.repositories import (
    CreateInspectionFn,
    GetInspectionByIdFn,
    UpdateInspectionImageKeysFn,
    UpdateInspectionFn,
)
from app.ports.storage import (
    DeleteFileFn,
    GeneratePresignedPutUrlFn,
    GetObjectEtagFn,
    UploadFileFn,
)


async def create_inspection(
    db: AsyncSession,
    annotation_domain: str,
    inspector_id: uuid.UUID,
    *,
    create_fn: CreateInspectionFn,
):
    return await create_fn(
        db,
        annotation_domain=annotation_domain,
        inspector_id=inspector_id,
    )


async def get_inspection(
    db: AsyncSession, inspection_id: str, *, get_by_id_fn: GetInspectionByIdFn
):
    try:
        uid = uuid.UUID(inspection_id)
    except ValueError as exc:
        raise NotFoundError from exc

    inspection = await get_by_id_fn(db, uid)
    if inspection is None:
        raise NotFoundError
    return inspection


async def get_upload_url(
    db: AsyncSession,
    inspection_id: str,
    requester_id: uuid.UUID,
    *,
    get_inspection_fn: GetInspectionByIdFn,
    generate_presigned_put_url_fn: GeneratePresignedPutUrlFn,
) -> dict:
    inspection = await get_inspection(db, inspection_id, get_by_id_fn=get_inspection_fn)
    if inspection.inspector_id != requester_id:
        raise ForbiddenError
    session_id = uuid.uuid4()
    key = build_upload_key(inspection_id, str(session_id))
    upload_url = await generate_presigned_put_url_fn(key)
    return {"upload_url": upload_url, "key": key, "expires_in": UPLOAD_URL_EXPIRES_IN}


async def confirm_upload(
    db: AsyncSession,
    inspection_id: str,
    requester_id: uuid.UUID,
    client_key: str,
    client_etag: str,
    *,
    get_inspection_fn: GetInspectionByIdFn,
    get_object_etag_fn: GetObjectEtagFn,
    update_image_keys_fn: UpdateInspectionImageKeysFn,
):
    inspection = await get_inspection(db, inspection_id, get_by_id_fn=get_inspection_fn)
    if inspection.inspector_id != requester_id:
        raise ForbiddenError
    if not is_valid_upload_key(inspection_id, client_key):
        raise InvalidUploadKeyError
    server_etag = await get_object_etag_fn(client_key)
    if server_etag is None:
        raise UploadVerificationError("missing")
    if server_etag != client_etag.strip('"'):
        raise UploadVerificationError("mismatch")
    return await update_image_keys_fn(db, inspection, image_key=client_key)


async def upload_image(
    db: AsyncSession,
    inspection_id: str,
    *,
    content_type: str,
    content: bytes,
    get_inspection_fn: GetInspectionByIdFn,
    upload_file_fn: UploadFileFn,
    delete_file_fn: DeleteFileFn,
    update_image_keys_fn: UpdateInspectionImageKeysFn,
):
    if not is_allowed_content_type(content_type):
        raise UnsupportedMediaTypeError

    inspection = await get_inspection(db, inspection_id, get_by_id_fn=get_inspection_fn)

    if len(content) > MAX_FILE_SIZE:
        raise PayloadTooLargeError

    key = build_image_key(inspection_id, content_type)

    await upload_file_fn(content, key, content_type)
    try:
        return await update_image_keys_fn(db, inspection, image_key=key)
    except Exception:
        await delete_file_fn(key)
        raise


async def update_inspection(
    db: AsyncSession,
    inspection_id: str,
    requester_id: uuid.UUID,
    *,
    annotation_domain: str | None = None,
    report_flagged: bool | None = None,
    get_inspection_fn: GetInspectionByIdFn,
    update_fn: UpdateInspectionFn,
):
    inspection = await get_inspection(db, inspection_id, get_by_id_fn=get_inspection_fn)
    if inspection.inspector_id != requester_id:
        raise ForbiddenError
    return await update_fn(
        db,
        inspection,
        annotation_domain=annotation_domain,
        report_flagged=report_flagged,
    )
