# 학습 게이트 및 보정 훅 결정 기록

## 게이트 규칙

- export 검증이 통과한 경우에만 YOLO 학습을 시작한다.
- 검증이 실패하면 학습 래퍼는 즉시 중단한다.
- class inclusion과 confidence threshold는 코드 하드코딩이 아니라 정책 객체로 전달한다.
- YOLO class id는 `task_specific_model_class_id`로만 해석하고, `DEFECT_CLASSES`는 사람용 분류 참고용으로만 남긴다.

## Calibration 훅

- validation prediction이 있으면 calibration 요약을 생성한다.
- validation prediction이 없으면 calibration은 조용히 생략한다.
- calibration 결과는 CSV/Markdown으로 남긴다.

## Self-Paced Curriculum Learning (SPL) 전략

- 구현 위치: `vision/scripts/self_paced_train.py`
- easy/hard 판단 기준: YOLO predict confidence 평균값

### easy 샘플 처리 방식 (확정)

**화질 저하(quality degradation) 방식** 사용. easy 샘플 제거 방식 사용 금지.

| 샘플 유형 | 처리 |
|-----------|------|
| easy (confidence 높음) | blur / noise / brightness 저하 적용 후 학습셋 유지 |
| hard (confidence 낮음) | 원본 품질 그대로 유지 |

- easy 제거 방식은 라운드마다 학습셋이 감소 → 데이터가 적을 때 불리
- 화질 저하 방식은 데이터 수 유지 + easy 샘플을 강제로 harder하게 만듦

현재 코드는 easy 제거 방식으로 구현되어 있음 → v2 데이터 확보 후 수정 예정.

## 비고

- 이 문서는 Phase 6의 실행 규칙을 고정한다.
- 실제 학습은 export가 검증된 뒤에만 붙인다.
