"""High-level preprocessing pipeline for Colab notebooks."""

from __future__ import annotations

from pathlib import Path

from vision.src.data.config import DEFAULT_YOLO_IMAGE_SIZE
from vision.src.data.images import resize_and_save_image
from vision.src.data.labels import (
    build_yolo_label_text,
    find_image_file,
    find_label_json_file,
)
from vision.src.data.manifest import ManifestItem


def _resolve_class_dirs(root: Path, class_name: str, split: str) -> tuple[Path, Path]:
    """Return the output directories for one class and split."""

    image_dir = root / class_name / "images" / split
    label_dir = root / class_name / "labels" / split
    image_dir.mkdir(parents=True, exist_ok=True)
    label_dir.mkdir(parents=True, exist_ok=True)
    return image_dir, label_dir


def prepare_curated_dataset(
    manifest: list[ManifestItem | dict],
    *,
    raw_root: Path,
    labels_root: Path,
    output_root: Path,
    target_size: int = DEFAULT_YOLO_IMAGE_SIZE,
) -> list[dict]:
    """Copy, resize, and convert samples into a YOLO-friendly layout.

    The function intentionally keeps the control flow explicit:
    - locate image
    - locate label JSON
    - resize image with letterbox padding
    - write YOLO label text
    This makes notebook debugging much easier when one sample fails.
    """

    results: list[dict] = []

    for item in manifest:
        sample = item if isinstance(item, dict) else item.__dict__
        class_name = f"{sample['defect_name']}_{sample['part_name']}"
        split = "train" if sample["split"] == "TL" else "val"
        image_dir, label_dir = _resolve_class_dirs(output_root, class_name, split)

        image_name = sample["file_name"]
        image_path = find_image_file(image_name, raw_root)
        if image_path is None:
            results.append({"file_name": image_name, "status": "skip", "reason": "이미지 없음"})
            continue

        label_json = find_label_json_file(image_name, sample["zip_source"], labels_root)
        if label_json is None:
            results.append({"file_name": image_name, "status": "skip", "reason": "라벨 JSON 없음"})
            continue

        label_text = build_yolo_label_text(
            label_json,
            int(sample["category_id"]),
            sample["label_type"],
            class_name=sample["defect_name"],
            image_size=target_size,
        )
        if label_text is None:
            results.append({"file_name": image_name, "status": "skip", "reason": "라벨 변환 실패"})
            continue

        image_stem = image_name.rsplit(".", 1)[0]
        output_image_path = image_dir / image_name
        output_label_path = label_dir / f"{image_stem}.txt"

        # Letterbox resize is the stable baseline for YOLOv8n-seg training.
        resize_and_save_image(image_path, output_image_path, target_size=target_size)
        output_label_path.write_text(label_text, encoding="utf-8")
        results.append({"file_name": image_name, "status": "ok", "reason": ""})

    return results
