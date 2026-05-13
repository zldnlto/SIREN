"""Batch prediction restore helpers for task-specific model outputs."""

from __future__ import annotations

from dataclasses import asdict, dataclass
from typing import Any, Iterable, Mapping

from vision.src.data.label_maps import TaskLabelMapRecord
from vision.src.data.restoration import (
    RestorationEntry,
    RestoredPrediction,
    build_restoration_index,
    restore_prediction,
    resolve_restored_display_label,
)


@dataclass(frozen=True)
class RestorationAuditRow:
    """One row in the restore roundtrip audit."""

    model_name: str
    task_type: str
    model_class_id: int
    ontology_id: str
    display_label: str
    restored_display_label: str
    canonical_class_name: str
    train_granularity: str
    restore_granularity: str
    is_roundtrip_deterministic: bool


@dataclass(frozen=True)
class RestorationAuditReport:
    """Summary for deterministic roundtrip validation."""

    total_rows: int
    unique_restoration_keys: int
    deterministic_row_count: int
    parent_restored_row_count: int
    binary_restored_row_count: int
    duplicate_key_count: int

    @property
    def is_deterministic(self) -> bool:
        return self.duplicate_key_count == 0 and self.deterministic_row_count == self.total_rows


def build_restore_prediction_index(
    label_map_records: Iterable[TaskLabelMapRecord],
) -> dict[tuple[str, str, int], RestorationEntry]:
    """Create the lookup table used by batch restore helpers."""

    return build_restoration_index(label_map_records)


def restore_prediction_row(
    prediction_row: Mapping[str, Any],
    entry: RestorationEntry,
) -> RestoredPrediction:
    """Restore one raw model row into the ontology-aware business schema."""

    return restore_prediction(
        image_id=str(prediction_row.get("image_id", "")),
        file_name=str(prediction_row.get("file_name", "")),
        confidence=float(prediction_row.get("confidence", 0.0)),
        entry=entry,
        bbox_xyxy=prediction_row.get("bbox_xyxy"),
        mask_polygon=prediction_row.get("mask_polygon"),
        source_geometry=str(prediction_row.get("source_geometry", "none")),
    )


def restore_prediction_rows(
    prediction_rows: Iterable[Mapping[str, Any]],
    restoration_index: Mapping[tuple[str, str, int], RestorationEntry],
) -> list[RestoredPrediction]:
    """Restore many raw prediction rows in a deterministic order."""

    restored_rows: list[RestoredPrediction] = []
    for row in prediction_rows:
        key = (
            str(row.get("model_name", "")),
            str(row.get("task_type", "")),
            int(row.get("model_class_id", -1)),
        )
        entry = restoration_index[key]
        restored_rows.append(restore_prediction_row(row, entry))
    return restored_rows


def build_restoration_audit_rows(
    label_map_records: Iterable[TaskLabelMapRecord],
) -> list[RestorationAuditRow]:
    """Build deterministic audit rows for the roundtrip contract."""

    rows: list[RestorationAuditRow] = []
    for record in label_map_records:
        restored_display_label = resolve_restored_display_label(
            RestorationEntry(
                model_name=record.model_name,
                task_type=record.task_type,
                model_class_id=record.model_class_id,
                ontology_id=record.ontology_id,
                display_label=record.display_label,
                canonical_class_name=record.canonical_class_name,
                domain=record.domain,
                defect_name=record.defect_name,
                part_name=record.part_name,
                quality_state=record.quality_state,
                train_granularity=record.train_granularity,
                restore_granularity=record.restore_granularity,
            )
        )
        rows.append(
            RestorationAuditRow(
                model_name=record.model_name,
                task_type=record.task_type,
                model_class_id=record.model_class_id,
                ontology_id=record.ontology_id,
                display_label=record.display_label,
                restored_display_label=restored_display_label,
                canonical_class_name=record.canonical_class_name,
                train_granularity=record.train_granularity,
                restore_granularity=record.restore_granularity,
                is_roundtrip_deterministic=restored_display_label == record.display_label
                or record.restore_granularity != "leaf",
            )
        )

    return rows


def build_restoration_audit_report(
    label_map_records: Iterable[TaskLabelMapRecord],
) -> RestorationAuditReport:
    """Summarise the restore roundtrip contract."""

    rows = build_restoration_audit_rows(label_map_records)
    key_count = len({(row.model_name, row.task_type, row.model_class_id) for row in rows})
    parent_count = sum(1 for row in rows if row.restore_granularity == "parent")
    binary_count = sum(1 for row in rows if row.restore_granularity == "binary")
    deterministic_count = sum(1 for row in rows if row.is_roundtrip_deterministic)
    return RestorationAuditReport(
        total_rows=len(rows),
        unique_restoration_keys=key_count,
        deterministic_row_count=deterministic_count,
        parent_restored_row_count=parent_count,
        binary_restored_row_count=binary_count,
        duplicate_key_count=len(rows) - key_count,
    )


def restoration_audit_rows_to_dicts(rows: Iterable[RestorationAuditRow]) -> list[dict[str, Any]]:
    """Convert audit rows to JSON-friendly dictionaries."""

    return [asdict(row) for row in rows]
