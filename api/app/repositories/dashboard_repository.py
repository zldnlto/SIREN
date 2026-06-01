import uuid
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.defect_item import DefectItem
from app.models.detection_job import DetectionJob
from app.models.guidance import Guidance
from app.models.inspection import Inspection
from app.schemas.dashboard import (
    AnalyticsResponse,
    DashboardSummary,
    DefectTypeDistributionItem,
    DomainDistributionItem,
    GuidanceDetail,
    InspectionDetail,
    InspectionListItem,
    QualityStateDistributionItem,
)


async def get_summary(db: AsyncSession) -> DashboardSummary:
    total = (await db.scalar(select(func.count()).select_from(Inspection))) or 0

    defect_inspection_ids = (
        select(DefectItem.inspection_id)
        .where(DefectItem.quality_state == "defect")
        .distinct()
    )
    defect_count = (
        await db.scalar(
            select(func.count()).select_from(
                select(DefectItem.inspection_id)
                .where(DefectItem.quality_state == "defect")
                .distinct()
                .subquery()
            )
        )
    ) or 0

    normal_count = (
        await db.scalar(
            select(func.count()).select_from(
                select(DefectItem.inspection_id)
                .where(DefectItem.quality_state == "good")
                .where(DefectItem.inspection_id.not_in(defect_inspection_ids))
                .distinct()
                .subquery()
            )
        )
    ) or 0

    failed_count = (
        await db.scalar(
            select(func.count()).select_from(
                select(DetectionJob.inspection_id)
                .where(DetectionJob.status == "failed")
                .distinct()
                .subquery()
            )
        )
    ) or 0

    completed_job_ids = select(DetectionJob.id).where(
        DetectionJob.status == "completed"
    )
    avg_conf = await db.scalar(
        select(func.avg(DefectItem.confidence_score)).where(
            DefectItem.detection_job_id.in_(completed_job_ids)
        )
    )

    unknown_count = max(0, total - defect_count - normal_count - failed_count)

    return DashboardSummary(
        total_inspections=total,
        defect_count=defect_count,
        normal_count=normal_count,
        unknown_count=unknown_count,
        failed_count=failed_count,
        average_confidence=float(avg_conf) if avg_conf is not None else None,
    )


async def list_inspections(
    db: AsyncSession,
    *,
    status: str | None = None,
    quality_state: str | None = None,
    annotation_domain: str | None = None,
    from_date: datetime | None = None,
    to_date: datetime | None = None,
    page: int = 1,
    limit: int = 20,
) -> tuple[list[InspectionListItem], int]:
    query = (
        select(Inspection)
        .options(
            selectinload(Inspection.detection_jobs),
            selectinload(Inspection.defect_items),
        )
        .order_by(Inspection.created_at.desc())
    )

    if annotation_domain:
        query = query.where(Inspection.annotation_domain == annotation_domain)
    if from_date:
        query = query.where(Inspection.created_at >= from_date)
    if to_date:
        query = query.where(Inspection.created_at <= to_date)

    result = await db.execute(query)
    all_inspections = list(result.scalars().all())

    items: list[InspectionListItem] = []
    for insp in all_inspections:
        latest_job = (
            max(insp.detection_jobs, key=lambda j: j.created_at)
            if insp.detection_jobs
            else None
        )
        primary_defect = (
            max(insp.defect_items, key=lambda d: d.confidence_score)
            if insp.defect_items
            else None
        )

        job_status = latest_job.status if latest_job else None
        if status and job_status != status:
            continue

        item_quality_state = primary_defect.quality_state if primary_defect else None
        if quality_state and item_quality_state != quality_state:
            continue

        items.append(
            InspectionListItem(
                inspection_id=insp.id,
                inspector_id=insp.inspector_id,
                created_at=insp.created_at,
                completed_at=latest_job.completed_at if latest_job else None,
                status=job_status,
                quality_state=item_quality_state,
                annotation_domain=insp.annotation_domain,
                canonical_class_name=(
                    primary_defect.canonical_class_name if primary_defect else None
                ),
                ontology_id=primary_defect.ontology_id if primary_defect else None,
                confidence_score=(
                    primary_defect.confidence_score if primary_defect else None
                ),
            )
        )

    total = len(items)
    offset = (page - 1) * limit
    return items[offset : offset + limit], total


