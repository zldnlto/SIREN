# Sentry 디자인 시스템 기반 App & Dashboard 일관성 검증 보고서

이 보고서는 `getdesign CLI`를 통해 프로젝트에 도입된 Sentry 디자인 가이드라인(`DESIGN.md`)을 기준으로, 태블릿 앱(`/app`, Flutter)과 웹 대시보드(`/dashboard`, Next.js/TailwindCSS) 간의 디자인 패턴 및 토큰 일관성을 정합하고 매핑한 기술 문서입니다.

---

## 1. 디자인 시스템 토큰 매핑 현황

Sentry의 고대비 딥 바이올렛 미드나잇 테마에 정의된 핵심 색상 및 구조적 토큰을 각 플랫폼의 코드 스펙에 맞추어 매핑하였습니다.

### 🎨 색상 토큰 (Colors Mapping)

| Sentry Token (DESIGN.md) | Hex Value | Flutter Token (tokens.dart) | Tailwind Class / Config (Next.js) | 용도 및 시각 위계 |
| :--- | :--- | :--- | :--- | :--- |
| `colors.background` | `#1F1633` | `AppColors.background` | `bg-[#1F1633]` / `bg-canvas-dark` | 전체 마케팅 / 제품 메인 캔버스 |
| `colors.surface-night` | `#150F23` | `AppColors.surface` | `bg-[#150F23]` / `bg-night` | 다크 카드 표면 및 코드 블록 |
| `colors.on-primary` | `#FFFFFF` | `AppColors.onPrimary` | `text-white` | 다크 모드 기본 본문 텍스트 |
| `colors.accent-lime` | `#C2EF4E` | `AppColors.lime` / `accent` | `bg-[#C2EF4E]` / `text-lime` | **Electric Lime** (헤드라인 키워드 칩 강조) |
| `colors.accent-pink` | `#FA7FAA` | `AppColors.pink` | `bg-[#FA7FAA]` / `text-pink` | **Hot Pink** (결함, 중대 경고, 스티커 장식) |
| `colors.hairline-violet` | `#362D59` | `AppColors.border` | `border-[#362D59]` / `border-hairline` | 다크 카드 테두리 선 (1px) |
| `colors.hairline-cool` | `#CFCFDB` | `AppColors.borderSubtle` | `border-[#CFCFDB]` | 인풋 필드 기본 테두리 선 (1px) |

### 📐 둥글기 스케일 (Border Radius Scale)

Sentry 고유의 친근하고 부드러운 코너 반경 규격을 양쪽 플랫폼에 공통 적용하여 직관성을 일치시킵니다.

| Sentry Token (DESIGN.md) | Value | Flutter Target | Tailwind Class | 주요 적용 컴포넌트 |
| :--- | :--- | :--- | :--- | :--- |
| `rounded.xs` | `4px` | `AppRadius.xs` | `rounded-[4px]` | 상태 칩, 카테고리 뱃지 |
| `rounded.sm` | `6px` | `AppRadius.sm` | `rounded-[6px]` | 텍스트 입력 필드(TextField) |
| `rounded.md` | `8px` | `AppRadius.md` | `rounded-[8px]` | **Primary CTA 버튼**, 코드 블록 |
| `rounded.xl` | `12px` | `AppRadius.xl` | `rounded-[12px]` | 일반 검사 태스크 카드, 상세 패널 |
| `rounded.xxl` | `18px` | `AppRadius.xxl` | `rounded-[18px]` | 대형 이미지 컨테이너, 메인 뷰어 |

---

## 2. 플랫폼별 구현 사양 및 검증

### 📱 Flutter 태블릿 앱 (`/app`)
*   **완료 항목**:
    - `app/lib/core/tokens.dart` 및 `app/lib/core/theme.dart` 리팩토링 및 커밋 완료.
    - Sentry-dark 스키마에 정의된 딥 바이올렛 캔버스 배경 및 얇은 보라색 선 테두리가 들어간 12px 둥근 카드 규격 반영 완료.
    - 44px 높이와 8px 둥글기를 보장하며, 다크 캔버스 위에서 백색 배경으로 강력하게 발산되는 Inverted Primary CTA 버튼 탑재 완료.
    - `Rubik` 및 계측 수치용 `JetBrains Mono` 폰트 에셋 설정 완료.

### 🖥️ Next.js 웹 대시보드 (`/dashboard`)
*   **권장 마이그레이션 가이드 (Action Items)**:
    - 대시보드 MVP 브랜치 (`feat/180-dashboard-mvp`) 통합 시, `dashboard/tailwind.config.ts` 파일의 `theme.extend` 영역에 상기 Sentry 고유 색상 및 둥글기 토큰을 커스텀 테마로 추가 등록하여 상호 완벽 일치를 유지하도록 함.
    - 웹 UI 컴포넌트(버튼, 입력 필드) 코딩 시 `rounded-md` (8px), `rounded-xl` (12px) 및 `bg-[#1F1633]`의 Canvas Polarity 법칙을 엄격 준수하도록 강제함.

---

## 3. 종합 평가

이번 **Slice 1** 작업을 통해 Sentry 개발자 Observability 특유의 감각적인 어두운 테마가 최초로 정의되었습니다. 태블릿 앱은 코드 수준에서 해당 테마 이식이 완료되었으며, 웹 대시보드 역시 `DESIGN.md`를 단일 진실 공급원(Single Source of Truth)으로 삼아 마이그레이션이 가능하게 되었습니다.
이를 통해 향후 어떤 기기나 디스플레이 환경에서도 SIREN 브랜드만의 끈끈하고 일관된 고대비 시인성을 완벽히 확보할 수 있을 것으로 전망됩니다.
