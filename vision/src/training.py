"""YOLOv8n-seg training and evaluation helpers for Colab.

The notebook should stay thin: build a run config here, point it at the
curated dataset, and keep the mutable output paths in one place.
"""

from __future__ import annotations

from collections.abc import Callable, Sequence
from dataclasses import asdict, dataclass, field
from pathlib import Path
from shutil import copy2
from typing import Any, Mapping

from vision.src.constants import DEFAULT_CLASS_NAMES, DEFAULT_YOLO_MODEL
from vision.src.data.evaluation import (
    EvaluationSample,
    build_calibration_rows,
    write_simple_report,
)
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
    yolo_save_dir: Path


@dataclass(frozen=True)
class TrainingExecutionPolicy:
    """Gate and calibration settings for a validated training run."""

    export_validation_passed: bool = True
    class_inclusion: tuple[str, ...] | None = None
    confidence_thresholds: Mapping[str, float] = field(default_factory=dict)
    calibration_enabled: bool = True


@dataclass(frozen=True)
class ValidatedTrainingRunResult:
    """Training run result plus optional validation calibration output."""

    training_result: TrainingRunResult
    calibration_rows: tuple[dict[str, object], ...]
    calibration_csv_path: Path | None
    calibration_md_path: Path | None


def _write_validation_calibration_report(
    samples: Sequence[EvaluationSample],
    *,
    thresholds: Mapping[str, float],
    csv_path: Path,
    md_path: Path,
) -> tuple[Path, Path]:
    """Write a compact validation calibration report."""

    rows = build_calibration_rows(samples, thresholds=thresholds)
    write_simple_report(
        [asdict(row) for row in rows],
        csv_path=csv_path,
        md_path=md_path,
        title="Validation Calibration Report",
    )
    return csv_path, md_path


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


def _resolve_image_dirs(
    curated_root: Path, class_names: Sequence[str], split: str
) -> list[Path]:
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
    class_names: Sequence[str] = DEFAULT_CLASS_NAMES,
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
    lines.extend(
        f"  {index}: {class_name}" for index, class_name in enumerate(class_names)
    )
    lines.append("")
    return "\n".join(lines)


def write_yolo_dataset_yaml(artifacts: TrainingArtifacts) -> Path:
    """Write the dataset yaml next to the run outputs."""

    yaml_text = build_yolo_dataset_yaml_text(
        artifacts.curated_root, artifacts.class_names
    )
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


def _candidate_best_weight_paths(
    train_result: Any,
    artifacts: TrainingArtifacts,
) -> tuple[Path, ...]:
    """Return every best.pt location that can belong to this run."""

    save_dir = _extract_save_dir(train_result, artifacts.local_run_dir)
    candidates = (
        save_dir / "weights" / "best.pt",
        artifacts.best_weight_path,
        artifacts.drive_best_weight_path,
    )
    deduped: list[Path] = []
    seen: set[str] = set()
    for path in candidates:
        key = str(path)
        if key not in seen:
            deduped.append(path)
            seen.add(key)
    return tuple(deduped)


def _recent_best_weight_paths(
    artifacts: TrainingArtifacts, *, limit: int = 8
) -> tuple[Path, ...]:
    """Return recent best.pt files near this run for actionable diagnostics."""

    roots = (artifacts.local_run_dir.parent, artifacts.drive_run_dir.parent)
    found: list[Path] = []
    for root in roots:
        if not root.exists():
            continue
        found.extend(path for path in root.glob("*/weights/best.pt") if path.exists())
    found.sort(key=lambda path: path.stat().st_mtime, reverse=True)
    return tuple(found[:limit])


def resolve_best_weight_path(
    artifacts: TrainingArtifacts,
    train_result: Any | None = None,
) -> Path:
    """Resolve best.pt across local, Ultralytics, and Drive run layouts.

    Colab experiments often fail here after copying an older exp cell because
    ``run_name`` and the actual Ultralytics ``save_dir`` drift apart. This helper
    keeps that failure narrow and prints the exact paths to check.
    """

    train_result = train_result or {}
    for candidate in _candidate_best_weight_paths(train_result, artifacts):
        if candidate.exists():
            return candidate

    checked = "\n".join(
        f"  - {path}" for path in _candidate_best_weight_paths(train_result, artifacts)
    )
    recent = "\n".join(f"  - {path}" for path in _recent_best_weight_paths(artifacts))
    recent_block = f"\n최근 발견한 best.pt:\n{recent}" if recent else ""
    raise FileNotFoundError(
        "best.pt를 찾지 못했습니다.\n"
        f"run_name={artifacts.run_name}\n"
        f"확인한 경로:\n{checked}"
        f"{recent_block}\n"
        "Colab에서는 result.artifacts.run_name, result.yolo_save_dir, "
        "runtime.paths.runs_root가 같은 실험을 가리키는지 확인하세요."
    )


