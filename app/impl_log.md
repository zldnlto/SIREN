# UI Polish impl_log — feat/155-app-ui-polish

## Sub-issue 1 (#156): 핵심 위젯 터치 피드백 + Border Radius
- ✅ siren_button: scale 0.96, isLoading, disabled 이미 구현 완성
- ✅ siren_card: scale 0.96 이미 구현 완성
- ✅ action_card: SirenCard 위임으로 완성
- ✅ Concentric radius: card(24px) + padding(16px) → button(8px) 수식 정합
- 코드 변경 없음, 커밋으로 마무리

## Sub-issue 2 (#157): 소형 컴포넌트 Hit Area + Toast 애니메이션
- [ ] defect_badge: onTap 시 44×44pt ConstrainedBox 추가
- [ ] toast: 커스텀 animated overlay (enter 400ms / exit 200ms)
- domain_chip: 44pt 이미 구현 ✅
- inspection_status_chip: 탭 없음, 불필요 ✅

## Sub-issue 3 (#158): Stagger 애니메이션 + Dialog Enter
- [ ] defect_result_screen: 결함 항목 stagger (30-50ms, translateY(8)→0 + opacity)
- [ ] confirm_dialog: showGeneralDialog + custom scale(0.95)+opacity enter
- history_detail tabular: monoSm 이미 FontFeature.tabularFigures 포함 ✅

## Sub-issue 4 (#159): 화면 전환 + EmptyState
- [ ] router.dart: GoRoute pageBuilder + CustomTransitionPage (250ms ease-out)
- [ ] history_list_screen: EmptyState 위젯 (아이콘 + 메시지 + 액션)
