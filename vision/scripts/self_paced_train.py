"""Self-Paced Curriculum Learning training loop for YOLOv8 segmentation.

# TODO: evaluate_yolo_segmentation 반환 객체의 val accuracy 키를 확인 후 수정 필요.
#   Ultralytics Metrics 후보 키:
#     result.seg.map                          → mAP50-95 (seg mask)
#     result.results_dict["metrics/mAP50-95(M)"]
#     result.results_dict["metrics/mAP50(M)"]
#   _extract_val_accuracy() 가 위 순서로 시도한다.
#   실제 run 후 반환 객체를 dir() / print() 로 확인하고 수정한다.
"""

from __future__ import annotations

import argparse
import random
from collections.abc import Callable
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import numpy as np

from vision.src.settings import VisionRuntimeConfig, build_default_runtime_config
from vision.src.training import (
    TrainingRunResult,
    evaluate_yolo_segmentation,
    train_yolo_segmentation,
)

try:
    from ultralytics import YOLO as _YOLO
except ImportError:  # pragma: no cover
    _YOLO = None

_IMAGE_EXTS: frozenset[str] = frozenset({".jpg", ".jpeg", ".png", ".bmp"})

# ---------------------------------------------------------------------------
# § 1  Config
# ---------------------------------------------------------------------------


@dataclass
class SPLConfig:
    seed_size: int
    easy_ratio: float
    min_improve: float
    patience: int
    max_rounds: int
    run_name: str
    data_root: Path
    candidate_root: Path
    seed: int

    @property
    def run_dir(self) -> Path:
        return Path("runs") / self.run_name

    @property
    def rounds_csv(self) -> Path:
        return self.run_dir / "rounds.csv"

    @property
    def summary_json(self) -> Path:
        return self.run_dir / "summary.json"


# ---------------------------------------------------------------------------
# § 1  CLI
# ---------------------------------------------------------------------------


def _parse_args() -> SPLConfig:
    p = argparse.ArgumentParser(
        description="Self-Paced Curriculum Learning — YOLOv8-seg",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--seed-size", type=int, default=500, metavar="N", help="Round 0 학습 샘플 수"
    )
    p.add_argument(
        "--easy-ratio",
        type=float,
        default=0.3,
        metavar="R",
        help="각 라운드에서 제거할 easy 샘플 비율 (0 < R < 1)",
    )
    p.add_argument(
        "--min-improve",
        type=float,
        default=0.005,
        metavar="D",
        help="개선으로 인정할 최소 accuracy 증가폭",
    )
    p.add_argument(
        "--patience",
        type=int,
        default=3,
        metavar="P",
        help="연속 미개선 허용 횟수 (초과 시 조기 종료)",
    )
    p.add_argument(
        "--max-rounds", type=int, default=10, metavar="M", help="최대 라운드 수"
    )
    p.add_argument(
        "--run-name",
        type=str,
        default="siren-spl-v1",
        help="run 식별자 (아티팩트 디렉터리 이름)",
    )
    p.add_argument(
        "--data-root",
        type=Path,
        required=True,
        help="초기 curated 데이터셋 루트 (train + val 분할 포함)",
    )
    p.add_argument(
        "--candidate-root",
        type=Path,
        required=True,
        help="Confidence 스코어링 대상 전체 후보 풀 루트",
    )
    p.add_argument("--seed", type=int, default=42, help="재현성 시드")
    args = p.parse_args()

    return SPLConfig(
        seed_size=args.seed_size,
        easy_ratio=args.easy_ratio,
        min_improve=args.min_improve,
        patience=args.patience,
        max_rounds=args.max_rounds,
        run_name=args.run_name,
        data_root=args.data_root.resolve(),
        candidate_root=args.candidate_root.resolve(),
        seed=args.seed,
    )


def _setup_dirs(cfg: SPLConfig) -> None:
    cfg.run_dir.mkdir(parents=True, exist_ok=True)


def _seed_everything(seed: int) -> None:
    random.seed(seed)
    np.random.seed(seed)


# ---------------------------------------------------------------------------
# § 2  Dataset helpers
# ---------------------------------------------------------------------------


