"""Label parsing and conversion helpers.

The functions here stay pure where possible so notebooks can call them
directly, while I/O is kept at the edges.
"""

from __future__ import annotations

import json
import unicodedata
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from vision.src.data.config import DEFAULT_YOLO_IMAGE_SIZE, SourceKeyMap

DEFECT_CLASSES: tuple[str, ...] = (
    "균열",
    "스크래치",
    "도장흐름",
    "도막떨어짐",
    "도막분리",
    "보온재손상",
    "탱크클리닝불량",
    "표면양품",
)

CLS_ONLY_CODES = {6, 7}

DOMAIN_CODES: dict[str, int] = {
    "표면처리": 25,
    "용접": 11,
    "절단": 12,
    "케이블": 13,
    "파이프": 14,
    "폼스프레이": 15,
}


@dataclass(frozen=True)
class CocoRow:
    """A single annotation row extracted from a COCO JSON file."""

    file_name: str
    split: str
    domain: str
    defect_name: str
    part_name: str
    category_id: int
    label_type: str
    width: int
    height: int
    date_captured: str
    area: float | int | str
    zip_source: str


def parse_zip_name(zip_name: str) -> dict[str, str]:
    """Parse `TL_표면처리_균열_도장.zip` into its parts."""

    stem = unicodedata.normalize("NFC", zip_name).replace(".zip", "")
    parts = stem.split("_", 3)
    return {
        "zip_name": zip_name,
        "split": parts[0] if len(parts) > 0 else "",
        "domain": parts[1] if len(parts) > 1 else "",
        "defect_name": parts[2] if len(parts) > 2 else "",
        "part_name": parts[3] if len(parts) > 3 else "",
    }


def detect_label_type(annotation: dict[str, Any]) -> str:
    """Infer the annotation type from one COCO annotation."""

    has_seg = bool(annotation.get("segmentation"))
    has_bbox = bool(annotation.get("bbox"))
    if has_seg and has_bbox:
        return "segmentation+bbox"
    if has_seg:
        return "segmentation"
    if has_bbox:
        return "bbox"
    return "classification"


def get_source_key(zip_source: str) -> str:
    """Return the AI Hub source key for a zip file name."""

    source_name = zip_source.replace(".zip", "")
    return SourceKeyMap.get(source_name, "")


def parse_coco_rows(data: dict[str, Any], zip_info: dict[str, str]) -> list[CocoRow]:
    """Convert a COCO JSON payload into flat rows for sampling."""

    rows: list[CocoRow] = []
    annotations = data.get("annotations", [])
    images = data.get("images", [])
    image_map = {img["id"]: img for img in images}

    for annotation in annotations:
        image_id = annotation.get("image_id")
        category_id = annotation.get("category_id")
        image = image_map.get(image_id, {})
        domain = zip_info["domain"]
        defect_name = zip_info["defect_name"]

        rows.append(
            CocoRow(
                file_name=image.get("file_name", ""),
                split=zip_info["split"],
                domain=domain,
                defect_name=defect_name,
                part_name=zip_info["part_name"],
                category_id=int(category_id or 0),
                label_type=detect_label_type(annotation),
                width=int(image.get("width", 0) or 0),
                height=int(image.get("height", 0) or 0),
                date_captured=image.get("date_captured", ""),
                area=annotation.get("area", ""),
                zip_source=zip_info.get("zip_name", ""),
            )
        )

    return rows


def find_image_file(file_name: str, raw_root: Path) -> Path | None:
    """Find an image file by exact or upper-case extension match."""

    matches = list(raw_root.rglob(file_name))
    if matches:
        return matches[0]
    alt = file_name.replace(".jpg", ".JPG")
    matches = list(raw_root.rglob(alt))
    return matches[0] if matches else None


def find_label_json_file(file_name: str, zip_source: str, labels_root: Path) -> dict | None:
    """Find and load the JSON file for one image sample."""

    zip_name = unicodedata.normalize("NFC", zip_source)
    matches = [
        path
        for path in labels_root.rglob("*.zip")
        if unicodedata.normalize("NFC", path.name) == zip_name
    ]
    if not matches:
        return None

    stem = file_name.rsplit(".", 1)[0]
    json_name = stem + ".json"

    import zipfile

    with zipfile.ZipFile(matches[0], "r") as zf:
        candidates = [name for name in zf.namelist() if name.endswith(json_name)]
        if not candidates:
            return None
        with zf.open(candidates[0]) as handle:
            return json.load(handle)


def _normalize_segmentation(segmentation: Any) -> list[float]:
    """Flatten the first COCO segmentation polygon into a point list."""

    if not segmentation:
        return []
    first = segmentation[0] if isinstance(segmentation[0], list) else segmentation
    return list(first)


def coco_to_yolo_segmentation(
    annotation: dict[str, Any], image_width: int, image_height: int, yolo_class_id: int
) -> str | None:
    """Convert COCO segmentation to one YOLO segmentation line."""

    points = _normalize_segmentation(annotation.get("segmentation", []))
    if len(points) < 6:
        return None

    normalized: list[str] = []
    for index in range(0, len(points) - 1, 2):
        normalized.append(f"{points[index] / image_width:.6f}")
        normalized.append(f"{points[index + 1] / image_height:.6f}")
    return f"{yolo_class_id} " + " ".join(normalized)


def coco_to_yolo_bbox(
    annotation: dict[str, Any], image_width: int, image_height: int, yolo_class_id: int
) -> str | None:
    """Convert COCO bbox to one YOLO detection line."""

    bbox = annotation.get("bbox", [])
    if not bbox:
        return None

    x, y, width, height = bbox
    center_x = (x + width / 2) / image_width
    center_y = (y + height / 2) / image_height
    return (
        f"{yolo_class_id} "
        f"{center_x:.6f} {center_y:.6f} "
        f"{width / image_width:.6f} {height / image_height:.6f}"
    )


def build_yolo_label_text(
    json_data: dict[str, Any],
    category_id: int,
    label_type: str,
    *,
    image_size: int = DEFAULT_YOLO_IMAGE_SIZE,
) -> str | None:
    """Build the label text for one image.

    Classification-only classes still emit a single YOLO line so the
    downstream pipeline can keep the same file naming convention.
    """

    annotations = json_data.get("annotations", [])
    images = json_data.get("images", [])
    if not images or not annotations:
        return None

    image = images[0]
    image_width = int(image.get("width", image_size) or image_size)
    image_height = int(image.get("height", image_size) or image_size)
    annotation = annotations[0]
    yolo_class_id = int(category_id)

    if label_type == "segmentation+bbox":
        return coco_to_yolo_segmentation(annotation, image_width, image_height, yolo_class_id)
    if label_type == "bbox":
        return coco_to_yolo_bbox(annotation, image_width, image_height, yolo_class_id)
    return f"{yolo_class_id} 0.5 0.5 1.0 1.0"
