"""Small helpers for writing markdown and CSV reports.

The Phase 1/2 pipeline keeps reports machine-readable so Colab and the repo
can share the same audit artifacts.
"""

from __future__ import annotations

import csv
from pathlib import Path
from typing import Iterable, Mapping, Sequence


def write_csv_rows(
    path: Path,
    rows: Iterable[Mapping[str, object]],
    *,
    fieldnames: Sequence[str],
) -> Path:
    """Write dictionaries to a CSV file and return the path."""

    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8-sig", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(fieldnames))
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fieldnames})
    return path


def write_markdown(path: Path, lines: Sequence[str]) -> Path:
    """Write a markdown document and return the path."""

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")
    return path

