"""One-line bootstrap helpers for notebook entry points."""

from __future__ import annotations

from vision.src.settings import (
    VisionRuntimeConfig,
    build_default_runtime_config,
    build_segmentation_runtime_config,
)

__all__ = [
    "VisionRuntimeConfig",
    "build_default_runtime_config",
    "build_segmentation_runtime_config",
]
