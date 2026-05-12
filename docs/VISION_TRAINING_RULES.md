# Vision Training Rules

## 범위

- Colab에서 `vision` 모듈을 import해 YOLOv8n-seg 학습과 평가를 돌리는 기준을 적는다.
- 이 문서는 `#63` 구현에서 정한 저장 규칙과 입력 규칙을 짧게 고정한다.

## 저장 규칙

- 학습 결과는 로컬 `vision/runs/<run_name>/` 아래에 남긴다.
- `best.pt`는 `vision/runs/<run_name>/weights/best.pt`를 기준 경로로 본다.
- Colab Drive에는 `/content/drive/MyDrive/siren/runs/<run_name>/weights/best.pt`로 미러링한다.
- FastAPI 서빙은 Drive 복사본을 우선 사용하고, 없으면 로컬 경로를 fallback으로 쓴다.

## 데이터 규칙

- curated dataset은 클래스별 폴더 구조를 유지한다.
- YOLO yaml은 클래스별 `images/train`, `images/val` 경로를 리스트로 적는다.
- 클래스 ID는 `DEFECT_CLASSES` 순서대로 `0..n-1`을 사용한다.

## 실행 규칙

- 학습과 평가는 `vision.train_yolo_segmentation`과 `vision.evaluate_yolo_segmentation`으로 호출한다.
- 노트북은 경로 조립과 mount 확인만 맡기고, 반복 가능한 로직은 모듈에 둔다.
