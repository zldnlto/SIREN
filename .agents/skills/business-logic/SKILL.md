---
name: business-logic
description: 도메인 규칙, 상태 전이, 검증, 유스케이스 흐름을 정리한다. Use when business rules, core policy, workflow orchestration, or pure logic around inspections, defects, and guidance need to be designed or refactored.
---

# Business Logic

## 목적

핵심 규칙을 HTTP, DB, S3, ML 구현에서 분리한다.  
유스케이스가 무엇을 해야 하는지 먼저 정하고, 어떻게 저장하거나 전달할지는 뒤로 미룬다.

## 다룰 것

- 결함 분류와 심각도 규칙
- 검사 상태 전이
- 소유자 검증 같은 정책
- 조치 카드 생성 규칙
- 입력 검증과 에러 조건

## 작업 순서

1. PRD의 사용자 흐름을 먼저 확인한다.
2. 순수 함수나 얇은 정책 객체로 규칙을 분리한다.
3. 외부 I/O는 포트로 남기고 직접 호출하지 않는다.
4. 규칙은 테스트로 고정한다.

## 기준

- 규칙이 HTTP 타입에 묶이지 않아야 한다.
- DB 쿼리 없이도 핵심 판단이 가능해야 한다.
- 같은 입력이면 같은 결과가 나와야 한다.

