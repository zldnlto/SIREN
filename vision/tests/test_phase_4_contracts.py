from __future__ import annotations

import json
import zipfile
from pathlib import Path

from PIL import Image

from vision.src.data import build_ontology_table, normalize_rows
from vision.src.data.classification_export import export_classification_dataset
from vision.src.data.detection_export import export_detection_dataset


def _write_sample_image(path: Path, size: tuple[int, int] = (64, 48)) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    Image.new("RGB", size, (255, 0, 0)).save(path)


def _write_sample_label_zip(
    path: Path,
    entries: dict[str, tuple[str, dict[str, object], int, int]],
) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(path, "w") as zf:
        for json_name, (image_name, annotation, width, height) in entries.items():
            payload = {
                "images": [
                    {
                        "id": 1,
                        "file_name": image_name,
                        "width": width,
                        "height": height,
                        "date_captured": "2024-01-01",
                    }
                ],
                "annotations": [annotation],
            }
            zf.writestr(json_name, json.dumps(payload, ensure_ascii=False))


def test_classification_export_manifest_is_deterministic_and_uses_task_specific_ids(tmp_path: Path) -> None:
    rows = normalize_rows(
        [
            {
                "file_name": "cls_0.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "표면양품",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "classification",
                "width": 640,
                "height": 640,
                "zip_source": "TL_표면처리_표면양품_도장.zip",
            }
        ],
        slugs_path=None,
    )
    ontology_records = build_ontology_table(rows)
    resized_root = tmp_path / "curated"
    labels_root = tmp_path / "labels"
    _write_sample_image(resized_root / "cls_0.jpg")

    first = export_classification_dataset(
        rows,
        ontology_records=ontology_records,
        resized_root=resized_root,
        labels_root=labels_root,
        output_root=tmp_path / "classification_a",
        label_map_root=tmp_path / "label_maps_a",
        model_name="surface_cls",
    )
    second = export_classification_dataset(
        rows,
        ontology_records=ontology_records,
        resized_root=resized_root,
        labels_root=labels_root,
        output_root=tmp_path / "classification_b",
        label_map_root=tmp_path / "label_maps_b",
        model_name="surface_cls",
    )

    first_manifest = json.loads(first.manifest_path.read_text(encoding="utf-8"))
    second_manifest = json.loads(second.manifest_path.read_text(encoding="utf-8"))

    for item in first_manifest + second_manifest:
        item["image_path"] = "<normalized>"
        item["label_path"] = "<normalized>"

    assert first_manifest == second_manifest
    assert first_manifest[0]["task_specific_model_class_id"] == 0
    assert first_manifest[0]["model_class_id"] == 0


def test_detection_export_excludes_taxonomy_review_candidates_by_default(tmp_path: Path) -> None:
    rows = normalize_rows(
        [
            {
                "file_name": "review_det.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "bbox",
                "width": 640,
                "height": 640,
                "zip_source": "TL_용접_용접불량_조인트.zip",
            }
        ],
        slugs_path=None,
    )
    ontology_records = build_ontology_table(rows)
    resized_root = tmp_path / "curated"
    labels_root = tmp_path / "labels"
    _write_sample_image(resized_root / "review_det.jpg")
    _write_sample_label_zip(
        labels_root / "TL_용접_용접불량_조인트.zip",
        {
            "review_det.json": (
                "review_det.jpg",
                {
                    "id": 1,
                    "image_id": 1,
                    "category_id": 11,
                    "bbox": [10, 20, 100, 80],
                    "area": 8000,
                },
                640,
                640,
            )
        },
    )

    result = export_detection_dataset(
        rows,
        ontology_records=ontology_records,
        resized_root=resized_root,
        labels_root=labels_root,
        output_root=tmp_path / "detection",
        label_map_root=tmp_path / "label_maps",
        model_name="surface_det",
    )

    assert result.report.blocked_images == 1
    assert result.report.exported_images == 0
    assert any(record.reason == "taxonomy_review_excluded_by_default" for record in result.records)
    assert result.manifest_path.exists()
    assert result.report_csv_path.exists()
    assert result.report_md_path.exists()
    assert result.label_map_path.exists()
