# Task Export Report

## Verdict

- classification, detection, segmentation export를 완전히 분리했다.
- `category_id`는 model class가 아니라 원본 메타데이터로만 보존한다.
- model class는 `task_specific_model_class_id`를 사용하고, 그 값은 ontology에서 deterministic하게 파생한다.
- classification-only sample은 detection/segmentation의 empty label로 내보내지 않는다.
- bbox-only sample은 segmentation mask로 승격하지 않는다.
- detection/segmentation은 `dataset_index.csv`의 width/height와 COCO JSON을 교차 확인한 뒤 640x640 letterbox transform을 적용한다.
- taxonomy review rows는 기본 export에서 제외하고 report/RAG용으로만 남긴다.

## Export Roots

- classification: `vision/data/processed/exports/classification`
- detection: `vision/data/processed/exports/detection`
- segmentation: `vision/data/processed/exports/segmentation`

## Generated Artifacts

- `*_classification_manifest.json`
- `*_classification_report.csv`
- `*_classification_report.md`
- `*_detection_manifest.json`
- `*_detection_report.csv`
- `*_detection_report.md`
- `*_segmentation_manifest.json`
- `*_segmentation_report.csv`
- `*_segmentation_report.md`

## Notes

- classification export는 image-level label만 기록한다.
- detection export는 bbox-backed annotation만 기록한다.
- segmentation export는 실제 polygon/mask가 있을 때만 기록한다.
- export manifest는 file_name 기준 deterministic order를 유지한다.