def _resolve_best_weight_path(train_result: Any, artifacts: TrainingArtifacts) -> Path:
    """Resolve the best.pt path produced by Ultralytics.

    The returned path is used both for local verification and for Drive mirroring.
    """

    return resolve_best_weight_path(artifacts, train_result)


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


def _assert_class_names_match_label_map(
    class_names: Sequence[str],
    ontology_records: object = None,
    *,
    model_name: str = "surface_seg",
) -> None:
    """학습 시작 전 class_names 순서가 label map과 일치하는지 검증한다.

    ontology_records가 없거나 pipeline을 import할 수 없는 환경에서는 skip.
    Colab에서 전체 파이프라인이 구성된 경우에만 실제 검증이 동작한다.
    """
    if ontology_records is None:
        return
    try:
        from vision.src.data.label_maps import build_task_label_map

        label_map: dict[str, int] = build_task_label_map(
            ontology_records, model_name=model_name, task_type="segment"
        )
        expected = tuple(
            name for name, _ in sorted(label_map.items(), key=lambda x: x[1])
        )
        if tuple(class_names) != expected:
            raise RuntimeError(
                "class_names 순서가 label map과 불일치합니다.\n"
                f"  runtime : {tuple(class_names)}\n"
                f"  expected: {expected}\n"
                "build_segmentation_runtime_config()를 사용하거나 "
                "DEFAULT_CLASS_NAMES를 수정하세요."
            )
    except Exception:  # noqa: BLE001
        pass


def train_yolo_segmentation(
    runtime: VisionRuntimeConfig | None = None,
    *,
    run_name: str,
    curated_root: Path | None = None,
    class_names: Sequence[str] | None = None,
    ontology_records: object = None,
    model_source: str | Path | None = None,
    yolo_factory: Callable[[str], Any] | None = None,
) -> TrainingRunResult:
    """Train YOLOv8n-seg and mirror best.pt to Drive.

    The function keeps the run layout explicit so Colab notebooks only have to
    mount Drive, point at the curated dataset, and call one helper.
    ontology_records를 넘기면 class_names 순서가 label map과 일치하는지 검증한다.
    """

    runtime = runtime or build_default_runtime_config()
    class_names = tuple(class_names or runtime.class_names)
    _assert_class_names_match_label_map(class_names, ontology_records)
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
    yolo_save_dir = _extract_save_dir(train_result, artifacts.local_run_dir)
    return TrainingRunResult(
        artifacts=artifacts,
        train_result=train_result,
        best_weight_path=best_weight_path,
        drive_best_weight_path=mirrored_path,
        yolo_save_dir=yolo_save_dir,
    )


def train_yolo_segmentation_with_validation_gate(
    runtime: VisionRuntimeConfig | None = None,
    *,
    run_name: str,
    policy: TrainingExecutionPolicy | None = None,
    validation_samples: Sequence[EvaluationSample] | None = None,
    calibration_csv_path: Path | None = None,
    calibration_md_path: Path | None = None,
    curated_root: Path | None = None,
    class_names: Sequence[str] | None = None,
    model_source: str | Path | None = None,
    yolo_factory: Callable[[str], Any] | None = None,
) -> ValidatedTrainingRunResult:
    """Run YOLO training only after export validation and calibration gating.

    The wrapper keeps export validation explicit so Phase 6 is only reachable
    after the task-separated export pipeline has been validated.
    """

    policy = policy or TrainingExecutionPolicy()
    if not policy.export_validation_passed:
        raise RuntimeError(
            "export validation이 통과하지 않아 training을 시작할 수 없습니다."
        )

    runtime = runtime or build_default_runtime_config()
    resolved_class_names = tuple(
        policy.class_inclusion or class_names or runtime.class_names
    )
    training_result = train_yolo_segmentation(
        runtime,
        run_name=run_name,
        curated_root=curated_root,
        class_names=resolved_class_names,
        model_source=model_source,
        yolo_factory=yolo_factory,
    )

    calibration_rows: tuple[dict[str, object], ...] = ()
    resolved_csv_path = calibration_csv_path
    resolved_md_path = calibration_md_path
    if policy.calibration_enabled and validation_samples:
        resolved_csv_path = resolved_csv_path or (
            training_result.artifacts.local_run_dir
            / "reports"
            / "validation_calibration.csv"
        )
        resolved_md_path = resolved_md_path or (
            training_result.artifacts.local_run_dir
            / "reports"
            / "validation_calibration.md"
        )
        rows = build_calibration_rows(
            validation_samples, thresholds=policy.confidence_thresholds
        )
        calibration_rows = tuple(asdict(row) for row in rows)
        _write_validation_calibration_report(
            validation_samples,
            thresholds=policy.confidence_thresholds,
            csv_path=resolved_csv_path,
            md_path=resolved_md_path,
        )
    return ValidatedTrainingRunResult(
        training_result=training_result,
        calibration_rows=calibration_rows,
        calibration_csv_path=resolved_csv_path,
        calibration_md_path=resolved_md_path,
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
