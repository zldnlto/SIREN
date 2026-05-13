from __future__ import annotations

from dataclasses import asdict

from vision.src.data.label_maps import TaskLabelMapRecord
from vision.src.data.restore_predictions import (
    build_restore_prediction_index,
    build_restoration_audit_report,
    build_restoration_audit_rows,
    restore_prediction_rows,
)


def _build_label_map_records() -> list[TaskLabelMapRecord]:
    return [
        TaskLabelMapRecord(
            model_name="leaf-model",
            task_type="classify",
            model_class_id=0,
            ontology_id="v1.표면처리.균열.도장.defect",
            display_label="표면처리_균열_도장",
            canonical_class_name="균열_도장",
            train_granularity="leaf",
            restore_granularity="leaf",
            domain="표면처리",
            defect_name="균열",
            part_name="도장",
            quality_state="defect",
            support_bucket="regular",
        ),
        TaskLabelMapRecord(
            model_name="parent-model",
            task_type="classify",
            model_class_id=1,
            ontology_id="v1.표면처리.균열.도장.defect",
            display_label="표면처리_균열_도장",
            canonical_class_name="균열_도장",
            train_granularity="parent",
            restore_granularity="parent",
            domain="표면처리",
            defect_name="균열",
            part_name="도장",
            quality_state="defect",
            support_bucket="tail",
        ),
        TaskLabelMapRecord(
            model_name="binary-model",
            task_type="classify",
            model_class_id=2,
            ontology_id="v1.표면처리.표면양품.도장.good",
            display_label="표면처리_표면양품_도장",
            canonical_class_name="표면양품_도장",
            train_granularity="binary",
            restore_granularity="binary",
            domain="표면처리",
            defect_name="표면양품",
            part_name="도장",
            quality_state="good",
            support_bucket="regular",
        ),
    ]


def test_restore_prediction_roundtrip_and_granularity_resolution() -> None:
    records = _build_label_map_records()
    index = build_restore_prediction_index(records)

    restored = restore_prediction_rows(
        [
            {
                "image_id": "img-1",
                "file_name": "sample.jpg",
                "model_name": "leaf-model",
                "task_type": "classify",
                "model_class_id": 0,
                "confidence": 0.91,
                "bbox_xyxy": [1.0, 2.0, 3.0, 4.0],
                "source_geometry": "image",
            },
            {
                "image_id": "img-2",
                "file_name": "sample.jpg",
                "model_name": "parent-model",
                "task_type": "classify",
                "model_class_id": 1,
                "confidence": 0.88,
                "bbox_xyxy": [1.0, 2.0, 3.0, 4.0],
                "source_geometry": "image",
            },
            {
                "image_id": "img-3",
                "file_name": "sample.jpg",
                "model_name": "binary-model",
                "task_type": "classify",
                "model_class_id": 2,
                "confidence": 0.99,
                "bbox_xyxy": [1.0, 2.0, 3.0, 4.0],
                "source_geometry": "image",
            },
        ],
        index,
    )

    assert [row.ontology_id for row in restored] == [
        "v1.표면처리.균열.도장.defect",
        "v1.표면처리.균열.도장.defect",
        "v1.표면처리.표면양품.도장.good",
    ]
    assert restored[0].display_label == "표면처리_균열_도장"
    assert restored[1].display_label == "표면처리"
    assert restored[2].display_label == "good"
    assert restored[1].display_label != "표면처리_균열_도장"
    assert restored[2].display_label != "표면처리_표면양품_도장"


def test_restoration_audit_reports_deterministic_roundtrip() -> None:
    records = _build_label_map_records()
    rows = build_restoration_audit_rows(records)
    report = build_restoration_audit_report(records)

    assert report.total_rows == 3
    assert report.unique_restoration_keys == 3
    assert report.duplicate_key_count == 0
    assert report.is_deterministic
    assert rows[1].restore_granularity == "parent"
    assert rows[2].restore_granularity == "binary"


def test_restoration_audit_rows_are_json_friendly() -> None:
    rows = build_restoration_audit_rows(_build_label_map_records())
    payload = [asdict(row) for row in rows]

    assert payload[0]["model_name"] == "leaf-model"
    assert payload[1]["restored_display_label"] == "표면처리"
    assert payload[2]["restored_display_label"] == "good"
