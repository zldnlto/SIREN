# AGENTS.md — SIREN

## 프로젝트

SIREN = Ship Inspection with RAG Engine + Neural network
목표: LNG 탱크 부품 결함 탐지 + RAG 기반 현장 조치 안내 앱

## 현재 우선순위

Phase 1 MVP:

- Flutter 현장 태블릿 앱
- FastAPI 백엔드
- PostgreSQL + ChromaDB
- YOLOv8 베이스라인 실험
- RAG 조치 안내 프로토타입

## 절대 금지

- 모델 가중치 커밋 금지: _.pt, _.onnx, _.pth, _.pkl
- .env, secrets, 토큰, API 키 읽기 또는 출력 금지
- 실제 dataset / raw data 읽기 또는 수정 금지
- 부모 이슈가 브랜치 단위
- Sub-issue가 커밋 단위
- Draft PR 먼저 생성
- PR에 반드시 Closes #부모이슈 및 모든 Sub-issue 명시

## 브랜치 네이밍

- 일반: <type>/<이슈번호>-<설명>
- 실험: exp/<설명>

## 커밋 컨벤션

허용 타입:
feat, fix, docs, test, refactor, style, ci, build, chore, revert,
data, train, model, exp

feat/fix/data/train/model/exp 타입은 이슈 번호 필수

## Review guidelines

명확한 근거 없이 아래 항목이 발견되면 P1으로 처리:

- secrets, credentials, Firebase config, 모델 가중치, raw dataset 노출
- FastAPI route가 service/repository 레이어를 우회
- API 응답 계약 변경 시 Flutter 연동 업데이트 누락
- RAG retrieval 동작 변경 시 smoke 증거 누락
- YOLO inference path / device / model 하드코딩
- PostgreSQL 스키마 변경 시 migration / 테스트 증거 누락
- 변경 영역에 대한 validation evidence 누락
- 위험 shell / DB 명령어 포함
