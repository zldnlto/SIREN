from unittest.mock import MagicMock, patch

import pytest
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException

from app.core.s3 import generate_presigned_put_url


@pytest.mark.asyncio
async def test_generate_presigned_put_url_params():
    mock_client = MagicMock()
    mock_client.generate_presigned_url.return_value = "https://s3.example.com/fake-url"

    with patch("app.core.s3._get_client", return_value=mock_client):
        result = await generate_presigned_put_url("inspections/test-id/image.jpg")

    mock_client.generate_presigned_url.assert_called_once_with(
        "put_object",
        Params={
            "Bucket": mock_client.generate_presigned_url.call_args.kwargs["Params"][
                "Bucket"
            ],
            "Key": "inspections/test-id/image.jpg",
            "ContentType": "image/jpeg",
        },
        ExpiresIn=900,
    )
    assert result == "https://s3.example.com/fake-url"


@pytest.mark.asyncio
async def test_generate_presigned_put_url_client_error():
    mock_client = MagicMock()
    mock_client.generate_presigned_url.side_effect = ClientError(
        {"Error": {"Code": "InvalidAccessKeyId", "Message": "invalid"}},
        "GeneratePresignedUrl",
    )

    with patch("app.core.s3._get_client", return_value=mock_client):
        with pytest.raises(HTTPException) as exc_info:
            await generate_presigned_put_url("inspections/test-id/image.jpg")

    assert exc_info.value.status_code == 502


@pytest.mark.asyncio
async def test_generate_presigned_put_url_botocore_error():
    mock_client = MagicMock()
    mock_client.generate_presigned_url.side_effect = BotoCoreError()

    with patch("app.core.s3._get_client", return_value=mock_client):
        with pytest.raises(HTTPException) as exc_info:
            await generate_presigned_put_url("inspections/test-id/image.jpg")

    assert exc_info.value.status_code == 502
