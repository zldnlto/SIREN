from __future__ import annotations

ALLOWED_MIME_TYPES: dict[str, str] = {
    "image/jpeg": "jpg",
    "image/png": "png",
}
MAX_FILE_SIZE = 20 * 1024 * 1024
UPLOAD_URL_EXPIRES_IN = 900


def is_allowed_content_type(content_type: str) -> bool:
    return content_type in ALLOWED_MIME_TYPES


def extension_for(content_type: str) -> str:
    return ALLOWED_MIME_TYPES[content_type]


def build_upload_key(inspection_id: str, session_id: str) -> str:
    return f"inspections/{inspection_id}/uploads/{session_id}.jpg"


def build_image_key(inspection_id: str, content_type: str) -> str:
    return f"inspections/{inspection_id}/image.{extension_for(content_type)}"


def is_valid_upload_key(inspection_id: str, client_key: str) -> bool:
    return client_key.startswith(f"inspections/{inspection_id}/uploads/")

