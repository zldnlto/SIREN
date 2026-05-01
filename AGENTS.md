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

## 리뷰 기준

다음 항목은 높은 우선순위로 표시:

- 변경된 동작에 대한 테스트 누락
- 롤백 계획 없는 DB 스키마 변경
- 출처 근거 없는 RAG 응답
- 데이터셋/설정/메트릭 기록 없는 Vision 실험
- 가중치 파일 커밋
- 시크릿, 토큰, .env 노출
- 위험한 쉘 명령어
