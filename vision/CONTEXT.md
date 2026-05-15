---
version: 1
updated: 2026-05-15
---

# SIREN Vision — Context

## 용어 사전

### 양품(Good) Sample
label_type이 `classification`인 정상 샘플. bbox 어노테이션이 없다.
YOLO detection 학습에서 클래스 ID를 부여받지 않으며, bbox label이 없는 이미지로 학습 데이터에 포함되어 background hard negative 역할을 한다.
classification 전용 파이프라인이 필요한 경우 별도 yaml로 분리한다.

> 관련 결정: [ADR-001](docs/adr/001-normal-class-excluded-from-detection.md)

### Canonical Class Name
`defect_name × part_name` 조합. YOLO class ID의 유일 식별자.
예: `crack_paint` (균열 × 도장), `scratch_insulation` (스크래치 × 보온재).
defect명에 재질이 포함되더라도 part_name을 생략하지 않는다.

### TS / VS Split
폴더명 prefix. `TS_` → train, `VS_` → val.
동일 파일이 TS와 VS 모두에 존재하면 TS(train) 우선 보존.
정렬 기준: `p.parts` 기준 `TS_` prefix 탐색 (`"/TS/" in str(p)` 패턴은 폴더명과 불일치하여 사용 금지).

### Single Source of Truth for Class Names
`build_task_label_map("segmentation")`이 class ID의 단일 소스다.
`build_segmentation_runtime_config()`는 이 map을 읽어 `VisionRuntimeConfig.class_names`를 결정한다.
Colab 학습 노트북은 `build_default_runtime_config()` 대신 `build_segmentation_runtime_config()`를 사용해야 한다.
`constants.py`의 `DEFAULT_CLASS_NAMES`는 폴백용 영문 canonical 8개 클래스로 고정되어 있으며, 파이프라인 소스(`build_task_label_map`)가 우선이다.

### Label Generation Pipeline
AIHub JSON 어노테이션 → YOLO 포맷 `.txt` 변환은 `vision/src/data/` 내 모듈이 담당한다
(`segmentation_export.py`, `detection_export.py`, `pipeline.py`).
`vision/src/prepare_yolo_dataset.py`는 레거시 코드로, `source_category_id`를 직접 YOLO class ID로 매핑하는 구조여서 ontology 계층을 우회한다. 현재 파이프라인에서 사용하지 않는다.

### Hard Negative
bbox label이 없는 학습 이미지. 모델이 false positive를 줄이도록 돕는다.
양품(Good) Sample과 Classification-Only Defect가 이 역할을 담당한다.

### Classification-Only Defect
label_type이 `classification`인 결함 샘플. 정상 샘플이 아니라 결함이지만 bbox 어노테이션이 없다.
예: `탱크클리닝불량_모재` → `cleaning_defect_base`.
detection/segmentation training yaml에 class로 포함하지 않는다.
이미지 파일은 CLASS_MAP 기준 폴더로 마이그레이션하여 미래 classification 모델 학습에 활용한다.
detection 학습 시에는 bbox label 없는 hard negative로 투입된다.

> 관련 결정: [ADR-002](docs/adr/002-classification-only-defect-excluded-from-detection.md)
