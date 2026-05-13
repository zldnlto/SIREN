from __future__ import annotations

from vision.src.data.normalization import normalize_rows


def test_normalized_rows_preserve_source_and_annotation_layers() -> None:
    rows = normalize_rows(
        [
            {
                "file_name": "ok.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "segmentation+bbox",
                "zip_source": "TL_표면처리_균열_도장.zip",
                "width": 3024,
                "height": 4032,
                "area": 120.0,
            }
        ]
    )

    row = rows[0]
    assert row.source_domain == "표면처리"
    assert row.source_defect == "균열"
    assert row.annotation_domain == "표면처리"
    assert row.domain == "표면처리"
    assert row.source_category_id == 25
    assert row.original_category_id == 25
    assert row.taxonomy_status == "normal"
    assert row.review_needed is False
    assert row.review_reason is None


def test_taxonomy_status_flags_cross_domain_and_review_candidates() -> None:
    rows = normalize_rows(
        [
            {
                "file_name": "cross.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "bbox",
                "zip_source": "TL_용접_용접불량_조인트.zip",
                "width": 3024,
                "height": 4032,
                "area": 120.0,
            },
            {
                "file_name": "extend.jpg",
                "split": "TL",
                "domain": "신규도메인",
                "defect_name": "임시결함",
                "part_name": "임시부품",
                "category_id": 999,
                "label_type": "classification",
                "zip_source": "TL_신규도메인_임시결함_임시부품.zip",
            },
            {
                "file_name": "error.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "스크래치",
                "part_name": "케이블타이",
                "category_id": 25,
                "label_type": "bbox",
                "zip_source": "TL_표면처리_스크래치_케이블타이.zip",
                "width": 3024,
                "height": 4032,
                "area": 80.0,
            },
            {
                "file_name": "missing.jpg",
                "split": "TL",
                "domain": "",
                "defect_name": "스크래치",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "classification",
                "zip_source": "",
            },
        ]
    )

    status_by_file = {row.file_name: row.taxonomy_status for row in rows}
    reason_by_file = {row.file_name: row.review_reason for row in rows}

    assert status_by_file["cross.jpg"] == "cross_domain_annotation_candidate"
    assert reason_by_file["cross.jpg"] == "source_and_annotation_domains_differ"
    assert status_by_file["extend.jpg"] == "taxonomy_extension_candidate"
    assert reason_by_file["extend.jpg"] == "unknown_annotation_domain"
    assert status_by_file["error.jpg"] == "likely_label_error"
    assert reason_by_file["error.jpg"] in {
        "source_defect_and_annotation_defect_differ",
        "defect_not_in_valid_domain_defects",
        "part_not_in_valid_domain_combos",
    }
    assert status_by_file["missing.jpg"] == "taxonomy_review_required"
    assert reason_by_file["missing.jpg"] == "missing_source_or_annotation_context"
