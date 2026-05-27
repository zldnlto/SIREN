# CLAUDE.md — SIREN Claude Code 운영 가이드

@AGENTS.md
@.claude/rules/git-workflow.md

## 프로젝트 개요

SIREN = Ship Inspection with RAG Engine + Neural network
LNG 탱크 부품 결함 탐지 + RAG 기반 현장 조치 안내 앱
1인 개발 포트폴리오. Claude Code가 메인 구현자.

## 디렉토리 구조

siren/
app/ Flutter — 현장 태블릿 앱 (MVP)
dashboard/ Next.js — 관리자 대시보드
api/ FastAPI — 백엔드 서버
vision/ PyTorch + YOLOv8 — 모델 학습/추론
docker-compose.yml
.claude/
settings.json / rules/ / agents/ / skills/ / hooks/

## Subagent 라우팅

siren-dev-loop ← 비자명한 모든 구현 작업
api-builder ← api/ 작업 시작 시
siren-code-reviewer ← 커밋 전 + pr-ready 전
harness-ci-guardian ← CI/hooks/settings 변경 시
component-architect ← 새 Flutter 위젯 구현 시작 전 (설계 생성 + 검증)
vision-runner ← YOLOv8 학습 전 데이터 검증 / 결과 해석 시

## Flutter 컴포넌트 라우팅 규칙

### 신규 도메인 컴포넌트 (DefectBadge, StatusChip 등)
도메인 규칙·Props가 아직 미확정인 새 위젯:
  1. /business-logic → 도메인 규칙·enum 확정
  2. component-architect → Props/State/Flow 설계 + 검증
  3. 구현 → make-interfaces-feel-better 검토

### 신규 화면 설계 (새 화면을 처음 만들 때)
레이아웃·인터랙션 방향 결정이 필요한 새 화면:
  /flutter-design screen → component-architect(필요시) → 구현 → Phase C 리뷰

### 기존 화면 마이그레이션 (디자인 시스템 적용)
토큰·컴포넌트가 이미 확정된 상태에서 기존 화면을 교체할 때:
  구현 → make-interfaces-feel-better(선택) → flutter analyze → 커밋
  ※ component-architect / business-logic / ui-ux-pro-max 불필요

## 워크플로우

/issue-draft → 합의 → /issue-start → 구현 → /subissue-commit → /pr-ready

Plan Mode 사용 시점:

- 2개 이상 패키지 동시 수정
- DB 스키마 / 마이그레이션
- Docker, CI, Husky, hooks, settings
- 모델 학습 / 평가 / RAG 정책 변경

## 검증 기준

Flutter: flutter analyze + flutter test
Backend: pytest + ruff check
RAG: 변경 시 retrieval smoke check
YOLO: 변경 시 inference smoke check
PR: validation evidence + Closes 목록 포함

## Agent Pipeline — SIREN UI Polish

### 사용 스킬 맵
- `make-interfaces-feel-better` → defect_badge 터치영역, confirm_dialog
- `emil-design-eng` → toast 비대칭 타이밍, stagger 구현, 화면전환
- `component-architect` → stagger 구조 설계 검증 (구현 전 반드시 먼저)
- `ui-ux-pro-max` → EmptyState 위젯
- `siren-code-reviewer` → 최종 PR 검토

### 자율 실행 규칙
- 중간 확인 질문 금지
- 판단 필요 시 보수적 선택 후 진행, impl_log.md에 기록
- 에러 발생 시 3회 재시도 후 skip하고 다음 단계 진행
- 각 단계 완료 시 impl_log.md에 ✅ 체크 추가

## 절대 금지

- .env\* / secrets / 모델 가중치 읽기·수정
- rm -rf / git push --force / docker volume rm
- 명시적 요청 없이 커밋 또는 PR 생성
- hooks / settings 무력화
