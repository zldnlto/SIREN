---
name: issue-draft
description: 모호한 기능 아이디어를 구체적인 설계 문서 초안으로 변환한다. 코드 작성 전 사용한다.
disable-model-invocation: true
argument-hint: "[기능 아이디어 또는 작업 설명]"
---

입력된 아이디어를 분석해 아래 구조의 설계 초안을 작성한다.
코드를 작성하거나 파일을 수정하지 않는다.

## 출력 형식

# Issue Draft: $ARGUMENTS

## 의도 (Intent)

이 작업을 왜 하는가

## 문제 (Problem)

현재 어떤 문제가 있는가

## 제안 방향 (Proposed Approach)

어떻게 해결할 것인가

## 영향 영역 (Affected Areas)

- [ ] Flutter (app/)
- [ ] FastAPI (api/)
- [ ] YOLOv8 (vision/)
- [ ] RAG / LangChain / ChromaDB
- [ ] PostgreSQL
- [ ] CI / Harness
- [ ] Dashboard (dashboard/)

## 완료 기준 (Acceptance Criteria)

- [ ]
- [ ]

## 제외 범위 (Non-goals)

이번 작업에서 하지 않을 것

## Sub-issue 후보 (Suggested Sub-issues)

- [ ]
- [ ]

## 리스크 (Risks)

잘못되면 어떤 문제가 생길 수 있는가

## 열린 질문 (Open Questions)

결정이 필요한 사항

## 검증 방법 (Suggested Verification)

완료 여부를 어떻게 확인할 것인가

---

초안 작성 후 설하님의 합의를 받은 뒤 /issue-start 를 사용한다.
