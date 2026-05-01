# CLAUDE.md — SIREN Claude Code 운영 가이드

@AGENTS.md

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
AGENTS.md
REVIEW.md
.claude/
settings.json
rules/ 영역별 규칙
agents/ 전문 Subagent
skills/ 반복 절차
hooks/ 자동 안전장치

## 자주 쓰는 명령어

```bash
# 로컬 DB 실행
docker compose up -d

# API 서버 실행
cd api && uvicorn app.main:app --reload

# API 테스트
cd api && pytest

# Flutter 분석
cd app && flutter analyze

# 컨테이너 상태 확인
docker compose ps
```

## 작업 흐름

비자명한 작업은 siren-dev-loop skill 적용
/issue-draft "기능 아이디어" ← 설계 초안 + 합의
/issue-start #N ← sub-issue 목록 생성
구현 (api-builder 등 subagent 호출)
/subissue-commit #M ← 커밋 gate
/pr-ready #N #M1 #M2 ← Draft PR 생성

Plan Mode 사용 시점:

- 2개 이상 패키지 동시 수정
- DB 스키마 / 마이그레이션
- Docker, CI, Husky, hooks, settings
- 모델 학습 / 평가
- RAG 검색 / 응답 정책
- .claude, CLAUDE.md, AGENTS.md 수정

편집 전:

1. 부모 이슈 / sub-issue 번호 확인
2. 변경될 파일 목록 작성
3. 가장 좁은 검증 명령어 명시

편집 후:

1. 가장 좁은 검증 실행
2. 변경된 파일 보고
3. 검증 결과 보고
4. 명시적 요청 없으면 커밋하지 않음

## 컨벤션 요약

→ CONTRIBUTING.md 참조

핵심만:

- 브랜치: <type>/<이슈번호>-<설명>
- 커밋: 자유롭게 (Sub-issue 번호 태그)
- PR 제목: <이모지> <type>(<scope>): <한글 설명>
- Merge: Squash Merge

## 절대 금지

읽기/수정 금지:

- .env\* / secrets/\*\* / 모델 가중치 / DB 볼륨 / GitHub secrets

실행 금지:

- rm -rf
- git push --force
- docker volume rm / docker system prune
- curl | sh / wget | sh
- DROP TABLE / TRUNCATE / WHERE 없는 DELETE FROM
