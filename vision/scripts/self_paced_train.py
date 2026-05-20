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
from dataclasses import dataclass
from pathlib import Path

import numpy as np

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
# § 1  Entry point skeleton
# ---------------------------------------------------------------------------


def main() -> None:
    cfg = _parse_args()
    _seed_everything(cfg.seed)
    _setup_dirs(cfg)

    print(f"[SPL] run={cfg.run_name}  seed={cfg.seed}")
    print(f"      data_root={cfg.data_root}")
    print(f"      candidate_root={cfg.candidate_root}")
    print(f"      seed_size={cfg.seed_size}  easy_ratio={cfg.easy_ratio}")
    print(
        f"      patience={cfg.patience}  min_improve={cfg.min_improve}  max_rounds={cfg.max_rounds}"
    )
    print(f"      artifacts → {cfg.run_dir.resolve()}")


if __name__ == "__main__":
    main()
