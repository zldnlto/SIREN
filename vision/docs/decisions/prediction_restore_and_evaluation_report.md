# 예측 복원 및 계층형 평가 결정 기록

## 복원 기준

- 복원 키는 `model_name + task_type + model_class_id`로 둔다.
- `category_id`는 복원 키나 모델 class로 쓰지 않는다.
- leaf 학습은 leaf label로 복원한다.
- parent 학습은 leaf label로 되돌리지 않고 domain level label로 복원한다.
- binary 학습은 `good` / `defect`로 복원한다.

## 평가 축

- leaf: `defect_name × part_name`
- parent: `domain`
- binary: `good` / `defect`

## 보고서

- label_type별 요약
- support_bucket별 요약
- confusion matrix
- false negative audit
- validation prediction이 있을 때 confidence calibration 요약

## 비고

- 이 문서는 Phase 5/6 구현과 테스트의 기준 문서다.
- leaf를 parent로, parent를 leaf로 자동 승격/복원하지 않는다.
