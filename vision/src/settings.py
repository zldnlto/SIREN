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


def build_segmentation_runtime_config(
    ontology_records: object = None,
    *,
    model_name: str = "surface_seg",
) -> VisionRuntimeConfig:
    """Return a runtime config with class_names for segmentation training.

    ontology_records를 넘기면 build_task_label_map()으로 class_names를 파생한다.
    이 경우 label map 순서와 완전히 동기화됨이 보장된다.
    ontology_records가 없으면 DEFAULT_CLASS_NAMES를 사용한다.

    Colab에서 권장 사용법:
        records = build_ontology_table(...)
        runtime = build_segmentation_runtime_config(records)
        train_yolo_segmentation(runtime=runtime, ontology_records=records, ...)
    """
    if ontology_records is not None:
        try:
            from vision.src.data.label_maps import build_task_label_map

            label_map_records = build_task_label_map(
                ontology_records, model_name=model_name, task_type="segment"
            )
            class_names = tuple(
                rec.canonical_class_name
                for rec in sorted(
                    label_map_records, key=lambda r: r.task_specific_model_class_id
                )
            )
            return VisionRuntimeConfig(class_names=class_names)
        except Exception:  # noqa: BLE001
            pass
    return VisionRuntimeConfig(class_names=DEFAULT_CLASS_NAMES)
