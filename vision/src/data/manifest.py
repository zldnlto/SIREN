"""Manifest generation helpers for the vision data pipeline."""

from __future__ import annotations

import csv
import json
import random
from dataclasses import asdict, dataclass
from pathlib import Path

from vision.src.data.config import (
    DEFAULT_DATASET_INDEX_PATH,
    DEFAULT_MANIFEST_PATH,
    DEFAULT_SAMPLE_SEED,
    DEFAULT_TRAIN_SAMPLES_PER_CLASS,
    DEFAULT_VAL_SAMPLES_PER_CLASS,
    ValidDomainCombos,
    ValidDomainDefects,
)


@dataclass(frozen=True)
class ManifestItem:
    """The sample metadata Colab will feed into preprocessing/training."""

    file_name: str
    zip_source: str
    source_key: str
    domain: str
    defect_name: str
    part_name: str
    category_id: int
    label_type: str
    split: str
    difficulty_score: float | None = None
    sample_type: str | None = None
    input_size: int = 640

    @property
    def class_name(self) -> str:
        """Return the human-readable class key used in curated paths."""

        return f"{self.defect_name}_{self.part_name}"


def load_dataset_index(path: Path = DEFAULT_DATASET_INDEX_PATH) -> list[dict]:
    """Load the parsed COCO index as dictionaries."""

    with open(path, "r", encoding="utf-8-sig") as handle:
        rows = list(csv.DictReader(handle))

    normalized: list[dict] = []
    for row in rows:
        item = dict(row)
        if "category_id" in item:
            try:
                item["category_id"] = int(item["category_id"])
            except ValueError:
                pass
        normalized.append(item)
    return normalized


def filter_dataset_rows(rows: list[dict], domain: str = "표면처리") -> list[dict]:
    """Keep only rows that match the intended domain and part names."""

    return [
        row
        for row in rows
        if row.get("domain") in ValidDomainDefects
        and row.get("defect_name") in ValidDomainDefects.get(row.get("domain"), [])
        and row.get("part_name") in ValidDomainCombos.get(row.get("domain"), [])
        and row.get("domain") == domain
    ]


def build_manifest_item(row: dict, split: str, *, input_size: int = 640) -> ManifestItem:
    """Convert an index row into a manifest item.

    Keeping this as a dataclass helps Colab notebooks inspect fields without
    mentally unpacking nested dictionaries.
    """

    from vision.src.data.labels import get_source_key

    return ManifestItem(
        file_name=row["file_name"],
        zip_source=row["zip_source"],
        source_key=get_source_key(row["zip_source"]),
        domain=row["domain"],
        defect_name=row["defect_name"],
        part_name=row["part_name"],
        category_id=int(row["category_id"]),
        label_type=row["label_type"],
        split=split,
        input_size=input_size,
    )


def sample_split_rows(
    rows: list[dict],
    *,
    train_samples_per_class: int = DEFAULT_TRAIN_SAMPLES_PER_CLASS,
    val_samples_per_class: int = DEFAULT_VAL_SAMPLES_PER_CLASS,
    seed: int = DEFAULT_SAMPLE_SEED,
) -> tuple[list[ManifestItem], list[dict]]:
    """Balanced sampling for TL/VL rows.

    The function keeps the current class balance logic but makes it callable
    from Colab, so the notebook only needs to orchestrate rather than re-implement.
    """

    rng = random.Random(seed)
    manifest: list[ManifestItem] = []
    stats: list[dict] = []

    tl_rows = [row for row in rows if row.get("split") == "TL"]
    vl_rows = [row for row in rows if row.get("split") == "VL"]

    for split_rows, split_name, target in (
        (tl_rows, "TL", train_samples_per_class),
        (vl_rows, "VL", val_samples_per_class),
    ):
        groups: dict[tuple[str, str], list[dict]] = {}
        for row in split_rows:
            groups.setdefault((row["defect_name"], row["part_name"]), []).append(row)

        for (defect_name, part_name), group in sorted(groups.items()):
            sample_count = min(target, len(group))
            sampled = rng.sample(group, sample_count) if sample_count else []
            for row in sampled:
                manifest.append(build_manifest_item(row, split=split_name))
            stats.append(
                {
                    "defect_name": defect_name,
                    "part_name": part_name,
                    "split": split_name,
                    "sampled": sample_count,
                    "total": len(group),
                }
            )

    return manifest, stats


def build_sample_manifest(
    index_path: Path = DEFAULT_DATASET_INDEX_PATH,
    *,
    domain: str = "표면처리",
    train_samples_per_class: int = DEFAULT_TRAIN_SAMPLES_PER_CLASS,
    val_samples_per_class: int = DEFAULT_VAL_SAMPLES_PER_CLASS,
    seed: int = DEFAULT_SAMPLE_SEED,
) -> tuple[list[ManifestItem], list[dict]]:
    """Build a balanced manifest from the parsed dataset index."""

    rows = load_dataset_index(index_path)
    filtered = filter_dataset_rows(rows, domain=domain)
    return sample_split_rows(
        filtered,
        train_samples_per_class=train_samples_per_class,
        val_samples_per_class=val_samples_per_class,
        seed=seed,
    )


def save_manifest(manifest: list[ManifestItem], path: Path = DEFAULT_MANIFEST_PATH) -> Path:
    """Write the manifest to JSON."""

    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", encoding="utf-8") as handle:
        json.dump([asdict(item) for item in manifest], handle, ensure_ascii=False, indent=2)
    return path


def load_manifest(path: Path = DEFAULT_MANIFEST_PATH) -> list[dict]:
    """Load a previously generated manifest."""

    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)
