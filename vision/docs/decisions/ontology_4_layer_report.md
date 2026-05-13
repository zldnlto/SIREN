# 4-Layer Ontology Decision Report

## Layer mapping

- source layer
  - `source_category_id`
  - `source_domain`
  - `source_defect`
  - `zip_source`
- annotation layer
  - `annotation_domain`
  - `defect_name`
  - `part_name`
  - `original_category_id`
  - `label_type`
  - `taxonomy_status`
- training layer
  - `task_type`
  - `canonical_class_name = defect_name × part_name`
  - `task_specific_model_class_id`
- restoration layer
  - `ontology_id`
  - `display_label`
  - `quality_state`
  - `hierarchy`

## Validation rule

- `category_id` is metadata only.
- training/export code must use `task_specific_model_class_id` as the local YOLO class id.
- `task_specific_model_class_id` is deterministic and ontology-derived: sort eligible ontology rows by `ontology_id`, then enumerate per task.
- `taxonomy_status` must preserve review candidates instead of deleting them.
- taxonomy review rows are excluded from default YOLO training/export, but remain available for reports and RAG review.
- `domain` in downstream code should be treated as annotation domain.

## 비고

- 이 문서는 Phase 3~6 재정렬의 기준이다.
- source domain과 annotation domain은 다를 수 있다.
- 이전 validation evidence는 `vision/docs/legacy/ontology_validation_report.md`에 보관한다.
