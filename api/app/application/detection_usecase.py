from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.errors import InvalidInputError, NotFoundError
from app.domain.detection import (
    DetectionItemCore,
    average_confidence,
    build_detection_item,
    build_persisted_defect,
)
from app.ports.repositories import (
    CreateManyDefectsFn,
    GetInspectionByIdFn,
    UpdateInspectionStatusFn,
)


MOCK_DETECTIONS = [
    {"class_code": 0, "confidence": 0.92, "bbox": [10.0, 20.0, 100.0, 80.0]},
    {"class_code": 1, "confidence": 0.78, "bbox": [50.0, 60.0, 200.0, 150.0]},
]


@dataclass(frozen=True)
class DetectionOutcome:
    id: str
    inspection_id: str
    defects: list[DetectionItemCore]
    confidence: float
    detected_at: datetime


async def run_detection(
    db: AsyncSession,
    inspection_id: str,
    *,
    get_by_id_fn: GetInspectionByIdFn,
    create_many_fn: CreateManyDefectsFn,
    update_status_fn: UpdateInspectionStatusFn,
    commit_fn,
) -> DetectionOutcome:
    try:
        uid = uuid.UUID(inspection_id)
    except ValueError as exc:
        raise InvalidInputError from exc

    inspection = await get_by_id_fn(db, uid)
    if inspection is None:
        raise NotFoundError

    domain_code = 25  # mock — annotation_domain 기반 실 모델 연동 시 교체
    _ = inspection.annotation_domain  # 컬럼 참조 확인용

    db_items = [
        build_persisted_defect(
            uid,
            domain_code,
            defect["class_code"],
            defect["confidence"],
            defect["bbox"],
        )
        for defect in MOCK_DETECTIONS
    ]
    await create_many_fn(db, db_items)
    await update_status_fn(db, inspection, "completed")
    await commit_fn()

    now = datetime.now(timezone.utc)
    response_defects = [
        build_detection_item(defect["class_code"], defect["confidence"], defect["bbox"])
        for defect in MOCK_DETECTIONS
    ]
    return DetectionOutcome(
        id=str(uuid.uuid4()),
        inspection_id=inspection_id,
        defects=response_defects,
        confidence=average_confidence(
            [defect["confidence"] for defect in MOCK_DETECTIONS]
        ),
        detected_at=now,
    )
