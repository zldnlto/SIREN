---
name: issue-start
description: 확정된 이슈 spec을 실행 가능한 Sub-issue 목록과 브랜치로 변환한다. 코드 시작 직전에 사용한다.
disable-model-invocation: true
argument-hint: "[parent-issue-number]"
---

1. 이슈 내용 확인:
   - gh issue view $ARGUMENTS
   - 완료 기준 확인
   - 영향 영역 확인

2. 브랜치명 제안:
   - 형식: <type>/<이슈번호>-<설명>
   - 예: feat/12-camera-upload

3. Sub-issue 목록 생성:
   각 Sub-issue는 아래 형식으로 작성한다

   ## Sub-issue N: <제목>
   - 부모 이슈: #$ARGUMENTS
   - 범위:
   - 변경될 파일:
   - 의존성:
   - 완료 기준:
   - 검증 명령어:
   - 리스크:
   - 커밋 태그:

4. Definition of Done 제안:
   전체 작업이 완료되었다고 판단하는 기준

5. 코드를 작성하거나 파일을 수정하지 않는다.
   계획만 출력하고 설하님의 승인을 기다린다.
