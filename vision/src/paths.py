"""Path helpers for local, Colab, and Drive-backed runs."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class VisionPaths:
    """Project paths used by the Colab-friendly vision workflow."""

    repo_root: Path
    vision_root: Path
    data_root: Path
    raw_root: Path
    resized_root: Path
    labels_root: Path
    runs_root: Path
    drive_runs_root: Path

    def class_root(self, class_name: str) -> Path:
        """Return the curated directory for one class."""

        return self.resized_root / class_name

    def class_image_dir(self, class_name: str, split: str) -> Path:
        """Return the image directory for one class and split."""

        return self.class_root(class_name) / "images" / split

    def class_label_dir(self, class_name: str, split: str) -> Path:
        """Return the label directory for one class and split."""

        return self.class_root(class_name) / "labels" / split

    def drive_run_dir(self, run_name: str) -> Path:
        """Return the Colab Drive run directory for one experiment."""

        return self.drive_runs_root / run_name


def build_default_paths() -> VisionPaths:
    """Build the default path layout from the repository root.

    Colab notebooks should import this helper instead of hardcoding paths,
    so a future directory move only needs one update here.
    """

    repo_root = Path(__file__).resolve().parents[2]
    vision_root = repo_root / "vision"
    data_root = vision_root / "data"
    return VisionPaths(
        repo_root=repo_root,
        vision_root=vision_root,
        data_root=data_root,
        raw_root=data_root / "raw",
        resized_root=data_root / "resized",
        labels_root=data_root / "labels",
        runs_root=vision_root / "runs",
        drive_runs_root=Path("/content/drive/MyDrive/siren/runs"),
    )

