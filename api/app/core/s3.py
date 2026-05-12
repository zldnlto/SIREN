import asyncio

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException, status

from app.core.config import settings


def _get_client():
    return boto3.client(
        "s3",
        region_name=settings.AWS_S3_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


async def upload_file(
    content: bytes, key: str, content_type: str = "image/jpeg"
) -> str:
    def _upload():
        client = _get_client()
        client.put_object(
            Bucket=settings.AWS_S3_BUCKET,
            Key=key,
            Body=content,
            ContentType=content_type,
        )
        return key

    try:
        return await asyncio.to_thread(_upload)
    except (BotoCoreError, ClientError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"S3 업로드 실패: {exc}",
        )


async def delete_file(key: str) -> None:
    """S3 오브젝트 삭제. DB 롤백 보상 처리용으로만 사용. 실패해도 예외를 전파하지 않는다."""

    def _delete():
        _get_client().delete_object(Bucket=settings.AWS_S3_BUCKET, Key=key)

    try:
        await asyncio.to_thread(_delete)
    except (BotoCoreError, ClientError):
        pass
