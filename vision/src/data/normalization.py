"""Deterministic label normalization for the task-separated vision pipeline."""

from __future__ import annotations

import unicodedata
from collections.abc import Iterable, Mapping
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

from vision.src.data.config import ValidDomainCombos, ValidDomainDefects
from vision.src.data.labels import parse_zip_name
from vision.src.data.ontology import (
    OntologySlugs,
    build_ontology_id,
    build_parent_ontology_id,
    canonical_class_name,
    load_ontology_slugs,
)

TASK_TYPE_BY_LABEL_TYPE = {
    "classification": "classify",
    "bbox": "detect",
    "segmentation+bbox": "segment",
}

GEOMETRY_LEVEL_BY_LABEL_TYPE = {
    "classification": "image",
    "bbox": "bbox",
    "segmentation+bbox": "mask",
}

AREA_BIN_RULES = (
    (0.005, "tiny"),
    (0.02, "small"),
    (0.10, "medium"),
)

KNOWN_TEXT_FIXES = {
    "용접블루홀": "용접블로우홀",
}


@dataclass(frozen=True)
class NormalizedAnnotation:
    """One normalized annotation row."""

    image_id: str
    file_name: str
    split: str
    source_category_id: int
    source_domain: str
    source_defect: str
    zip_source: str
    annotation_domain: str
    defect_name_raw: str
    part_name_raw: str
    defect_name_norm: str
    part_name_norm: str
    canonical_class_name: str
    original_category_id: int
    label_type: str
    task_type: str
    geometry_level: str
    quality_state: str
    ontology_id: str
    parent_ontology_id: str
    taxonomy_status: str
    taxonomy_reason: str | None
    width: int
    height: int
    area: float | None
    area_ratio: float | None
    area_bin: str | None
    date_captured: str | None
    review_needed: bool
    review_reason: str | None

    @property
    def domain(self) -> str:
        """Backward-compatible alias for the annotation domain."""

        return self.annotation_domain


def normalize_text(value: str | None) -> str:
    """Normalize raw text into a stable NFC string."""

    if value is None:
        return ""
    text = unicodedata.normalize("NFC", str(value)).strip()
    text = " ".join(text.split())
    return KNOWN_TEXT_FIXES.get(text, text)


def normalize_defect_name(value: str | None) -> str:
    """Normalize defect names using explicit typo/synonym fixes."""

    return normalize_text(value)


def normalize_part_name(value: str | None) -> str:
    """Normalize part names using the shared text normalizer."""

    return normalize_text(value)


def infer_quality_state(defect_name: str) -> str:
    """Apply the validated provisional quality-state rule."""

    return "good" if "양품" in defect_name else "defect"


def infer_task_type(label_type: str) -> str:
    """Map label_type to the corresponding task type."""

    return TASK_TYPE_BY_LABEL_TYPE.get(label_type, label_type)


def infer_geometry_level(label_type: str) -> str:
    """Map label_type to the geometry level preserved in the output."""

    return GEOMETRY_LEVEL_BY_LABEL_TYPE.get(label_type, "image")


def infer_area_bin(area_ratio: float | None) -> str | None:
    """Bucket localized labels by normalized area."""

    if area_ratio is None:
        return None
    if area_ratio < AREA_BIN_RULES[0][0]:
        return AREA_BIN_RULES[0][1]
    if area_ratio < AREA_BIN_RULES[1][0]:
        return AREA_BIN_RULES[1][1]
    if area_ratio < AREA_BIN_RULES[2][0]:
        return AREA_BIN_RULES[2][1]
    return "large"


def infer_taxonomy_status(
    *,
    source_domain: str,
    source_defect: str,
    annotation_domain: str,
    defect_name: str,
    part_name: str,
) -> tuple[str, str | None]:
    """Classify rows that need taxonomy review instead of silent deletion."""

    if not source_domain or not source_defect or not annotation_domain:
        return "taxonomy_review_required", "missing_source_or_annotation_context"
    if annotation_domain not in ValidDomainDefects:
        return "taxonomy_extension_candidate", "unknown_annotation_domain"
    if source_domain != annotation_domain:
        return "cross_domain_annotation_candidate", "source_and_annotation_domains_differ"
    if source_defect != defect_name:
        return "likely_label_error", "source_defect_and_annotation_defect_differ"
    if defect_name not in ValidDomainDefects.get(annotation_domain, []):
        return "likely_label_error", "defect_not_in_valid_domain_defects"
    if part_name not in ValidDomainCombos.get(annotation_domain, []):
        return "likely_label_error", "part_not_in_valid_domain_combos"
    return "normal", None


