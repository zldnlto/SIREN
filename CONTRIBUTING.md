# Contributing to SIREN

## 핵심 원칙

```
Issue = 문제 정의 / 요구 정의 / 실험 가설
PR    = 머지 후 main에 남을 코드 변경 요약
```

- Issue는 **왜 이 작업을 하는지** 정의한다
- PR은 **무엇이 바뀌었는지** 요약한다
- 하나의 PR에는 하나의 변경 의도만 담는다
- 타입 / 우선순위 / 상태는 Label로 관리한다

---

## Merge 전략

**Squash Merge** 사용.
작업 중 커밋은 자유롭게 작성하고, PR을 닫을 때 PR 제목에만 컨벤션을 적용한다.
PR 제목이 `main` 브랜치의 최종 커밋 메시지가 된다.

```
작업 중 커밋  →  자유롭게  (feat: 추가, 수정중, wip 등)
PR 제목       →  <이모지> <type>(<scope>): <한글 설명>  ← 이게 실제 기록
```

---

## Issue Convention

### 제목 형식

```
[Type][영역] 제목
```

**Feature Issue** — 사용자/운영자가 무엇을 할 수 있게 되는지 쓴다

```
[Feat][web] 작업자가 태블릿으로 부품 이미지를 촬영할 수 있다
[Feat][api] 검사 결과가 DB에 자동 저장된다
[Feat][vision] 표면처리 도메인 YOLOv8n 베이스라인을 학습할 수 있다
```

**Bug Issue** — 조건 + 증상 중심으로 쓴다. 원인 추정은 본문에 쓴다

```
[Bug][api] docker-compose 실행 시 PostgreSQL 연결이 되지 않는다
[Bug][web] iOS Safari에서 카메라 권한 요청이 표시되지 않는다
```

**Exp Issue** — 실험 가설을 쓴다

```
[Exp][vision] image size 640 고정 시 mAP가 안정적으로 측정될 것이다
[Exp][vision] Hard Example Mining 적용 시 베이스라인 대비 성능이 향상될 것이다
```

### 영역 prefix

```
[web]    web/ 관련 작업
[api]    api/ 관련 작업
[vision] vision/ 관련 작업
[infra]  Docker, CI/CD, 배포 관련
[docs]   문서, Wiki, README 관련
[repo]   레포 전체 설정
```

### Rules

- 50자 이내
- 영역이 2개 이상이면 주요 영역 하나만 선택

---

## PR Convention

### 제목 형식

```
<이모지> <type>(<scope>): <한글 설명>
```

**Rules**

- 설명은 한글로 작성
- 현재형 명사로 작성 (추가 / 수정 / 개선 / 실행 / 변환)
- 50자 이내
- 이모지는 GitHub 웹 UI 이모지 피커로 작성

### 예시

```
✨ feat(web): 이미지 업로드 페이지 추가
🐛 fix(api): docker-compose PostgreSQL 연결 오류 수정
🗃️ data(vision): 표면처리 순서 기반 샘플링 스크립트 추가
🏋️ train(vision): YOLOv8n 베이스라인 v1 학습 실행
```

### scope 기준

```
web     → web/ 작업
api     → api/ 작업
vision  → vision/ 작업
infra   → Docker, CI/CD
docs    → 문서
repo    → 레포 전체
```

### PR 본문 필수 항목

```markdown
## 관련 이슈

Closes #

## Why

<!-- 이 변경이 왜 필요한지 -->

## Changes

## <!-- 무엇이 바뀌었는지 -->

-

## Test

<!-- 어떻게 확인했는지 -->

- [ ] 로컬 실행 확인
- [ ] 주요 기능 수동 확인
```

---

## Commit Types

### 공통

