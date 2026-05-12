---
name: ui-adapter
description: FastAPI 라우터, 요청/응답 스키마, 인증 의존성, 파일 업로드 같은 inbound adapter를 다룬다. Use when HTTP endpoints, response models, auth wiring, or client-facing contract mapping need to be built or simplified.
---

# UI Adapter

## 목적

UI와 Core 사이의 번역만 맡는다.  
라우터는 얇게, 스키마는 명확하게, 에러는 일관되게 유지한다.

## 다룰 것

- FastAPI router
- Pydantic request/response schema
- 인증 dependency
- 업로드 엔드포인트
- HTTP status code 매핑

## 작업 순서

1. 클라이언트가 실제로 필요한 계약을 정한다.
2. 요청과 응답을 최소 스키마로 만든다.
3. Core 유스케이스를 호출한다.
4. 도메인 오류를 HTTP 오류로 바꾼다.

## 기준

- router 안에 규칙을 넣지 않는다.
- schema는 전달용으로만 유지한다.
- 동일한 오류는 동일한 HTTP 응답으로 보낸다.