async def get_inspection_detail(
    db: AsyncSession,
    inspection_id: uuid.UUID,
) -> InspectionDetail | None:
    result = await db.execute(
        select(Inspection)
        .options(
            selectinload(Inspection.detection_jobs),
            selectinload(Inspection.defect_items),
        )
        .where(Inspection.id == inspection_id)
    )
    insp = result.scalar_one_or_none()
    if insp is None:
        return None

    latest_job = (
        max(insp.detection_jobs, key=lambda j: j.created_at)
        if insp.detection_jobs
        else None
    )
    primary_defect = (
        max(insp.defect_items, key=lambda d: d.confidence_score)
        if insp.defect_items
        else None
    )

    image_url: str | None = None
    overlay_image_url: str | None = None
    if insp.image_key:
        from app.core.s3 import generate_presigned_get_url

        try:
            image_url = await generate_presigned_get_url(insp.image_key)
        except Exception:
            image_url = None

    if primary_defect and primary_defect.gradcam_key:
        from app.core.s3 import generate_presigned_get_url

        try:
            overlay_image_url = await generate_presigned_get_url(
                primary_defect.gradcam_key
            )
        except Exception:
            overlay_image_url = None

    guidance: GuidanceDetail | None = None
    if primary_defect:
        g_result = await db.execute(
            select(Guidance).where(Guidance.ontology_id == primary_defect.ontology_id)
        )
        g = g_result.scalar_one_or_none()
        if g:
            guidance = GuidanceDetail(
                cause=g.cause,
                action=g.action_steps if isinstance(g.action_steps, list) else [],
                reinspection=g.reinspection_criteria,
                caution=g.disclaimer,
            )

    return InspectionDetail(
        inspection_id=insp.id,
        inspector_id=insp.inspector_id,
        image_url=image_url,
        overlay_image_url=overlay_image_url,
        status=latest_job.status if latest_job else None,
        quality_state=primary_defect.quality_state if primary_defect else None,
        annotation_domain=insp.annotation_domain,
        canonical_class_name=(
            primary_defect.canonical_class_name if primary_defect else None
        ),
        ontology_id=primary_defect.ontology_id if primary_defect else None,
        confidence_score=primary_defect.confidence_score if primary_defect else None,
        guidance=guidance,
        created_at=insp.created_at,
        completed_at=latest_job.completed_at if latest_job else None,
        error_message=latest_job.error_message if latest_job else None,
    )


async def get_analytics(db: AsyncSession) -> AnalyticsResponse:
    domain_rows = await db.execute(
        select(Inspection.annotation_domain, func.count().label("cnt"))
        .group_by(Inspection.annotation_domain)
        .order_by(func.count().desc())
    )
    domain_distribution = [
        DomainDistributionItem(annotation_domain=row.annotation_domain, count=row.cnt)
        for row in domain_rows
    ]

    defect_rows = await db.execute(
        select(
            DefectItem.ontology_id,
            DefectItem.canonical_class_name,
            func.count().label("cnt"),
        )
        .group_by(DefectItem.ontology_id, DefectItem.canonical_class_name)
        .order_by(func.count().desc())
        .limit(20)
    )
    defect_type_distribution = [
        DefectTypeDistributionItem(
            ontology_id=row.ontology_id,
            canonical_class_name=row.canonical_class_name,
            count=row.cnt,
        )
        for row in defect_rows
    ]

    defect_inspection_ids = (
        select(DefectItem.inspection_id)
        .where(DefectItem.quality_state == "defect")
        .distinct()
    )
    defect_count = (
        await db.scalar(
            select(func.count()).select_from(
                select(DefectItem.inspection_id)
                .where(DefectItem.quality_state == "defect")
                .distinct()
                .subquery()
            )
        )
    ) or 0
    normal_count = (
        await db.scalar(
            select(func.count()).select_from(
                select(DefectItem.inspection_id)
                .where(DefectItem.quality_state == "good")
                .where(DefectItem.inspection_id.not_in(defect_inspection_ids))
                .distinct()
                .subquery()
            )
        )
    ) or 0
    total = (await db.scalar(select(func.count()).select_from(Inspection))) or 0
    unknown_count = max(0, total - defect_count - normal_count)

    quality_state_distribution = [
        QualityStateDistributionItem(label="defect", count=defect_count),
        QualityStateDistributionItem(label="normal", count=normal_count),
        QualityStateDistributionItem(label="unknown", count=unknown_count),
    ]

    return AnalyticsResponse(
        domain_distribution=domain_distribution,
        defect_type_distribution=defect_type_distribution,
        quality_state_distribution=quality_state_distribution,
    )
