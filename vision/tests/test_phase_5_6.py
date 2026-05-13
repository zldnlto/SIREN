from __future__ import annotations

from dataclasses import asdict
from pathlib import Path

from vision.src.data.label_maps import TaskLabelMapRecord
from vision.src.data.evaluation import (
    EvaluationSample,
    build_calibration_rows,
    build_confusion_matrix_rows,
    build_false_negative_rows,
    build_hierarchical_metric_rows,
    build_label_type_report,
    build_support_bucket_report,
    write_hierarchical_metric_report,
    write_simple_report,
)
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


def _build_evaluation_samples() -> list[EvaluationSample]:
    return [
        EvaluationSample(
            image_id="img-1",
            file_name="sample-1.jpg",
            task_type="classify",
            label_type="classification",
            support_bucket="regular",
            true_canonical_class_name="균열_도장",
            predicted_canonical_class_name="균열_도장",
            true_domain="표면처리",
            predicted_domain="표면처리",
            true_quality_state="defect",
            predicted_quality_state="defect",
            confidence=0.91,
        ),
        EvaluationSample(
            image_id="img-2",
            file_name="sample-2.jpg",
            task_type="detect",
            label_type="bbox",
            support_bucket="tail",
            true_canonical_class_name="도막떨어짐_도장",
            predicted_canonical_class_name="도막분리_도장",
            true_domain="표면처리",
            predicted_domain="표면처리",
            true_quality_state="defect",
            predicted_quality_state="defect",
            confidence=0.65,
        ),
        EvaluationSample(
            image_id="img-3",
            file_name="sample-3.jpg",
            task_type="segment",
            label_type="segmentation+bbox",
            support_bucket="regular",
            true_canonical_class_name="표면양품_도장",
            predicted_canonical_class_name="표면양품_도장",
            true_domain="표면처리",
            predicted_domain="표면처리",
            true_quality_state="good",
            predicted_quality_state="good",
            confidence=0.83,
        ),
    ]


def test_hierarchical_metrics_confusion_and_false_negative_reports() -> None:
    samples = _build_evaluation_samples()

    leaf_rows = build_hierarchical_metric_rows(samples, granularity="leaf")
    parent_rows = build_hierarchical_metric_rows(samples, granularity="parent")
    binary_rows = build_hierarchical_metric_rows(samples, granularity="binary")
    confusion_rows = build_confusion_matrix_rows(samples, granularity="leaf")
    false_negative_rows = build_false_negative_rows(samples, granularity="leaf")
    label_type_rows = build_label_type_report(samples)
    support_rows = build_support_bucket_report(samples)
    calibration_rows = build_calibration_rows(samples, thresholds={"__default__": 0.7})

    assert [row.label for row in leaf_rows] == ["균열_도장", "도막떨어짐_도장", "표면양품_도장"]
    assert [row.label for row in parent_rows] == ["표면처리"]
    assert [row.label for row in binary_rows] == ["defect", "good"]
    assert any(row.true_label == "도막떨어짐_도장" and row.predicted_label == "도막분리_도장" for row in confusion_rows)
    assert len(false_negative_rows) == 1
    assert label_type_rows[0]["count"] == 1
    assert support_rows[0]["support_bucket"] == "regular"
    assert len(calibration_rows) == 3
    assert calibration_rows[0].threshold == 0.7


def test_hierarchical_reports_are_writable(tmp_path: Path) -> None:
    samples = _build_evaluation_samples()
    metric_rows = build_hierarchical_metric_rows(samples, granularity="leaf")

    metric_csv, metric_md = write_hierarchical_metric_report(
        metric_rows,
        csv_path=tmp_path / "metrics.csv",
        md_path=tmp_path / "metrics.md",
    )
    simple_csv, simple_md = write_simple_report(
        build_label_type_report(samples),
        csv_path=tmp_path / "label_type.csv",
        md_path=tmp_path / "label_type.md",
        title="Label Type Report",
    )

    assert metric_csv.exists()
    assert metric_md.exists()
    assert simple_csv.exists()
    assert simple_md.exists()
