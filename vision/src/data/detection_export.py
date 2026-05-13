"""Detection export pipeline."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from vision.src.data.config import DEFAULT_DETECTION_EXPORT_ROOT, DEFAULT_LABEL_MAP_ROOT
from vision.src.data.geometry import bbox_xywh_to_yolo, polygon_to_bbox_xywh, scale_bbox_xywh
from vision.src.data.label_maps import build_task_label_map, save_task_label_map
from vision.src.data.normalization import NormalizedAnnotation
from vision.src.data.ontology import OntologyRecord
from vision.src.data.task_export_base import (
    TaskExportRecord,
    TaskExportReport,
    build_task_label_map_index,
    copy_resized_image,
    group_rows_by_file_name,
    load_label_json,
    resolve_image_source,
    resolve_letterbox_transform,
    resolve_task_output_dirs,
    write_task_export_manifest,
    write_task_export_report,
)


@dataclass(frozen=True)
class DetectionExportResult:
    """Return value for the detection export pipeline."""

    manifest_path: Path
    report_csv_path: Path
    report_md_path: Path
    label_map_path: Path
    records: tuple[TaskExportRecord, ...]
    report: TaskExportReport


def _build_detection_line(
    annotation: dict,
    *,
    transform,
    model_class_id: int,
) -> str | None:
    bbox = annotation.get("bbox") or []
    segmentation = annotation.get("segmentation") or []
    if bbox:
        scaled_bbox = scale_bbox_xywh(bbox, transform)
    elif segmentation:
        first_polygon = segmentation[0] if isinstance(segmentation[0], list) else segmentation
        bbox_xywh = polygon_to_bbox_xywh(first_polygon)
        scaled_bbox = scale_bbox_xywh(bbox_xywh, transform)
    else:
        return None
    x_center, y_center, width, height = bbox_xywh_to_yolo(scaled_bbox, transform)
    return f"{model_class_id} {x_center:.6f} {y_center:.6f} {width:.6f} {height:.6f}"


def export_detection_dataset(
    rows: Iterable[NormalizedAnnotation],
    *,
    ontology_records: Iterable[OntologyRecord],
    resized_root: Path,
    labels_root: Path,
    output_root: Path | None = None,
    label_map_root: Path | None = None,
    model_name: str = "surface_det",
) -> DetectionExportResult:
    """Export a bbox-only detection dataset."""

    output_root = output_root or DEFAULT_DETECTION_EXPORT_ROOT
    label_map_root = label_map_root or DEFAULT_LABEL_MAP_ROOT
    rows = list(rows)
    grouped = group_rows_by_file_name(rows)
    label_map_records = build_task_label_map(
        ontology_records,
        model_name=model_name,
        task_type="detect",
        include_review=True,
    )
    label_map_index = build_task_label_map_index(label_map_records)
    label_map_path = save_task_label_map(
        label_map_records,
        label_map_root / f"{model_name}_detection_label_map.json",
    )

    records: list[TaskExportRecord] = []
    exported_labels = 0
    blocked_images = 0

    for file_name in sorted(grouped):
        group = grouped[file_name]
        primary = sorted(group, key=lambda row: (row.split, row.ontology_id, row.label_type))[0]
        if any(row.taxonomy_status != "normal" for row in group):
            blocked_images += 1
            records.append(
                TaskExportRecord(
                    task_type="detect",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    task_specific_model_class_id=-1,
                    label_type=primary.label_type,
                    geometry_level=primary.geometry_level,
                    image_path="",
                    label_path="",
                    status="blocked",
                    reason="taxonomy_review_excluded_by_default",
                    original_width=primary.width,
                    original_height=primary.height,
                    target_width=640,
                    target_height=640,
                    resize_method="letterbox",
                    annotation_count=len(group),
                )
            )
            continue
        if primary.task_type == "classify":
            records.append(
                TaskExportRecord(
                    task_type="detect",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    task_specific_model_class_id=-1,
                    label_type=primary.label_type,
                    geometry_level=primary.geometry_level,
                    image_path="",
                    label_path="",
                    status="skip",
                    reason="classification_only_rows_are_not_exported_to_detection",
                    original_width=primary.width,
                    original_height=primary.height,
                    target_width=640,
                    target_height=640,
                    resize_method="letterbox",
                    annotation_count=len(group),
                )
            )
            continue

        label_map = label_map_index.get(primary.ontology_id)
        if label_map is None:
            blocked_images += 1
            records.append(
                TaskExportRecord(
                    task_type="detect",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    task_specific_model_class_id=-1,
                    label_type=primary.label_type,
                    geometry_level=primary.geometry_level,
                    image_path="",
                    label_path="",
                    status="blocked",
                    reason="label_map_missing",
                    original_width=primary.width,
                    original_height=primary.height,
                    target_width=640,
                    target_height=640,
                    resize_method="letterbox",
                    annotation_count=len(group),
                )
            )
            continue

        source_image = resolve_image_source(resized_root, file_name)
        if source_image is None:
            blocked_images += 1
            records.append(
                TaskExportRecord(
                    task_type="detect",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    task_specific_model_class_id=label_map.task_specific_model_class_id,
                    label_type=primary.label_type,
                    geometry_level=primary.geometry_level,
                    image_path="",
                    label_path="",
                    status="blocked",
                    reason="resized_image_missing",
                    original_width=primary.width,
                    original_height=primary.height,
                    target_width=640,
                    target_height=640,
                    resize_method="letterbox",
                    annotation_count=len(group),
                )
            )
            continue

        json_data = load_label_json(labels_root, primary.zip_source, file_name)
        if json_data is None:
            blocked_images += 1
            records.append(
                TaskExportRecord(
                    task_type="detect",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    task_specific_model_class_id=label_map.task_specific_model_class_id,
                    label_type=primary.label_type,
                    geometry_level=primary.geometry_level,
                    image_path="",
                    label_path="",
                    status="blocked",
                    reason="label_json_missing",
                    original_width=primary.width,
                    original_height=primary.height,
                    target_width=640,
                    target_height=640,
                    resize_method="letterbox",
                    annotation_count=len(group),
                )
            )
            continue

        transform, original_width, original_height = resolve_letterbox_transform(
            primary,
            json_data,
            target_width=640,
            target_height=640,
        )
        annotations = json_data.get("annotations", [])
        label_lines = []
        for annotation in annotations:
            line = _build_detection_line(annotation, transform=transform, model_class_id=label_map.task_specific_model_class_id)
            if line is not None:
                label_lines.append(line)

        if not label_lines:
            blocked_images += 1
            records.append(
                TaskExportRecord(
                    task_type="detect",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    task_specific_model_class_id=label_map.task_specific_model_class_id,
                    label_type=primary.label_type,
                    geometry_level=primary.geometry_level,
                    image_path="",
                    label_path="",
                    status="blocked",
                    reason="no_bbox_backed_annotations",
                    original_width=original_width,
                    original_height=original_height,
                    target_width=640,
                    target_height=640,
                    resize_method="letterbox",
                    annotation_count=len(annotations),
                )
            )
            continue

        image_dir, label_dir = resolve_task_output_dirs(output_root, primary.canonical_class_name, primary.split)
        image_path = image_dir / file_name
        label_path = label_dir / f"{Path(file_name).stem}.txt"
        copy_resized_image(source_image, image_path)
        label_path.write_text("\n".join(label_lines) + "\n", encoding="utf-8")
        exported_labels += len(label_lines)
        records.append(
            TaskExportRecord(
                task_type="detect",
                model_name=model_name,
                file_name=file_name,
                split=primary.split,
                domain=primary.domain,
                defect_name=primary.defect_name_norm,
                part_name=primary.part_name_norm,
                canonical_class_name=primary.canonical_class_name,
                ontology_id=primary.ontology_id,
                task_specific_model_class_id=label_map.task_specific_model_class_id,
                label_type=primary.label_type,
                geometry_level=primary.geometry_level,
                image_path=str(image_path),
                label_path=str(label_path),
                status="exported",
                reason="",
                original_width=original_width,
                original_height=original_height,
                target_width=640,
                target_height=640,
                resize_method="letterbox",
                annotation_count=len(annotations),
            )
        )

    report = TaskExportReport(
        task_type="detect",
        model_name=model_name,
        total_unique_images=len(grouped),
        exported_images=sum(1 for record in records if record.status == "exported"),
        skipped_images=sum(1 for record in records if record.status == "skip"),
        exported_labels=exported_labels,
        blocked_images=blocked_images,
        notes=(
            "detection export는 bbox-backed annotation만 쓴다.",
            "classification-only sample은 empty detection label로 내보내지 않는다.",
            "taxonomy review candidates are excluded from standard export.",
            "category_id는 model class가 아니라 ontology restoration metadata다.",
        ),
    )

    manifest_path = write_task_export_manifest(records, output_root / f"{model_name}_detection_manifest.json")
    report_csv_path, report_md_path = write_task_export_report(
        report,
        csv_path=output_root / f"{model_name}_detection_report.csv",
        md_path=output_root / f"{model_name}_detection_report.md",
    )
    return DetectionExportResult(
        manifest_path=manifest_path,
        report_csv_path=report_csv_path,
        report_md_path=report_md_path,
        label_map_path=label_map_path,
        records=tuple(records),
        report=report,
    )
