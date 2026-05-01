---
name: subissue-commit
description: Sub-issue 작업 완료 후 커밋 전 게이트를 통과시킨다. diff 점검, 검증 실행, 커밋 메시지 생성을 수행한다.
disable-model-invocation: true
argument-hint: "[sub-issue-number]"
---

1. 현재 상태 확인:
   - git status
   - git diff --stat
   - git log --oneline -3

2. Sub-issue 범위 확인:
   - 변경된 파일이 Sub-issue #$ARGUMENTS 범위 안인가
   - 범위 밖 파일이 포함되어 있으면 즉시 중단하고 보고한다

3. 보안 점검:
   - .env / secret 파일 포함 여부
   - _.pt / _.onnx / _.pth / _.pkl 파일 포함 여부
   - 위험 명령어 포함 여부

4. 검증 실행:
   - api/ 변경: python -m pytest api/tests/ 또는 python -m compileall api
   - vision/ 변경: python -m compileall vision
   - app/ 변경: flutter analyze
   - dashboard/ 변경: npm run lint

5. 커밋 메시지 생성:
   - 형식: <type>: <한글 설명> #$ARGUMENTS
   - feat/fix/data/train/model/exp 타입은 이슈 번호 필수

6. 출력:
   - 변경된 파일 목록
   - 검증 결과
   - 추천 커밋 메시지
   - 잔여 리스크

명시적 요청 없이 커밋하지 않는다.
