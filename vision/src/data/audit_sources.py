"""Repository and data-source discovery helpers for Phase 1.

These helpers stay metadata-only: they inspect analysis files, config files,
and path availability without trying to guess missing geometry or inventing
new labels.
"""

from __future__ import annotations

import csv
from collections import Counter
from dataclasses import dataclass
from pathlib import Path

from vision.src.data.config import (
    DataConfig,
    build_default_data_config,
)
from vision.src.data.reports import write_markdown


@dataclass(frozen=True)
class DiscoveredPath:
    """One path discovered during repository inspection."""

    name: str
    path: Path
    exists: bool
    note: str = ""


@dataclass(frozen=True)
class DatasetValidationReport:
    """Summarized Phase 1 audit output."""

    config: DataConfig
    discovered_paths: tuple[DiscoveredPath, ...]
    row_count: int
    unique_image_count: int
    split_counts: dict[str, int]
    label_type_counts: dict[str, int]
    combo_count: int
    resized_image_count: int | None
    missing_sources: tuple[str, ...]
    notes: tuple[str, ...]

    @property
    def resized_root_available(self) -> bool:
        return self.config.resized_root.exists()


def _read_csv_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def load_dataset_index_rows(path: Path | None = None) -> list[dict[str, str]]:
    """Load the dataset index as flat dictionaries."""

    config = build_default_data_config()
    return _read_csv_rows(path or config.dataset_index_path)


def load_combo_count_rows(path: Path | None = None) -> list[dict[str, str]]:
    """Load the defect-part combination summary table."""

    config = build_default_data_config()
    return _read_csv_rows(path or config.combo_counts_path)


def _count_existing_images(root: Path) -> int | None:
    if not root.exists():
        return None
    patterns = ("*.jpg", "*.jpeg", "*.png", "*.JPG", "*.JPEG", "*.PNG")
    total = 0
    for pattern in patterns:
        total += sum(1 for _ in root.rglob(pattern))
    return total


def discover_repository_sources(
    config: DataConfig | None = None,
    *,
    repo_root: Path | None = None,
) -> DatasetValidationReport:
    """Inspect the repository's data-oriented paths and build a validation report."""

    config = config or build_default_data_config()
    rows = load_dataset_index_rows(config.dataset_index_path)
    combo_rows = load_combo_count_rows(config.combo_counts_path)
    unique_images = {row.get("file_name", "") for row in rows if row.get("file_name")}
    split_counts = Counter(row.get("split", "") for row in rows if row.get("split"))
    label_type_counts = Counter(row.get("label_type", "") for row in rows if row.get("label_type"))
    discovered_paths = tuple(
        DiscoveredPath(
            name=name,
            path=path,
            exists=path.exists(),
        )
        for name, path in (
            ("dataset_index", config.dataset_index_path),
            ("combo_counts", config.combo_counts_path),
            ("label_report", config.label_report_path),
            ("ontology_audit", config.ontology_audit_path),
            ("ontology_audit_md", config.ontology_audit_md_path),
            ("quality_state_audit", config.quality_state_audit_path),
            ("ontology_validation_report", config.ontology_validation_report_path),
            ("annotation_root", config.annotation_root),
            ("raw_root", config.raw_root),
            ("resized_root", config.resized_root),
        )
    )

    missing_sources: list[str] = []
    for item in discovered_paths:
        if not item.exists:
            missing_sources.append(f"{item.name}: {item.path}")

    resized_image_count = _count_existing_images(config.resized_root)
    notes = [
        "bbox는 COCO JSON의 annotations[].bbox에 저장된다는 전제는 ontology_validation_report.md로 확인한다.",
        "segmentation polygon은 COCO JSON의 annotations[].segmentation에 저장된다는 전제는 ontology_validation_report.md로 확인한다.",
        "원본 width/height는 COCO JSON의 images[].width / images[].height에 저장된다는 전제는 ontology_validation_report.md로 확인한다.",
        "resize 메서드는 640x640 letterbox로 문서화되어 있다.",
    ]
    if resized_image_count is None:
        missing_sources.append(f"resized_root_missing: {config.resized_root}")
    elif resized_image_count == 0:
        notes.append("local resized root는 존재하지만 실제 이미지 파일은 발견되지 않았다.")

    return DatasetValidationReport(
        config=config,
        discovered_paths=discovered_paths,
        row_count=len(rows),
        unique_image_count=len(unique_images),
        split_counts=dict(split_counts),
        label_type_counts=dict(label_type_counts),
        combo_count=len(combo_rows),
        resized_image_count=resized_image_count,
        missing_sources=tuple(missing_sources),
        notes=tuple(notes),
    )


def write_dataset_validation_report(
    report: DatasetValidationReport,
    path: Path | None = None,
) -> Path:
    """Write a markdown summary of the discovered source layout."""

    path = path or report.config.ontology_validation_report_path.with_name(
        "dataset_validation_report.md"
    )
    lines = [
        "# Dataset Validation Report",
        "",
        "## 확인된 경로",
        "",
    ]
    for item in report.discovered_paths:
        lines.append(f"- `{item.name}`: `{item.path}` ({'exists' if item.exists else 'missing'})")
    lines.extend(
        [
            "",
            "## 요약",
            "",
            f"- row 수: {report.row_count}",
            f"- unique image 수: {report.unique_image_count}",
            f"- combo 수: {report.combo_count}",
            f"- split 분포: {report.split_counts}",
            f"- label_type 분포: {report.label_type_counts}",
            f"- resized image file 수: {report.resized_image_count}",
            "",
            "## 비고",
            "",
        ]
    )
    lines.extend(f"- {note}" for note in report.notes)
    if report.missing_sources:
        lines.extend(["", "## 누락 / blocker", ""])
        lines.extend(f"- {item}" for item in report.missing_sources)
    return write_markdown(path, lines)
