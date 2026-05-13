"""Image-level split management and deterministic sampling helpers."""

from __future__ import annotations

import json
from collections import defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping

import yaml

from vision.src.data.config import (
    DEFAULT_SAMPLING_AUDIT_MD_PATH,
    DEFAULT_SAMPLING_AUDIT_PATH,
    DEFAULT_SPLIT_AUDIT_MD_PATH,
    DEFAULT_SPLIT_AUDIT_PATH,
    DEFAULT_SPLIT_MANIFEST_PATH,
    DataConfig,
)
from vision.src.data.normalization import NormalizedAnnotation
from vision.src.data.ontology import OntologyRecord
from vision.src.data.reports import write_csv_rows, write_markdown


@dataclass(frozen=True)
class SamplingConfig:
    """Sampling thresholds and caps loaded from YAML."""

    regular_min_unique_images: int = 1000
    tail_min_unique_images: int = 100
    regular_train_cap: int = 5000
    tail_train_cap: int = 1000
    review_train_cap: int = 0
    validation_policy: str = "natural"
    area_aware_weights: dict[str, float] | None = None

    def train_cap_for_bucket(self, bucket: str) -> int:
        if bucket == "regular":
            return self.regular_train_cap
        if bucket == "tail":
            return self.tail_train_cap
        return self.review_train_cap

    def bucket_for_unique_image_count(self, unique_image_count: int) -> str:
        if unique_image_count >= self.regular_min_unique_images:
            return "regular"
        if unique_image_count >= self.tail_min_unique_images:
            return "tail"
        return "review"


@dataclass(frozen=True)
class SplitLeakFinding:
    """A file-level split conflict that must not be ignored."""

    file_name: str
    observed_splits: tuple[str, ...]
    observed_canonical_class_names: tuple[str, ...]
    observed_ontology_ids: tuple[str, ...]
    row_count: int
    reason: str


@dataclass(frozen=True)
class ImageSplitRecord:
    """One unique image with its split and canonical label metadata."""

    file_name: str
    split: str
    domain: str
    defect_name: str
    part_name: str
    canonical_class_name: str
    ontology_id: str
    quality_state: str
    taxonomy_statuses: tuple[str, ...]
    label_types: tuple[str, ...]
    task_types: tuple[str, ...]
    original_category_ids: tuple[int, ...]
    zip_sources: tuple[str, ...]
    row_count: int
    unique_label_type_count: int
    unique_category_id_count: int
    unique_domain_count: int
    width: int
    height: int
    has_localized_geometry: bool
    has_taxonomy_review: bool
    area_bins: tuple[str, ...]
    max_area_ratio: float | None
    support_bucket: str


@dataclass(frozen=True)
class SplitManagementReport:
    """Summary of the image-level split validation."""

    total_unique_images: int
    train_unique_images: int
    validation_unique_images: int
    split_counts: dict[str, int]
    leakage_count: int
    leak_files: tuple[str, ...]
    notes: tuple[str, ...]


@dataclass(frozen=True)
class SamplingSelectionRecord:
    """One image-level sampling decision."""

    file_name: str
    split: str
    canonical_class_name: str
    ontology_id: str
    support_bucket: str
    has_taxonomy_review: bool
    area_weight: float
    selected_for_train: bool
    selected_for_validation: bool
    selection_reason: str
    class_size: int
    train_cap: int
    rank_in_class: int


@dataclass(frozen=True)
class SamplingReport:
    """Summary of the class-balanced sampling plan."""

    validation_policy: str
    total_unique_images: int
    selected_train_images: int
    selected_validation_images: int
    class_bucket_counts: dict[str, int]
    class_sample_counts: dict[str, int]
    taxonomy_review_image_count: int
    blocked_notes: tuple[str, ...]


