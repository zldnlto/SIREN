# Ontology Audit

## Summary

- `dataset_index.csv` rows: 299,123
- Unique images: 279,320
- Category IDs: 23
- Canonical `defect_name × part_name` classes: 43
- Label-type separated canonical classes:
  - `segmentation+bbox`: 31
  - `bbox`: 6
  - `classification`: 6
- Category IDs with multiple canonical classes: 12
- Canonical classes spanning multiple domains: 0
- Quality-state ambiguities: 0

## 1) `category_id` cannot be used as a model class

Several `category_id` values map to multiple `defect_name × part_name` classes.
`category_id` must remain metadata only as `original_category_id`.

| category_id | unique combos | mapped canonical classes |
| --- | --- | --- |
| 1101 | 3 | 용접양품_도장, 용접양품_보온재, 용접양품_조인트 |
| 1102 | 2 | 용접불량_도장, 용접불량_조인트 |
| 2101 | 3 | 표면양품_도장, 표면양품_모재, 표면양품_보온재 |
| 2102 | 2 | 균열_도장, 균열_보온재 |
| 2302 | 4 | 도막떨어짐_도장, 도막떨어짐_케이블, 도막떨어짐_케이블타이, 도막떨어짐_파이프 |
| 2402 | 2 | 도막분리_도장, 도막분리_케이블타이 |
| 2502 | 6 | 스크래치_도장, 스크래치_모재, 스크래치_보온재, 스크래치_조인트, 스크래치_케이블, 스크래치_케이블타이 |
| 3101 | 2 | 볼트체결양품_케이블그랜드, 볼트체결양품_파이프 |
| 3102 | 2 | 볼트체결불량_케이블그랜드, 볼트체결불량_파이프 |
| 4202 | 2 | 케이블손상_케이블, 케이블손상_케이블타이 |
| 5101 | 2 | 절단양품_모재, 절단양품_보온재 |
| 5102 | 2 | 절단불량_모재, 절단불량_보온재 |

## 2) `defect_name × part_name` is sufficient as the canonical model class

No canonical class spans multiple domains.
`domain` should stay in the ontology hierarchy only.

| canonical class | unique domains | domains | label types | unique category_ids | rows | unique images |
| --- | --- | --- | --- | --- | --- | --- |
| 표면처리_균열_도장 | 1 | 표면처리 | segmentation+bbox | 1 | 14,859 | 10,736 |
| 파이프_볼트체결양품_파이프 | 1 | 파이프 | bbox | 1 | 5,275 | 4,005 |
| 파이프_볼트체결불량_파이프 | 1 | 파이프 | bbox | 1 | 10,097 | 10,048 |

## 3) Domain stays as ontology parent only

- `표면처리_균열_도장`: single domain, no collision
- `파이프_볼트체결양품_파이프`: single domain, no collision
- `파이프_볼트체결불량_파이프`: single domain, no collision

Recommended default: keep `domain` in ontology IDs, lineage, and reports, not in the model class.

## 4) Provisional quality rule is valid

Rule:
- if `defect_name` contains `양품`, `quality_state = good`
- otherwise, `quality_state = defect`

No violations or ambiguities were found under this rule in the current index.

## 5) Label type separation is clean at the canonical-class level

- Mixed label-type canonical classes: 0
- Bounding-box-only canonical classes: 6
- Classification-only canonical classes: 6
- Segmentation+bbox canonical classes: 31

Classification-only positive defect labels must remain image-level only and must not be exported as empty detection labels.

## 6) Restoration is deterministic

Use a restoration key of:

`(model_name, task_type, model_class_id) -> ontology_id -> display_label`

Restoration must not depend on `category_id`.

## Geometry and image-source audit

- `dataset_index.csv` exists at `vision/data/analysis/dataset_index.csv`
- `combo_counts.csv` exists at `vision/data/analysis/combo_counts.csv`
- `label_report.md` exists at `vision/data/analysis/label_report.md`
- Raw annotation zips exist under `vision/data/labels`
- Raw image directory exists under `vision/data/raw`, but no image files are present in this working tree
- Curated/resized directory exists under `vision/data/curated`, but no image files are present in this working tree

Geometry sources:
- Original image width/height are stored in the COCO JSON `images[].width` / `images[].height` fields inside each annotation zip
- Bbox coordinates are stored in `annotations[].bbox`
- Segmentation polygons are stored in `annotations[].segmentation`
- Resize method is documented in `vision/data/scripts/resize_images.py` as YOLO-style letterbox 640×640

Because the local synced resized image root is absent, file-level 640×640 resolution verification is blocked in this workspace.

## Outputs

- [`ontology_audit.csv`](ontology_audit.csv)
- [`quality_state_audit.csv`](quality_state_audit.csv)
- [`ontology_validation_report.md`](../docs/decisions/ontology_validation_report.md)
