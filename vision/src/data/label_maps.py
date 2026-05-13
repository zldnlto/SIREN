"""Task-specific label map helpers."""

from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable

from vision.src.data.config import DEFAULT_LABEL_MAP_ROOT
from vision.src.data.ontology import OntologyRecord


@dataclass(frozen=True)
class TaskLabelMapRecord:
    """One task-specific label map row."""

    model_name: str
    task_type: str
    task_specific_model_class_id: int
    ontology_id: str
    display_label: str
    canonical_class_name: str
    train_granularity: str
    restore_granularity: str
    domain: str
    defect_name: str
    part_name: str
    quality_state: str
    support_bucket: str

    @property
    def model_class_id(self) -> int:
        """Backward-compatible alias for the task-specific local class id."""

        return self.task_specific_model_class_id


def build_task_label_map(
    ontology_records: Iterable[OntologyRecord],
    *,
    model_name: str,
    task_type: str,
    include_review: bool = False,
    train_granularity: str = "leaf",
    restore_granularity: str = "leaf",
) -> list[TaskLabelMapRecord]:
    """Build a deterministic label map for one task."""

    eligible = [
        record
        for record in ontology_records
        if task_type in record.allowed_task_types and (include_review or record.support_bucket != "review")
    ]
    eligible.sort(key=lambda record: (record.ontology_id, record.display_label))
    return [
        TaskLabelMapRecord(
            model_name=model_name,
            task_type=task_type,
            task_specific_model_class_id=index,
            ontology_id=record.ontology_id,
            display_label=record.display_label,
            canonical_class_name=record.canonical_class_name,
            train_granularity=train_granularity,
            restore_granularity=restore_granularity,
            domain=record.domain,
            defect_name=record.defect_name,
            part_name=record.part_name,
            quality_state=record.quality_state,
            support_bucket=record.support_bucket,
        )
        for index, record in enumerate(eligible)
    ]


def label_map_records_to_dicts(
    records: Iterable[TaskLabelMapRecord],
) -> list[dict[str, Any]]:
    """Convert label map records into plain dictionaries."""

    payload: list[dict[str, Any]] = []
    for record in records:
        item = asdict(record)
        item["model_class_id"] = record.task_specific_model_class_id
        payload.append(item)
    return payload


def save_task_label_map(
    records: Iterable[TaskLabelMapRecord],
    path: Path | None = None,
) -> Path:
    """Write a task label map as JSON."""

    path = path or DEFAULT_LABEL_MAP_ROOT / "task_label_map.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(label_map_records_to_dicts(records), ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    return path


def load_task_label_map(path: Path) -> list[dict[str, Any]]:
    """Load a previously saved task label map."""

    payload = json.loads(path.read_text(encoding="utf-8"))
    for item in payload:
        if "task_specific_model_class_id" not in item and "model_class_id" in item:
            item["task_specific_model_class_id"] = item["model_class_id"]
        if "model_class_id" not in item and "task_specific_model_class_id" in item:
            item["model_class_id"] = item["task_specific_model_class_id"]
    return payload


def build_label_map_index(
    records: Iterable[TaskLabelMapRecord],
) -> dict[tuple[str, str, int], TaskLabelMapRecord]:
    """Index records by (model_name, task_type, task_specific_model_class_id)."""

    index: dict[tuple[str, str, int], TaskLabelMapRecord] = {}
    for record in records:
        index[(record.model_name, record.task_type, record.task_specific_model_class_id)] = record
    return index
