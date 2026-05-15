# Vision Colab Guide

## 목적

- Colab에서 `vision` 모듈을 import해서 데이터 준비, split/sampling, task export, 학습, 평가를 순서대로 실행한다.
- 노트북은 실행 순서만 담당하고, 반복되는 로직은 `vision/` 모듈이 맡는다.
- YOLO 학습/라벨 export 기준은 `task_specific_model_class_id`이고, 사람용 결함 목록/RAG 기준은 `DEFECT_CLASSES` 또는 `DEFECT_FAMILIES`이다.

## 준비 순서

1. 저장소를 Colab에 clone한다.
2. `siren-api` 루트를 `sys.path`에 넣고 `import vision`이 되는지 확인한다.
3. Google Drive를 마운트한다.
4. `vision`의 데이터 설정과 dataset index를 읽는다.
5. `normalize_rows(...)`와 `build_ontology_table(...)`로 ontology/annotation을 정규화한다.
6. `build_image_split_records(...)`와 `build_sampling_manifest(...)`로 split/sampling을 고정한다.
7. `export_classification_dataset(...)`, `export_detection_dataset(...)`, `export_segmentation_dataset(...)`로 task별 export를 따로 생성한다.
8. `build_yolo_dataset_yaml_text(...)`로 YOLO yaml을 만든다.
9. `train_yolo_segmentation(...)` 또는 `train_yolo_segmentation_with_validation_gate(...)`로 학습을 실행한다.
10. `evaluate_yolo_segmentation(...)`으로 검증 지표를 확인하고, `sync_best_weight_to_drive(...)`로 `best.pt`를 Drive에 미러링한다.

## import 예시

```python
from vision import (
    build_segmentation_runtime_config,  # 권장: class_names를 label map에서 자동으로 결정
    build_default_runtime_config,       # 폴백: DEFAULT_CLASS_NAMES(8개 영문 canonical) 사용
    build_image_split_records,
    build_ontology_table,
    build_sampling_manifest,
    build_yolo_dataset_yaml_text,
    evaluate_yolo_segmentation,
    export_classification_dataset,
    export_detection_dataset,
    export_segmentation_dataset,
    load_data_config,
    load_dataset_index_rows,
    normalize_rows,
    sync_best_weight_to_drive,
    train_yolo_segmentation,
    train_yolo_segmentation_with_validation_gate,
)
```

> `build_segmentation_runtime_config()`는 `build_task_label_map("segmentation")`을 읽어
> `VisionRuntimeConfig.class_names`를 결정한다. class ID가 label map에서 파생되어야 하므로
> 학습 노트북에서는 `build_default_runtime_config()` 대신 이 함수를 사용한다.

## 4단계 코드 셀: 데이터 설정 + dataset index 로드

```python
from pathlib import Path

from vision import load_data_config, load_dataset_index_rows

# Colab에서 Drive에 curated 데이터를 sync한 경우 이 값을 맞춘다.
# 예: /content/drive/MyDrive/siren/data/curated
# 이미 환경변수가 있으면 이 줄은 생략 가능하다.
# import os
# os.environ["VISION_RESIZED_IMAGE_ROOT"] = "/content/drive/MyDrive/siren/data/curated"

data_config = load_data_config()

print("[config] dataset_index_path:", data_config.dataset_index_path)
print("[config] annotation_root:", data_config.annotation_root)
print("[config] resized_root:", data_config.resized_root)
print("[config] resized_root exists:", data_config.resized_root.exists())

rows = load_dataset_index_rows(data_config.dataset_index_path)
print("[dataset_index] row_count:", len(rows))

if rows:
    sample = rows[0]
    print("[dataset_index] sample keys:", sorted(sample.keys()))
    print("[dataset_index] sample file_name:", sample.get("file_name"))
    print("[dataset_index] sample split:", sample.get("split"))
    print("[dataset_index] sample label_type:", sample.get("label_type"))

# file_name -> resized image direct mapping quick check
missing_file_name = [r for r in rows[:200] if not r.get("file_name")]
print("[dataset_index] missing file_name in first 200 rows:", len(missing_file_name))
```

## 실행 예시

```python
data_config = load_data_config()
runtime = build_segmentation_runtime_config()  # label map 기반 class_names 자동 결정

rows = load_dataset_index_rows(data_config.dataset_index_path)
normalized_rows = normalize_rows(rows, slugs_path=data_config.ontology_slugs_path)
ontology_records = build_ontology_table(normalized_rows)

split_records, split_report = build_image_split_records(
    normalized_rows,
    ontology_records=ontology_records,
)
sampling_records, sampling_report = build_sampling_manifest(
    split_records,
    ontology_records,
)

cls_result = export_classification_dataset(
    normalized_rows,
    ontology_records=ontology_records,
    resized_root=data_config.resized_root,
    labels_root=data_config.annotation_root,
)
det_result = export_detection_dataset(
    normalized_rows,
    ontology_records=ontology_records,
    resized_root=data_config.resized_root,
    labels_root=data_config.annotation_root,
)
seg_result = export_segmentation_dataset(
    normalized_rows,
    ontology_records=ontology_records,
    resized_root=data_config.resized_root,
    labels_root=data_config.annotation_root,
)

data_yaml_text = build_yolo_dataset_yaml_text(data_config.resized_root)
result = train_yolo_segmentation(
    runtime,
    run_name="surface-seg-v1",
    curated_root=data_config.resized_root,
)
metrics = evaluate_yolo_segmentation(
    result.best_weight_path,
    result.artifacts.data_yaml_path,
    runtime,
)
drive_weight = sync_best_weight_to_drive(result.artifacts, result.best_weight_path)
```

## 실행 원칙

- Colab에서는 경로를 하드코딩하지 않는다.
- `vision/runs/<run_name>/`는 실험별 로컬 결과 폴더로 본다.
- `task_specific_model_class_id`는 `ontology_id`를 task별로 deterministic하게 정렬한 뒤 파생한 local label이다.
- taxonomy review 후보는 기본 학습/export에서 제외하고, report/RAG/검토용으로만 보존한다.
- `DEFECT_CLASSES`는 사람이 읽는 결함 목록이며, YOLO class id의 기준이 아니다.
- Drive의 `best.pt`가 있으면 그 경로를 서빙 기준으로 쓴다.
- 노트북 셀은 실패 지점을 좁게 나눠서 디버깅하기 쉽게 작성한다.
- `build_segmentation_runtime_config()`를 사용해야 class_names가 label map에서 자동 결정된다. `build_default_runtime_config()`는 폴백 전용이다.
- `vision/src/prepare_yolo_dataset.py`는 레거시 코드(`vision/src/legacy/`로 이동됨)다. 현재 파이프라인에서 사용하지 않는다.

## 자주 보는 문제

- `import vision`이 실패하면 repo 루트가 `sys.path`에 들어갔는지 먼저 본다.
- `best.pt`가 없으면 학습 결과 폴더와 Drive 미러링 경로를 먼저 본다.
- `train/val` 디렉터리가 비어 있으면 split/sampling과 export가 먼저 끝났는지 확인한다.
- 특정 sample이 빠졌다면 taxonomy review 후보인지 먼저 확인한다.
