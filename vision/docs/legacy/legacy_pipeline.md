# Legacy Pipeline Isolation

The following older scripts are treated as legacy references only:

- `vision/src/prepare_yolo_dataset.py`
- `vision/src/create_sample_manifest.py`
- `vision/src/repair_sample_manifest.py`
- `vision/src/parse_all_labels.py`
- `vision/src/inspect_label.py`

Phase 1/2 code must not import these modules.
The new pipeline lives under `vision/src/data/` and the supporting ontology
helpers live beside it in task-specific modules.
