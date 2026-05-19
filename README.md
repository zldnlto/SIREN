# SIREN

### Ship Inspection with RAG Engine + Neural network

> 선박 LNG탱크 부품 결함을 AI가 탐지하고, 조치 방법까지 안내하는 현장 보조 앱

---

## 프로젝트 개요

현장 작업자가 태블릿으로 부품을 촬영하면, AI가 결함을 탐지하고 위치를 시각화합니다.
결함이 발견되면 RAG 기반으로 과거 매뉴얼을 검색해 조치 방법을 안내합니다.

```
카메라 촬영 → 결함 탐지 (YOLOv8) → 위치 시각화 (Grad-CAM) → 조치 안내 (RAG)
```

---

## 레포 구조

```
siren/
  ├── app/          Flutter — 현장 태블릿 앱 (MVP)
  ├── dashboard/    Next.js — 관리자 대시보드
  ├── api/          FastAPI — 백엔드 서버
  └── vision/       PyTorch + YOLOv8 — 모델 학습/추론
```

---

## 기술스택

| 영역     | 기술                          |
| -------- | ----------------------------- |
| 현장 앱  | Flutter                       |
| 대시보드 | Next.js 14                    |
| 백엔드   | FastAPI, PostgreSQL, ChromaDB |
| AI 모델  | PyTorch, YOLOv8, Grad-CAM     |
| RAG      | LangChain, OpenAI API         |
| 인프라   | Docker Compose                |

---

## 지원 기기 및 해상도

> 상세 스펙: [app/docs/decisions/supported_devices.md](./app/docs/decisions/supported_devices.md)

### 현장 앱 (Flutter)

| 구분 | 우선순위 | 방향 | 타겟 기기 | 개발 기준 해상도 |
|---|---|---|---|---|
| 태블릿 | First | Landscape | Galaxy Tab S9/Active4 Pro, iPad 10th/Pro 11" | 800×500 dp |
| 모바일 폰 | Sub | Portrait | Galaxy S24/S25, iPhone 15/16 | 360×800 dp |

- 태블릿 분기점: `shortestSide >= 600 dp`
- 최소 지원: 640×480 dp (4:3 구형 산업용 태블릿)
- Android minSdk: **26** (Android 8.0) / targetSdk: **34**
- 카메라·결함 촬영은 폰·태블릿 모두 지원. 폰은 대형 뷰어 대신 스크롤/탭 전환으로 처리

---

## 로컬 실행

```bash
# 환경변수 설정
cp api/.env.example api/.env

# DB 실행
docker-compose up -d

# API 서버 실행
cd api
uvicorn app.main:app --reload
```

---

## 개발 현황

| Phase   | 내용                                 | 상태      |
| ------- | ------------------------------------ | --------- |
| Phase 1 | 표면처리 도메인 탐지 + RAG + 앱 MVP  | 🚧 진행중 |
| Phase 2 | 전체 6개 도메인 확장 + 이상탐지      | ⬜ 예정   |
| Phase 3 | 실시간 스트림 + 전체 데이터 스케일업 | ⬜ 예정   |

---

## 관련 문서

- [docs/PRD.md](./docs/PRD.md) — 제품 요구사항 문서
- [app/docs/decisions/supported_devices.md](./app/docs/decisions/supported_devices.md) — 지원 기기·해상도·SDK 버전 스펙
- [CONTRIBUTING.md](./CONTRIBUTING.md) — 커밋/브랜치/이슈/PR 컨벤션
- [CLAUDE.md](./CLAUDE.md) — 에이전트 작업 가이드
