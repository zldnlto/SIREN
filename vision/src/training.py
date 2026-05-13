"""YOLOv8n-seg training and evaluation helpers for Colab.

The notebook should stay thin: build a run config here, point it at the
curated dataset, and keep the mutable output paths in one place.
"""

from __future__ import annotations

from collections.abc import Callable, Sequence
from dataclasses import dataclass
from pathlib import Path
from shutil import copy2
from typing import Any, Mapping

from vision.src.constants import DEFAULT_YOLO_MODEL
from vision.src.data.labels import DEFECT_CLASSES
from vision.src.settings import VisionRuntimeConfig, build_default_runtime_config

try:  # pragma: no cover - ultralytics is optional in the test environment
    from ultralytics import YOLO as _ULTRALYTICS_YOLO
except ImportError:  # pragma: no cover - keep imports working without the wheel
    _ULTRALYTICS_YOLO = None


@dataclass(frozen=True)
class TrainingArtifacts:
    """Paths that move together during one Colab training run."""

    run_name: str
    curated_root: Path
    data_yaml_path: Path
    local_run_dir: Path
    local_weights_dir: Path
    drive_run_dir: Path
    drive_weights_dir: Path
    class_names: tuple[str, ...]

    @property
    def best_weight_path(self) -> Path:
        """Return the local best weight path produced by Ultralytics."""

        return self.local_weights_dir / "best.pt"

    @property
    def drive_best_weight_path(self) -> Path:
        """Return the mirrored Drive best weight path."""

        return self.drive_weights_dir / "best.pt"

    @property
    def serving_weight_path(self) -> Path:
        """Return the preferred path for FastAPI to load.

        We prefer the Drive copy because Colab sessions are ephemeral, but
        fall back to the local run folder when Drive has not been mirrored yet.
        """

        if self.drive_best_weight_path.exists():
            return self.drive_best_weight_path
        return self.best_weight_path


@dataclass(frozen=True)
class TrainingRunResult:
    """Return value for one train/eval cycle."""

    artifacts: TrainingArtifacts
    train_result: Any
    best_weight_path: Path
    drive_best_weight_path: Path | None


def _resolve_yolo_factory(
    yolo_factory: Callable[[str], Any] | None,
) -> Callable[[str], Any]:
    """Return a YOLO constructor that works in tests and Colab."""

    if yolo_factory is not None:
        return yolo_factory
    if _ULTRALYTICS_YOLO is None:
        raise RuntimeError(
            "ultralytics 패키지가 설치되지 않았습니다. Colab에서 `pip install ultralytics` 후 실행하세요."
        )
    return _ULTRALYTICS_YOLO


def build_training_artifacts(
    runtime: VisionRuntimeConfig | None = None,
    *,
    run_name: str,
    curated_root: Path | None = None,
    class_names: Sequence[str] | None = None,
) -> TrainingArtifacts:
    """Create the local and Drive output layout for one training run."""

    runtime = runtime or build_default_runtime_config()
    curated_root = curated_root or runtime.paths.resized_root
    class_names = tuple(class_names or runtime.class_names)

    local_run_dir = runtime.paths.runs_root / run_name
    drive_run_dir = runtime.paths.drive_run_dir(run_name)
    local_weights_dir = local_run_dir / "weights"
    drive_weights_dir = drive_run_dir / "weights"
    data_yaml_path = local_run_dir / "dataset.yaml"

    for path in (local_run_dir, local_weights_dir, drive_run_dir, drive_weights_dir):
        path.mkdir(parents=True, exist_ok=True)

    return TrainingArtifacts(
        run_name=run_name,
        curated_root=curated_root,
        data_yaml_path=data_yaml_path,
        local_run_dir=local_run_dir,
        local_weights_dir=local_weights_dir,
        drive_run_dir=drive_run_dir,
        drive_weights_dir=drive_weights_dir,
        class_names=class_names,
    )


def _resolve_image_dirs(curated_root: Path, class_names: Sequence[str], split: str) -> list[Path]:
    """Return curated image directories that actually exist.

    The curated dataset keeps each class in its own folder, so YOLO gets a list
    of image roots rather than one flattened directory.
    """

    image_dirs = [
        curated_root / class_name / "images" / split
        for class_name in class_names
        if (curated_root / class_name / "images" / split).exists()
    ]
    if not image_dirs:
        raise FileNotFoundError(
            f"curated_root={curated_root}에서 split={split} 이미지 디렉터리를 찾지 못했습니다."
        )
    return image_dirs


