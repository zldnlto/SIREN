# 학습 게이트 및 보정 훅 결정 기록

## 게이트 규칙

- export 검증이 통과한 경우에만 YOLO 학습을 시작한다.
- 검증이 실패하면 학습 래퍼는 즉시 중단한다.
- class inclusion과 confidence threshold는 코드 하드코딩이 아니라 정책 객체로 전달한다.

## Calibration 훅

- validation prediction이 있으면 calibration 요약을 생성한다.
- validation prediction이 없으면 calibration은 조용히 생략한다.
- calibration 결과는 CSV/Markdown으로 남긴다.

## 비고

- 이 문서는 Phase 6의 실행 규칙을 고정한다.
- 실제 학습은 export가 검증된 뒤에만 붙인다.
