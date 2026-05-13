"""Hierarchical evaluation and calibration scaffolding."""

from __future__ import annotations

from collections import Counter, defaultdict
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable, Mapping

from vision.src.data.reports import write_csv_rows, write_markdown


@dataclass(frozen=True)
class EvaluationSample:
    """One truth/prediction pair used for hierarchical scoring."""

    image_id: str
    file_name: str
    task_type: str
    label_type: str
    support_bucket: str
    true_canonical_class_name: str
    predicted_canonical_class_name: str
    true_domain: str
    predicted_domain: str
    true_quality_state: str
    predicted_quality_state: str
    confidence: float


@dataclass(frozen=True)
class HierarchicalMetricRow:
    """Aggregated metric row for one label at one granularity."""

    granularity: str
    label: str
    support: int
    correct_count: int
    incorrect_count: int
    false_negative_count: int
    precision: float
    recall: float
    f1: float


@dataclass(frozen=True)
class ConfusionMatrixRow:
    """One confusion-matrix cell."""

    granularity: str
    true_label: str
    predicted_label: str
    count: int


@dataclass(frozen=True)
class FalseNegativeRow:
    """One false-negative audit row."""

    granularity: str
    image_id: str
    file_name: str
    true_label: str
    predicted_label: str
    task_type: str
    label_type: str
    support_bucket: str
    confidence: float


@dataclass(frozen=True)
class CalibrationRow:
    """One class-wise confidence calibration row."""

    label: str
    threshold: float
    total_count: int
    above_threshold_count: int
    mean_confidence: float


def _label_for(sample: EvaluationSample, granularity: str, *, side: str) -> str:
    if granularity == "binary":
        value = sample.true_quality_state if side == "true" else sample.predicted_quality_state
        return "good" if value == "good" else "defect"
    if granularity == "parent":
        return sample.true_domain if side == "true" else sample.predicted_domain
    return (
        sample.true_canonical_class_name
        if side == "true"
        else sample.predicted_canonical_class_name
    )


def _precision_recall_f1(
    *,
    support: int,
    correct_count: int,
    false_negative_count: int,
) -> tuple[float, float, float]:
    false_positive_count = max(0, support - correct_count)
    predicted_positive = correct_count + false_positive_count
    precision = correct_count / predicted_positive if predicted_positive else 0.0
    recall = correct_count / support if support else 0.0
    if precision + recall == 0:
        return precision, recall, 0.0
    f1 = 2 * precision * recall / (precision + recall)
    return precision, recall, f1


def build_hierarchical_metric_rows(
    samples: Iterable[EvaluationSample],
    *,
    granularity: str,
) -> list[HierarchicalMetricRow]:
    """Aggregate one granularity of metrics."""

    grouped: dict[str, list[EvaluationSample]] = defaultdict(list)
    for sample in samples:
        grouped[_label_for(sample, granularity, side="true")].append(sample)

    rows: list[HierarchicalMetricRow] = []
    for label in sorted(grouped):
        group = grouped[label]
        correct_count = sum(
            1
            for sample in group
            if _label_for(sample, granularity, side="true")
            == _label_for(sample, granularity, side="pred")
        )
        incorrect_count = len(group) - correct_count
        false_negative_count = sum(
            1
            for sample in group
            if _label_for(sample, granularity, side="true") != _label_for(sample, granularity, side="pred")
            and _label_for(sample, granularity, side="true") != "good"
        )
        precision, recall, f1 = _precision_recall_f1(
            support=len(group),
            correct_count=correct_count,
            false_negative_count=false_negative_count,
        )
        rows.append(
            HierarchicalMetricRow(
                granularity=granularity,
                label=label,
                support=len(group),
                correct_count=correct_count,
                incorrect_count=incorrect_count,
                false_negative_count=false_negative_count,
                precision=precision,
                recall=recall,
                f1=f1,
            )
        )
    return rows


def build_confusion_matrix_rows(
    samples: Iterable[EvaluationSample],
    *,
    granularity: str,
) -> list[ConfusionMatrixRow]:
    """Return a confusion matrix at one granularity."""

    counts: Counter[tuple[str, str]] = Counter()
    for sample in samples:
        true_label = _label_for(sample, granularity, side="true")
        predicted_label = _label_for(sample, granularity, side="pred")
        counts[(true_label, predicted_label)] += 1

    return [
        ConfusionMatrixRow(
            granularity=granularity,
            true_label=true_label,
            predicted_label=predicted_label,
            count=count,
        )
        for (true_label, predicted_label), count in sorted(counts.items())
    ]


