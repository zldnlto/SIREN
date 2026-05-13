# Vision Colab Guide

## 목적

- Colab에서 `vision` 모듈을 import해서 데이터 준비, 학습, 평가를 한 흐름으로 실행한다.
- 노트북은 실행 순서만 담당하고, 반복되는 로직은 `vision/` 모듈이 맡는다.

## 준비 순서

1. 저장소를 Colab에 clone한다.
2. `siren-api` 루트를 `sys.path`에 넣고 `import vision`이 되는지 확인한다.
3. Google Drive를 마운트한다.
4. `vision.data`의 데이터 준비 함수를 써서 curated dataset을 만든다.
5. `vision.train_yolo_segmentation(...)`으로 학습을 실행한다.
6. `vision.evaluate_yolo_segmentation(...)`으로 검증 지표를 확인한다.
7. 생성된 `best.pt`를 Drive 복사본 기준으로 FastAPI에 연결한다.

## import 예시

```python
from pathlib import Path

from vision import (
    build_default_runtime_config,
    build_sample_manifest,
    prepare_curated_dataset,
    train_yolo_segmentation,
    evaluate_yolo_segmentation,
)
```

## 데이터 준비 예시

```python
runtime = build_default_runtime_config()
manifest, _ = build_sample_manifest()
prepare_curated_dataset(
    manifest,
    raw_root=runtime.paths.raw_root,
    labels_root=runtime.paths.labels_root,
    output_root=runtime.paths.resized_root,
    target_size=runtime.image_size,
)
```

## 학습 예시

```python
result = train_yolo_segmentation(
    runtime,
    run_name="surface-seg-v1",
    curated_root=runtime.paths.resized_root,
)
print(result.best_weight_path)
print(result.drive_best_weight_path)
```

## 평가 예시

```python
metrics = evaluate_yolo_segmentation(
    result.best_weight_path,
    result.artifacts.data_yaml_path,
    runtime,
)
print(metrics)
```

## 실행 원칙

- Colab에서는 경로를 하드코딩하지 않는다.
- `vision/runs/<run_name>/`는 실험별 로컬 결과 폴더로 본다.
- Drive의 `best.pt`가 있으면 그 경로를 서빙 기준으로 쓴다.
- 노트북 셀은 실패 지점을 좁게 나눠서 디버깅하기 쉽게 작성한다.

## 자주 보는 문제

- `import vision`이 실패하면 repo 루트가 `sys.path`에 들어갔는지 먼저 본다.
- `best.pt`가 없으면 학습 결과 폴더와 Drive 미러링 경로를 먼저 본다.
- `train/val` 디렉터리가 비어 있으면 curated dataset 생성이 먼저 끝났는지 확인한다.
