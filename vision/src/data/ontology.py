"""Ontology helpers for canonical class and label-map generation."""

from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass, asdict
from pathlib import Path
import re
from typing import Any, Iterable, Mapping

import yaml

from vision.src.data.config import DEFAULT_ONTOLOGY_SLUGS_PATH
from vision.src.data.reports import write_csv_rows, write_markdown

TASK_TYPE_MAP = {
    "classification": "classify",
    "bbox": "detect",
    "segmentation+bbox": "segment",
}

QUALITY_STATE_MAP = {
    "good": "good",
    "defect": "defect",
}


def _slugify(text: str) -> str:
    """Convert a text value into a deterministic lowercase slug."""

    text = re.sub(r"\s+", "_", text.strip().lower())
    text = re.sub(r"[^0-9a-zA-Z가-힣_]+", "_", text)
    text = re.sub(r"_+", "_", text).strip("_")
    return text or "unknown"


@dataclass(frozen=True)
class OntologySlugs:
    """Deterministic slug mapping loaded from YAML."""

    version: int
    domain_slugs: dict[str, str]
    defect_slugs: dict[str, str]
    part_slugs: dict[str, str]
    quality_state_slugs: dict[str, str]
    task_type_slugs: dict[str, str]

    def domain_slug(self, domain: str) -> str:
        return self.domain_slugs.get(domain, _slugify(domain))

    def defect_slug(self, defect_name: str) -> str:
        return self.defect_slugs.get(defect_name, _slugify(defect_name))

    def part_slug(self, part_name: str) -> str:
        return self.part_slugs.get(part_name, _slugify(part_name))

    def quality_state_slug(self, quality_state: str) -> str:
        return self.quality_state_slugs.get(quality_state, _slugify(quality_state))

    def task_type_slug(self, task_type: str) -> str:
        return self.task_type_slugs.get(task_type, _slugify(task_type))


@dataclass(frozen=True)
class OntologyRecord:
    """One canonical ontology row."""

    ontology_id: str
    parent_ontology_id: str
    display_label: str
    canonical_class_name: str
    domain: str
    defect_name: str
    part_name: str
    quality_state: str
    allowed_task_types: tuple[str, ...]
    row_count: int
    unique_image_count: int
    unique_domain_count: int
    unique_label_type_count: int
    unique_category_id_count: int
    support_bucket: str
    is_primary_kpi_class: bool

    @property
    def support_count(self) -> int:
        return self.unique_image_count


def load_ontology_slugs(path: Path | None = None) -> OntologySlugs:
    """Load deterministic slug mappings from YAML."""

    path = path or DEFAULT_ONTOLOGY_SLUGS_PATH
    if not path.exists():
        return OntologySlugs(
            version=1,
            domain_slugs={},
            defect_slugs={},
            part_slugs={},
            quality_state_slugs=dict(QUALITY_STATE_MAP),
            task_type_slugs=dict(TASK_TYPE_MAP),
        )

    with path.open("r", encoding="utf-8") as handle:
        payload = yaml.safe_load(handle) or {}

    return OntologySlugs(
        version=int(payload.get("version", 1)),
        domain_slugs=dict(payload.get("domain_slugs", {})),
        defect_slugs=dict(payload.get("defect_slugs", {})),
        part_slugs=dict(payload.get("part_slugs", {})),
        quality_state_slugs=dict(payload.get("quality_state_slugs", QUALITY_STATE_MAP)),
        task_type_slugs=dict(payload.get("task_type_slugs", TASK_TYPE_MAP)),
    )


def canonical_class_name(defect_name: str, part_name: str) -> str:
    """Return the defect-part leaf class name."""

    return f"{defect_name}_{part_name}"


def infer_support_bucket(unique_image_count: int) -> str:
    """Bucket classes by unique-image support."""

    if unique_image_count >= 1000:
        return "regular"
    if unique_image_count >= 100:
        return "tail"
    return "review"


def infer_allowed_task_types(label_types: Iterable[str]) -> tuple[str, ...]:
    """Map label_type values to task_type values."""

    mapped = {TASK_TYPE_MAP.get(label_type, label_type) for label_type in label_types}
    return tuple(sorted(mapped))


def _row_value(row: Mapping[str, Any] | Any, key: str, default: Any = "") -> Any:
    if isinstance(row, Mapping):
        return row.get(key, default)
    return getattr(row, key, default)


def build_ontology_id(
    *,
    domain: str,
    defect_name: str,
    part_name: str,
    quality_state: str,
    slugs: OntologySlugs | None = None,
) -> str:
    """Create the versioned ontology id for one canonical class."""

    slugs = slugs or load_ontology_slugs()
    return ".".join(
        [
            f"v{slugs.version}",
            slugs.domain_slug(domain),
            slugs.defect_slug(defect_name),
            slugs.part_slug(part_name),
            slugs.quality_state_slug(quality_state),
        ]
    )


