---
name: flutter-design
description: Flutter 디자인 시스템 작업 진입점. 설치된 디자인 스킬들을 올바른 순서로 오케스트레이션한다. tokens.dart 작업 시작 전, 새 화면/컴포넌트 설계 시 사용한다.
disable-model-invocation: true
argument-hint: "[task] — token|component|screen|review"
---

Flutter 디자인 작업의 단계별 스킬 오케스트레이션 가이드다.
`$ARGUMENTS`에 따라 아래 Phase 중 해당하는 것부터 시작한다.

---

## Phase A — 디자인 시스템 정의 (`token`)

**언제**: `tokens.dart` 신규 작성 또는 대규모 개편 시

### Step 1: 디자인 시스템 생성 (`ui-ux-pro-max`)

```bash
python3 .agents/skills/ui-ux-pro-max/scripts/search.py \
  "industrial LNG inspection safety field worker dark mode tablet" \
  --design-system --persist -p "SIREN"
```

출력된 color palette, typography, spacing, style을 기록한다.

### Step 2: Aesthetic 방향 교차 검증 (`frontend-design`)

`/frontend-design` 스킬을 호출해 Step 1 결과를 아래 관점으로 재검토한다:
- 산업 현장 앱의 tone — utilitarian/industrial이 맞는가, 아니면 다른 방향인가
- 색상 팔레트가 dark mode + 현장 조명 조건에서 읽히는가
- 타이포가 태블릿 landscape + 장갑 착용 사용자에게 충분히 큰가

### Step 3: `tokens.dart` 작성

Step 1–2 결과를 Dart 상수로 변환한다:

```dart
// 구조 기준
class AppColors { ... }      // semantic: defect/good/warning/critical + surface 계층
class AppSpacing { ... }     // xs(4) sm(8) md(16) lg(24) xl(32)
class AppRadius { ... }      // sm(4) md(8) lg(16)
class AppTextStyles { ... }  // titleSection, labelMeta, bodyReport
```

### Step 4: 토큰값 디테일 체크 (`make-interfaces-feel-better`)

작성된 토큰을 아래 기준으로 재검토한다:
- 중첩 컨테이너의 concentric radius 계획 (outer = inner + padding)
- 동적 숫자에 tabular figures 토큰 포함 여부
- 그림자 토큰이 border 대신 layered BoxShadow로 정의되어 있는가

---

## Phase B — 컴포넌트 설계 (`component`)

**언제**: 새 위젯 구현 시작 전

### Step 1: 도메인 규칙 확인 (`business-logic`)

도메인 컴포넌트(DefectBadge, InspectionStatusChip 등)라면 먼저:
- `/business-logic` 스킬로 severity 분류 규칙, 상태 전이 정의
- 컴포넌트가 받아야 할 도메인 타입(enum) 확정

### Step 2: 설계 생성 + 검증 (`component-architect`)

`component-architect` 에이전트에 아래를 전달한다:
- 기능 요구사항
- Step 1에서 확정된 도메인 타입/규칙
- 관련 기존 Provider / Model 파일 경로

에이전트가 Phase 1(설계 생성) + Phase 2(검증) 자동 실행.

### Step 3: 인터랙션 모델 확정 (`emil-design-eng`)

`/emil-design-eng` 스킬로 아래를 결정한다:
- 이 컴포넌트에 애니메이션이 필요한가 (빈도 기준)
- 필요하다면: easing curve, duration, spring 여부
- scale-on-press 적용 여부 (0.96–0.97)

---

## Phase C — 화면 구현 후 리뷰 (`review`)

**언제**: 화면 또는 컴포넌트 구현 완료 후, `siren-code-reviewer` 호출 전

### Step 1: 폴리시 체크 (`make-interfaces-feel-better`)

구현된 위젯 코드를 아래 체크리스트로 검토한다:
- [ ] 중첩 컨테이너의 concentric border radius
- [ ] 모든 인터랙티브 요소 최소 40×40pt hit area (현장 앱: 44×44pt 권장)
- [ ] 동적 숫자에 `FontFeature.tabularFigures()` 적용
- [ ] 이미지에 `BoxDecoration(border: Border.all(..., width: 1, color: rgba(255,255,255,0.1)))` 아웃라인

### Step 2: 애니메이션 리뷰 (`emil-design-eng`)

애니메이션이 포함된 경우:
- `transition: all` 상당하는 코드 없는지 (AnimatedContainer의 과도한 범위 등)
- enter scale이 0.0이 아닌 0.95에서 시작하는지
- exit duration이 enter보다 짧은지 (60–70%)

### Step 3: UX/접근성 감사 (`web-design-guidelines`)

`/web-design-guidelines` 스킬로 구현된 위젯 파일들을 검토한다.
Flutter `.dart` 코드를 직접 읽고 웹 가이드라인 원칙을 Flutter 맥락으로 해석 적용.

---

## 스킬 호출 요약

| Phase | 스킬/에이전트 | 순서 |
|---|---|---|
| A — 토큰 | `ui-ux-pro-max` → `frontend-design` → `make-interfaces-feel-better` | 순차 |
| B — 컴포넌트 | `business-logic` → `component-architect` → `emil-design-eng` | 순차 |
| C — 리뷰 | `make-interfaces-feel-better` → `emil-design-eng` → `web-design-guidelines` | 순차 |
