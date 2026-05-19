# SIREN Flutter App — UI Generation Request (Pass 2: Extended Screens)

## Context
This is Pass 2. Reuse all components, tokens, and design language
established in Pass 1 (Login / Home / Progress / Result screens).
Material 3, Riverpod, GoRouter. Same dark-mode-first, industrial aesthetic.

---

## Screens to Generate (Pass 2)

### Screen 6: Inspection History List
Purpose: Browse personal inspection records

Components:
- Page header: "검사 이력" + date filter chip row (오늘 / 이번 주 / 이번 달)
- Inspection card list (infinite scroll)

Card layout per item:
┌──────────────────────────────────┐
│ [Thumbnail 80x80] 균열 (도장)    │
│                   2026.05.13     │
│                   [결함있음 배지] │
│                   표면처리 공정  │
└──────────────────────────────────┘
- Thumbnail: original_url image, rounded corners
- QualityBadge: reuse component from Pass 1 (결함있음/정상)
- Tap → History Detail

UX:
- Empty state: "검사 이력이 없습니다" + camera icon
- Pull-to-refresh

---

### Screen 7: History Detail
Purpose: Review past inspection in full

Reuse Result Screen layout exactly with these differences:
- No Save button (already saved)
- Report button shows correct state based on record's report_flagged value
  - false → enabled state ("보고서 발송")
  - true  → sent state ("보고 완료 ✓")
- Add timestamp row: "검사일시: 2026.05.13 14:32"
- Grad-CAM toggle: same behavior as Result Screen

---

### Screen 8: My Profile
Purpose: View account info + logout

Components:
- Avatar placeholder (initials-based, large circle)
- Employee name (large)
- Employee ID
- Role badge ("검사원")
- Divider
- Stats row: 총 검사 {N}건 | 결함 발견 {N}건 | 보고 완료 {N}건
- Logout button (outlined, bottom — NOT destructive red, neutral color)

UX:
- Logout → Confirm Dialog → navigate to Login, clear session
- Stats are read-only display

---

## Reuse Checklist (must carry over from Pass 1)
- QualityBadge widget (결함있음: red #D32F2F / 정상: green #388E3C)
- ActionCard widget (cause / action_steps / reinspection_criteria / disclaimer)
- ImageOverlayViewer widget (BBox default, Grad-CAM toggle)
- Toast component (success/error variants)
- ConfirmDialog component
- All color tokens and typography scale
