from __future__ import annotations

import csv
import json
import zipfile
from pathlib import Path

from PIL import Image

from vision.src.data import (
    build_sample_manifest,
    letterbox_image,
    parse_zip_name,
    prepare_curated_dataset,
)


def _write_sample_csv(path: Path) -> None:
    rows = [
        {
            "file_name": "sample_a.jpg",
            "zip_source": "TL_표면처리_균열_도장.zip",
            "domain": "표면처리",
            "defect_name": "균열",
            "part_name": "도장",
            "category_id": "25",
            "label_type": "segmentation+bbox",
            "split": "TL",
        },
        {
            "file_name": "sample_b.jpg",
            "zip_source": "VL_표면처리_균열_도장.zip",
            "domain": "표면처리",
            "defect_name": "균열",
            "part_name": "도장",
            "category_id": "25",
            "label_type": "segmentation+bbox",
            "split": "VL",
        },
        {
            "file_name": "ignore.jpg",
            "zip_source": "TL_케이블_케이블설치불량_케이블타이.zip",
            "domain": "케이블",
            "defect_name": "케이블설치불량",
            "part_name": "케이블타이",
            "category_id": "13",
            "label_type": "bbox",
            "split": "TL",
        },
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(
            handle,
            fieldnames=[
                "file_name",
                "zip_source",
                "domain",
                "defect_name",
                "part_name",
                "category_id",
                "label_type",
                "split",
            ],
        )
        writer.writeheader()
        writer.writerows(rows)


def _write_sample_image(path: Path, size: tuple[int, int] = (100, 50)) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image = Image.new("RGB", size, (255, 0, 0))
    image.save(path)


def _write_sample_label_zip(path: Path, json_name: str, image_name: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "images": [
            {
                "id": 1,
                "file_name": image_name,
                "width": 100,
                "height": 50,
                "date_captured": "2024-01-01",
            }
        ],
        "annotations": [
            {
                "id": 1,
                "image_id": 1,
                "category_id": 25,
                "segmentation": [[10, 10, 40, 10, 40, 30, 10, 30]],
                "bbox": [10, 10, 30, 20],
                "area": 600,
            }
        ],
    }
    with zipfile.ZipFile(path, "w") as zf:
        zf.writestr(json_name, json.dumps(payload, ensure_ascii=False))


def test_parse_zip_name_keeps_file_name() -> None:
    parsed = parse_zip_name("TL_표면처리_균열_도장.zip")

    assert parsed["zip_name"] == "TL_표면처리_균열_도장.zip"
    assert parsed["split"] == "TL"
    assert parsed["domain"] == "표면처리"
    assert parsed["defect_name"] == "균열"
    assert parsed["part_name"] == "도장"


def test_build_sample_manifest_filters_and_splits(tmp_path: Path) -> None:
    index_path = tmp_path / "dataset_index.csv"
    _write_sample_csv(index_path)

    manifest, stats = build_sample_manifest(
        index_path=index_path,
        train_samples_per_class=1,
        val_samples_per_class=1,
        seed=7,
    )

    assert len(manifest) == 2
    assert {item.split for item in manifest} == {"TL", "VL"}
    assert all(item.domain == "표면처리" for item in manifest)
    assert len(stats) == 2


def test_prepare_curated_dataset_writes_resized_image_and_label(tmp_path: Path) -> None:
    raw_root = tmp_path / "raw"
    labels_root = tmp_path / "labels"
    output_root = tmp_path / "resized"

    image_name = "sample_a.jpg"
    zip_name = "TL_표면처리_균열_도장.zip"
    _write_sample_image(raw_root / "cluster" / image_name)
    _write_sample_label_zip(labels_root / zip_name, "sample_a.json", image_name)

    results = prepare_curated_dataset(
        [
            {
                "file_name": image_name,
                "zip_source": zip_name,
                "domain": "표면처리",
                "defect_name": "균열",
                "part_name": "도장",
                "category_id": 25,
                "label_type": "segmentation+bbox",
                "split": "TL",
            }
        ],
        raw_root=raw_root,
        labels_root=labels_root,
        output_root=output_root,
        target_size=640,
    )

    output_image = output_root / "균열_도장" / "images" / "train" / image_name
    output_label = output_root / "균열_도장" / "labels" / "train" / "sample_a.txt"

    assert results == [{"file_name": image_name, "status": "ok", "reason": ""}]
    assert output_image.exists()
    assert output_label.exists()

    with Image.open(output_image) as resized:
        assert resized.size == (640, 640)

    assert output_label.read_text(encoding="utf-8").startswith("25 ")


def test_letterbox_image_preserves_aspect_ratio() -> None:
    image = Image.new("RGB", (120, 60), (0, 255, 0))

    canvas, result = letterbox_image(image, target_size=640)

    assert canvas.size == (640, 640)
    assert result.original_size == (120, 60)
    assert result.resized_size[0] >= result.resized_size[1]
    assert result.scale > 0
