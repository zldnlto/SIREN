"""Configuration shared by the Colab-friendly data pipeline.

The old scripts hardcoded paths and class rules in several places.
This module centralizes them so future notebook changes only touch one file.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

DATASET_INDEX_FILENAME = "dataset_index.csv"
DEFAULT_SAMPLE_MANIFEST = "sample_manifest.json"
DEFAULT_SAMPLE_SEED = 42
DEFAULT_TRAIN_SAMPLES_PER_CLASS = 500
DEFAULT_VAL_SAMPLES_PER_CLASS = 100
DEFAULT_YOLO_IMAGE_SIZE = 640

DEFAULT_DATASET_INDEX_PATH = Path("vision/data") / DATASET_INDEX_FILENAME
DEFAULT_MANIFEST_PATH = Path("vision/data") / DEFAULT_SAMPLE_MANIFEST
DEFAULT_RAW_ROOT = Path("vision/data/raw")
DEFAULT_RESIZED_ROOT = Path("vision/data/resized")

# TL/VL 파일명에서 읽어낸 도메인과 품질 규칙을 한 곳에 둔다.
ValidDomainCombos: dict[str, list[str]] = {
    "용접": ["조인트"],
    "절단": ["모재", "보온재"],
    "케이블": ["케이블타이", "케이블그랜드", "케이블"],
    "파이프": ["파이프"],
    "폼스프레이": ["우레탄폼"],
    "표면처리": ["도장", "모재", "보온재"],
}

ValidDomainDefects: dict[str, list[str]] = {
    "용접": ["용접불량", "용접블로우홀", "용접양품"],
    "절단": ["절단불량", "절단양품"],
    "케이블": ["바인딩불량", "바인딩양품", "케이블설치불량", "케이블설치양품", "케이블손상", "케이블양품"],
    "파이프": ["볼트체결불량", "볼트체결양품"],
    "폼스프레이": ["폼스프레이불량", "폼스프레이양품"],
    "표면처리": ["균열", "도막떨어짐", "도막분리", "도장흐름", "보온재손상", "스크래치", "탱크클리닝불량", "표면양품"],
}

# AI Hub에서 내려받은 zip 파일명 → package key 매핑.
SourceKeyMap: dict[str, str] = {
    "TL_표면처리_균열_도장": "526047",
    "TL_표면처리_균열_보온재": "526048",
    "TL_표면처리_도막떨어짐_도장": "526049",
    "TL_표면처리_도막분리_도장": "526050",
    "TL_표면처리_도장흐름_도장": "526051",
    "TL_표면처리_보온재손상_보온재": "526052",
    "TL_표면처리_스크래치_도장": "526053",
    "TL_표면처리_스크래치_모재": "526054",
    "TL_표면처리_스크래치_보온재": "526055",
    "TL_표면처리_탱크클리닝불량_모재": "526056",
    "TL_표면처리_표면양품_도장": "526057",
    "TL_표면처리_표면양품_모재": "526058",
    "TL_표면처리_표면양품_보온재": "526059",
    "VL_표면처리_균열_도장": "526107",
    "VL_표면처리_균열_보온재": "526108",
    "VL_표면처리_도막떨어짐_도장": "526109",
    "VL_표면처리_도막분리_도장": "526110",
    "VL_표면처리_도장흐름_도장": "526111",
    "VL_표면처리_보온재손상_보온재": "526112",
    "VL_표면처리_스크래치_도장": "526113",
    "VL_표면처리_스크래치_모재": "526114",
    "VL_표면처리_스크래치_보온재": "526115",
    "VL_표면처리_탱크클리닝불량_모재": "526116",
    "VL_표면처리_표면양품_도장": "526117",
    "VL_표면처리_표면양품_모재": "526118",
    "VL_표면처리_표면양품_보온재": "526119",
}


@dataclass(frozen=True)
class DataConfig:
    """All paths and sample counts used by the data pipeline."""

    dataset_index_path: Path = DEFAULT_DATASET_INDEX_PATH
    manifest_path: Path = DEFAULT_MANIFEST_PATH
    raw_root: Path = DEFAULT_RAW_ROOT
    resized_root: Path = DEFAULT_RESIZED_ROOT
    train_samples_per_class: int = DEFAULT_TRAIN_SAMPLES_PER_CLASS
    val_samples_per_class: int = DEFAULT_VAL_SAMPLES_PER_CLASS
    sample_seed: int = DEFAULT_SAMPLE_SEED
    image_size: int = DEFAULT_YOLO_IMAGE_SIZE

    def class_dir(self, class_name: str) -> Path:
        """Return the class-specific resized directory."""

        return self.resized_root / class_name


def build_default_data_config() -> DataConfig:
    """Return the default data config used in Colab notebooks."""

    return DataConfig()

