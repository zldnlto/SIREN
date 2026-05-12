from __future__ import annotations

import subprocess
from pathlib import Path


def test_import_boundaries_pass():
    api_dir = Path(__file__).resolve().parents[1]
    result = subprocess.run(
        ["lint-imports", "--config", "pyproject.toml"],
        cwd=api_dir,
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, result.stdout + result.stderr
