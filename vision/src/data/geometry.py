"""Geometry helpers for original-image to YOLO coordinate transforms."""

from __future__ import annotations

from dataclasses import dataclass
from typing import Sequence


@dataclass(frozen=True)
class GeometrySourceContract:
    """Document where geometry is expected to live."""

    bbox_source: str
    segmentation_source: str
    original_dimension_source: str
    resize_method: str
    coordinate_space: str
    target_width: int
    target_height: int


@dataclass(frozen=True)
class LetterboxTransform:
    """Map original-image coordinates into a resized letterbox canvas."""

    original_width: int
    original_height: int
    target_width: int
    target_height: int
    scale: float
    resized_width: int
    resized_height: int
    pad_left: int
    pad_top: int


@dataclass(frozen=True)
class ClippingEvent:
    """Record that coordinate clipping occurred during normalization."""

    kind: str
    before: tuple[float, ...]
    after: tuple[float, ...]


DEFAULT_GEOMETRY_SOURCE_CONTRACT = GeometrySourceContract(
    bbox_source="COCO JSON annotations[].bbox",
    segmentation_source="COCO JSON annotations[].segmentation",
    original_dimension_source="COCO JSON images[].width / images[].height",
    resize_method="letterbox",
    coordinate_space="original-image",
    target_width=640,
    target_height=640,
)


def build_letterbox_transform(
    original_width: int,
    original_height: int,
    *,
    target_width: int = 640,
    target_height: int = 640,
) -> LetterboxTransform:
    """Return the letterbox transform for one original image size."""

    if original_width <= 0 or original_height <= 0:
        raise ValueError("원본 이미지 크기가 0 이하라 transform을 계산할 수 없습니다.")

    scale = min(target_width / original_width, target_height / original_height)
    resized_width = max(1, round(original_width * scale))
    resized_height = max(1, round(original_height * scale))
    pad_left = (target_width - resized_width) // 2
    pad_top = (target_height - resized_height) // 2
    return LetterboxTransform(
        original_width=original_width,
        original_height=original_height,
        target_width=target_width,
        target_height=target_height,
        scale=scale,
        resized_width=resized_width,
        resized_height=resized_height,
        pad_left=pad_left,
        pad_top=pad_top,
    )


def _clip(value: float, lower: float, upper: float) -> float:
    return max(lower, min(upper, value))


def clip_xyxy(
    x1: float,
    y1: float,
    x2: float,
    y2: float,
    *,
    max_width: int,
    max_height: int,
) -> tuple[tuple[float, float, float, float], ClippingEvent | None]:
    """Clip a bounding box into the image bounds."""

    before = (x1, y1, x2, y2)
    after = (
        _clip(x1, 0.0, float(max_width)),
        _clip(y1, 0.0, float(max_height)),
        _clip(x2, 0.0, float(max_width)),
        _clip(y2, 0.0, float(max_height)),
    )
    event = ClippingEvent("bbox", before, after) if before != after else None
    return after, event


def scale_point(point_x: float, point_y: float, transform: LetterboxTransform) -> tuple[float, float]:
    """Scale one original-image point into letterbox coordinates."""

    return (
        point_x * transform.scale + transform.pad_left,
        point_y * transform.scale + transform.pad_top,
    )


def scale_bbox_xywh(
    bbox_xywh: Sequence[float],
    transform: LetterboxTransform,
) -> tuple[float, float, float, float]:
    """Scale a COCO xywh bbox into letterbox coordinates."""

    x, y, width, height = bbox_xywh
    x1, y1 = scale_point(x, y, transform)
    x2, y2 = scale_point(x + width, y + height, transform)
    return (x1, y1, x2 - x1, y2 - y1)


def scale_polygon(
    polygon: Sequence[float],
    transform: LetterboxTransform,
) -> list[float]:
    """Scale a flattened polygon into letterbox coordinates."""

    scaled: list[float] = []
    for index in range(0, len(polygon), 2):
        point_x, point_y = scale_point(float(polygon[index]), float(polygon[index + 1]), transform)
        scaled.extend([point_x, point_y])
    return scaled


def polygon_to_bbox_xywh(polygon: Sequence[float]) -> tuple[float, float, float, float]:
    """Derive a bbox from one flattened polygon."""

    xs = list(map(float, polygon[0::2]))
    ys = list(map(float, polygon[1::2]))
    if not xs or not ys:
        raise ValueError("polygon이 비어 있어 bbox를 만들 수 없습니다.")
    x1, x2 = min(xs), max(xs)
    y1, y2 = min(ys), max(ys)
    return (x1, y1, x2 - x1, y2 - y1)


def bbox_xywh_to_yolo(
    bbox_xywh: Sequence[float],
    transform: LetterboxTransform,
) -> tuple[float, float, float, float]:
    """Convert a letterbox-space bbox to YOLO normalized xywh."""

    x, y, width, height = bbox_xywh
    center_x = (x + width / 2) / transform.target_width
    center_y = (y + height / 2) / transform.target_height
    return (
        center_x,
        center_y,
        width / transform.target_width,
        height / transform.target_height,
    )


def polygon_to_yolo(
    polygon: Sequence[float],
    transform: LetterboxTransform,
) -> list[float]:
    """Convert a letterbox-space polygon to YOLO normalized points."""

    normalized: list[float] = []
    for index in range(0, len(polygon), 2):
        normalized.append(float(polygon[index]) / transform.target_width)
        normalized.append(float(polygon[index + 1]) / transform.target_height)
    return normalized


def bbox_and_polygon_from_mask(
    polygon: Sequence[float],
    transform: LetterboxTransform,
) -> tuple[tuple[float, float, float, float], list[float]]:
    """Return both bbox and polygon in letterbox coordinates."""

    scaled_polygon = scale_polygon(polygon, transform)
    return polygon_to_bbox_xywh(scaled_polygon), scaled_polygon
