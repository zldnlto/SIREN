# SIREN PR Review Guide

이 문서는 Codex(독립 리뷰어)와 사람이 PR을 검토할 때 사용하는 기준입니다.
Claude Code의 구현 컨텍스트와 무관하게, 코드와 규칙만으로 판단합니다.

---

## 사용 방법

- 문제가 있는 항목만 지적한다
- 통과한 항목은 생략한다
- 각 항목은 Pass / Fail / N/A 로만 표기한다

---

## 1. 공통 컨벤션

### 브랜치

- [ ] 브랜치명이 `<type>/<이슈번호>-<설명>` 형식인가
  - 올바른 예: `feat/12-camera-upload`, `fix/7-cors-config`
  - 실험 브랜치 예외: `exp/<설명>` 형식 허용

### PR 제목

- [ ] `<이모지> <type>(<scope>): <한글 설명>` 형식인가
  - 올바른 예: `✨ feat(api): 검사 엔드포인트 추가`
  - scope: `app` `dashboard` `api` `vision` `infra` `docs` `repo` 중 하나

### 커밋 타입

- [ ] 모든 커밋이 허용 타입을 사용하는가
  - 공통: `feat` `fix` `docs` `test` `refactor` `style` `ci` `build` `chore` `revert`
  - vision 전용: `data` `train` `model` `exp`
- [ ] `feat` `fix` `data` `train` `model` `exp` 타입 커밋에 이슈 번호가 포함되어 있는가

### PR 본문

- [ ] `Closes #N` 이 포함되어 있는가
- [ ] Why / Changes / Validation 섹션이 작성되어 있는가
- [ ] Sub-issue가 있다면 전부 `Closes #N` 으로 명시되어 있는가

---

## 2. 코드 품질 (공통)

- [ ] 함수가 단일 책임을 가지는가
- [ ] 타입 힌트가 명시되어 있는가 (Python / TypeScript / Dart 모두)
- [ ] 매직 넘버 / 하드코딩 문자열이 없는가
- [ ] 사용하지 않는 import가 없는가
- [ ] 빈 except / catch 블록이 없는가

---

## 3. api/ 규칙

### 레이어 의존성

- [ ] `router → service → model` 방향만 존재하는가
- [ ] router가 직접 DB 접근하지 않는가
- [ ] service가 router 객체를 import하지 않는가

### FastAPI 규칙

- [ ] 모든 엔드포인트에 Pydantic response model이 정의되어 있는가
- [ ] 에러 응답이 `HTTPException` 으로 처리되는가
- [ ] 환경변수가 `core/config.py` 를 통해서만 참조되는가

### DB 규칙

- [ ] 쿼리가 ORM(SQLAlchemy)을 통해서만 실행되는가
- [ ] `DROP` `TRUNCATE` `DELETE FROM` (WHERE 없는) 쿼리가 없는가

---

## 4. vision/ 규칙

### 실험 관리

- [ ] 실험 결과가 `reports/experiments/YYYY-MM-DD-실험명.md` 에 기록되어 있는가
- [ ] 학습 설정이 `configs/*.yaml` 에 저장되어 있는가
- [ ] weight 저장 위치가 PR 본문에 명시되어 있는가

### 데이터 규칙

- [ ] `data/` `datasets/` `runs/` 폴더가 커밋에 포함되지 않는가
- [ ] `sample_manifest.json` 이 업데이트되었는가 (샘플링 변경 시)

---

## 5. 보안 / 하네스

### 절대 금지 — 하나라도 발견되면 즉시 Fail

- [ ] `.env` 파일이 커밋에 포함되지 않았는가
- [ ] API key / secret / token 값이 코드에 하드코딩되지 않았는가
- [ ] `*.pt` `*.onnx` `*.pth` `*.pkl` 파일이 커밋에 없는가
- [ ] `git push --force` 명령이 스크립트에 없는가
- [ ] `rm -rf` 명령이 스크립트에 없는가
- [ ] `docker volume rm` `docker system prune` 이 없는가
- [ ] `curl | sh` `wget | sh` 패턴이 없는가
- [ ] GitHub Actions secret이 로그에 출력되지 않는가

### 환경변수

- [ ] `.env.example` 이 업데이트되었는가 (새 환경변수 추가 시)
- [ ] `.env` 가 `.gitignore` 에 포함되어 있는가

---

## 6. 사람이 반드시 검토해야 하는 항목

Codex가 Pass해도 사람이 직접 확인:
DB 스키마 변경 → 마이그레이션 영향 범위 확인
RAG 답변 정책 변경 → 현장 안내 문구 적절성 확인
CI/CD 권한 변경 → GitHub Actions secret 접근 범위 확인
Docker volume 변경 → 데이터 유실 가능성 확인
모델 평가 결론 → 실제 추론 결과 샘플 확인

---

## 백로그

[ ] Flutter 섹션 추가 → Flutter 개발 시작 전  
[ ] RAG 섹션 추가 → RAG 파이프라인 구현 시작 전
