# ADR-003: 서빙 모델을 YOLOv8n-seg 단일 모델로 확정

| 항목   | 내용       |
|--------|------------|
| 상태   | 확정       |
| 결정일 | 2026-05-15 |

## 맥락

표면처리 도메인 주요 결함(균열·스크래치 등)은 label_type이 `segmentation+bbox`로,
detection과 segmentation 학습 모두 가능하다.
PRD 6-C는 YOLOv8n-seg를 명시하고 있으며, bbox는 segmentation 출력에서 자동 파생된다.

## 결정

MVP 서빙 모델은 `YOLOv8n-seg` 단일 모델로 한다.

- `seg_train.yaml` 기준으로 학습.
- bbox는 segmentation head 출력에서 자동 파생.
- `det_train.yaml`은 ablation/실험용으로 보존 (삭제하지 않음).

## 기각된 대안

- **detection + segmentation 앙상블(B)**: EC2 단일 인스턴스에서 모델 두 개 동시 로드 시 메모리 압박, 결과 불일치 처리 로직 추가 비용, MVP 기간 내 구현 비용 과다.

## 확장 경로 (A 이후)

- 모델 크기 스케일업: YOLOv8n → s → m (아키텍처 변경 없음)
- 도메인 확장 시 bbox-only 공정은 det_train.yaml 재활용
- 분류 전용 결함(탱크클리닝불량 등)은 동일 backbone에 classification head 추가
- MVP 이후 detection 모델 추가해 앙상블(B)로 업그레이드 가능

## 결과

- 서빙 모델: YOLOv8n-seg (seg_train.yaml 기준)
- Grad-CAM++: backbone에 적용, 마스크·bbox 오버레이 모두 단일 모델에서 커버
