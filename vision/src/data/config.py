"""Configuration shared by the Colab-friendly vision data pipeline.

This module centralizes all path, sampling, and ontology configuration used by
the Phase 1/2 data pipeline. The defaults follow the repository layout and can
be overridden with a small YAML config or environment variables.
"""

from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path
from typing import Any

import yaml

DATASET_INDEX_FILENAME = "dataset_index.csv"
COMBO_COUNTS_FILENAME = "combo_counts.csv"
LABEL_REPORT_FILENAME = "label_report.md"
ONTOLOGY_AUDIT_FILENAME = "ontology_audit.csv"
ONTOLOGY_AUDIT_MD_FILENAME = "ontology_audit.md"
QUALITY_STATE_AUDIT_FILENAME = "quality_state_audit.csv"
ONTOLOGY_VALIDATION_REPORT_FILENAME = "ontology_validation_report.md"
VISION_DATA_PATHS_FILENAME = "vision_data_paths.yaml"
ONTOLOGY_SLUGS_FILENAME = "ontology_slugs.yaml"
SAMPLING_CONFIG_FILENAME = "sampling.yaml"
DEFAULT_SAMPLE_MANIFEST = "sample_manifest.json"

DEFAULT_SAMPLE_SEED = 42
DEFAULT_TRAIN_SAMPLES_PER_CLASS = 500
DEFAULT_VAL_SAMPLES_PER_CLASS = 100
DEFAULT_YOLO_IMAGE_SIZE = 640
DEFAULT_TARGET_IMAGE_WIDTH = 640
DEFAULT_TARGET_IMAGE_HEIGHT = 640
DEFAULT_COORDINATE_SPACE = "original-image"
DEFAULT_RESIZE_METHOD = "letterbox"

