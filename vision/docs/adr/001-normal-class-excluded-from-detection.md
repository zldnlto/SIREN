# ADR-001: 양품(Good) 클래스를 YOLO detection에서 제외

| 항목   | 내용       |
|--------|------------|
| 상태   | 확정       |
| 결정일 | 2026-05-15 |

## 맥락

CLASS_MAP에 `normal_paint`, `normal_base`, `normal_insulation` 등 11개 양품 클래스가 정의되어 있었고, `det_train.yaml`에도 class ID 9-11로 포함되어 있었다.

그러나 표면처리 양품 샘플(`표면양품_*`)의 label_type은 `classification`으로, bbox 어노테이션이 존재하지 않는다.

## 결정

양품 클래스를 YOLO detection 학습 대상에서 제외한다.

- `det_train.yaml`, `seg_train.yaml`에서 `normal_*` class 항목을 제거한다 (`nc` 값도 조정).
- 양품 이미지는 detection label 없이 학습 데이터에 포함시켜 **background hard negative**로 활용한다.
- classification 전용 파이프라인이 필요한 경우 별도 yaml(`cls_train.yaml`)로 분리한다.

## 기각된 대안

- **bbox 어노테이션 추가**: 양품 전체에 bbox를 새로 작성해야 하므로 비용 대비 효과 없음.
- **detection class 유지**: label_count=0 이미지가 클래스 ID와 혼재하면 학습 혼란 가중.

## 결과

- detection nc: 12 → 9 (표면처리 결함 클래스만)
- 양품 이미지는 hard negative로 유효하게 재활용됨
