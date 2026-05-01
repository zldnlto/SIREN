---
name: siren-dev-loop
description: 비자명한 구현, 버그 수정, 리팩터링, 리뷰 작업에 사용한다. Karpathy 코딩 규율과 SIREN 워크플로우를 결합한 wrapper skill이다.
disable-model-invocation: true
argument-hint: "[parent-issue] [sub-issue] [task]"
---

Karpathy 코딩 규율을 적용한다:

1. 코딩 전에 생각한다
2. 단순함을 우선한다
3. 수술적 변경을 한다
4. 검증 가능한 성공 기준을 정의한다

SIREN 워크플로우를 적용한다:

- 부모 이슈가 브랜치 단위
- Sub-issue가 커밋 단위
- 현재 Sub-issue에 필요한 파일만 수정한다
- 인접한 개선사항을 구현하지 않는다
- 모델 가중치를 커밋하지 않는다
- secret / .env를 읽거나 출력하지 않는다
- 명시적 요청 없이 커밋하거나 PR을 생성하지 않는다

편집 전 출력:

1. 가정 사항
2. 모호한 부분 또는 반론
3. 가장 단순한 구현 계획
4. 변경될 파일 목록
5. 검증 명령어

편집 후 출력:

1. 변경된 파일 목록
2. 검증 결과
3. 잔여 리스크
4. 추천 커밋 메시지
