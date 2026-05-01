# Git 워크플로우 규칙

## 브랜치 전략

GitHub Flow 기반.
main은 항상 포트폴리오로 보여줘도 되는 상태로 유지한다.

### 브랜치 네이밍

일반: <type>/<이슈번호>-<설명>
실험: exp/<설명>
예시:
feat/12-camera-upload
fix/7-cors-config
build/5-husky-precommit
exp/yolov8n-baseline-v1

### 브랜치 단위

부모 이슈 = 브랜치 단위
Sub-issue = 커밋 단위

## 커밋 컨벤션

### Merge 전략

Squash Merge 사용.
작업 중 커밋은 자유롭게 작성하고,
PR 제목이 main 브랜치의 최종 커밋 메시지가 된다.

### PR 제목 형식

<이모지> <type>(<scope>): <한글 설명>

### 허용 타입

| 이모지 | 타입     | 의미               |
| ------ | -------- | ------------------ |
| ✨     | feat     | 기능 추가          |
| 🐛     | fix      | 버그 수정          |
| 📝     | docs     | 문서 수정          |
| ✅     | test     | 테스트 추가/수정   |
| ♻️     | refactor | 구조 개선          |
| 💄     | style    | 포맷, 들여쓰기     |
| 🤖     | ci       | CI/CD 설정         |
| 🏗️     | build    | 의존성/빌드 설정   |
| 🔧     | chore    | 기타 잡무          |
| ⏪     | revert   | 커밋 되돌리기      |
| 🗃️     | data     | 데이터 처리/샘플링 |
| 🏋️     | train    | 모델 학습          |
| 💾     | model    | 모델 구조/export   |
| 🧪     | exp      | 실험               |

### 이슈 번호 필수 타입

`feat` `fix` `data` `train` `model` `exp`
→ 커밋 메시지에 반드시 이슈 번호 포함

## PR 규칙

### Draft PR 먼저

모든 PR은 Draft로 먼저 생성한다.
CI + hook 검증 → 사람이 diff 검수 → Squash Merge

### PR 본문 필수 항목

Why
Changes
Validation
관련 이슈
Closes #부모이슈
Closes #sub-issue-1
Closes #sub-issue-2

### Sub-issue 자동 close

단순 `#N` 참조는 자동 close 보장 안 됨.
반드시 `Closes #N` 키워드 사용.

## 이슈 컨벤션

### 제목 형식

[Type][영역] 제목
예시:
[Feat][api] 검사 결과가 DB에 자동 저장된다
[Bug][api] docker-compose 실행 시 PostgreSQL 연결이 되지 않는다
[Exp][vision] YOLOv8n baseline v1 학습 실험

### Sub-issue 규칙

부모 이슈가 맥락을 담당하므로
Sub-issue 제목은 prefix 없이 작업 내용만 작성한다.
