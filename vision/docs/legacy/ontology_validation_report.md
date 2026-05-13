# Ontology Validation Report

> Archived validation evidence. The current ontology contract is documented in
> `vision/docs/decisions/ontology_4_layer_report.md`.

This report validates the ontology and canonical-label assumptions before finalizing the vision data pipeline.

## Verdict

- `category_id` is **not** safe as a model class.
- `defect_name × part_name` is sufficient as the canonical model class.
- `domain` should remain in the ontology hierarchy and reports, not in the model class.
- The provisional quality-state rule is valid on the current index.
- Label type is cleanly separated by task modality in the current index.
- Restoration should be deterministic and key off task-specific model class IDs, not `category_id`.

## Key Evidence

- `category_id` collision count: 12
- Cross-domain canonical-class collisions: 0
- Quality rule ambiguities: 0
- Mixed label-type canonical classes: 0

## Non-negotiable Decisions

- Preserve `category_id` only as `original_category_id`.
- Use `defect_name × part_name` as the model canonical class.
- Keep `domain` as ontology parent only unless a future collision appears.
- Keep `classification`, `bbox`, and `segmentation+bbox` pipelines separate.
- Never export classification-only positive defects as empty detection labels.
- Use ontology IDs for restoration and hierarchical evaluation.

## Geometry Audit

- Original image dimensions are stored in the COCO JSON inside annotation zips under `images[].width` / `images[].height`.
- Bbox coordinates are stored in `annotations[].bbox`.
- Segmentation polygons are stored in `annotations[].segmentation`.
- Resize method is documented in `vision/data/scripts/resize_images.py` as 640×640 letterbox padding.
- Local resized image root is missing in this workspace (`vision/data/curated` contains only `.DS_Store`), so image-level resolution verification is blocked here.

## Files

- [`ontology_audit.csv`](vision/data/analysis/ontology_audit.csv)
- [`ontology_audit.md`](vision/data/analysis/ontology_audit.md)
- [`quality_state_audit.csv`](vision/data/analysis/quality_state_audit.csv)
