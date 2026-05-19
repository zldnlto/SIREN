# SIREN Flutter App — UI Generation Request (Pass 1: Core Screens)

## Project Overview
SIREN is an LNG tank surface defect detection system for industrial field workers.
Workers use a tablet to photograph tank surfaces, receive AI defect analysis results,
and get action guidance on-site.

## Platform
Flutter (Material 3) + Riverpod + GoRouter
Target device: Industrial tablet (landscape/portrait both supported)

## Design Principles
- Glove-friendly: minimum touch target 64x64dp, button gap ≥ 16dp
- High contrast (outdoor bright lighting conditions)
- Maximum 3 taps from capture to result
- Dark mode preferred
- Industrial / functional aesthetic — NOT consumer app style

---

## Screens to Generate (Pass 1)

### Screen 1: Login
Purpose: Employee ID + password authentication

Components:
- SIREN logo + tagline ("LNG Tank Inspection System")
- Employee ID text field (numeric keyboard)
- Password text field (obscure toggle)
- Login button (full width, minimum 64dp height)
- Error message area (below button, red text)

UX:
- Auto-focus on Employee ID field on mount
- Login button shows CircularProgressIndicator while loading
- Shake animation on error

---

### Screen 2: Home (Capture Entry)
Purpose: Primary entry point for inspection image input

Components:
- User info header (employee name + badge)
- PRIMARY CTA: "촬영하기" button — minimum 80dp height, full width, accent color
- SECONDARY CTA: "갤러리에서 선택" button — outlined style, below primary
- Recent inspection shortcut card (last 1 item: thumbnail + defect name + QualityBadge)

UX:
- Camera CTA must be visually dominant (2x weight vs gallery button)
- One-hand operable layout
- Recent shortcut is tappable → navigates to History Detail

---

### Screen 3: Inspection Progress
Purpose: Show AI inference status while user waits

States and UI per state:
- uploading: "이미지 업로드 중..." + linear progress bar (animated)
- inferencing: "AI 분석 중입니다..." + radar/scanning animation (NOT simple spinner)
- timeout: "응답 시간이 초과되었습니다" + Retry button (64dp height)
- network_error: "네트워크 오류" + error icon + Retry button

UX:
- Block back navigation during uploading/inferencing states
- Max assumed wait time: 3 seconds
- Scanning animation should feel industrial (radar sweep or horizontal scan line)

---

### Screen 4: Inspection Result — Defect Found
Purpose: Display AI result + action guidance (quality_state = defect)

Layout priority (top to bottom):
1. Image viewer with overlay
2. Defect info row
3. Quality Badge (결함있음)
4. Action Card
5. Action buttons (Save / Report)

#### Image Viewer
- Shows original_url as base image
- BBox overlay rendered by default (drawn over image using Canvas/CustomPaint)
- Grad-CAM toggle button (top-right corner of image): OFF by default
  - When ON: renders gradcam_url as semi-transparent layer (opacity 0.6) over original
  - Toggle icon: eye icon or heatmap icon

#### Defect Info Row
- display_label: large bold text (20sp+) — e.g. "균열 (도장)"
- confidence: "신뢰도 94.2%" format, smaller secondary text

#### Quality Badge
Full-width colored banner:
- DEFECT → background: red (#D32F2F), text: "결함 있음", white label
- Shifts app bar/header accent color to red

#### Action Card
Card component with sections:

┌─────────────────────────────────┐
│ [결함있음 배지] display_label   │ ← header
│ 신뢰도: 94.2%                   │
├─────────────────────────────────┤
│ 📌 원인                         │
│ {cause text}                    │
├─────────────────────────────────┤
│ 🔧 조치 방법                    │
│ 1. {step}                       │
│ 2. {step}                       │
├─────────────────────────────────┤
│ ✅ 재검사 기준                   │
│ {reinspection_criteria text}    │
├─────────────────────────────────┤
│ ⚠️ 이 안내는 참고용입니다.      │ ← fixed disclaimer, small italic
└─────────────────────────────────┘

Font: minimum 16sp throughout card. Bold on section headers.

#### Action Buttons
Two buttons at bottom, full width:

Save Button:
- Label: "검사 결과 저장"
- Tap → Confirm Dialog ("검사 결과를 저장하겠습니까?") → POST
- On success: green Toast "저장 완료"

Report Button (3 states):
- disabled: gray, "보고서 발송" — shown before save
- enabled: accent color, "보고서 발송" — shown after save success
- sent: gray, "보고 완료 ✓" — non-tappable, shown after report sent
- Tap (enabled) → Confirm Dialog ("관리자에게 보고하겠습니까?") → PATCH
- On success: Toast "보고 완료"

---

### Screen 5: Inspection Result — No Defect
Purpose: Display normal result (quality_state = good)

Layout priority (top to bottom):
1. Image viewer (original only, no overlay)
2. Quality Badge (정상)
3. "결함이 감지되지 않았습니다" message
4. Action buttons (Save / Continue)

#### Quality Badge
Full-width colored banner:
- GOOD → background: green (#388E3C), text: "정상", white label
- Shifts app bar/header accent color to green

#### Action Buttons
Two buttons at bottom, full width:

Save Button:
- Label: "검사 결과 저장"
- Same confirm + toast flow as Screen 4

Continue Button:
- Label: "검사 계속하기"
- Tap → navigate back to Camera (Screen 2)
- Outlined style

---

## Data Models (for Mock Data Generation)

### DetectedDefect
```json
{
  "ontology_id": "surface_treatment.crack.paint",
  "display_label": "균열 (도장)",
  "quality_state": "defect",
  "annotation_domain": "surface_treatment",
  "canonical_class_name": "crack_paint",
  "confidence_score": 0.942,
  "bbox": [0.35, 0.28, 0.52, 0.41],
  "gradcam_key": "gradcam/insp_001_heatmap.png"
}
```

### InspectionResult
```json
{
  "inspection_id": "insp_20260513_001",
  "annotation_domain": "surface_treatment",
  "defects": [ /* DetectedDefect list */ ],
  "detected_at": "2026-05-13T14:32:00Z"
}
```

### GuidanceResponse
```json
{
  "inspection_id": "insp_20260513_001",
  "ontology_id": "surface_treatment.crack.paint",
  "display_label": "균열 (도장)",
  "quality_state": "defect",
  "cause": "반복 하중 또는 용접부 결함으로 인한 균열 발생",
  "action_steps": [
    "해당 구역 즉시 작업 중단",
    "관리자에게 보고 후 승인 대기",
    "보수팀 긴급 출동 요청"
  ],
  "reinspection_criteria": "보수 완료 후 동일 구역 재촬영 및 AI 재검사 필수",
  "disclaimer": "이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.",
  "referenced_doc": "sop_surface_crack_v1"
}
```

### Expected display_label values (use for mock variety):
균열 (도장) | 스크래치 (도장) | 도장흐름 (도장) | 도막떨어짐 (도장) | 도막분리 (도장) | 탱크클리닝불량 (모재)

### quality_state values:
- "defect" → Screen 4 (결함 있음, 빨강 배너, 조치 카드 표시)
- "good"   → Screen 5 (정상, 초록 배너, 조치 카드 없음)

---

## Status Definitions
InspectionStatus: PENDING | DEFECT_FOUND | NORMAL | REPORTED
LoadingStates: idle | uploading | inferencing | success | error | timeout
ReportButtonState: disabled | enabled | sent
