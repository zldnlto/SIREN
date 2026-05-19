from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.detection_usecase import run_detection as run_detection_usecase
from app.application.errors import InvalidInputError, NotFoundError
from app.repositories import defect_repository, inspection_repository
from app.schemas.detection import DefectItem, DetectionResult


async def run_detection(db: AsyncSession, inspection_id: str) -> DetectionResult:
    try:
        outcome = await run_detection_usecase(
            db,
            inspection_id,
            get_by_id_fn=inspection_repository.get_by_id,
            create_many_fn=defect_repository.create_many,
            update_status_fn=inspection_repository.update_status,
            commit_fn=db.commit,
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

    return DetectionResult(
        id=outcome.id,
        inspection_id=outcome.inspection_id,
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
