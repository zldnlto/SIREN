"""Prediction restoration helpers for task-specific model outputs."""

from __future__ import annotations

from dataclasses import dataclass, asdict
from typing import Iterable

from vision.src.data.label_maps import TaskLabelMapRecord


@dataclass(frozen=True)
class RestorationEntry:
    """One row in the restoration index."""

    model_name: str
    task_type: str
    model_class_id: int
    ontology_id: str
    display_label: str
    canonical_class_name: str
    domain: str
    defect_name: str
    part_name: str
    quality_state: str
    train_granularity: str
    restore_granularity: str


@dataclass(frozen=True)
class RestoredPrediction:
    """Ontology-aware prediction output."""

    image_id: str
    file_name: str
    model_name: str
    task_type: str
    model_class_id: int
    ontology_id: str
    display_label: str
    domain: str
    defect_name: str
    part_name: str
    quality_state: str
    canonical_class_name: str
    confidence: float
    geometry_level: str
    bbox_xyxy: list[float] | None
    mask_polygon: list[list[float]] | None
    source_geometry: str


def build_restoration_index(
    label_map_records: Iterable[TaskLabelMapRecord],
) -> dict[tuple[str, str, int], RestorationEntry]:
    """Index label-map rows for restoration lookup."""

    index: dict[tuple[str, str, int], RestorationEntry] = {}
    for record in label_map_records:
        index[(record.model_name, record.task_type, record.model_class_id)] = RestorationEntry(
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
    return index


def restore_prediction(
    *,
    image_id: str,
    file_name: str,
    confidence: float,
    entry: RestorationEntry,
    bbox_xyxy: list[float] | None = None,
    mask_polygon: list[list[float]] | None = None,
    source_geometry: str = "none",
) -> RestoredPrediction:
    """Convert a raw model hit into the ontology-aware business schema."""

    if entry.task_type == "classify":
        geometry_level = "image"
        bbox_xyxy = None
        mask_polygon = None
    elif entry.task_type == "detect":
        geometry_level = "bbox"
        mask_polygon = None
    else:
        geometry_level = "mask" if mask_polygon else "bbox" if bbox_xyxy else "image"

    return RestoredPrediction(
        image_id=image_id,
        file_name=file_name,
        model_name=entry.model_name,
        task_type=entry.task_type,
        model_class_id=entry.model_class_id,
        ontology_id=entry.ontology_id,
        display_label=entry.display_label,
        domain=entry.domain,
        defect_name=entry.defect_name,
        part_name=entry.part_name,
        quality_state=entry.quality_state,
        canonical_class_name=entry.canonical_class_name,
        confidence=confidence,
        geometry_level=geometry_level,
        bbox_xyxy=bbox_xyxy,
        mask_polygon=mask_polygon,
        source_geometry=source_geometry,
    )


def restored_prediction_to_dict(prediction: RestoredPrediction) -> dict[str, object]:
    """Convert a restored prediction into plain JSON-friendly data."""

    return asdict(prediction)
