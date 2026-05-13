from __future__ import annotations

from collections import defaultdict
from pathlib import Path

import pytest

from vision.src.data import (
    DataConfig,
    build_letterbox_transform,
    build_ontology_table,
    build_restoration_index,
    build_task_label_map,
    bbox_xywh_to_yolo,
    canonical_class_name,
    clip_xyxy,
    discover_repository_sources,
    load_dataset_index_rows,
    normalize_rows,
    polygon_to_yolo,
    restore_prediction,
    scale_bbox_xywh,
    scale_polygon,
    write_dataset_validation_report,
)


@pytest.fixture(scope="module")
def dataset_index_rows() -> list[dict[str, str]]:
    return load_dataset_index_rows()


@pytest.fixture(scope="module")
def normalized_rows(dataset_index_rows: list[dict[str, str]]):
    return normalize_rows(dataset_index_rows)


@pytest.fixture(scope="module")
def ontology_records(normalized_rows):
    return build_ontology_table(normalized_rows)


def test_repository_discovery_reports_missing_resized_root(tmp_path: Path) -> None:
    config = DataConfig(resized_root=tmp_path / "missing-resized-root")

    report = discover_repository_sources(config)
    out_path = write_dataset_validation_report(report, tmp_path / "dataset_validation_report.md")

    assert report.row_count == 299123
    assert report.unique_image_count == 279320
    assert report.combo_count == 43
    assert report.resized_image_count is None
    assert any("resized_root_missing" in item for item in report.missing_sources)
    assert out_path.exists()


def test_normalization_and_ontology_rules_hold(normalized_rows, ontology_records) -> None:
    category_to_canonical: dict[int, set[str]] = defaultdict(set)
    canonical_to_domains: dict[str, set[str]] = defaultdict(set)

    for row in normalized_rows:
        category_to_canonical[row.original_category_id].add(row.canonical_class_name)
        canonical_to_domains[row.canonical_class_name].add(row.domain)
        assert row.canonical_class_name == canonical_class_name(
            row.defect_name_norm, row.part_name_norm
        )
        assert row.quality_state == ("good" if "양품" in row.defect_name_norm else "defect")
        if row.label_type == "classification":
            assert row.task_type == "classify"
            assert row.geometry_level == "image"
        elif row.label_type == "bbox":
            assert row.task_type == "detect"
            assert row.geometry_level == "bbox"
        elif row.label_type == "segmentation+bbox":
            assert row.task_type == "segment"
            assert row.geometry_level == "mask"

    collision_count = sum(1 for values in category_to_canonical.values() if len(values) > 1)
    assert collision_count == 12
    assert all(len(values) == 1 for values in canonical_to_domains.values())
    assert len(ontology_records) == 43
    assert all(record.support_bucket in {"regular", "tail", "review"} for record in ontology_records)
    assert {
        bucket: sum(1 for record in ontology_records if record.support_bucket == bucket)
        for bucket in ("regular", "tail", "review")
    } == {"regular": 30, "tail": 2, "review": 11}


def test_task_label_maps_are_separated_and_restore_roundtrip(ontology_records) -> None:
    classify_map = build_task_label_map(ontology_records, model_name="surface_cls", task_type="classify")
    detect_map = build_task_label_map(ontology_records, model_name="surface_det", task_type="detect")
    segment_map = build_task_label_map(ontology_records, model_name="surface_seg", task_type="segment")
    classification_only = {
        record.ontology_id for record in ontology_records if record.allowed_task_types == ("classify",)
    }
    detect_ontology_ids = {entry.ontology_id for entry in detect_map}

    assert len(classify_map) == 6
    assert len(detect_map) == 4
    assert len(segment_map) == 22
    assert classify_map == sorted(classify_map, key=lambda row: row.ontology_id)
    assert detect_map == sorted(detect_map, key=lambda row: row.ontology_id)
    assert segment_map == sorted(segment_map, key=lambda row: row.ontology_id)

    classify_entry = build_restoration_index(classify_map)[("surface_cls", "classify", 0)]
    detect_entry = build_restoration_index(detect_map)[("surface_det", "detect", 0)]
    segment_entry = build_restoration_index(segment_map)[("surface_seg", "segment", 0)]

    restored_classify = restore_prediction(
        image_id="img-1",
        file_name="img-1.jpg",
        confidence=0.91,
        entry=classify_entry,
    )
    restored_detect = restore_prediction(
        image_id="img-2",
        file_name="img-2.jpg",
        confidence=0.88,
        entry=detect_entry,
        bbox_xyxy=[10.0, 20.0, 100.0, 120.0],
        source_geometry="bbox",
    )
    restored_segment = restore_prediction(
        image_id="img-3",
        file_name="img-3.jpg",
        confidence=0.97,
        entry=segment_entry,
        bbox_xyxy=[12.0, 22.0, 102.0, 122.0],
        mask_polygon=[[12.0, 22.0, 102.0, 22.0, 102.0, 122.0, 12.0, 122.0]],
        source_geometry="mask",
    )

    assert restored_classify.geometry_level == "image"
    assert restored_classify.bbox_xyxy is None
    assert restored_classify.mask_polygon is None
    assert restored_detect.geometry_level == "bbox"
    assert restored_detect.bbox_xyxy == [10.0, 20.0, 100.0, 120.0]
    assert restored_detect.mask_polygon is None
    assert restored_segment.geometry_level == "mask"
    assert restored_segment.mask_polygon is not None
    assert classification_only.isdisjoint(detect_ontology_ids)


def test_geometry_scaffold_scales_and_normalizes_coordinates() -> None:
    transform = build_letterbox_transform(3024, 4032, target_width=640, target_height=640)
    scaled_bbox = scale_bbox_xywh([100.0, 200.0, 300.0, 400.0], transform)
    normalized_bbox = bbox_xywh_to_yolo(scaled_bbox, transform)
    scaled_polygon = scale_polygon([100.0, 200.0, 400.0, 200.0, 400.0, 500.0, 100.0, 500.0], transform)
    normalized_polygon = polygon_to_yolo(scaled_polygon, transform)
    clipped_bbox, clipping_event = clip_xyxy(-10.0, 5.0, 700.0, 800.0, max_width=640, max_height=640)

    assert transform.target_width == 640
    assert transform.target_height == 640
    assert all(0.0 <= value <= 1.0 for value in normalized_bbox)
    assert len(normalized_polygon) == 8
    assert all(0.0 <= value <= 1.0 for value in normalized_polygon)
    assert clipped_bbox == (0.0, 5.0, 640.0, 640.0)
    assert clipping_event is not None