def load_sampling_config(path: Path | None = None) -> SamplingConfig:
    """Load the Phase 3 sampling config from YAML."""

    path = path or DataConfig().sampling_config_path
    if not path.exists():
        return SamplingConfig()

    payload = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
    weights = payload.get("area_aware_weights", {})
    return SamplingConfig(
        regular_min_unique_images=int(payload.get("support_buckets", {}).get("regular_min_unique_images", 1000)),
        tail_min_unique_images=int(payload.get("support_buckets", {}).get("tail_min_unique_images", 100)),
        regular_train_cap=int(payload.get("train_caps", {}).get("regular", 5000)),
        tail_train_cap=int(payload.get("train_caps", {}).get("tail", 1000)),
        review_train_cap=int(payload.get("train_caps", {}).get("review", 0)),
        validation_policy=str(payload.get("validation_policy", "natural")),
        area_aware_weights={str(key): float(value) for key, value in weights.items()} or None,
    )


def _row_value(row: Mapping[str, Any] | NormalizedAnnotation, key: str, default: Any = "") -> Any:
    if isinstance(row, Mapping):
        return row.get(key, default)
    return getattr(row, key, default)


def group_rows_by_file_name(
    rows: Iterable[Mapping[str, Any] | NormalizedAnnotation],
) -> dict[str, list[Mapping[str, Any] | NormalizedAnnotation]]:
    """Group annotations by image file name."""

    grouped: dict[str, list[Mapping[str, Any] | NormalizedAnnotation]] = defaultdict(list)
    for row in rows:
        file_name = str(_row_value(row, "file_name", "")).strip()
        if not file_name:
            continue
        grouped[file_name].append(row)
    return grouped


