import boto3
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException, status

from app.config import settings


def _get_client():
    return boto3.client(
        "s3",
        region_name=settings.AWS_S3_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID or None,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY or None,
    )


def download_image(image_key: str) -> bytes:
    try:
        resp = _get_client().get_object(Bucket=settings.AWS_S3_BUCKET, Key=image_key)
        return resp["Body"].read()
    except ClientError as exc:
        code = exc.response["Error"]["Code"]
        if code in ("404", "NoSuchKey"):
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"이미지 없음: {image_key}",
            )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"S3 다운로드 실패: {exc}",
        )
    except BotoCoreError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"S3 다운로드 실패: {exc}",
        )
