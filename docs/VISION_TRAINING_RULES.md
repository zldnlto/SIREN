# Vision Training Rules

## 범위

- Colab에서 `vision` 모듈을 import해 YOLOv8n-seg 학습과 평가를 돌리는 기준을 적는다.
- YOLO 학습/라벨 export 기준은 `task_specific_model_class_id`다.
- 사람이 읽는 결함 목록/RAG 기준은 `DEFECT_CLASSES`다.
- 복원/연결 기준은 `ontology_id`다.

## class id 규칙

- `task_specific_model_class_id`는 `ontology_id`를 task별로 deterministic하게 정렬한 뒤 0부터 enumerate해서 만든다.
- class id는 실행할 때마다 랜덤 생성하지 않는다.
- label map artifact가 학습, export, restore를 연결하는 단일 계약이다.
- `category_id`는 metadata only이며, YOLO class id로 쓰지 않는다.

## 서빙 모델 규칙

- MVP 서빙 모델은 `YOLOv8n-seg` 단일 모델로 확정한다 (ADR-003).
- 학습 기준 yaml은 `seg_train.yaml`이며, bbox는 segmentation head 출력에서 자동 파생한다.
- `det_train.yaml`은 ablation/실험 전용으로 보존하되 서빙에는 사용하지 않는다.

## 클래스 제외 규칙

- 양품(Good) 클래스(`normal_*`)는 YOLO detection 학습 대상에서 제외한다 (ADR-001).
  - 양품 이미지는 bbox label 없는 background hard negative로 투입한다.
  - classification 전용 파이프라인이 필요하면 별도 yaml(`cls_train.yaml`)로 분리한다.
- classification-only 결함 클래스(`label_type == classification`인 결함)는 detection/segmentation yaml에서 제외한다 (ADR-002).
  - 해당 이미지는 bbox label 없는 hard negative로 투입한다.
  - 미래 classification 전용 모델 학습 시 재활용한다.
- 위 두 규칙을 바꾸고 싶다면 코드가 아니라 ADR부터 바꾼다.

## taxonomy 규칙

- `taxonomy_status != normal`인 row는 기본 학습/export에서 제외한다.
- taxonomy review 후보는 문서, report, RAG, 수동 검토용으로만 보존한다.
- review 제외를 바꾸고 싶다면 코드가 아니라 정책부터 바꾼다.

## 저장 규칙

- 학습 결과는 로컬 `vision/runs/<run_name>/` 아래에 남긴다.
- `best.pt`는 `vision/runs/<run_name>/weights/best.pt`를 기준 경로로 본다.
- Colab Drive에는 `/content/drive/MyDrive/siren/runs/<run_name>/weights/best.pt`로 미러링한다.
- FastAPI 서빙은 Drive 복사본을 우선 사용하고, 없으면 로컬 경로를 fallback으로 쓴다.

## 데이터 규칙

- curated dataset은 클래스별 폴더 구조를 유지한다.
- task별 export는 classification / detection / segmentation으로 분리한다.
- YOLO yaml은 export 결과의 `images/train`, `images/val` 경로를 사용한다.
- `DEFECT_CLASSES`는 사람용 결함 목록이며, class id 매핑 기준이 아니다.

## 실행 규칙

- 일반 학습은 `vision.train_yolo_segmentation(...)`으로 실행한다.
- validation gate가 필요한 경우 `vision.train_yolo_segmentation_with_validation_gate(...)`를 사용한다.
- 평가는 `vision.evaluate_yolo_segmentation(...)`으로 실행한다.
- 노트북은 경로 조립과 mount 확인만 맡기고, 반복 가능한 로직은 모듈에 둔다.