def _collect_images(root: Path, split: str = "train") -> list[Path]:
    """Deterministically collect image paths in {root}/**/{split}/*.ext."""
    found = sorted(
        p
        for p in root.rglob("*")
        if p.suffix.lower() in _IMAGE_EXTS and p.parent.name == split
    )
    if not found:
        # fallback: flat structure
        found = sorted(p for p in root.rglob("*") if p.suffix.lower() in _IMAGE_EXTS)
    return found


def _label_path_for(img: Path, root: Path) -> Path | None:
    """Resolve {root}/.../labels/{split}/{stem}.txt from an image path."""
    try:
        rel = img.relative_to(root)
    except ValueError:
        return None
    parts = list(rel.parts)
    try:
        idx = parts.index("images")
        parts[idx] = "labels"
    except ValueError:
        pass
    candidate = root / Path(*parts).with_suffix(".txt")
    return candidate if candidate.exists() else None


def _symlink_pair(img: Path, src_root: Path, dst_dir: Path) -> None:
    """Symlink img (and its label) from src_root into dst_dir, preserving relative path."""
    try:
        rel = img.relative_to(src_root)
    except ValueError:
        return
    dst_img = dst_dir / rel
    dst_img.parent.mkdir(parents=True, exist_ok=True)
    if not dst_img.exists():
        dst_img.symlink_to(img)
    label = _label_path_for(img, src_root)
    if label:
        lbl_rel = label.relative_to(src_root)
        dst_lbl = dst_dir / lbl_rel
        dst_lbl.parent.mkdir(parents=True, exist_ok=True)
        if not dst_lbl.exists():
            dst_lbl.symlink_to(label)


def _build_round_curated_dir(
    run_dir: Path,
    round_idx: int,
    train_images: list[Path],
    train_root: Path,
    data_root: Path,
) -> Path:
    """Create a per-round curated directory.

    Train images come from train_root (symlinked subset).
    Val images are always taken from data_root to keep evaluation stable.
    """
    curated = run_dir / f"round_{round_idx}" / "curated"
    curated.mkdir(parents=True, exist_ok=True)
    for img in train_images:
        _symlink_pair(img, train_root, curated)
    for img in _collect_images(data_root, split="val"):
        _symlink_pair(img, data_root, curated)
    return curated


def _seed_sample(images: list[Path], n: int) -> list[Path]:
    """Return first n from sorted list (deterministic — caller seeds RNG)."""
    return sorted(images)[:n]


# ---------------------------------------------------------------------------
# § 2  Evaluate helpers
# ---------------------------------------------------------------------------


def _extract_val_accuracy(eval_result: Any) -> float:
    """Extract val mAP from a YOLO evaluation result object.

    TODO: Ultralytics 버전에 따라 키가 다를 수 있음. 실제 run 후 확인 필요.
    """
    if hasattr(eval_result, "seg") and hasattr(eval_result.seg, "map"):
        return float(eval_result.seg.map)
    if hasattr(eval_result, "results_dict"):
        d = eval_result.results_dict
        for key in ("metrics/mAP50-95(M)", "metrics/mAP50-95(B)", "metrics/mAP50(M)"):
            if key in d:
                return float(d[key])
    if hasattr(eval_result, "box") and hasattr(eval_result.box, "map"):
        return float(eval_result.box.map)
    return 0.0


def _run_one_round(
    cfg: SPLConfig,
    runtime: VisionRuntimeConfig,
    round_idx: int,
    curated_dir: Path,
) -> tuple[TrainingRunResult, float]:
    """Train + evaluate one round. Returns (train_result, val_accuracy)."""
    round_run_name = f"{cfg.run_name}-r{round_idx}"
    print(f"[SPL] round {round_idx}: training on {curated_dir}")
    train_result = train_yolo_segmentation(
        runtime,
        run_name=round_run_name,
        curated_root=curated_dir,
    )
    eval_result = evaluate_yolo_segmentation(
        train_result.best_weight_path,
        train_result.artifacts.data_yaml_path,
        runtime,
    )
    accuracy = _extract_val_accuracy(eval_result)
    print(f"[SPL] round {round_idx}: val_accuracy={accuracy:.4f}")
    return train_result, accuracy


