# Legacy Pipeline Isolation

The following older scripts are treated as legacy references only:

- `vision/src/prepare_yolo_dataset.py`
- `vision/src/create_sample_manifest.py`
- `vision/src/repair_sample_manifest.py`
- `vision/src/parse_all_labels.py`
- `vision/src/inspect_label.py`
- `vision/docs/legacy/dataset_validation_report.md`
- `vision/docs/legacy/ontology_validation_report.md`

Phase 1/2 code must not import these modules.
The new pipeline lives under `vision/src/data/` and the supporting ontology
helpers live beside it in task-specific modules.
The legacy reports are retained for historical evidence, but they are not the
source of truth for the current ontology contract or Colab execution order.
