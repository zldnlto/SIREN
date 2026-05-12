"""Image resizing helpers for Colab and local runs."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image


@dataclass(frozen=True)
class LetterboxResult:
    """Metadata describing the resized image."""

    original_size: tuple[int, int]
    resized_size: tuple[int, int]
    pad_left: int
    pad_top: int
    scale: float


def letterbox_image(
    image: Image.Image,
    target_size: int = 640,
    fill_color: tuple[int, int, int] = (114, 114, 114),
) -> tuple[Image.Image, LetterboxResult]:
    """Resize an image with padding so the aspect ratio stays intact.

    We keep this logic pure-ish so Colab notebooks can call it directly and
    the same code can later be reused in training or preprocessing scripts.
    """

    original_width, original_height = image.size
    if original_width == 0 or original_height == 0:
        raise ValueError("이미지 크기가 0이라 letterbox를 수행할 수 없습니다.")

    scale = min(target_size / original_width, target_size / original_height)
    resized_width = max(1, round(original_width * scale))
    resized_height = max(1, round(original_height * scale))
    resized = image.resize((resized_width, resized_height), Image.Resampling.BILINEAR)

    canvas = Image.new("RGB", (target_size, target_size), fill_color)
    pad_left = (target_size - resized_width) // 2
    pad_top = (target_size - resized_height) // 2
    canvas.paste(resized, (pad_left, pad_top))

    return canvas, LetterboxResult(
        original_size=(original_width, original_height),
        resized_size=(resized_width, resized_height),
        pad_left=pad_left,
        pad_top=pad_top,
        scale=scale,
    )


def resize_and_save_image(
    image_path: Path,
    output_path: Path,
    target_size: int = 640,
) -> LetterboxResult:
    """Resize one image and save it as a letterboxed RGB image."""

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(image_path) as image:
        canvas, result = letterbox_image(image.convert("RGB"), target_size=target_size)
        canvas.save(output_path)
        return result