def build_parent_ontology_id(domain: str, *, slugs: OntologySlugs | None = None) -> str:
    """Create the ontology parent id for one domain."""

    slugs = slugs or load_ontology_slugs()
    return ".".join([f"v{slugs.version}", slugs.domain_slug(domain)])


def build_ontology_table(
    normalized_rows: Iterable[Mapping[str, Any]],
    *,
    slugs: OntologySlugs | None = None,
) -> list[OntologyRecord]:
    """Build the canonical ontology table from normalized annotation rows."""

    slugs = slugs or load_ontology_slugs()
    grouped: dict[tuple[str, str, str], list[Mapping[str, Any]]] = defaultdict(list)
    for row in normalized_rows:
        grouped[
            (
                str(_row_value(row, "domain", "")),
                str(_row_value(row, "defect_name_norm", "")),
                str(_row_value(row, "part_name_norm", "")),
            )
        ].append(row)

    records: list[OntologyRecord] = []
    for (domain, defect_name, part_name), group in sorted(grouped.items()):
        canonical = canonical_class_name(defect_name, part_name)
        quality_states = {str(_row_value(row, "quality_state", "")) for row in group}
        if not quality_states:
            quality_states = {""}
        label_types = {str(_row_value(row, "label_type", "")) for row in group}
        category_ids = {
            str(_row_value(row, "original_category_id", _row_value(row, "category_id", "")))
            for row in group
            if str(_row_value(row, "original_category_id", _row_value(row, "category_id", "")))
        }
        file_names = {
            str(_row_value(row, "file_name", ""))
            for row in group
            if _row_value(row, "file_name", "")
        }
        unique_domains = {
            str(_row_value(row, "domain", ""))
            for row in group
            if _row_value(row, "domain", "")
        }
        for quality_state in sorted(quality_states):
            ontology_id = build_ontology_id(
                domain=domain,
                defect_name=defect_name,
                part_name=part_name,
                quality_state=quality_state or "defect",
                slugs=slugs,
            )
            allowed_task_types = infer_allowed_task_types(label_types)
            support_bucket = infer_support_bucket(len(file_names))
            records.append(
                OntologyRecord(
                    ontology_id=ontology_id,
                    parent_ontology_id=build_parent_ontology_id(domain, slugs=slugs),
                    display_label=f"{domain}_{defect_name}_{part_name}",
                    canonical_class_name=canonical,
                    domain=domain,
                    defect_name=defect_name,
                    part_name=part_name,
                    quality_state=quality_state or "defect",
                    allowed_task_types=allowed_task_types,
                    row_count=len(group),
                    unique_image_count=len(file_names),
                    unique_domain_count=len(unique_domains),
                    unique_label_type_count=len(label_types),
                    unique_category_id_count=len(category_ids),
                    support_bucket=support_bucket,
                    is_primary_kpi_class=support_bucket == "regular",
                )
            )
    return records


def ontology_records_to_rows(records: Iterable[OntologyRecord]) -> list[dict[str, Any]]:
    """Convert ontology records to plain dictionaries."""

    return [asdict(record) for record in records]


def write_ontology_audit_csv(records: Iterable[OntologyRecord], path: Path) -> Path:
    """Write the ontology table as CSV."""

    rows = ontology_records_to_rows(records)
    if not rows:
        rows = []
    fieldnames = [
        "ontology_id",
        "parent_ontology_id",
        "display_label",
        "canonical_class_name",
        "domain",
        "defect_name",
        "part_name",
        "quality_state",
        "allowed_task_types",
        "row_count",
        "unique_image_count",
        "unique_domain_count",
        "unique_label_type_count",
        "unique_category_id_count",
        "support_bucket",
        "is_primary_kpi_class",
    ]
    normalized_rows = []
    for row in rows:
        normalized = dict(row)
        normalized["allowed_task_types"] = "|".join(row["allowed_task_types"])
        normalized_rows.append(normalized)
    return write_csv_rows(path, normalized_rows, fieldnames=fieldnames)


def write_ontology_audit_markdown(records: Iterable[OntologyRecord], path: Path) -> Path:
    """Write a human-readable ontology summary."""

    records = list(records)
    regular = sum(1 for record in records if record.support_bucket == "regular")
    tail = sum(1 for record in records if record.support_bucket == "tail")
    review = sum(1 for record in records if record.support_bucket == "review")
    lines = [
        "# Ontology Audit",
        "",
        "## Verdict",
        "",
        "- `category_id`는 모델 class로 사용하지 않는다.",
        "- `defect_name × part_name`는 canonical model class로 충분하다.",
        "- `domain`은 ontology hierarchy와 report에만 둔다.",
        "- quality state와 label type은 task별로 분리한다.",
        "",
        "## Support buckets",
        "",
        f"- regular: {regular}",
        f"- tail: {tail}",
        f"- review: {review}",
        "",
        "## Notes",
        "",
        "- ontology_id는 versioned slug 조합으로 생성한다.",
        "- restored prediction은 task-specific local class id를 기준으로 복원한다.",
    ]
    return write_markdown(path, lines)
