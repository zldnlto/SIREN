from __future__ import annotations

import httpx
from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.detection_usecase import run_detection as run_detection_usecase
from app.application.errors import ConflictError, InvalidInputError, NotFoundError
from app.core.config import settings
from app.repositories import (
    defect_repository,
    detection_job_repository,
    inspection_repository,
)
from app.schemas.detection import DefectItem, DetectionResult


async def _call_ml_server(image_key: str) -> list[dict]:
    if image_key is None:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="이미지가 업로드되지 않은 inspection입니다.",
        )
    async with httpx.AsyncClient(timeout=30.0) as client:
        try:
            resp = await client.post(
                f"{settings.ML_SERVER_URL}/predict",
                json={"image_key": image_key},
            )
            resp.raise_for_status()
        except httpx.TimeoutException:
            raise HTTPException(
                status_code=status.HTTP_504_GATEWAY_TIMEOUT,
                detail="ML 서버 응답 시간 초과",
            )
        except httpx.HTTPError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"ML 서버 오류: {exc}",
            )
    return [
        {
            "class_code": d["class_code"],
            "confidence": d["confidence"],
            "bbox": d["bbox"],
        }
        for d in resp.json()["detections"]
    ]


async def run_detection(db: AsyncSession, inspection_id: str) -> DetectionResult:
    try:
        outcome = await run_detection_usecase(
            db,
            inspection_id,
            get_by_id_fn=inspection_repository.get_by_id,
            create_job_fn=detection_job_repository.create,
            get_active_job_fn=detection_job_repository.get_active,
            update_job_status_fn=detection_job_repository.update_status,
            create_many_fn=defect_repository.create_many,
            commit_fn=db.commit,
            run_inference_fn=_call_ml_server,
        )
    except InvalidInputError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="inspection_id가 유효한 UUID 형식이 아닙니다.",
        )
    except NotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )
    except ConflictError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="이미 진행 중인 탐지 작업이 있습니다.",
        )

    return DetectionResult(
        id=outcome.id,
        inspection_id=outcome.inspection_id,
        detection_job_id=outcome.detection_job_id,
        defects=[
            DefectItem(
                canonical_class_name=defect.canonical_class_name,
                ontology_id=defect.ontology_id,
                display_label=defect.display_label,
                annotation_domain=defect.annotation_domain,
                quality_state=defect.quality_state,
                confidence_score=defect.confidence_score,
                bbox=defect.bbox,
                gradcam_key=defect.gradcam_key,
            )
            for defect in outcome.defects
        ],
        confidence=outcome.confidence,
        detected_at=outcome.detected_at,
    )
