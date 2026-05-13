"""Segmentation export pipeline."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from vision.src.data.config import DEFAULT_LABEL_MAP_ROOT, DEFAULT_SEGMENTATION_EXPORT_ROOT
from vision.src.data.geometry import polygon_to_yolo, scale_polygon
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
class SegmentationExportResult:
    """Return value for the segmentation export pipeline."""

    manifest_path: Path
    report_csv_path: Path
    report_md_path: Path
    label_map_path: Path
    records: tuple[TaskExportRecord, ...]
    report: TaskExportReport


def _build_segmentation_line(
    annotation: dict,
    *,
    transform,
    model_class_id: int,
) -> str | None:
    segmentation = annotation.get("segmentation") or []
    if not segmentation:
        return None
    first_polygon = segmentation[0] if isinstance(segmentation[0], list) else segmentation
    if len(first_polygon) < 6:
        return None
    scaled_polygon = scale_polygon(first_polygon, transform)
    normalized = polygon_to_yolo(scaled_polygon, transform)
    if len(normalized) < 6:
        return None
    text = " ".join(f"{value:.6f}" for value in normalized)
    return f"{model_class_id} {text}"


def export_segmentation_dataset(
    rows: Iterable[NormalizedAnnotation],
    *,
    ontology_records: Iterable[OntologyRecord],
    resized_root: Path,
    labels_root: Path,
    output_root: Path | None = None,
    label_map_root: Path | None = None,
    model_name: str = "surface_seg",
) -> SegmentationExportResult:
    """Export a polygon-backed segmentation dataset."""

    output_root = output_root or DEFAULT_SEGMENTATION_EXPORT_ROOT
    label_map_root = label_map_root or DEFAULT_LABEL_MAP_ROOT
    rows = list(rows)
    grouped = group_rows_by_file_name(rows)
    label_map_records = build_task_label_map(
        ontology_records,
        model_name=model_name,
        task_type="segment",
        include_review=True,
    )
    label_map_index = build_task_label_map_index(label_map_records)
    label_map_path = save_task_label_map(
        label_map_records,
        label_map_root / f"{model_name}_segmentation_label_map.json",
    )

    records: list[TaskExportRecord] = []
    exported_labels = 0
    blocked_images = 0

    for file_name in sorted(grouped):
        group = grouped[file_name]
        primary = sorted(group, key=lambda row: (row.split, row.ontology_id, row.label_type))[0]
        if primary.task_type == "classify":
            records.append(
                TaskExportRecord(
                    task_type="segment",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    model_class_id=-1,
                    label_type=primary.label_type,
                    geometry_level=primary.geometry_level,
                    image_path="",
                    label_path="",
                    status="skip",
                    reason="classification_only_rows_are_not_exported_to_segmentation",
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
                    task_type="segment",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    model_class_id=-1,
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
                    task_type="segment",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    model_class_id=label_map.model_class_id,
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
                    task_type="segment",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    model_class_id=label_map.model_class_id,
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
            line = _build_segmentation_line(annotation, transform=transform, model_class_id=label_map.model_class_id)
            if line is not None:
                label_lines.append(line)

        if not label_lines:
            blocked_images += 1
            records.append(
                TaskExportRecord(
                    task_type="segment",
                    model_name=model_name,
                    file_name=file_name,
                    split=primary.split,
                    domain=primary.domain,
                    defect_name=primary.defect_name_norm,
                    part_name=primary.part_name_norm,
                    canonical_class_name=primary.canonical_class_name,
                    ontology_id=primary.ontology_id,
                    model_class_id=label_map.model_class_id,
                    label_type=primary.label_type,
                    geometry_level=primary.geometry_level,
                    image_path="",
                    label_path="",
                    status="blocked",
                    reason="no_polygon_backed_annotations",
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
                task_type="segment",
                model_name=model_name,
                file_name=file_name,
                split=primary.split,
                domain=primary.domain,
                defect_name=primary.defect_name_norm,
                part_name=primary.part_name_norm,
                canonical_class_name=primary.canonical_class_name,
                ontology_id=primary.ontology_id,
                model_class_id=label_map.model_class_id,
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
        task_type="segment",
        model_name=model_name,
        total_unique_images=len(grouped),
        exported_images=sum(1 for record in records if record.status == "exported"),
        skipped_images=sum(1 for record in records if record.status == "skip"),
        exported_labels=exported_labels,
        blocked_images=blocked_images,
        notes=(
            "segmentation export는 실제 polygon/mask가 있을 때만 쓴다.",
            "bbox-only row는 rectangular segmentation mask로 변환하지 않는다.",
            "classification-only sample은 segmentation export에 재사용하지 않는다.",
        ),
    )

    manifest_path = write_task_export_manifest(records, output_root / f"{model_name}_segmentation_manifest.json")
    report_csv_path, report_md_path = write_task_export_report(
        report,
        csv_path=output_root / f"{model_name}_segmentation_report.csv",
        md_path=output_root / f"{model_name}_segmentation_report.md",
    )
    return SegmentationExportResult(
        manifest_path=manifest_path,
        report_csv_path=report_csv_path,
        report_md_path=report_md_path,
        label_map_path=label_map_path,
        records=tuple(records),
        report=report,
    )
