"""Regression test: export and runtime label maps must use the same indices.

Root cause of EXP-001 bug: export used include_review=True while
build_segmentation_runtime_config used include_review=False (default),
causing task_specific_model_class_id offsets that corrupted all label files.
"""

from __future__ import annotations

from vision.src.data.label_maps import build_task_label_map
from vision.src.data.ontology import OntologyRecord


def _record(
    ontology_id: str, canonical: str, support_bucket: str = "confirmed"
) -> OntologyRecord:
    return OntologyRecord(
        ontology_id=ontology_id,
        parent_ontology_id="",
        display_label=canonical,
        canonical_class_name=canonical,
        domain="surface",
        defect_name="scratch",
        part_name="paint",
        quality_state="defect",
        allowed_task_types=("segment",),
        row_count=10,
        unique_image_count=10,
        unique_domain_count=1,
        unique_label_type_count=1,
        unique_category_id_count=1,
        support_bucket=support_bucket,
        is_primary_kpi_class=True,
    )


_RECORDS = [
    _record("A001", "coating_drop_paint"),
    _record("A002", "coating_separation_paint"),
    _record("A003", "review_class_a", support_bucket="review"),
    _record("A004", "crack_paint"),
    _record("A005", "scratch_paint"),
    _record("A006", "review_class_b", support_bucket="review"),
]


def test_export_and_runtime_indices_match():
    """include_review=False 시 export / runtime 인덱스가 동일해야 한다."""
    export_map = build_task_label_map(
        _RECORDS, model_name="m", task_type="segment", include_review=False
    )
    runtime_map = build_task_label_map(_RECORDS, model_name="m", task_type="segment")

    export_ids = {
        r.canonical_class_name: r.task_specific_model_class_id for r in export_map
    }
    runtime_ids = {
        r.canonical_class_name: r.task_specific_model_class_id for r in runtime_map
    }

    assert export_ids == runtime_ids, (
        f"export/runtime 인덱스 불일치 — include_review 파라미터 확인:\n"
        f"  export : {export_ids}\n"
        f"  runtime: {runtime_ids}"
    )


def test_review_class_excluded_from_label_map():
    """include_review=False 시 review-bucket 클래스가 label map에 없어야 한다."""
    label_map = build_task_label_map(
        _RECORDS, model_name="m", task_type="segment", include_review=False
    )
    names = {r.canonical_class_name for r in label_map}

    assert "review_class_a" not in names
    assert "review_class_b" not in names
    assert "coating_drop_paint" in names
    assert "scratch_paint" in names


def test_indices_are_zero_based_sequential():
    """label map 인덱스는 0부터 연속이어야 한다."""
    label_map = build_task_label_map(
        _RECORDS, model_name="m", task_type="segment", include_review=False
    )
    ids = sorted(r.task_specific_model_class_id for r in label_map)
    assert ids == list(range(len(ids))), f"비연속 인덱스: {ids}"


def test_review_true_shifts_indices():
    """include_review=True 시 인덱스가 달라짐을 확인 (버그 재현 케이스)."""
    export_false = build_task_label_map(
        _RECORDS, model_name="m", task_type="segment", include_review=False
    )
    export_true = build_task_label_map(
        _RECORDS, model_name="m", task_type="segment", include_review=True
    )

    ids_false = {
        r.canonical_class_name: r.task_specific_model_class_id for r in export_false
    }
    ids_true = {
        r.canonical_class_name: r.task_specific_model_class_id for r in export_true
    }

    # review 클래스가 끼어들면 non-review 클래스 인덱스가 달라진다
    assert (
        ids_false != ids_true
    ), "review 클래스가 있어도 인덱스가 같다면 버그 재현 데이터 확인 필요"
