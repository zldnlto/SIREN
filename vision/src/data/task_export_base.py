"""Shared export helpers for task-specific datasets."""

from __future__ import annotations

import json
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from shutil import copy2
from typing import Any, Mapping

from vision.src.data.config import (
    DEFAULT_TARGET_IMAGE_HEIGHT,
    DEFAULT_TARGET_IMAGE_WIDTH,
)
from vision.src.data.geometry import (
    LetterboxTransform,
    build_letterbox_transform,
)
from vision.src.data.labels import find_label_json_file
from vision.src.data.label_maps import TaskLabelMapRecord
from vision.src.data.normalization import NormalizedAnnotation
from vision.src.data.reports import write_csv_rows, write_markdown


@dataclass(frozen=True)
class TaskExportRecord:
    """One task-specific export decision."""

    task_type: str
    model_name: str
    file_name: str
    split: str
    domain: str
    defect_name: str
    part_name: str
    canonical_class_name: str
    ontology_id: str
    model_class_id: int
    label_type: str
    geometry_level: str
    image_path: str
    label_path: str
    status: str
    reason: str
    original_width: int
    original_height: int
    target_width: int
    target_height: int
    resize_method: str
    annotation_count: int


@dataclass(frozen=True)
class TaskExportReport:
    """Summary of one task export run."""

    task_type: str
    model_name: str
    total_unique_images: int
    exported_images: int
    skipped_images: int
    exported_labels: int
    blocked_images: int
    notes: tuple[str, ...]


def group_rows_by_file_name(rows: list[NormalizedAnnotation]) -> dict[str, list[NormalizedAnnotation]]:
    """Group normalized rows by image file name."""

    grouped: dict[str, list[NormalizedAnnotation]] = defaultdict(list)
    for row in rows:
        grouped[row.file_name].append(row)
    return grouped


def build_task_label_map_index(records: list[TaskLabelMapRecord]) -> dict[str, TaskLabelMapRecord]:
    """Index a task label map by ontology id."""

    return {record.ontology_id: record for record in records}


def resolve_image_source(resized_root: Path, file_name: str) -> Path | None:
    """Resolve an image path from the synced resized-root convention."""

    direct = resized_root / file_name
    if direct.exists():
        return direct
    matches = list(resized_root.rglob(file_name))
    return matches[0] if matches else None


def load_label_json(labels_root: Path, zip_source: str, file_name: str) -> dict[str, Any] | None:
    """Load the COCO JSON payload for one image."""

    return find_label_json_file(file_name, zip_source, labels_root)


def resolve_letterbox_transform(
    row: Mapping[str, Any] | NormalizedAnnotation,
    json_data: Mapping[str, Any] | None = None,
    *,
    target_width: int = DEFAULT_TARGET_IMAGE_WIDTH,
    target_height: int = DEFAULT_TARGET_IMAGE_HEIGHT,
) -> tuple[LetterboxTransform, int, int]:
    """Resolve and cross-check original dimensions before scaling."""

    row_width = int(getattr(row, "width", row.get("width", 0)) or 0) if isinstance(row, Mapping) else int(row.width or 0)
    row_height = int(getattr(row, "height", row.get("height", 0)) or 0) if isinstance(row, Mapping) else int(row.height or 0)
    json_width = 0
    json_height = 0
    if json_data:
        images = json_data.get("images", [])
        if images:
            first = images[0]
            json_width = int(first.get("width", 0) or 0)
            json_height = int(first.get("height", 0) or 0)
    width = row_width or json_width
    height = row_height or json_height
    if width <= 0 or height <= 0:
        raise ValueError("원본 width/height를 확인할 수 없어 geometry export를 중단합니다.")
    if row_width and json_width and row_width != json_width:
        raise ValueError(f"width 불일치: dataset_index={row_width}, coco_json={json_width}")
    if row_height and json_height and row_height != json_height:
        raise ValueError(f"height 불일치: dataset_index={row_height}, coco_json={json_height}")
    return build_letterbox_transform(width, height, target_width=target_width, target_height=target_height), width, height


def resolve_task_output_dirs(
    output_root: Path,
    canonical_class_name: str,
    split: str,
) -> tuple[Path, Path]:
    """Return the task-specific image and label directories."""

    image_dir = output_root / canonical_class_name / "images" / split
    label_dir = output_root / canonical_class_name / "labels" / split
    image_dir.mkdir(parents=True, exist_ok=True)
    label_dir.mkdir(parents=True, exist_ok=True)
    return image_dir, label_dir


def write_task_export_manifest(records: list[TaskExportRecord], path: Path) -> Path:
    """Write a deterministic export manifest."""

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps([asdict(record) for record in records], ensure_ascii=False, indent=2), encoding="utf-8")
    return path


def write_task_export_report(report: TaskExportReport, *, csv_path: Path, md_path: Path) -> tuple[Path, Path]:
    """Write a task export summary as CSV and Markdown."""

    write_csv_rows(
        csv_path,
        [
            {"metric": "total_unique_images", "value": report.total_unique_images},
            {"metric": "exported_images", "value": report.exported_images},
            {"metric": "skipped_images", "value": report.skipped_images},
            {"metric": "exported_labels", "value": report.exported_labels},
            {"metric": "blocked_images", "value": report.blocked_images},
        ],
        fieldnames=("metric", "value"),
    )
    lines = [
        f"# {report.task_type.title()} Export Report",
        "",
        "## Summary",
        "",
        f"- model: {report.model_name}",
        f"- total unique images: {report.total_unique_images}",
        f"- exported images: {report.exported_images}",
        f"- skipped images: {report.skipped_images}",
        f"- exported labels: {report.exported_labels}",
        f"- blocked images: {report.blocked_images}",
        "",
        "## Notes",
        "",
    ]
    lines.extend(f"- {note}" for note in report.notes)
    write_markdown(md_path, lines)
    return csv_path, md_path


def copy_resized_image(source_path: Path, destination_path: Path) -> Path:
    """Copy a resized image into a task export tree."""

    destination_path.parent.mkdir(parents=True, exist_ok=True)
    copy2(source_path, destination_path)
    return destination_path
