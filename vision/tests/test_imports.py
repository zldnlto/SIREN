from __future__ import annotations


def test_vision_package_exports():
    from vision import (
        DEFAULT_CLASS_NAMES,
        VisionPaths,
        VisionRuntimeConfig,
        build_default_paths,
        build_default_runtime_config,
    )

    config = build_default_runtime_config()

    assert isinstance(DEFAULT_CLASS_NAMES, tuple)
    assert len(DEFAULT_CLASS_NAMES) == 8
    assert isinstance(config, VisionRuntimeConfig)
    assert isinstance(config.paths, VisionPaths)
    assert build_default_paths().raw_root.name == "raw"

