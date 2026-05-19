# Supported Devices & Resolution Spec

> 기준일: 2026-05-19
> 적용 범위: Flutter 현장 태블릿 앱 (`app/`)

---

## 1. 지원 전략

| 우선순위 | 폼팩터 | 방향 | 역할 |
|---|---|---|---|
| First | 태블릿 10~12" | Landscape | 현장 검사 (카메라·결함 뷰) |
| Sub | 모바일 폰 | Portrait | 이력 조회·RAG 가이드 확인 |

---

## 2. 태블릿 (First UI)

### 타겟 기기

| 기기 | 화면 크기 | 물리 해상도 |
|---|---|---|
| Samsung Galaxy Tab S9 | 11" | 2560×1600 |
| Samsung Galaxy Tab S9+ | 12.4" | 2560×1752 |
| Samsung Galaxy Tab Active4 Pro | 10.1" | 2560×1600 |
| Apple iPad 10th gen | 10.9" | 2360×1640 |
| Apple iPad Pro 11" (M4) | 11" | 2420×1668 |

### Flutter 논리 해상도 (dp 기준)

- **개발 기준**: 800×500 dp (landscape)
- **최소 지원**: 640×480 dp (1024×768 물리 해상도, 4:3 구형 산업용 태블릿)
- **태블릿 분기점**: `shortestSide >= 600 dp` (Material Design 권장)

### 카메라 뷰 비율

- **고정 비율 4:3** — bbox 좌표 왜곡 방지
- `AspectRatio(aspectRatio: 4/3)` 적용 필수. % 기반 가변 배치 금지

---

## 3. 모바일 폰 (Sub UI)

### 타겟 기기

| 기기 | 물리 해상도 |
|---|---|
| Samsung Galaxy S24/S25 | 2340×1080 |
| Apple iPhone 15/16 | 2556×1179 |

### Flutter 논리 해상도 (dp 기준)

- **개발 기준**: 360×800 dp, 393×852 dp (portrait)
- **최소 지원**: 320×568 dp

### 제약

- 카메라·결함 촬영 지원 (태블릿과 동일)
- 카메라 대형 뷰어는 스크롤/탭 전환으로 처리 (전체 화면 분할 레이아웃 미적용)
- 이동 중 가벼운 이력 확인·RAG 가이드 열람 용도에 최적화

---

## 4. Android SDK 버전

| 항목 | 값 | 근거 |
|---|---|---|
| `minSdkVersion` | 26 | Android 8.0 — Galaxy Tab Active3(2021) 이상 포괄 |
| `targetSdkVersion` | 34 | Android 14 — 현행 Play Store 요구사항 |
| `compileSdkVersion` | 34 | targetSdk와 동일 |

---

## 5. 화면 방향 정책

```
shortestSide >= 600 dp  →  landscapeLeft + landscapeRight 고정
shortestSide <  600 dp  →  모든 방향 허용 (폰)
```

- `SystemChrome.setPreferredOrientations` 코드 레벨 적용
- `AndroidManifest.xml` `screenOrientation` 미지정 (코드 제어로 통일)

---

## 6. Flutter Breakpoint 상수

```dart
// app/lib/core/theme.dart
const double kTabletBreakpoint = 600;   // shortestSide 기준
const double kDesktopBreakpoint = 960;  // 향후 확장용
```
