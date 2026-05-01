---
name: failure-debug
description: 에러 로그를 기반으로 원인을 분석하고 최소 수정 계획을 제안한다.
disable-model-invocation: true
argument-hint: "[에러 로그 또는 실패 설명]"
---

1. 실패 유형 분류:

   ## 실패 유형
   - [ ] Flutter analyze / build / runtime
   - [ ] FastAPI pytest / runtime
   - [ ] YOLOv8 inference / model path / device
   - [ ] RAG retrieval / embedding / ChromaDB
   - [ ] PostgreSQL migration / query
   - [ ] Husky / CI / harness
   - [ ] Git / PR workflow

2. 에러 분석:
   - root cause를 찾기 전에 fix를 시작하지 않는다
   - 한 번에 하나의 가설만 테스트한다
   - 여러 번 실패했다면 멈추고 재평가한다

3. 출력 형식:

   ## 에러 시그니처

   ## 가장 유력한 root cause

   ## 근거

   ## 재현 명령어

   ## 최소 수정 계획

   ## 검증 명령어

4. 규칙:
   - 파일을 수정하지 않는다
   - 분석과 제안만 출력한다
   - 수정은 명시적 요청 후 siren-dev-loop와 함께 진행한다
