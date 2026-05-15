"""Runtime settings for Colab and local vision workflows."""

from __future__ import annotations

from dataclasses import dataclass, field

from vision.src.constants import (
    DEFAULT_BATCH_SIZE,
    DEFAULT_CLASS_NAMES,
    DEFAULT_CONFIDENCE_THRESHOLD,
    DEFAULT_DEVICE,
    DEFAULT_EPOCHS,
    DEFAULT_IMAGE_SIZE,
    DEFAULT_YOLO_MODEL,
)
from vision.src.paths import VisionPaths, build_default_paths


@dataclass(frozen=True)
class VisionRuntimeConfig:
    """Container for the values a notebook needs most often."""

    paths: VisionPaths = field(default_factory=build_default_paths)
    class_names: tuple[str, ...] = DEFAULT_CLASS_NAMES
    image_size: int = DEFAULT_IMAGE_SIZE
    batch_size: int = DEFAULT_BATCH_SIZE
    epochs: int = DEFAULT_EPOCHS
    confidence_threshold: float = DEFAULT_CONFIDENCE_THRESHOLD
    device: str = DEFAULT_DEVICE
    yolo_model: str = DEFAULT_YOLO_MODEL

    def as_dict(self) -> dict[str, object]:
        """Return a plain dictionary for notebook display or logging."""

        return {
            "repo_root": self.paths.repo_root,
            "vision_root": self.paths.vision_root,
            "raw_root": self.paths.raw_root,
            "resized_root": self.paths.resized_root,
            "drive_runs_root": self.paths.drive_runs_root,
            "class_names": self.class_names,
            "image_size": self.image_size,
            "batch_size": self.batch_size,
            "epochs": self.epochs,
            "confidence_threshold": self.confidence_threshold,
            "device": self.device,
            "yolo_model": self.yolo_model,
        }


def build_default_runtime_config() -> VisionRuntimeConfig:
    """Return the default runtime config used by the Colab workflow."""

    return VisionRuntimeConfig()


def build_segmentation_runtime_config() -> VisionRuntimeConfig:
    """Return a runtime config whose class_names are derived from the label map.

    build_task_label_map("segmentation") is the single source of truth for class
    ordering. Using this function instead of build_default_runtime_config() ensures
    the dataset yaml names and the label .txt class IDs stay in sync automatically.
    """

    from vision.src.data.label_maps import build_task_label_map

    label_map: dict[str, int] = build_task_label_map("segmentation")
    class_names = tuple(
        name for name, _ in sorted(label_map.items(), key=lambda x: x[1])
    )
    return VisionRuntimeConfig(class_names=class_names)
