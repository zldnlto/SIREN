from __future__ import annotations

from pathlib import Path

from vision.src.data import (
    ImageSplitRecord,
    SamplingConfig,
    build_image_split_records,
    build_sampling_manifest,
    build_split_management_report,
    normalize_rows,
    save_sampling_manifest,
    save_split_manifest,
    write_sampling_report,
    write_split_management_report,
)


def _build_normalized_rows_with_split_leak() -> list[dict[str, object]]:
    return normalize_rows(
        [
            {
                "file_name": "shared.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "segmentation+bbox",
                "width": 3024,
                "height": 4032,
                "area": 100.0,
                "zip_source": "TL_표면처리_균열_도장.zip",
            },
            {
                "file_name": "shared.jpg",
                "split": "VL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "segmentation+bbox",
                "width": 3024,
                "height": 4032,
                "area": 120.0,
                "zip_source": "VL_표면처리_균열_도장.zip",
            },
            {
                "file_name": "other.jpg",
                "split": "VL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "segmentation+bbox",
                "width": 3024,
                "height": 4032,
                "area": 140.0,
                "zip_source": "VL_표면처리_균열_도장.zip",
            },
        ],
        slugs_path=None,
    )


def test_image_split_records_group_by_file_name_and_report_leakage(tmp_path: Path) -> None:
    normalized_rows = _build_normalized_rows_with_split_leak()
    records, leaks = build_image_split_records(normalized_rows)
    report = build_split_management_report(records, leaks)

    assert len(records) == 2
    assert report.total_unique_images == 2
    assert report.leakage_count == 1
    assert report.leak_files == ("shared.jpg",)
    assert {record.file_name for record in records} == {"shared.jpg", "other.jpg"}

    split_csv, split_md = write_split_management_report(report, csv_path=tmp_path / "split.csv", md_path=tmp_path / "split.md")
    split_manifest = save_split_manifest(records, tmp_path / "split_manifest.json")

    assert split_csv.exists()
    assert split_md.exists()
    assert split_manifest.exists()


def test_sampling_manifest_uses_unique_image_caps_and_natural_validation(tmp_path: Path) -> None:
    sampling_config = SamplingConfig(
        regular_min_unique_images=3,
        tail_min_unique_images=2,
        regular_train_cap=1,
        tail_train_cap=2,
        review_train_cap=0,
        validation_policy="natural",
        area_aware_weights={"tiny": 2.0, "small": 1.5, "medium": 1.0, "large": 0.8},
    )
    records = [
        ImageSplitRecord(
            file_name=f"train_{index}.jpg",
            split="TL",
            domain="표면처리",
            defect_name="균열",
            part_name="도장",
            canonical_class_name="균열_도장",
            ontology_id="v1.표면처리.균열.도장.defect",
            quality_state="defect",
            label_types=("segmentation+bbox",),
            task_types=("segment",),
            original_category_ids=(25,),
            zip_sources=("TL_표면처리_균열_도장.zip",),
            row_count=1,
            unique_label_type_count=1,
            unique_category_id_count=1,
            unique_domain_count=1,
            width=3024,
            height=4032,
            has_localized_geometry=True,
            area_bins=("tiny",) if index == 0 else ("large",),
            max_area_ratio=0.01,
            support_bucket="regular",
        )
        for index in range(3)
    ] + [
        ImageSplitRecord(
            file_name="val_0.jpg",
            split="VL",
            domain="표면처리",
            defect_name="균열",
            part_name="도장",
            canonical_class_name="균열_도장",
            ontology_id="v1.표면처리.균열.도장.defect",
            quality_state="defect",
            label_types=("segmentation+bbox",),
            task_types=("segment",),
            original_category_ids=(25,),
            zip_sources=("VL_표면처리_균열_도장.zip",),
            row_count=1,
            unique_label_type_count=1,
            unique_category_id_count=1,
            unique_domain_count=1,
            width=3024,
            height=4032,
            has_localized_geometry=True,
            area_bins=("small",),
            max_area_ratio=0.02,
            support_bucket="regular",
        )
    ]

    selections, report = build_sampling_manifest(records, sampling_config=sampling_config)

    assert report.validation_policy == "natural"
    assert report.selected_train_images == 1
    assert report.selected_validation_images == 1
    assert sum(1 for item in selections if item.selected_for_train) == 1
    assert sum(1 for item in selections if item.selected_for_validation) == 1
    assert [item.file_name for item in selections if item.selected_for_train] == ["train_0.jpg"]

    sampling_csv, sampling_md = write_sampling_report(report, csv_path=tmp_path / "sampling.csv", md_path=tmp_path / "sampling.md")
    sampling_manifest = save_sampling_manifest(selections, tmp_path / "sampling_manifest.json")

    assert sampling_csv.exists()
    assert sampling_md.exists()
    assert sampling_manifest.exists()


def test_sampling_manifest_is_deterministic() -> None:
    sampling_config = SamplingConfig(
        regular_min_unique_images=1,
        tail_min_unique_images=1,
        regular_train_cap=2,
        tail_train_cap=2,
        review_train_cap=0,
        validation_policy="natural",
        area_aware_weights={"tiny": 2.0},
    )
    records = [
        ImageSplitRecord(
            file_name=f"image_{index}.jpg",
            split="TL",
            domain="표면처리",
            defect_name="균열",
            part_name="도장",
            canonical_class_name="균열_도장",
            ontology_id="v1.표면처리.균열.도장.defect",
            quality_state="defect",
            label_types=("segmentation+bbox",),
            task_types=("segment",),
            original_category_ids=(25,),
            zip_sources=("TL_표면처리_균열_도장.zip",),
            row_count=1,
            unique_label_type_count=1,
            unique_category_id_count=1,
            unique_domain_count=1,
            width=3024,
            height=4032,
            has_localized_geometry=True,
            area_bins=("tiny",),
            max_area_ratio=0.01,
            support_bucket="regular",
        )
        for index in range(2)
    ]

    first, _ = build_sampling_manifest(records, sampling_config=sampling_config)
    second, _ = build_sampling_manifest(records, sampling_config=sampling_config)

    assert first == second