| 이모지 | 타입     | 의미                       | PR 제목 예시                                     |
| ------ | -------- | -------------------------- | ------------------------------------------------ |
| ✨     | feat     | 기능 추가                  | `✨ feat(web): 이미지 업로드 페이지 추가`        |
| 🐛     | fix      | 버그 수정                  | `🐛 fix(api): CORS 설정 오류 수정`               |
| 📝     | docs     | 문서 수정                  | `📝 docs(repo): API 엔드포인트 테이블 업데이트`  |
| ✅     | test     | 테스트 추가/수정           | `✅ test(api): 검사 엔드포인트 테스트 추가`      |
| ♻️     | refactor | 구조 개선                  | `♻️ refactor(api): 서비스 레이어 분리`           |
| 💄     | style    | 포맷, 들여쓰기 (로직 무관) | `💄 style(web): 들여쓰기 정리`                   |
| 🤖     | ci       | CI/CD 설정                 | `🤖 ci(infra): pytest 워크플로우 추가`           |
| 🏗️     | build    | 의존성/빌드 설정           | `🏗️ build(web): Next.js 빌드 설정 수정`          |
| 🔧     | chore    | 기타 잡무                  | `🔧 chore(repo): gitignore 업데이트`             |
| ⏪     | revert   | 커밋 되돌리기              | `⏪ revert(vision): 베이스라인 v1 학습 되돌리기` |

### ML 전용 (vision/)

| 이모지 | 타입  | 의미                       | PR 제목 예시                                               |
| ------ | ----- | -------------------------- | ---------------------------------------------------------- |
| 🗃️     | data  | 데이터 처리/라벨/샘플링    | `🗃️ data(vision): 표면처리 순서 기반 샘플링 스크립트 추가` |
| 🏋️     | train | 학습 실행/학습 설정        | `🏋️ train(vision): YOLOv8n 베이스라인 v1 학습 실행`        |
| 💾     | model | 모델 구조/export/inference | `💾 model(vision): 표면처리 v1 모델 ONNX 변환`             |
| 🧪     | exp   | 실험                       | `🧪 exp(vision): Hard Example Mining 1차 실험`             |

---

## Branch Convention

GitHub Flow 기반.
`main`에서 브랜치를 따고, 작업 후 PR로 기록을 남기고, 다시 `main`에 머지한다.
`main`은 항상 **포트폴리오로 보여줘도 되는 상태**로 유지한다.

### 네이밍 규칙

**web/ / api/**

```
<type>/#<이슈번호>

feat/#12
fix/#7
refactor/#19
```

**vision/ 일반 작업**

```
<type>/#<이슈번호>

feat/#3
data/#5
```

**vision/ 실험 브랜치**

```
exp/<설명>

exp/yolov8n-baseline-v1
exp/yolov8n-img640-epoch50
exp/hard-example-mining-v1
```

### 브랜치 구조 예시

```
main
 ├─ feat/#12               ← web: 이미지 업로드 페이지
 ├─ fix/#7                 ← api: CORS 오류 수정
 ├─ data/#5                ← vision: 표면처리 샘플링 스크립트
 ├─ exp/yolov8n-baseline-v1
 └─ docs/#2                ← MVP 아키텍처 문서
```

---

## ML GitHub 작업 유의사항

**커밋 전 반드시 확인**

```
# .gitignore에 반드시 포함
*.pt
*.onnx
*.pth
data/
datasets/
runs/
*.csv
```

**실험 결과는 반드시 MD로 기록**

```
# reports/experiments/YYYY-MM-DD-실험명.md
- 실험 목적
- 하이퍼파라미터
- 결과 (mAP, recall)
- 다음 실험 방향
```

**실험 브랜치는 main에 머지하지 않는다**

```
exp/* 브랜치는 결과 기록 후 close
성공한 모델 구조만 feat/* 브랜치로 main에 반영
```

**PR 단위를 작게 유지**

```
학습 1회 실행 = 커밋 1개
여러 실험을 하나의 PR에 몰아넣지 않는다
```

> 모델 weight 관리 방법 (추후 결정)
> GitHub Release / Hugging Face / DVC / Weights & Biases 중 선택
