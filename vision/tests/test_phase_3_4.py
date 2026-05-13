from __future__ import annotations

import json
import zipfile
from pathlib import Path

from PIL import Image

from vision.src.data import (
    build_ontology_table,
    normalize_rows,
)
from vision.src.data.classification_export import export_classification_dataset
from vision.src.data.detection_export import export_detection_dataset
from vision.src.data.segmentation_export import export_segmentation_dataset


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


def test_classification_export_uses_image_level_labels_only(tmp_path: Path) -> None:
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

    result = export_classification_dataset(
        rows,
        ontology_records=ontology_records,
        resized_root=resized_root,
        labels_root=labels_root,
        output_root=tmp_path / "classification",
        label_map_root=tmp_path / "label_maps",
        model_name="surface_cls",
    )

    assert result.report.exported_images == 1
    assert result.report.blocked_images == 0
    assert result.records[0].status == "exported"
    assert result.records[0].task_specific_model_class_id == 0
    assert Path(result.records[0].label_path).read_text(encoding="utf-8").strip() == "0"
    assert Path(result.records[0].image_path).exists()
    assert result.manifest_path.exists()
    assert result.report_csv_path.exists()
    assert result.report_md_path.exists()
    assert result.label_map_path.exists()
    manifest_rows = json.loads(result.manifest_path.read_text(encoding="utf-8"))
    assert manifest_rows[0]["task_specific_model_class_id"] == 0
    assert manifest_rows[0]["model_class_id"] == 0


def test_detection_export_skips_classification_only_and_uses_bbox_backed_rows(tmp_path: Path) -> None:
    rows = normalize_rows(
        [
            {
                "file_name": "cls_only.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "표면양품",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "classification",
                "width": 640,
                "height": 640,
                "zip_source": "TL_표면처리_표면양품_도장.zip",
            },
            {
                "file_name": "det_0.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "bbox",
                "width": 640,
                "height": 640,
                "zip_source": "TL_표면처리_균열_도장.zip",
            },
            {
                "file_name": "seg_0.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "segmentation+bbox",
                "width": 640,
                "height": 640,
                "zip_source": "TL_표면처리_균열_도장.zip",
            },
        ],
        slugs_path=None,
    )
    ontology_records = build_ontology_table(rows)
    resized_root = tmp_path / "curated"
    labels_root = tmp_path / "labels"
    _write_sample_image(resized_root / "cls_only.jpg")
    _write_sample_image(resized_root / "det_0.jpg")
    _write_sample_image(resized_root / "seg_0.jpg")
    _write_sample_label_zip(
        labels_root / "TL_표면처리_균열_도장.zip",
        {
            "det_0.json": (
                "det_0.jpg",
                {
                    "id": 1,
                    "image_id": 1,
                    "category_id": 25,
                    "bbox": [10, 20, 100, 80],
                    "segmentation": [[10, 20, 110, 20, 110, 100, 10, 100]],
                    "area": 8000,
                },
                640,
                640,
            ),
            "seg_0.json": (
                "seg_0.jpg",
                {
                    "id": 1,
                    "image_id": 1,
                    "category_id": 25,
                    "bbox": [10, 20, 100, 80],
                    "segmentation": [[10, 20, 110, 20, 110, 100, 10, 100]],
                    "area": 8000,
                },
                640,
                640,
            ),
        },
    )
    _write_sample_label_zip(
        labels_root / "TL_표면처리_표면양품_도장.zip",
        {
            "cls_only.json": (
                "cls_only.jpg",
                {
                    "id": 1,
                    "image_id": 1,
                    "category_id": 25,
                    "bbox": [0, 0, 10, 10],
                    "area": 100,
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

    exported = [record for record in result.records if record.status == "exported"]
    assert result.report.exported_images == 2
    assert result.report.exported_labels >= 2
    assert all(record.file_name != "cls_only.jpg" for record in exported)
    assert any(record.file_name == "det_0.jpg" for record in exported)
    assert any(record.file_name == "seg_0.jpg" for record in exported)
    assert all(record.task_specific_model_class_id >= 0 for record in exported)
    assert result.manifest_path.exists()
    assert result.report_csv_path.exists()
    assert result.report_md_path.exists()
    assert result.label_map_path.exists()


def test_segmentation_export_uses_polygon_geometry_only_and_rejects_bbox_only_rows(tmp_path: Path) -> None:
    rows = normalize_rows(
        [
            {
                "file_name": "bbox_only.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "bbox",
                "width": 640,
                "height": 640,
                "zip_source": "TL_표면처리_균열_도장.zip",
            },
            {
                "file_name": "seg_only.jpg",
                "split": "TL",
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "segmentation+bbox",
                "width": 640,
                "height": 640,
                "zip_source": "TL_표면처리_균열_도장.zip",
            },
        ],
        slugs_path=None,
    )
    ontology_records = build_ontology_table(rows)
    resized_root = tmp_path / "curated"
    labels_root = tmp_path / "labels"
    _write_sample_image(resized_root / "bbox_only.jpg")
    _write_sample_image(resized_root / "seg_only.jpg")
    _write_sample_label_zip(
        labels_root / "TL_표면처리_균열_도장.zip",
        {
            "seg_only.json": (
                "seg_only.jpg",
                {
                    "id": 1,
                    "image_id": 1,
                    "category_id": 25,
                    "bbox": [10, 20, 100, 80],
                    "segmentation": [[10, 20, 110, 20, 110, 100, 10, 100]],
                    "area": 8000,
                },
                640,
                640,
            ),
            "bbox_only.json": (
                "bbox_only.jpg",
                {
                    "id": 1,
                    "image_id": 1,
                    "category_id": 25,
                    "bbox": [10, 20, 100, 80],
                    "area": 8000,
                },
                640,
                640,
            ),
        },
    )

    result = export_segmentation_dataset(
        rows,
        ontology_records=ontology_records,
        resized_root=resized_root,
        labels_root=labels_root,
        output_root=tmp_path / "segmentation",
        label_map_root=tmp_path / "label_maps",
        model_name="surface_seg",
    )

    exported = [record for record in result.records if record.status == "exported"]
    assert result.report.exported_images == 1
    assert result.report.exported_labels >= 1
    assert all(record.file_name != "bbox_only.jpg" for record in exported)
    assert any(record.file_name == "seg_only.jpg" for record in exported)
    assert all(record.task_specific_model_class_id >= 0 for record in exported)
    assert result.manifest_path.exists()
    assert result.report_csv_path.exists()
    assert result.report_md_path.exists()
    assert result.label_map_path.exists()