def normalize_row(
    row: Mapping[str, Any],
    *,
    slugs: OntologySlugs | None = None,
    slugs_path: Path | None = None,
) -> NormalizedAnnotation:
    """Normalize one dataset index row."""

    slugs = slugs or load_ontology_slugs(slugs_path)
    zip_info = parse_zip_name(str(row.get("zip_source", "")))
    defect_name_raw = normalize_text(row.get("defect_name", ""))
    part_name_raw = normalize_text(row.get("part_name", ""))
    annotation_domain = normalize_text(row.get("domain", ""))
    source_domain = normalize_text(zip_info.get("domain", ""))
    source_defect = normalize_text(zip_info.get("defect_name", ""))
    source_category_id = int(row.get("category_id") or 0)
    label_type = normalize_text(row.get("label_type", ""))
    task_type = infer_task_type(label_type)
    geometry_level = infer_geometry_level(label_type)
    width = int(row.get("width") or 0)
    height = int(row.get("height") or 0)
    area_value = row.get("area")
    try:
        area = float(area_value) if area_value not in (None, "", "None") else None
    except ValueError:
        area = None
    area_ratio: float | None = None
    area_bin: str | None = None
    if area is not None and width > 0 and height > 0 and geometry_level != "image":
        area_ratio = area / (width * height)
        area_bin = infer_area_bin(area_ratio)
    quality_state = infer_quality_state(defect_name_raw)
    taxonomy_status, taxonomy_reason = infer_taxonomy_status(
        source_domain=source_domain,
        source_defect=source_defect,
        annotation_domain=annotation_domain,
        defect_name=defect_name_raw,
        part_name=part_name_raw,
    )
    ontology_id = build_ontology_id(
        domain=annotation_domain,
        defect_name=defect_name_raw,
        part_name=part_name_raw,
        quality_state=quality_state,
        slugs=slugs,
    )
    parent_ontology_id = build_parent_ontology_id(annotation_domain, slugs=slugs)

    return NormalizedAnnotation(
        image_id=normalize_text(row.get("file_name", "")),
        file_name=normalize_text(row.get("file_name", "")),
        split=normalize_text(row.get("split", "")),
        source_category_id=source_category_id,
        source_domain=source_domain,
        source_defect=source_defect,
        zip_source=normalize_text(row.get("zip_source", "")),
        annotation_domain=annotation_domain,
        defect_name_raw=normalize_text(row.get("defect_name", "")),
        part_name_raw=normalize_text(row.get("part_name", "")),
        defect_name_norm=defect_name_raw,
        part_name_norm=part_name_raw,
        canonical_class_name=canonical_class_name(defect_name_raw, part_name_raw, slugs=slugs),
        original_category_id=source_category_id,
        label_type=label_type,
        task_type=task_type,
        geometry_level=geometry_level,
        quality_state=quality_state,
        ontology_id=ontology_id,
        parent_ontology_id=parent_ontology_id,
        taxonomy_status=taxonomy_status,
        taxonomy_reason=taxonomy_reason,
        width=width,
        height=height,
        area=area,
        area_ratio=area_ratio,
        area_bin=area_bin,
        date_captured=normalize_text(row.get("date_captured", "")) or None,
        review_needed=taxonomy_status != "normal",
        review_reason=taxonomy_reason,
    )


def normalize_rows(
    rows: Iterable[Mapping[str, Any]],
    *,
    slugs_path: Path | None = None,
) -> list[NormalizedAnnotation]:
    """Normalize a sequence of dataset index rows."""

    slugs = load_ontology_slugs(slugs_path)
    return [normalize_row(row, slugs=slugs) for row in rows]


def normalized_rows_to_dicts(rows: Iterable[NormalizedAnnotation]) -> list[dict[str, Any]]:
    """Convert normalized rows into plain dictionaries."""

    dict_rows = []
    for row in rows:
        payload = asdict(row)
        payload["domain"] = row.annotation_domain
        dict_rows.append(payload)
    return dict_rows