def build_image_split_records(
    rows: Iterable[Mapping[str, Any] | NormalizedAnnotation],
    *,
    ontology_records: Iterable[OntologyRecord] | None = None,
) -> tuple[list[ImageSplitRecord], tuple[SplitLeakFinding, ...]]:
    """Collapse annotation rows into unique image records."""

    ontology_lookup = {}
    if ontology_records is not None:
        ontology_lookup = {record.ontology_id: record for record in ontology_records}

    records: list[ImageSplitRecord] = []
    leaks: list[SplitLeakFinding] = []
    grouped = group_rows_by_file_name(rows)

    for file_name, group in sorted(grouped.items()):
        split_values = {str(_row_value(row, "split", "")) for row in group if _row_value(row, "split", "")}
        canonical_values = {
            str(_row_value(row, "canonical_class_name", ""))
            for row in group
            if _row_value(row, "canonical_class_name", "")
        }
        ontology_values = {
            str(_row_value(row, "ontology_id", ""))
            for row in group
            if _row_value(row, "ontology_id", "")
        }
        if len(split_values) > 1 or len(canonical_values) > 1 or len(ontology_values) > 1:
            leaks.append(
                SplitLeakFinding(
                    file_name=file_name,
                    observed_splits=tuple(sorted(split_values)),
                    observed_canonical_class_names=tuple(sorted(canonical_values)),
                    observed_ontology_ids=tuple(sorted(ontology_values)),
                    row_count=len(group),
                    reason="file_name-level split or ontology disagreement",
                )
            )

        primary = sorted(
            group,
            key=lambda row: (
                str(_row_value(row, "split", "")),
                str(_row_value(row, "ontology_id", "")),
                str(_row_value(row, "label_type", "")),
                int(_row_value(row, "original_category_id", 0) or 0),
            ),
        )[0]
        ontology_id = str(_row_value(primary, "ontology_id", ""))
        ontology_record = ontology_lookup.get(ontology_id)
        domain = str(_row_value(primary, "domain", ""))
        defect_name = str(_row_value(primary, "defect_name_norm", _row_value(primary, "defect_name", "")))
        part_name = str(_row_value(primary, "part_name_norm", _row_value(primary, "part_name", "")))
        label_types = tuple(sorted({str(_row_value(row, "label_type", "")) for row in group if _row_value(row, "label_type", "")}))
        task_types = tuple(sorted({str(_row_value(row, "task_type", "")) for row in group if _row_value(row, "task_type", "")}))
        taxonomy_statuses = tuple(
            sorted(
                {
                    str(_row_value(row, "taxonomy_status", "normal") or "normal")
                    for row in group
                    if _row_value(row, "taxonomy_status", "normal")
                }
            )
        )
        original_category_ids = tuple(
            sorted(
                {
                    int(_row_value(row, "original_category_id", _row_value(row, "category_id", 0)) or 0)
                    for row in group
                    if _row_value(row, "original_category_id", _row_value(row, "category_id", 0)) not in ("", None)
                }
            )
        )
        zip_sources = tuple(sorted({str(_row_value(row, "zip_source", "")) for row in group if _row_value(row, "zip_source", "")}))
        area_bins = tuple(sorted({str(_row_value(row, "area_bin", "")) for row in group if _row_value(row, "area_bin", "")}))
        area_ratios = [
            float(_row_value(row, "area_ratio", 0.0) or 0.0)
            for row in group
            if _row_value(row, "area_ratio", None) not in (None, "", "None")
        ]
        widths = [int(_row_value(row, "width", 0) or 0) for row in group if int(_row_value(row, "width", 0) or 0) > 0]
        heights = [int(_row_value(row, "height", 0) or 0) for row in group if int(_row_value(row, "height", 0) or 0) > 0]
        split_value = str(_row_value(primary, "split", ""))
        support_bucket = ontology_record.support_bucket if ontology_record is not None else "review"
        records.append(
            ImageSplitRecord(
                file_name=file_name,
                split=split_value,
                domain=domain,
                defect_name=defect_name,
                part_name=part_name,
                canonical_class_name=str(_row_value(primary, "canonical_class_name", f"{defect_name}_{part_name}")),
                ontology_id=ontology_id,
                quality_state=str(_row_value(primary, "quality_state", "")),
                taxonomy_statuses=taxonomy_statuses,
                label_types=label_types,
                task_types=task_types,
                original_category_ids=original_category_ids,
                zip_sources=zip_sources,
                row_count=len(group),
                unique_label_type_count=len(label_types),
                unique_category_id_count=len(original_category_ids),
                unique_domain_count=len({str(_row_value(row, "domain", "")) for row in group if _row_value(row, "domain", "")}),
                width=max(widths) if widths else 0,
                height=max(heights) if heights else 0,
                has_localized_geometry=any(task_type in {"detect", "segment"} for task_type in task_types),
                has_taxonomy_review=any(status != "normal" for status in taxonomy_statuses),
                area_bins=area_bins,
                max_area_ratio=max(area_ratios) if area_ratios else None,
                support_bucket=support_bucket,
            )
        )

    return records, tuple(leaks)


