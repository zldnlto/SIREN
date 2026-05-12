import uuid
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories import defect_repository, inspection_repository
from app.schemas.detection import (
    CLS_ONLY_CODES,
    DEFECT_CLASSES,
    DefectItem,
    DetectionResult,
    confidence_to_severity,
)


async def run_detection(db: AsyncSession, inspection_id: str) -> DetectionResult:
    try:
        uid = uuid.UUID(inspection_id)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="inspection_id가 유효한 UUID 형식이 아닙니다.",
        )

    inspection = await inspection_repository.get_by_id(db, uid)
    if inspection is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Inspection not found"
        )

    mock_defects = [
        {"class_code": 0, "confidence": 0.92, "bbox": [10.0, 20.0, 100.0, 80.0]},
        {"class_code": 1, "confidence": 0.78, "bbox": [50.0, 60.0, 200.0, 150.0]},
    ]

    db_items = []
    for d in mock_defects:
        class_code = d["class_code"]
        bbox_raw = d["bbox"]
        bbox = (
            None
            if class_code in CLS_ONLY_CODES
            else {
                "x_min": bbox_raw[0],
                "y_min": bbox_raw[1],
                "x_max": bbox_raw[2],
                "y_max": bbox_raw[3],
            }
        )
        db_items.append(
            {
                "inspection_id": uid,
                "domain_code": 0,
                "class_code": class_code,
                "confidence": d["confidence"],
                "bbox": bbox,
                "severity": confidence_to_severity(d["confidence"]),
            }
        )

    # defect 저장 + status 업데이트를 단일 트랜잭션으로 처리
    await defect_repository.create_many(db, db_items)
    await inspection_repository.update_status(db, inspection, "completed")
    await db.commit()

    now = datetime.now(timezone.utc)
    response_defects = [
        DefectItem(
            class_name=DEFECT_CLASSES[d["class_code"]],
            confidence=d["confidence"],
            bbox=d["bbox"] if d["class_code"] not in CLS_ONLY_CODES else None,
        )
        for d in mock_defects
    ]
    overall_confidence = sum(d["confidence"] for d in mock_defects) / len(mock_defects)

    return DetectionResult(
        id=str(uuid.uuid4()),
        inspection_id=inspection_id,
        defects=response_defects,
        confidence=overall_confidence,
        detected_at=now,
    )
