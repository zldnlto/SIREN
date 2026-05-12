"""SIREN vision package.

Colab can add the repo root to ``sys.path`` and import from here directly.
This module keeps the top-level entry point small and stable.
"""

from vision.src.bootstrap import build_default_runtime_config
from vision.src.constants import DEFAULT_CLASS_NAMES
from vision.src.data import (
    DataConfig,
    ManifestItem,
    build_default_data_config,
    build_sample_manifest,
    build_yolo_label_text,
    letterbox_image,
    load_dataset_index,
    load_manifest,
    prepare_curated_dataset,
    resize_and_save_image,
    save_manifest,
)
from vision.src.paths import VisionPaths, build_default_paths
from vision.src.settings import VisionRuntimeConfig

__all__ = [
    "DEFAULT_CLASS_NAMES",
    "DataConfig",
    "ManifestItem",
    "VisionPaths",
    "VisionRuntimeConfig",
    "build_default_paths",
    "build_default_data_config",
    "build_sample_manifest",
    "build_default_runtime_config",
    "build_yolo_label_text",
    "letterbox_image",
    "load_dataset_index",
    "load_manifest",
    "prepare_curated_dataset",
    "resize_and_save_image",
    "save_manifest",
]
