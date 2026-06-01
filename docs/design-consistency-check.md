# IBM Carbon 디자인 시스템 기반 App & Dashboard 일관성 검증 보고서

이 보고서는 `getdesign CLI`를 통해 프로젝트에 공식 도입된 IBM Carbon 디자인 가이드라인(`DESIGN.md`)을 기준으로, 태블릿 앱(`/app`, Flutter)과 웹 대시보드(`/dashboard`, Next.js/TailwindCSS) 간의 디자인 패턴 및 토큰 일관성을 정합하고 매핑한 기술 문서입니다.

---

## 1. 디자인 시스템 토큰 매핑 현황

IBM Carbon의 Confident IBM Blue와 Monotone Dark Gray 100 테마에 정의된 핵심 색상 및 구조적 토큰을 각 플랫폼의 코드 스펙에 맞추어 매핑하였습니다.

### 🎨 색상 토큰 (Colors Mapping)

| Carbon Token (DESIGN.md) | Hex Value | Flutter Token (tokens.dart) | Tailwind Class / Config (Next.js) | 용도 및 시각 위계 |
| :--- | :--- | :--- | :--- | :--- |
| `colors.canvas` | `#161616` | `AppColors.background` | `bg-[#161616]` / `bg-canvas-dark` | 전체 마케팅 / 제품 메인 캔버스 (Dark Canvas) |
| `colors.surface-1` | `#262626` | `AppColors.surface` | `bg-[#262626]` / `bg-surface-dark` | 다크 카드 표면 및 인풋 필드 배경 |
| `colors.primary` | `#0F62FE` | `AppColors.primary` / `accent` | `bg-[#0F62FE]` / `text-ibm-blue` | **Confident IBM Blue** (Confidence Primary CTA, 포커스 등) |
| `colors.on-primary` | `#FFFFFF` | `AppColors.onPrimary` | `text-white` | primary 버튼 위 및 주요 텍스트 색상 |
| `colors.hairline` | `#393939` | `AppColors.border` | `border-[#393939]` / `border-hairline` | 다크 카드 테두리 및 구분선 (1px Gray-80) |
| `colors.semantic-success` | `#24A148` | `AppColors.good` | `bg-[#24A148]` / `text-success` | 양호 상태 (Carbon Green-50) |
| `colors.semantic-warning` | `#F1C21B` | `AppColors.warning` | `bg-[#F1C21B]` / `text-warning` | 주의 상태 (Carbon Yellow-30) |
| `colors.semantic-error` | `#DA1E28` | `AppColors.defect` | `bg-[#DA1E28]` / `text-error` | 결함 상태 (Carbon Red-60) |

### 📐 둥글기 스케일 (Border Radius Scale)

IBM Carbon 고유의 기하학적이고 견고한 직각 코너 반경 규격을 양쪽 플랫폼에 공통 적용하여 직관성과 일치성을 확립합니다.

| Carbon Token (DESIGN.md) | Value | Flutter Target | Tailwind Class | 주요 적용 컴포넌트 |
| :--- | :--- | :--- | :--- | :--- |
| `rounded.none` | `0px` | `BorderRadius.zero` | `rounded-none` | **모든 버튼, 카드, 텍스트 입력 필드, 상세 패널** |
| `rounded.full` | `9999px` | `AppRadius.borderFull` | `rounded-full` | 원형 아바타, 예외적인 완전 원형 아이콘 버튼 |

---

## 2. 플랫폼별 구현 사양 및 검증

### 📱 Flutter 태블릿 앱 (`/app`)
*   **완료 항목**:
    - `app/lib/core/tokens.dart` 및 `app/lib/core/theme.dart` 리팩토링 및 커밋 완료.
    - IBM Carbon Gray 100 Dark 테마 사양에 따른 다크 캔버스(`161616`)와 약간 떠 있는 직각 카드 표면(`262626`), `1px Gray-80 hairline border` 적용 완료.
    - 48px 높이와 `0px` 직각 규격을 보장하며, Confident IBM Blue `#0F62FE` 배경에 백색 텍스트가 조화된 Primary CTA 버튼 탑재 완료.
    - 기본 폰트를 원래 탑재되어 있던 `IBM Plex Sans` 및 수치 계측용 `IBM Plex Mono` 폰트 에셋 설정 완료.
    - display 및 대형 타이틀에는 Plex Sans의 `300` (Light) 웨이트를 적용하고, 본문 텍스트에는 weight 400과 `0.16px` 자간(LetterSpacing) precision tracking을 엄격히 적용.

### 🖥️ Next.js 웹 대시보드 (`/dashboard`)
*   **권장 마이그레이션 가이드 (Action Items)**:
    - 대시보드 MVP 브랜치 (`feat/180-dashboard-mvp`) 통합 시, `dashboard/tailwind.config.ts` 파일의 `theme.extend` 영역에 상기 IBM Carbon 고유 색상 및 `rounded-none` 규격을 커스텀 테마로 추가 등록하여 상호 완벽 일치를 유지하도록 함.
    - 웹 UI 컴포넌트(버튼, 입력 필드) 코딩 시 `rounded-none` 및 `bg-[#161616]`의 Canvas Polarity 법칙을 엄격 준수하도록 강제함.

---

## 3. 종합 평가

이번 **Slice 1** 작업을 통해 IBM Carbon 특유의 견고하고 기하학적인 엔터프라이즈 다크 테마가 최초로 정의되었습니다. 태블릿 앱은 코드 수준에서 해당 테마 이식이 완료되었으며, 웹 대시보드 역시 `DESIGN.md`를 단일 진실 공급원(Single Source of Truth)으로 삼아 마이그레이션이 가능하게 되었습니다.
이를 통해 향후 어떤 기기나 디스플레이 환경에서도 SIREN 브랜드만의 신뢰성 있고 정밀한 고대비 시인성을 완벽히 확보할 수 있을 것으로 전망됩니다.
