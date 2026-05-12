# Refactor Decisions

## 2026-05-12

- `app/services/`는 현재 FastAPI 라우터와 application usecase 사이의 임시 adapter로 유지한다.
- `app/application/`은 repository와 S3 함수를 직접 import하지 않고, service가 주입하는 함수 포트를 통해 동작한다.
- `app/domain/`은 HTTP, ORM, FastAPI, S3를 모르는 순수 규칙 계층으로 둔다.
- 이 저장소에는 아직 실제 UI 컴포넌트 소스가 없어서, `UI adapter shell` 리팩터는 현재 적용 대상이 없다.
- UI 구현이 추가되면 router/presenter/humble shell 기준을 그 시점의 코드에 맞춰 적용한다.