def build_yolo_dataset_yaml_text(
    curated_root: Path,
    class_names: Sequence[str] = DEFECT_CLASSES,
) -> str:
    """Build a YOLO dataset yaml string for the per-class curated layout."""

    train_dirs = _resolve_image_dirs(curated_root, class_names, "train")
    val_dirs = _resolve_image_dirs(curated_root, class_names, "val")

    lines = [
        f"path: {curated_root}",
        "train:",
    ]
    lines.extend(f"  - {path}" for path in train_dirs)
    lines.append("val:")
    lines.extend(f"  - {path}" for path in val_dirs)
    lines.append("names:")
    lines.extend(f"  {index}: {class_name}" for index, class_name in enumerate(class_names))
    lines.append("")
    return "\n".join(lines)


def write_yolo_dataset_yaml(artifacts: TrainingArtifacts) -> Path:
    """Write the dataset yaml next to the run outputs."""

    yaml_text = build_yolo_dataset_yaml_text(artifacts.curated_root, artifacts.class_names)
    artifacts.data_yaml_path.write_text(yaml_text, encoding="utf-8")
    return artifacts.data_yaml_path


def _extract_save_dir(train_result: Any, fallback_dir: Path) -> Path:
    """Resolve the Ultralytics save directory from a result object."""

    if isinstance(train_result, Mapping):
        save_dir = train_result.get("save_dir")
    else:
        save_dir = getattr(train_result, "save_dir", None)
    if save_dir:
        return Path(save_dir)
    return fallback_dir


def _resolve_best_weight_path(train_result: Any, artifacts: TrainingArtifacts) -> Path:
    """Resolve the best.pt path produced by Ultralytics.

    The returned path is used both for local verification and for Drive mirroring.
    """

    save_dir = _extract_save_dir(train_result, artifacts.local_run_dir)
    candidate = save_dir / "weights" / "best.pt"
    if candidate.exists():
        return candidate
    if artifacts.best_weight_path.exists():
        return artifacts.best_weight_path
    raise FileNotFoundError(
        f"best.pt를 찾지 못했습니다. 확인한 경로: {candidate} / {artifacts.best_weight_path}"
    )


def sync_best_weight_to_drive(
    artifacts: TrainingArtifacts,
    best_weight_path: Path | None = None,
) -> Path | None:
    """Mirror best.pt to Drive so the FastAPI server can load it later."""

    source = best_weight_path or artifacts.best_weight_path
    if not source.exists():
        return None
    artifacts.drive_weights_dir.mkdir(parents=True, exist_ok=True)
    copy2(source, artifacts.drive_best_weight_path)
    return artifacts.drive_best_weight_path


def train_yolo_segmentation(
    runtime: VisionRuntimeConfig | None = None,
    *,
    run_name: str,
    curated_root: Path | None = None,
    class_names: Sequence[str] | None = None,
    model_source: str | Path | None = None,
    yolo_factory: Callable[[str], Any] | None = None,
) -> TrainingRunResult:
    """Train YOLOv8n-seg and mirror best.pt to Drive.

    The function keeps the run layout explicit so Colab notebooks only have to
    mount Drive, point at the curated dataset, and call one helper.
    """

    runtime = runtime or build_default_runtime_config()
    class_names = tuple(class_names or runtime.class_names)
    artifacts = build_training_artifacts(
        runtime,
        run_name=run_name,
        curated_root=curated_root,
        class_names=class_names,
    )
    write_yolo_dataset_yaml(artifacts)

    yolo_cls = _resolve_yolo_factory(yolo_factory)
    model = yolo_cls(str(model_source or runtime.yolo_model or DEFAULT_YOLO_MODEL))
    train_result = model.train(
        data=str(artifacts.data_yaml_path),
        imgsz=runtime.image_size,
        batch=runtime.batch_size,
        epochs=runtime.epochs,
        device=runtime.device,
        project=str(runtime.paths.runs_root),
        name=run_name,
        exist_ok=True,
        save=True,
    )

    best_weight_path = _resolve_best_weight_path(train_result, artifacts)
    mirrored_path = sync_best_weight_to_drive(artifacts, best_weight_path)
    return TrainingRunResult(
        artifacts=artifacts,
        train_result=train_result,
        best_weight_path=best_weight_path,
        drive_best_weight_path=mirrored_path,
    )


def evaluate_yolo_segmentation(
    weights_path: Path,
    data_yaml_path: Path,
    runtime: VisionRuntimeConfig | None = None,
    *,
    yolo_factory: Callable[[str], Any] | None = None,
) -> Any:
    """Run YOLO validation for a saved weight file."""

    runtime = runtime or build_default_runtime_config()
    yolo_cls = _resolve_yolo_factory(yolo_factory)
    model = yolo_cls(str(weights_path))
    return model.val(
        data=str(data_yaml_path),
        imgsz=runtime.image_size,
        device=runtime.device,
    )
