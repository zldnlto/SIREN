# vision/docs/decisions

vision pipeline의 **canonical decision source**다.
이 디렉터리의 문서가 파이프라인 구현 및 Colab 실행의 최종 기준이다.
`vision/docs/legacy/`의 이전 validation report는 historical evidence로만 남아 있으며, 이 디렉터리의 문서가 우선한다.

## 파일 목록

| 파일 | 역할 | 중요 계약 |
|------|------|-----------|
| `ontology_4_layer_report.md` | 4-layer ontology 구조 결정 기록 | `task_specific_model_class_id`는 `ontology_id` 기준 deterministic 정렬 후 enumerate; `category_id`는 metadata only |
| `split_sampling_report.md` | TS/VS split 및 class-balanced sampling 결정 기록 | split 충돌 시 TL 우선; sampling 키는 training layer 파생; taxonomy review 행은 기본 sampling에서 제외 |
| `task_export_report.md` | classification/detection/segmentation task별 export 결정 기록 | classification-only sample을 detection empty label로 내보내지 않음; export root는 `vision/data/processed/exports/<task>` |
| `training_validation_report.md` | 학습 게이트 및 calibration 훅 결정 기록 | export 검증 통과 후에만 학습 시작; YOLO class id는 `task_specific_model_class_id`만 사용 |
| `prediction_restore_and_evaluation_report.md` | 예측 복원 및 계층형 평가 결정 기록 | 복원 키 = `model_name + task_type + model_class_id`; `category_id`를 복원 키로 쓰지 않음 |

## ADR과의 관계

이 디렉터리는 pipeline 실행 계약을 담는다.
아키텍처 수준의 결정(모델 선정, 클래스 제외 근거)은 `vision/docs/adr/`에 있다.
