from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

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
from app.ports.storage import RunInferenceFn

MODEL_VERSION = "siren-seg-v1"
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
    run_inference_fn: RunInferenceFn,
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
        raw_detections: list[Any] = await run_inference_fn(inspection.image_key)

        # Automatically infer annotation_domain based on YOLO detection classes
        detected_domains = []
        for d in raw_detections:
            item = build_detection_item(
                d["class_code"],
                d["confidence"],
                d["bbox"],
                class_name=d.get("class_name"),
            )
            if item.annotation_domain:
                detected_domains.append(item.annotation_domain)

        if detected_domains:
            # Choose the most frequent domain from detected items
            inferred_domain = max(set(detected_domains), key=detected_domains.count)
        else:
            inferred_domain = "surface_treatment"

        # Update the inspection's domain with the inferred domain
        inspection.annotation_domain = inferred_domain

        domain_code = 25  # surface_treatment

        db_items = [
            build_persisted_defect(
                uid,
                job.id,
                domain_code,
                d["class_code"],
                d["confidence"],
                d["bbox"],
                class_name=d.get("class_name"),
            )
            for d in raw_detections
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
        build_detection_item(
            d["class_code"],
            d["confidence"],
            d["bbox"],
            class_name=d.get("class_name"),
        )
        for d in raw_detections
    ]
    return DetectionOutcome(
        id=str(uuid.uuid4()),
        inspection_id=inspection_id,
        detection_job_id=str(job.id),
        defects=response_defects,
        confidence=average_confidence([d["confidence"] for d in raw_detections]),
        detected_at=datetime.now(timezone.utc),
    )
