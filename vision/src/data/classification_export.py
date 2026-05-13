"""Classification-only export pipeline."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from vision.src.data.config import DEFAULT_CLASSIFICATION_EXPORT_ROOT, DEFAULT_LABEL_MAP_ROOT
from vision.src.data.label_maps import build_task_label_map, save_task_label_map
from vision.src.data.normalization import NormalizedAnnotation
from vision.src.data.ontology import OntologyRecord
from vision.src.data.task_export_base import (
    TaskExportRecord,
    TaskExportReport,
    build_task_label_map_index,
    copy_resized_image,
    group_rows_by_file_name,
    resolve_image_source,
    resolve_task_output_dirs,
    write_task_export_manifest,
    write_task_export_report,
)


@dataclass(frozen=True)
class ClassificationExportResult:
    """Return value for the classification export pipeline."""

    manifest_path: Path
    report_csv_path: Path
    report_md_path: Path
    label_map_path: Path
    records: tuple[TaskExportRecord, ...]
    report: TaskExportReport


def export_classification_dataset(
    rows: Iterable[NormalizedAnnotation],
    *,
    ontology_records: Iterable[OntologyRecord],
    resized_root: Path,
    labels_root: Path,
    output_root: Path | None = None,
    label_map_root: Path | None = None,
    model_name: str = "surface_cls",
) -> ClassificationExportResult:
    """Export an image-level classification dataset."""

    output_root = output_root or DEFAULT_CLASSIFICATION_EXPORT_ROOT
    label_map_root = label_map_root or DEFAULT_LABEL_MAP_ROOT
    rows = list(rows)
    grouped = group_rows_by_file_name(rows)
    label_map_records = build_task_label_map(
        ontology_records,
        model_name=model_name,
        task_type="classify",
        include_review=True,
    )
    label_map_index = build_task_label_map_index(label_map_records)
    label_map_path = save_task_label_map(
        label_map_records,
        label_map_root / f"{model_name}_classification_label_map.json",
    )

    records: list[TaskExportRecord] = []
    exported_labels = 0
    blocked_images = 0

    for file_name in sorted(grouped):
        group = grouped[file_name]
        primary = sorted(group, key=lambda row: (row.split, row.ontology_id, row.label_type))[0]
        if primary.task_type != "classify":
            records.append(
                TaskExportRecord(
                    task_type="classify",
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
                    reason="classification_only_export_requires_image_level_rows",
                    original_width=primary.width,
                    original_height=primary.height,
                    target_width=640,
                    target_height=640,
                    resize_method="copy",
                    annotation_count=len(group),
                )
            )
            continue

        label_map = label_map_index.get(primary.ontology_id)
        if label_map is None:
            blocked_images += 1
            records.append(
                TaskExportRecord(
                    task_type="classify",
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
                    resize_method="copy",
                    annotation_count=len(group),
                )
            )
            continue

        source_image = resolve_image_source(resized_root, file_name)
        if source_image is None:
            blocked_images += 1
            records.append(
                TaskExportRecord(
                    task_type="classify",
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
                    resize_method="copy",
                    annotation_count=len(group),
                )
            )
            continue

        image_dir, label_dir = resolve_task_output_dirs(output_root, primary.canonical_class_name, primary.split)
        image_path = image_dir / file_name
        label_path = label_dir / f"{Path(file_name).stem}.txt"
        copy_resized_image(source_image, image_path)
        label_path.write_text(f"{label_map.model_class_id}\n", encoding="utf-8")
        exported_labels += 1
        records.append(
            TaskExportRecord(
                task_type="classify",
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
                original_width=primary.width,
                original_height=primary.height,
                target_width=640,
                target_height=640,
                resize_method="copy",
                annotation_count=len(group),
            )
        )

    report = TaskExportReport(
        task_type="classify",
        model_name=model_name,
        total_unique_images=len(grouped),
        exported_images=sum(1 for record in records if record.status == "exported"),
        skipped_images=sum(1 for record in records if record.status == "skip"),
        exported_labels=exported_labels,
        blocked_images=blocked_images,
        notes=(
            "classification export는 image-level label만 기록한다.",
            "category_id는 export model class로 사용하지 않는다.",
            "classification-only sample은 detection/segmentation export에 재사용하지 않는다.",
        ),
    )

    manifest_path = write_task_export_manifest(records, output_root / f"{model_name}_classification_manifest.json")
    report_csv_path, report_md_path = write_task_export_report(
        report,
        csv_path=output_root / f"{model_name}_classification_report.csv",
        md_path=output_root / f"{model_name}_classification_report.md",
    )
    return ClassificationExportResult(
        manifest_path=manifest_path,
        report_csv_path=report_csv_path,
        report_md_path=report_md_path,
        label_map_path=label_map_path,
        records=tuple(records),
        report=report,
    )
