# ADR-002: Classification-Only 결함 클래스를 detection yaml에서 제외

| 항목   | 내용       |
|--------|------------|
| 상태   | 확정       |
| 결정일 | 2026-05-15 |

## 맥락

`탱크클리닝불량_모재`(cleaning_defect_base)는 결함 클래스이지만 AIHub 원천 데이터의 label_type이 `classification`으로, bbox 어노테이션이 존재하지 않는다.

Ontology export 규칙:
> classification label_type → detection: ❌ empty label 금지

det_train.yaml에 class ID로 포함할 경우, 해당 이미지에 대응하는 label 파일이 비어 있어 YOLO가 이를 "아무것도 없는 배경"으로 해석하게 된다. 클래스 ID를 정의했지만 예측이 발생하지 않는 dead class가 된다.

## 결정

`탱크클리닝불량_모재` 및 동일한 상황의 모든 classification-only 결함 클래스를 detection/segmentation training yaml에서 제외한다.

- `det_train.yaml`, `seg_train.yaml`에서 `cleaning_defect_base` 제거 (`nc: 9 → 8`).
- 이미지는 CLASS_MAP 기준 폴더(`images/surface/cleaning_defect_base/`)로 마이그레이션하여 보존.
- detection 학습 시 bbox label 없는 hard negative로 투입.
- 미래 classification 전용 모델 학습 시 별도 yaml로 재활용.

## 기각된 대안

- **detection yaml 유지 + pseudo-bbox 작성**: 수작업 어노테이션 비용이 높고 ontology export 규칙 위반.
- **migration 대상 제외(C)**: 20,748장 데이터 손실. classification 모델 활용 가능성 차단.

## 결과

- detection nc: 9 → 8 (classification-only 결함 제외)
- `cleaning_defect_base` 이미지는 hard negative + 미래 분류 모델 학습 데이터로 보존
