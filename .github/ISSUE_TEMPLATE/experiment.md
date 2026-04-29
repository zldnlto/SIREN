---
name: Experiment
about: vision 모델 학습, 데이터셋, 성능 비교 실험을 기록합니다.
title: "[exp] "
labels: "🧠 ML, 🧪 exp"
assignees: "zldnlto"
---

## 실험 목적

<!-- 이 실험을 왜 하는지 적어주세요. -->

예: YOLOv8n baseline 성능을 확인한다.

## 대상 영역

- [ ] app
- [ ] api
- [x] vision
- [ ] infra
- [ ] docs

## 실험 가설

<!-- 어떤 변경이 성능에 어떤 영향을 줄 것으로 예상하나요? -->

예: image size를 640으로 고정하면 mAP가 안정적으로 측정될 것이다.

## 실험 내용

<!-- 실험 전 계획을 적어주세요. 아직 모르는 값은 "미정"으로 남겨도 됩니다. -->

- 모델:
- 데이터셋:
- 주요 변경사항:
- 학습 epoch:
- image size:
- batch size:
- augmentation:
- 기타 설정:

## 작업 범위

### 생성할 파일

<!-- 예: config, experiment log, notebook, result md 등 -->

-

### 수정할 파일

<!-- 예: train script, dataset config 등 -->

-

### 건드리지 않을 파일

<!-- 기존 baseline, weight, dataset 등을 실수로 건드리지 않도록 적어주세요. -->

-

## 완료 조건

- [ ] 학습 또는 추론 실험을 완료했다.
- [ ] 실험 결과 metric을 기록했다.
- [ ] weight 저장 위치를 기록했다.
- [ ] 이전 실험 또는 baseline과 비교했다.
- [ ] 불필요한 파일 변경이 없다.

## 실험 결과

<!-- 실험 완료 후 작성합니다. PR 작성 시에도 동일한 내용을 복사해 기록합니다. -->

| 항목           | 값  |
| -------------- | --- |
| 모델명         |     |
| 데이터셋       |     |
| mAP@50         |     |
| mAP@50-95      |     |
| Precision      |     |
| Recall         |     |
| 이전 대비 성능 |     |
| 학습 시간      |     |
| 비고           |     |

## Weight 저장 위치

<!-- Git에 weight를 직접 올리지 말고 저장 위치만 기록합니다. -->
<!-- 예: vision/runs/detect/yolov8n-baseline-v1/weights/best.pt -->

## 결과 해석

<!-- 성능이 좋아졌는지, 나빠졌는지, 다음 실험은 무엇인지 적어주세요. -->

## 관련 이슈 / PR

- 관련 이슈:
- 관련 PR:
- baseline 실험:

## 참고 컨텍스트

<!-- 데이터셋 설명, 이전 실험, 참고 문서, 주의사항 등을 적어주세요. -->

-
