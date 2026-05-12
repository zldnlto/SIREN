"""Run import boundary checks for the FastAPI backend."""

from __future__ import annotations

import subprocess
from pathlib import Path


def main() -> int:
    api_dir = Path(__file__).resolve().parents[1]
    result = subprocess.run(
        ["lint-imports", "--config", "pyproject.toml"],
        cwd=api_dir,
        check=False,
        text=True,
    )
    return result.returncode


if __name__ == "__main__":
    raise SystemExit(main())