# ---------------------------------------------------------------------------
# § 3  Confidence scoring + curriculum rebuild
# ---------------------------------------------------------------------------


def _score_candidates(
    weights_path: Path,
    candidate_root: Path,
    runtime: VisionRuntimeConfig,
    yolo_factory: Callable[[str], Any] | None = None,
) -> dict[Path, float]:
    """Run YOLO predict on all candidate images. Returns {img_path: mean_conf}.

    Images with no detections receive confidence = 0.0 (treated as hardest).
    """
    if yolo_factory is not None:
        yolo_cls = yolo_factory
    elif _YOLO is None:
        raise RuntimeError(
            "ultralytics 패키지가 필요합니다. `pip install ultralytics` 후 실행하세요."
        )
    else:
        yolo_cls = _YOLO

    model = yolo_cls(str(weights_path))
    all_images = _collect_images(candidate_root)
    scores: dict[Path, float] = {}

    for img in all_images:
        results = model.predict(
            source=str(img),
            conf=runtime.confidence_threshold,
            verbose=False,
            save=False,
        )
        if results and len(results) > 0:
            boxes = getattr(results[0], "boxes", None)
            if boxes is not None and len(boxes) > 0:
                confs = boxes.conf
                arr = (
                    confs.cpu().numpy() if hasattr(confs, "cpu") else np.asarray(confs)
                )
                scores[img] = float(np.mean(arr))
            else:
                scores[img] = 0.0
        else:
            scores[img] = 0.0

    return scores


def _split_easy_hard(
    scores: dict[Path, float],
    easy_ratio: float,
) -> tuple[list[Path], list[Path]]:
    """Split scored images into easy (high conf) and hard (low conf).

    Sorted deterministically by (score desc, path asc) so results are
    reproducible regardless of dict insertion order.
    """
    ordered = sorted(scores.keys(), key=lambda p: (-scores[p], str(p)))
    n_easy = max(0, int(len(ordered) * easy_ratio))
    easy = ordered[:n_easy]
    hard = ordered[n_easy:]
    return easy, hard


# ---------------------------------------------------------------------------
# § 3  Entry point (curriculum loop skeleton)
# ---------------------------------------------------------------------------


def main() -> None:
    cfg = _parse_args()
    _seed_everything(cfg.seed)
    _setup_dirs(cfg)
    runtime = build_default_runtime_config()

    print(f"[SPL] run={cfg.run_name}  seed={cfg.seed}")
    print(f"      data_root={cfg.data_root}")
    print(f"      candidate_root={cfg.candidate_root}")
    print(f"      seed_size={cfg.seed_size}  easy_ratio={cfg.easy_ratio}")
    print(
        f"      patience={cfg.patience}  min_improve={cfg.min_improve}"
        f"  max_rounds={cfg.max_rounds}"
    )
    print(f"      artifacts → {cfg.run_dir.resolve()}")

    # Round 0 — seed baseline
    seed_images = _seed_sample(
        _collect_images(cfg.data_root, split="train"),
        cfg.seed_size,
    )
    round0_curated = _build_round_curated_dir(
        cfg.run_dir, 0, seed_images, cfg.data_root, cfg.data_root
    )
    train_result, accuracy = _run_one_round(cfg, runtime, 0, round0_curated)

    # Round 1+ — curriculum loop
    best_accuracy = accuracy
    best_weight = train_result.best_weight_path

    for round_idx in range(1, cfg.max_rounds):
        scores = _score_candidates(best_weight, cfg.candidate_root, runtime)
        _, hard = _split_easy_hard(scores, cfg.easy_ratio)

        if not hard:
            print(f"[SPL] round {round_idx}: hard 샘플이 없습니다. 루프 종료.")
            break

        round_curated = _build_round_curated_dir(
            cfg.run_dir, round_idx, hard, cfg.candidate_root, cfg.data_root
        )
        train_result, accuracy = _run_one_round(cfg, runtime, round_idx, round_curated)

        if accuracy > best_accuracy:
            best_accuracy = accuracy
            best_weight = train_result.best_weight_path

    print(f"[SPL] 완료: best_accuracy={best_accuracy:.4f}  best_weight={best_weight}")


if __name__ == "__main__":
    main()
