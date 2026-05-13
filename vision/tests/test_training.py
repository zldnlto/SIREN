from __future__ import annotations

from pathlib import Path

from vision.src.paths import VisionPaths
from vision.src.settings import VisionRuntimeConfig
from vision.src.training import (
    build_training_artifacts,
    build_yolo_dataset_yaml_text,
    evaluate_yolo_segmentation,
    train_yolo_segmentation,
)


class DummyYolo:
    def __init__(self, source: str) -> None:
        self.source = source
        self.train_kwargs: dict | None = None
        self.val_kwargs: dict | None = None

    def train(self, **kwargs):
        self.train_kwargs = kwargs
        save_dir = Path(kwargs["project"]) / kwargs["name"]
        weights_dir = save_dir / "weights"
        weights_dir.mkdir(parents=True, exist_ok=True)
        (weights_dir / "best.pt").write_text(f"best from {self.source}", encoding="utf-8")
        return {"save_dir": str(save_dir)}

    def val(self, **kwargs):
        self.val_kwargs = kwargs
        return {"weights": self.source, **kwargs}


class DummyFactory:
    def __init__(self) -> None:
        self.instances: list[DummyYolo] = []

    def __call__(self, source: str) -> DummyYolo:
        instance = DummyYolo(source)
        self.instances.append(instance)
        return instance


def _build_runtime(tmp_path: Path) -> VisionRuntimeConfig:
    repo_root = tmp_path / "repo"
    vision_root = repo_root / "vision"
    data_root = vision_root / "data"
    paths = VisionPaths(
        repo_root=repo_root,
        vision_root=vision_root,
        data_root=data_root,
        raw_root=data_root / "raw",
        resized_root=data_root / "resized",
        labels_root=data_root / "labels",
        runs_root=vision_root / "runs",
        drive_runs_root=tmp_path / "drive" / "runs",
    )
    return VisionRuntimeConfig(
        paths=paths,
        class_names=("균열", "스크래치"),
        image_size=640,
        batch_size=2,
        epochs=1,
        device="cpu",
        yolo_model="yolov8n-seg.pt",
    )


def _prepare_curated_dirs(root: Path) -> None:
    for class_name in ("균열", "스크래치"):
        for split in ("train", "val"):
            (root / class_name / "images" / split).mkdir(parents=True, exist_ok=True)


def test_build_training_artifacts_and_yaml_text(tmp_path: Path) -> None:
    runtime = _build_runtime(tmp_path)
    curated_root = runtime.paths.resized_root
    _prepare_curated_dirs(curated_root)

    artifacts = build_training_artifacts(
        runtime,
        run_name="surface-run",
        curated_root=curated_root,
        class_names=runtime.class_names,
    )
    yaml_text = build_yolo_dataset_yaml_text(curated_root, runtime.class_names)

    assert artifacts.local_run_dir.exists()
    assert artifacts.drive_run_dir.exists()
    assert artifacts.data_yaml_path.parent == artifacts.local_run_dir
    assert "train:" in yaml_text
    assert "val:" in yaml_text
    assert "0: 균열" in yaml_text
    assert "1: 스크래치" in yaml_text


def test_train_and_evaluate_yolo_segmentation_mirror_best_weight(tmp_path: Path) -> None:
    runtime = _build_runtime(tmp_path)
    curated_root = runtime.paths.resized_root
    _prepare_curated_dirs(curated_root)

    factory = DummyFactory()
    run_result = train_yolo_segmentation(
        runtime,
        run_name="surface-run",
        curated_root=curated_root,
        class_names=runtime.class_names,
        model_source="fake-yolo.pt",
        yolo_factory=factory,
    )

    assert run_result.best_weight_path.exists()
    assert run_result.drive_best_weight_path is not None
    assert run_result.drive_best_weight_path.exists()
    assert run_result.best_weight_path.read_text(encoding="utf-8") == "best from fake-yolo.pt"
    assert run_result.drive_best_weight_path.read_text(encoding="utf-8") == "best from fake-yolo.pt"
    assert run_result.artifacts.serving_weight_path == run_result.drive_best_weight_path
    assert factory.instances[0].train_kwargs is not None
    assert factory.instances[0].train_kwargs["data"] == str(run_result.artifacts.data_yaml_path)

    eval_result = evaluate_yolo_segmentation(
        run_result.best_weight_path,
        run_result.artifacts.data_yaml_path,
        runtime,
        yolo_factory=factory,
    )

    assert factory.instances[1].val_kwargs is not None
    assert factory.instances[1].val_kwargs["data"] == str(run_result.artifacts.data_yaml_path)
    assert eval_result["weights"] == str(run_result.best_weight_path)
