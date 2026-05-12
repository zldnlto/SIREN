# ARCHITECTURE

## 현재 상태

- 현재 백엔드는 `router -> service -> repository -> model` 흐름으로 동작한다.
- PRD가 요구하는 방향은 단일 FastAPI 서버 안에서 `Core`와 `Adapter`를 분리하는 구조다.
- 이 문서는 MVP 기준의 현재 상태를 기록하고, 이후 리팩터 순서를 잃지 않기 위한 작업 메모다.

## 관찰된 경계 위반

1. `app/schemas/detection.py`
   - `DEFECT_CLASSES`, `DOMAIN_CODES`, `CLS_ONLY_CODES`, `confidence_to_severity`가 함께 들어 있다.
   - 응답 스키마와 도메인 규칙이 섞여 있어, 스키마를 바꾸지 않으면 규칙도 같이 흔들린다.

2. `app/services/inspection_service.py`
   - 검사 생성, 소유자 검증, UUID 파싱, S3 key 생성, presigned URL 발급, 업로드 검증, DB 업데이트가 한 파일에 있다.
   - 유스케이스와 인프라가 분리되지 않아 테스트가 얕아진다.

3. `app/services/detection_service.py`
   - 탐지 결과 생성, DB 저장, 상태 변경, mock 탐지가 한 흐름에 묶여 있다.
   - 현재는 실제 ML 어댑터가 없어서, 애플리케이션 규칙과 외부 추론 경계가 보이지 않는다.

4. `app/services/guidance_service.py`
   - RAG/조치 카드가 아니라 하드코딩 응답을 반환한다.
   - PRD의 “결함명 → 매뉴얼 검색 → OpenAI 요약” 흐름과 아직 분리되지 않았다.

5. `app/repositories/*`
   - repository가 `commit()`과 `refresh()`까지 수행한다.
   - 저장소가 영속성 책임을 넘어서 트랜잭션 경계를 대신 정하고 있다.

6. `app/models/*`
   - ORM 모델에 상태 기본값과 일부 도메인 의미가 들어 있다.
   - 영속성 형태와 핵심 규칙이 함께 배치되어 있다.

7. `app/routers/inspections.py`
   - 라우터가 유스케이스를 직접 호출하고, HTTP 입력을 거의 그대로 service에 넘긴다.
   - inbound adapter는 맞지만, 현재는 매핑만 하고 끝나는 얇은 외피에 가깝다.

## 목표 Core/Adapter 구조

### Core

- `core/domain`
  - 결함 분류, 심각도 규칙, 검사 상태 전이, 조치 카드의 핵심 규칙을 둔다.
  - 외부 I/O와 HTTP 타입을 모른다.

- `core/application`
  - `CreateInspection`, `GetInspection`, `RequestUploadUrl`, `ConfirmUpload`, `RunDetection`, `GetGuidance`, `Login` 같은 유스케이스를 둔다.
  - 입력 포트와 출력 포트를 통해 Core와 Adapter를 연결한다.

### Adapter

- `adapters/inbound/http`
  - FastAPI router, request/response schema, auth dependency, 파일 업로드 처리, 에러 매핑을 담당한다.

- `adapters/outbound/persistence`
  - SQLAlchemy ORM model, repository, transaction 처리, Alembic 변경을 담당한다.

- `adapters/outbound/storage`
  - S3 presigned URL, upload, delete, ETag 확인을 담당한다.

- `adapters/outbound/ai`
  - YOLO 추론, Grad-CAM++, RAG 요약, 모델/프롬프트 버전 관리를 담당한다.

## 리팩터 순서

1. HTTP 계약 고정
   - 현재 router 기준 응답을 유지한 채 characterization test를 먼저 만든다.
   - 이 단계에서는 외부 동작을 바꾸지 않는다.

2. 도메인 규칙 추출
   - `schemas/detection.py`의 상수와 `confidence_to_severity`를 Core로 옮긴다.
   - `guidance_service.py`의 하드코딩 응답도 Core 규칙 또는 outbound RAG adapter로 이동한다.

3. 검사 유스케이스 분리
   - `inspection_service.py`를 application use case 단위로 나눈다.
   - 소유자 검증, UUID 파싱, 업로드 정책, 상태 변경을 한 파일에 두지 않는다.

4. 저장소 트랜잭션 정리
   - repository에서 `commit()`을 제거하고, application 쪽에 트랜잭션 경계를 둔다.
   - ORM model은 persistence adapter로만 남긴다.

5. 외부 어댑터 분리
   - S3, 탐지, RAG를 출력 포트 뒤로 숨긴다.
   - mock 구현은 테스트용 adapter로 한정한다.

6. 라우터 슬림화
   - router는 요청 수신과 응답 변환만 맡는다.
   - 비즈니스 판단은 Core에 남긴다.

## 검증 방법

- `pytest`로 characterization test와 core/usecase 회귀를 고정한다.
- `ruff check .`로 문법과 스타일, 불필요한 import를 잡는다.
- `lint-imports --config pyproject.toml`로 계층 경계 위반을 막는다.
- `python scripts/check_import_boundaries.py`를 수동 품질 게이트로 쓸 수 있다.
- 위 검증은 `api/` FastAPI 백엔드 기준이다.

## 기록용 가정

- 가정: MVP에서는 단일 FastAPI 프로세스를 유지하고, 마이크로서비스 분리는 하지 않는다.
- 가정: 현재 `services/`는 임시 유스케이스 계층이며, 이후 `application/`으로 재배치한다.
- 가정: PRD의 RAG와 Grad-CAM 기능은 아직 미구현이므로, 현재의 mock 구현은 adapter 교체 대상으로 본다.
- 가정: 현재 저장소에는 Flutter/Next.js UI 소스가 없어서 `UI adapter shell` 리팩터는 백엔드 범위 밖으로 둔다.
