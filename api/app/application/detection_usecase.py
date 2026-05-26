from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.errors import ConflictError, InvalidInputError, NotFoundError
from app.domain.detection import (
    DetectionItemCore,
    average_confidence,
    build_detection_item,
    build_persisted_defect,
)
from app.ports.repositories import (
    CreateDetectionJobFn,
    CreateManyDefectsFn,
    GetActiveDetectionJobFn,
    GetInspectionByIdFn,
    UpdateDetectionJobStatusFn,
)

# TODO: siren-ml 추론 서버 연동 시 교체 (Feat/ml-server 이슈 참고)
MOCK_DETECTIONS = [
    {"class_code": 0, "confidence": 0.92, "bbox": [10.0, 20.0, 100.0, 80.0]},
    {"class_code": 1, "confidence": 0.78, "bbox": [50.0, 60.0, 200.0, 150.0]},
]

MODEL_VERSION = "mock-v0"
RAG_VERSION = "mock-v0"


@dataclass(frozen=True)
class DetectionOutcome:
    id: str
    inspection_id: str
    detection_job_id: str
    defects: list[DetectionItemCore]
    confidence: float
    detected_at: datetime


async def run_detection(
    db: AsyncSession,
    inspection_id: str,
    *,
    get_by_id_fn: GetInspectionByIdFn,
    create_job_fn: CreateDetectionJobFn,
    get_active_job_fn: GetActiveDetectionJobFn,
    update_job_status_fn: UpdateDetectionJobStatusFn,
    create_many_fn: CreateManyDefectsFn,
    commit_fn,
) -> DetectionOutcome:
    try:
        uid = uuid.UUID(inspection_id)
    except ValueError as exc:
        raise InvalidInputError from exc

    inspection = await get_by_id_fn(db, uid)
    if inspection is None:
        raise NotFoundError

    active_job = await get_active_job_fn(db, uid)
    if active_job is not None:
        raise ConflictError

    job = await create_job_fn(db, uid, MODEL_VERSION, RAG_VERSION)
    await update_job_status_fn(db, job, "processing")

    try:
        domain_code = 25  # surface_treatment

        db_items = [
            build_persisted_defect(
                uid,
                job.id,
                domain_code,
                defect["class_code"],
                defect["confidence"],
                defect["bbox"],
            )
            for defect in MOCK_DETECTIONS
        ]
        await create_many_fn(db, db_items)
        await update_job_status_fn(db, job, "completed")
        await commit_fn()
    except Exception as exc:
        try:
            await update_job_status_fn(db, job, "failed", error_message=str(exc))
            await commit_fn()
        except Exception:
            pass
        raise

    response_defects = [
        build_detection_item(defect["class_code"], defect["confidence"], defect["bbox"])
        for defect in MOCK_DETECTIONS
    ]
    return DetectionOutcome(
        id=str(uuid.uuid4()),
        inspection_id=inspection_id,
        detection_job_id=str(job.id),
        defects=response_defects,
        confidence=average_confidence(
            [defect["confidence"] for defect in MOCK_DETECTIONS]
        ),
        detected_at=datetime.now(timezone.utc),
    )
