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
    build_default_runtime_config,
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

## 실행 예시

```python
data_config = load_data_config()
runtime = build_default_runtime_config()

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

## 자주 보는 문제

- `import vision`이 실패하면 repo 루트가 `sys.path`에 들어갔는지 먼저 본다.
- `best.pt`가 없으면 학습 결과 폴더와 Drive 미러링 경로를 먼저 본다.
- `train/val` 디렉터리가 비어 있으면 split/sampling과 export가 먼저 끝났는지 확인한다.
- 특정 sample이 빠졌다면 taxonomy review 후보인지 먼저 확인한다.
