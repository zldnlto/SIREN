# Dataset Validation Report

Phase 1은 현재 저장소의 분석 파일과 메타데이터 경로를 검증해, 이후 정규화와 온톨로지 구현이 어떤 입력을 전제로 해야 하는지 고정한다.

## 확인된 입력

- `vision/data/analysis/dataset_index.csv`
- `vision/data/analysis/combo_counts.csv`
- `vision/data/analysis/label_report.md`
- `vision/data/analysis/ontology_audit.csv`
- `vision/data/analysis/ontology_audit.md`
- `vision/data/analysis/quality_state_audit.csv`
- `vision/docs/decisions/ontology_validation_report.md`
- raw annotation zip: `vision/data/labels/`
- raw image root: `vision/data/raw/TS/`, `vision/data/raw/VS/`
- local resized image root fallback: `vision/data/curated`

## 현재 확인 결과

- `dataset_index.csv` row 수: 299,123
- unique image 수: 279,320
- `label_type` 분포:
  - `segmentation+bbox`: 185,930
  - `bbox`: 24,742
  - `classification`: 88,451
- `defect_name × part_name` 조합 수: 43
- `category_id`는 모델 class로 안전하지 않음
- `defect_name × part_name`는 canonical model class로 충분함
- domain collision: 없음
- mixed label-type canonical class: 없음

## geometry / resize 상태

- bbox는 COCO JSON의 `annotations[].bbox`에 저장된다.
- segmentation polygon은 COCO JSON의 `annotations[].segmentation`에 저장된다.
- 원본 width / height는 COCO JSON의 `images[].width`, `images[].height`에 저장된다.
- resize 메서드는 640×640 letterbox padding으로 문서화돼 있다.
- 이 워크스페이스에서는 local resized image root가 비어 있어 file-level 640×640 검증은 일부 막힌다.

## blocker

- 실제 이미지 파일이 없으면 geometry-dependent export와 file-level 해상도 검증은 하지 않는다.
- metadata-only normalization, ontology mapping, label map 생성, audit report 생성은 계속 가능하다.