def save_split_manifest(records: Iterable[ImageSplitRecord], path: Path | None = None) -> Path:
    """Write the image-level split manifest as JSON."""

    path = path or DEFAULT_SPLIT_MANIFEST_PATH
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps([asdict(record) for record in records], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return path


def build_split_management_report(
    records: Iterable[ImageSplitRecord],
    leaks: Iterable[SplitLeakFinding] = (),
) -> SplitManagementReport:
    """Summarize split-level leakage and unique-image counts."""

    records = list(records)
    leaks = tuple(leaks)
    split_counts = defaultdict(int)
    for record in records:
        split_counts[record.split] += 1
    train_unique_images = split_counts.get("TL", 0)
    validation_unique_images = split_counts.get("VL", 0)
    return SplitManagementReport(
        total_unique_images=len(records),
        train_unique_images=train_unique_images,
        validation_unique_images=validation_unique_images,
        split_counts=dict(split_counts),
        leakage_count=len(leaks),
        leak_files=tuple(leak.file_name for leak in leaks),
        notes=(
            "split grouping은 file_name 기준으로만 계산한다.",
            "validation/test는 natural distribution을 기본으로 유지한다.",
        ),
    )


def write_split_management_report(
    report: SplitManagementReport,
    *,
    csv_path: Path | None = None,
    md_path: Path | None = None,
) -> tuple[Path, Path]:
    """Write split-management summary artifacts."""

    csv_path = csv_path or DEFAULT_SPLIT_AUDIT_PATH
    md_path = md_path or DEFAULT_SPLIT_AUDIT_MD_PATH
    write_csv_rows(
        csv_path,
        [
            {"metric": "total_unique_images", "value": report.total_unique_images},
            {"metric": "train_unique_images", "value": report.train_unique_images},
            {"metric": "validation_unique_images", "value": report.validation_unique_images},
            {"metric": "leakage_count", "value": report.leakage_count},
        ],
        fieldnames=("metric", "value"),
    )
    lines = [
        "# Split Management Report",
        "",
        "## Summary",
        "",
        f"- total unique images: {report.total_unique_images}",
        f"- train(TL) unique images: {report.train_unique_images}",
        f"- validation(VL) unique images: {report.validation_unique_images}",
        f"- leakage count: {report.leakage_count}",
        "",
        "## Notes",
        "",
    ]
    lines.extend(f"- {note}" for note in report.notes)
    if report.leak_files:
        lines.extend(["", "## Leakage Files", ""])
        lines.extend(f"- {file_name}" for file_name in report.leak_files)
    write_markdown(md_path, lines)
    return csv_path, md_path


def _area_weight(record: ImageSplitRecord, sampling_config: SamplingConfig) -> float:
    if not record.has_localized_geometry or not record.area_bins:
        return 1.0
    weights = sampling_config.area_aware_weights or {}
    if not weights:
        return 1.0
    best = max((weights.get(area_bin, 1.0) for area_bin in record.area_bins), default=1.0)
    return float(best)


def build_sampling_manifest(
    records: Iterable[ImageSplitRecord],
    ontology_records: Iterable[OntologyRecord] = (),
    *,
    sampling_config: SamplingConfig | None = None,
    exclude_taxonomy_review: bool = True,
) -> tuple[list[SamplingSelectionRecord], SamplingReport]:
    """Select deterministic train/validation samples using unique-image counts."""

    sampling_config = sampling_config or load_sampling_config()
    records = list(records)
    ontology_lookup = {record.canonical_class_name: record for record in ontology_records}
    by_class: dict[str, list[ImageSplitRecord]] = defaultdict(list)
    for record in records:
        by_class[record.canonical_class_name].append(record)

    selections: list[SamplingSelectionRecord] = []
    bucket_counts = defaultdict(int)
    class_sample_counts = defaultdict(int)

    for canonical_class_name in sorted(by_class):
        class_records = sorted(by_class[canonical_class_name], key=lambda record: (record.split, record.file_name))
        unique_image_count = len(class_records)
        ontology_record = ontology_lookup.get(canonical_class_name)
        bucket = (
            ontology_record.support_bucket
            if ontology_record is not None
            else sampling_config.bucket_for_unique_image_count(unique_image_count)
        )
        train_cap = sampling_config.train_cap_for_bucket(bucket)
        tl_records = [record for record in class_records if record.split == "TL"]
        vl_records = [record for record in class_records if record.split == "VL"]
        sorted_train = sorted(
            tl_records,
            key=lambda record: (-_area_weight(record, sampling_config), record.file_name),
        )
        selected_train = {
            record.file_name for record in sorted_train[: min(train_cap, len(sorted_train))]
        }
        for rank, record in enumerate(sorted_train, start=1):
            selected = record.file_name in selected_train and not (exclude_taxonomy_review and record.has_taxonomy_review)
            if selected:
                class_sample_counts[canonical_class_name] += 1
            selections.append(
                SamplingSelectionRecord(
                    file_name=record.file_name,
                    split=record.split,
                    canonical_class_name=canonical_class_name,
                    ontology_id=record.ontology_id,
                    support_bucket=bucket,
                    has_taxonomy_review=record.has_taxonomy_review,
                    area_weight=_area_weight(record, sampling_config),
                    selected_for_train=selected,
                    selected_for_validation=False,
                    selection_reason=(
                        "taxonomy_review_excluded"
                        if not selected and exclude_taxonomy_review and record.has_taxonomy_review
                        else "train_cap"
                        if selected
                        else "train_cap_exceeded"
                    ),
                    class_size=unique_image_count,
                    train_cap=train_cap,
                    rank_in_class=rank,
                )
            )
        for record in vl_records:
            selections.append(
                SamplingSelectionRecord(
                    file_name=record.file_name,
                    split=record.split,
                    canonical_class_name=canonical_class_name,
                    ontology_id=record.ontology_id,
                    support_bucket=bucket,
                    has_taxonomy_review=record.has_taxonomy_review,
                    area_weight=_area_weight(record, sampling_config),
                    selected_for_train=False,
                    selected_for_validation=True,
                    selection_reason="validation_natural_distribution",
                    class_size=unique_image_count,
                    train_cap=train_cap,
                    rank_in_class=0,
                )
            )
        bucket_counts[bucket] += unique_image_count

    report = SamplingReport(
        validation_policy=sampling_config.validation_policy,
        total_unique_images=len(records),
        selected_train_images=sum(1 for record in selections if record.selected_for_train),
        selected_validation_images=sum(1 for record in selections if record.selected_for_validation),
        class_bucket_counts=dict(bucket_counts),
        class_sample_counts=dict(class_sample_counts),
        taxonomy_review_image_count=sum(1 for record in records if record.has_taxonomy_review),
        blocked_notes=(
            "validation/test oversampling is disabled by default.",
            "area-aware weights only affect train selection when localized geometry exists.",
            "taxonomy_review_required images are excluded from train sampling by default.",
        ),
    )
    return selections, report


def save_sampling_manifest(
    records: Iterable[SamplingSelectionRecord],
    path: Path | None = None,
) -> Path:
    """Write the deterministic sampling manifest as JSON."""

    path = path or Path(DEFAULT_SPLIT_MANIFEST_PATH).with_name("sampling_manifest.json")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps([asdict(record) for record in records], ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return path


def write_sampling_report(
    report: SamplingReport,
    *,
    csv_path: Path | None = None,
    md_path: Path | None = None,
) -> tuple[Path, Path]:
    """Write sampling summary artifacts."""

    csv_path = csv_path or DEFAULT_SAMPLING_AUDIT_PATH
    md_path = md_path or DEFAULT_SAMPLING_AUDIT_MD_PATH
    write_csv_rows(
        csv_path,
        [
            {"metric": "total_unique_images", "value": report.total_unique_images},
            {"metric": "selected_train_images", "value": report.selected_train_images},
            {"metric": "selected_validation_images", "value": report.selected_validation_images},
            {"metric": "taxonomy_review_image_count", "value": report.taxonomy_review_image_count},
            {"metric": "validation_policy", "value": report.validation_policy},
        ],
        fieldnames=("metric", "value"),
    )
    lines = [
        "# Sampling Report",
        "",
        "## Summary",
        "",
        f"- validation policy: {report.validation_policy}",
        f"- total unique images: {report.total_unique_images}",
        f"- selected train images: {report.selected_train_images}",
        f"- selected validation images: {report.selected_validation_images}",
        f"- taxonomy review images: {report.taxonomy_review_image_count}",
        "",
        "## Bucket Counts",
        "",
    ]
    lines.extend(f"- {bucket}: {count}" for bucket, count in sorted(report.class_bucket_counts.items()))
    lines.extend(["", "## Class Sample Counts", ""])
    lines.extend(f"- {class_name}: {count}" for class_name, count in sorted(report.class_sample_counts.items()))
    lines.extend(["", "## Notes", ""])
    lines.extend(f"- {note}" for note in report.blocked_notes)
    write_markdown(md_path, lines)
    return csv_path, md_path
