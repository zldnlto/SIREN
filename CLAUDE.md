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

## 절대 금지

- .env\* / secrets / 모델 가중치 읽기·수정
- rm -rf / git push --force / docker volume rm
- 명시적 요청 없이 커밋 또는 PR 생성
- hooks / settings 무력화