def build_false_negative_rows(
    samples: Iterable[EvaluationSample],
    *,
    granularity: str,
) -> list[FalseNegativeRow]:
    """Return an audit table for false negatives."""

    rows: list[FalseNegativeRow] = []
    for sample in samples:
        true_label = _label_for(sample, granularity, side="true")
        predicted_label = _label_for(sample, granularity, side="pred")
        if true_label == predicted_label:
            continue
        if granularity == "binary" and true_label == "good":
            continue
        rows.append(
            FalseNegativeRow(
                granularity=granularity,
                image_id=sample.image_id,
                file_name=sample.file_name,
                true_label=true_label,
                predicted_label=predicted_label,
                task_type=sample.task_type,
                label_type=sample.label_type,
                support_bucket=sample.support_bucket,
                confidence=sample.confidence,
            )
        )
    return rows


def build_label_type_report(samples: Iterable[EvaluationSample]) -> list[dict[str, Any]]:
    """Summarize accuracy by label type."""

    grouped: dict[str, list[EvaluationSample]] = defaultdict(list)
    for sample in samples:
        grouped[sample.label_type].append(sample)

    rows: list[dict[str, Any]] = []
    for label_type, group in sorted(grouped.items()):
        correct = sum(
            1 for sample in group if sample.true_canonical_class_name == sample.predicted_canonical_class_name
        )
        rows.append(
            {
                "label_type": label_type,
                "count": len(group),
                "correct_count": correct,
                "incorrect_count": len(group) - correct,
                "accuracy": correct / len(group) if group else 0.0,
            }
        )
    return rows


def build_support_bucket_report(samples: Iterable[EvaluationSample]) -> list[dict[str, Any]]:
    """Summarize accuracy by support bucket."""

    grouped: dict[str, list[EvaluationSample]] = defaultdict(list)
    for sample in samples:
        grouped[sample.support_bucket].append(sample)

    rows: list[dict[str, Any]] = []
    for support_bucket, group in sorted(grouped.items()):
        correct = sum(
            1 for sample in group if sample.true_canonical_class_name == sample.predicted_canonical_class_name
        )
        rows.append(
            {
                "support_bucket": support_bucket,
                "count": len(group),
                "correct_count": correct,
                "incorrect_count": len(group) - correct,
                "accuracy": correct / len(group) if group else 0.0,
            }
        )
    return rows


def build_calibration_rows(
    samples: Iterable[EvaluationSample],
    *,
    thresholds: Mapping[str, float] | None = None,
) -> list[CalibrationRow]:
    """Build a light-weight calibration report from validation predictions."""

    thresholds = thresholds or {}
    grouped: dict[str, list[EvaluationSample]] = defaultdict(list)
    for sample in samples:
        grouped[sample.predicted_canonical_class_name].append(sample)

    rows: list[CalibrationRow] = []
    for label, group in sorted(grouped.items()):
        threshold = float(thresholds.get(label, thresholds.get("__default__", 0.0)))
        above = sum(1 for sample in group if sample.confidence >= threshold)
        mean_confidence = sum(sample.confidence for sample in group) / len(group)
        rows.append(
            CalibrationRow(
                label=label,
                threshold=threshold,
                total_count=len(group),
                above_threshold_count=above,
                mean_confidence=mean_confidence,
            )
        )
    return rows


def write_hierarchical_metric_report(
    rows: Iterable[HierarchicalMetricRow],
    *,
    csv_path: Path,
    md_path: Path,
) -> tuple[Path, Path]:
    """Persist hierarchical metric rows in both CSV and markdown form."""

    row_dicts = [asdict(row) for row in rows]
    write_csv_rows(
        csv_path,
        row_dicts,
        fieldnames=[
            "granularity",
            "label",
            "support",
            "correct_count",
            "incorrect_count",
            "false_negative_count",
            "precision",
            "recall",
            "f1",
        ],
    )
    write_markdown(
        md_path,
        [
            "# Hierarchical Metric Report",
            "",
            f"- rows: {len(row_dicts)}",
        ],
    )
    return csv_path, md_path


def write_simple_report(
    rows: Iterable[Mapping[str, Any]],
    *,
    csv_path: Path,
    md_path: Path,
    title: str,
) -> tuple[Path, Path]:
    """Persist a generic report table."""

    row_dicts = [dict(row) for row in rows]
    fieldnames = sorted({field for row in row_dicts for field in row})
    write_csv_rows(csv_path, row_dicts, fieldnames=fieldnames)
    write_markdown(md_path, [f"# {title}", "", f"- rows: {len(row_dicts)}"])
    return csv_path, md_path