DEFAULT_PROJECT_ROOT = Path("vision")
DEFAULT_DATA_ROOT = DEFAULT_PROJECT_ROOT / "data"
DEFAULT_ANALYSIS_ROOT = DEFAULT_DATA_ROOT / "analysis"
DEFAULT_PROCESSED_ROOT = DEFAULT_DATA_ROOT / "processed"
DEFAULT_LABEL_MAP_ROOT = DEFAULT_PROCESSED_ROOT / "label_maps"
DEFAULT_SPLIT_MANIFEST = "split_manifest.json"
DEFAULT_SPLIT_AUDIT_FILENAME = "split_audit.csv"
DEFAULT_SPLIT_AUDIT_MD_FILENAME = "split_audit.md"
DEFAULT_SAMPLING_AUDIT_FILENAME = "sampling_audit.csv"
DEFAULT_SAMPLING_AUDIT_MD_FILENAME = "sampling_audit.md"
DEFAULT_CLASSIFICATION_EXPORT_ROOT = DEFAULT_PROCESSED_ROOT / "exports" / "classification"
DEFAULT_DETECTION_EXPORT_ROOT = DEFAULT_PROCESSED_ROOT / "exports" / "detection"
DEFAULT_SEGMENTATION_EXPORT_ROOT = DEFAULT_PROCESSED_ROOT / "exports" / "segmentation"
DEFAULT_SPLIT_MANIFEST_PATH = DEFAULT_PROCESSED_ROOT / DEFAULT_SPLIT_MANIFEST
DEFAULT_SPLIT_AUDIT_PATH = DEFAULT_ANALYSIS_ROOT / DEFAULT_SPLIT_AUDIT_FILENAME
DEFAULT_SPLIT_AUDIT_MD_PATH = DEFAULT_ANALYSIS_ROOT / DEFAULT_SPLIT_AUDIT_MD_FILENAME
DEFAULT_SAMPLING_AUDIT_PATH = DEFAULT_ANALYSIS_ROOT / DEFAULT_SAMPLING_AUDIT_FILENAME
DEFAULT_SAMPLING_AUDIT_MD_PATH = DEFAULT_ANALYSIS_ROOT / DEFAULT_SAMPLING_AUDIT_MD_FILENAME
DEFAULT_SAMPLING_CONFIG_PATH = Path("vision") / "configs" / SAMPLING_CONFIG_FILENAME
DEFAULT_RAW_ROOT = DEFAULT_DATA_ROOT / "raw"
DEFAULT_ANNOTATION_ROOT = DEFAULT_DATA_ROOT / "labels"
DEFAULT_RESIZED_ROOT = DEFAULT_DATA_ROOT / "curated"
DEFAULT_DATASET_INDEX_PATH = DEFAULT_ANALYSIS_ROOT / DATASET_INDEX_FILENAME
DEFAULT_COMBO_COUNTS_PATH = DEFAULT_ANALYSIS_ROOT / COMBO_COUNTS_FILENAME
DEFAULT_LABEL_REPORT_PATH = DEFAULT_ANALYSIS_ROOT / LABEL_REPORT_FILENAME
DEFAULT_ONTOLOGY_AUDIT_PATH = DEFAULT_ANALYSIS_ROOT / ONTOLOGY_AUDIT_FILENAME
DEFAULT_ONTOLOGY_AUDIT_MD_PATH = DEFAULT_ANALYSIS_ROOT / ONTOLOGY_AUDIT_MD_FILENAME
DEFAULT_QUALITY_STATE_AUDIT_PATH = DEFAULT_ANALYSIS_ROOT / QUALITY_STATE_AUDIT_FILENAME
DEFAULT_ONTOLOGY_VALIDATION_REPORT_PATH = (
    Path("vision") / "docs" / "decisions" / ONTOLOGY_VALIDATION_REPORT_FILENAME
)
DEFAULT_VISION_DATA_PATHS_PATH = Path("vision") / "configs" / VISION_DATA_PATHS_FILENAME
DEFAULT_ONTOLOGY_SLUGS_PATH = Path("vision") / "configs" / ONTOLOGY_SLUGS_FILENAME
DEFAULT_MANIFEST_PATH = DEFAULT_DATA_ROOT / DEFAULT_SAMPLE_MANIFEST

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
    "케이블": [
        "바인딩불량",
        "바인딩양품",
        "케이블설치불량",
        "케이블설치양품",
        "케이블손상",
        "케이블양품",
    ],
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


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def _load_yaml_mapping(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as handle:
        loaded = yaml.safe_load(handle)
    return loaded or {}


def _resolve_path(value: str | Path | None, *, base: Path, fallback: Path) -> Path:
    if value is None:
        return fallback
    path = Path(value).expanduser()
    if not path.is_absolute():
        path = base / path
    return path


def _resolve_resized_root(
    *,
    repo_root: Path,
    yaml_value: str | Path | None,
    env_value: str | Path | None,
) -> Path:
    fallback = repo_root / DEFAULT_RESIZED_ROOT
    if yaml_value:
        fallback = _resolve_path(yaml_value, base=repo_root, fallback=fallback)
    if env_value:
        return _resolve_path(env_value, base=repo_root, fallback=fallback)
    return fallback


@dataclass(frozen=True)
class DataConfig:
    """All paths and sample counts used by the data pipeline."""

    dataset_index_path: Path = DEFAULT_DATASET_INDEX_PATH
    combo_counts_path: Path = DEFAULT_COMBO_COUNTS_PATH
    label_report_path: Path = DEFAULT_LABEL_REPORT_PATH
    ontology_audit_path: Path = DEFAULT_ONTOLOGY_AUDIT_PATH
    ontology_audit_md_path: Path = DEFAULT_ONTOLOGY_AUDIT_MD_PATH
    quality_state_audit_path: Path = DEFAULT_QUALITY_STATE_AUDIT_PATH
    ontology_validation_report_path: Path = DEFAULT_ONTOLOGY_VALIDATION_REPORT_PATH
    manifest_path: Path = DEFAULT_MANIFEST_PATH
    split_manifest_path: Path = DEFAULT_SPLIT_MANIFEST_PATH
    split_audit_path: Path = DEFAULT_SPLIT_AUDIT_PATH
    split_audit_md_path: Path = DEFAULT_SPLIT_AUDIT_MD_PATH
    sampling_audit_path: Path = DEFAULT_SAMPLING_AUDIT_PATH
    sampling_audit_md_path: Path = DEFAULT_SAMPLING_AUDIT_MD_PATH
    raw_root: Path = DEFAULT_RAW_ROOT
    annotation_root: Path = DEFAULT_ANNOTATION_ROOT
    resized_root: Path = DEFAULT_RESIZED_ROOT
    sampling_config_path: Path = DEFAULT_SAMPLING_CONFIG_PATH
    processed_root: Path = DEFAULT_PROCESSED_ROOT
    label_map_root: Path = DEFAULT_LABEL_MAP_ROOT
    vision_data_paths_path: Path = DEFAULT_VISION_DATA_PATHS_PATH
    ontology_slugs_path: Path = DEFAULT_ONTOLOGY_SLUGS_PATH
    train_samples_per_class: int = DEFAULT_TRAIN_SAMPLES_PER_CLASS
    val_samples_per_class: int = DEFAULT_VAL_SAMPLES_PER_CLASS
    sample_seed: int = DEFAULT_SAMPLE_SEED
    target_image_width: int = DEFAULT_TARGET_IMAGE_WIDTH
    target_image_height: int = DEFAULT_TARGET_IMAGE_HEIGHT
    coordinate_space: str = DEFAULT_COORDINATE_SPACE
    resize_method: str = DEFAULT_RESIZE_METHOD

    @property
    def labels_root(self) -> Path:
        return self.annotation_root

    @property
    def resized_image_root(self) -> Path:
        return self.resized_root

    def class_dir(self, class_name: str) -> Path:
        """Return the class-specific resized directory."""

        return self.resized_root / class_name

    def is_local_resized_root_available(self) -> bool:
        """Return whether the configured local resized root exists."""

        return self.resized_root.exists()


def load_data_config(
    config_path: Path | None = None,
    *,
    repo_root: Path | None = None,
) -> DataConfig:
    """Load the vision data config from YAML and environment overrides.

    The repo-relative defaults stay stable, while Colab can override only the
    resized image root through `VISION_RESIZED_IMAGE_ROOT`.
    """

    repo_root = repo_root or _repo_root()
    config_path = config_path or repo_root / DEFAULT_VISION_DATA_PATHS_PATH
    yaml_data = _load_yaml_mapping(config_path)

    resized_root = _resolve_resized_root(
        repo_root=repo_root,
        yaml_value=yaml_data.get("resized_image_root"),
        env_value=os.environ.get("VISION_RESIZED_IMAGE_ROOT"),
    )

    return DataConfig(
        dataset_index_path=_resolve_path(
            yaml_data.get("dataset_index_path"), base=repo_root, fallback=repo_root / DEFAULT_DATASET_INDEX_PATH
        ),
        combo_counts_path=_resolve_path(
            yaml_data.get("combo_counts_path"), base=repo_root, fallback=repo_root / DEFAULT_COMBO_COUNTS_PATH
        ),
        label_report_path=_resolve_path(
            yaml_data.get("label_report_path"), base=repo_root, fallback=repo_root / DEFAULT_LABEL_REPORT_PATH
        ),
        ontology_audit_path=_resolve_path(
            yaml_data.get("ontology_audit_path"), base=repo_root, fallback=repo_root / DEFAULT_ONTOLOGY_AUDIT_PATH
        ),
        ontology_audit_md_path=_resolve_path(
            yaml_data.get("ontology_audit_md_path"), base=repo_root, fallback=repo_root / DEFAULT_ONTOLOGY_AUDIT_MD_PATH
        ),
        quality_state_audit_path=_resolve_path(
            yaml_data.get("quality_state_audit_path"), base=repo_root, fallback=repo_root / DEFAULT_QUALITY_STATE_AUDIT_PATH
        ),
        ontology_validation_report_path=_resolve_path(
            yaml_data.get("ontology_validation_report_path"),
            base=repo_root,
            fallback=repo_root / DEFAULT_ONTOLOGY_VALIDATION_REPORT_PATH,
        ),
        manifest_path=_resolve_path(
            yaml_data.get("manifest_path"), base=repo_root, fallback=repo_root / DEFAULT_MANIFEST_PATH
        ),
        split_manifest_path=_resolve_path(
            yaml_data.get("split_manifest_path"), base=repo_root, fallback=repo_root / DEFAULT_SPLIT_MANIFEST_PATH
        ),
        split_audit_path=_resolve_path(
            yaml_data.get("split_audit_path"), base=repo_root, fallback=repo_root / DEFAULT_SPLIT_AUDIT_PATH
        ),
        split_audit_md_path=_resolve_path(
            yaml_data.get("split_audit_md_path"), base=repo_root, fallback=repo_root / DEFAULT_SPLIT_AUDIT_MD_PATH
        ),
        sampling_audit_path=_resolve_path(
            yaml_data.get("sampling_audit_path"), base=repo_root, fallback=repo_root / DEFAULT_SAMPLING_AUDIT_PATH
        ),
        sampling_audit_md_path=_resolve_path(
            yaml_data.get("sampling_audit_md_path"),
            base=repo_root,
            fallback=repo_root / DEFAULT_SAMPLING_AUDIT_MD_PATH,
        ),
        raw_root=_resolve_path(yaml_data.get("raw_root"), base=repo_root, fallback=repo_root / DEFAULT_RAW_ROOT),
        annotation_root=_resolve_path(
            yaml_data.get("annotation_root"), base=repo_root, fallback=repo_root / DEFAULT_ANNOTATION_ROOT
        ),
        resized_root=resized_root,
        sampling_config_path=_resolve_path(
            yaml_data.get("sampling_config_path"), base=repo_root, fallback=repo_root / DEFAULT_SAMPLING_CONFIG_PATH
        ),
        processed_root=_resolve_path(
            yaml_data.get("processed_root"), base=repo_root, fallback=repo_root / DEFAULT_PROCESSED_ROOT
        ),
        label_map_root=_resolve_path(
            yaml_data.get("label_map_root"), base=repo_root, fallback=repo_root / DEFAULT_LABEL_MAP_ROOT
        ),
        vision_data_paths_path=config_path,
        ontology_slugs_path=_resolve_path(
            yaml_data.get("ontology_slugs_path"), base=repo_root, fallback=repo_root / DEFAULT_ONTOLOGY_SLUGS_PATH
        ),
        train_samples_per_class=int(yaml_data.get("train_samples_per_class", DEFAULT_TRAIN_SAMPLES_PER_CLASS)),
        val_samples_per_class=int(yaml_data.get("val_samples_per_class", DEFAULT_VAL_SAMPLES_PER_CLASS)),
        sample_seed=int(yaml_data.get("sample_seed", DEFAULT_SAMPLE_SEED)),
        target_image_width=int(yaml_data.get("target_image_width", DEFAULT_TARGET_IMAGE_WIDTH)),
        target_image_height=int(yaml_data.get("target_image_height", DEFAULT_TARGET_IMAGE_HEIGHT)),
        coordinate_space=str(yaml_data.get("coordinate_space", DEFAULT_COORDINATE_SPACE)),
        resize_method=str(yaml_data.get("resize_method", DEFAULT_RESIZE_METHOD)),
    )


def build_default_data_config() -> DataConfig:
    """Return the default data config used in Colab notebooks."""

    return load_data_config()
