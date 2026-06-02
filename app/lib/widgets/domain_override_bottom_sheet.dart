import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/tokens.dart';
import '../providers/inspection_provider.dart';

class DomainOverrideBottomSheet extends ConsumerStatefulWidget {
  const DomainOverrideBottomSheet({
    super.key,
    required this.inspectionId,
    required this.currentDomain,
  });

  final String inspectionId;
  final String currentDomain;

  static Future<void> show(
    BuildContext context, {
    required String inspectionId,
    required String currentDomain,
  }) {
    return showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      isScrollControlled: true,
      builder: (context) => DomainOverrideBottomSheet(
        inspectionId: inspectionId,
        currentDomain: currentDomain,
      ),
    );
  }

  @override
  ConsumerState<DomainOverrideBottomSheet> createState() =>
      _DomainOverrideBottomSheetState();
}

class _DomainOverrideBottomSheetState
    extends ConsumerState<DomainOverrideBottomSheet> {
  // Define the 6 Premium LNG Industry domains matching RAG engine & Neural net specs
  final List<Map<String, String>> _domains = [
    {
      'key': 'surface_treatment',
      'title': 'LNG Tank Outer Surface',
      'desc': '외벽 및 탱크 도장 표면 결함 탐지',
      'icon': '', // Custom unicode icon mapping or system fallback
    },
    {
      'key': 'pipe_weld',
      'title': 'Pipe Weld Joints',
      'desc': '배관 용접 라인 및 기공 손상 판독',
      'icon': '',
    },
    {
      'key': 'pump_tower',
      'title': 'Pump Tower Structures',
      'desc': '펌프 타워 구조물 용접부 및 균열 진단',
      'icon': '',
    },
    {
      'key': 'internal_cargo',
      'title': 'Internal Cargo Containment',
      'desc': '내부 단열재 카고 멤브레인 이상 거동 검사',
      'icon': '',
    },
    {
      'key': 'manhole_valve',
      'title': 'Manhole & Valves',
      'desc': '맨홀 결속 부위 및 가스 배출 밸브 점검',
      'icon': '',
    },
    {
      'key': 'secondary_barrier',
      'title': 'Secondary Barrier System',
      'desc': '이차 방벽 누설 흔적 및 단열 폼 결함 식별',
      'icon': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl),
          topRight: Radius.circular(AppRadius.xl),
        ),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle HUD element
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header text block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '도메인 수동 오버라이드',
                style: AppTextStyles.headlineSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: AppRadius.borderXs,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'MANUAL OVERRIDE',
                  style: AppTextStyles.monoSm.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '신경망 자동 탐지 결과를 강제로 오버라이드할 도메인을 선택하십시오.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 6 domains list with 50ms Staggered entry transitions
          Column(
            children: _domains.indexed.map((entry) {
              final idx = entry.$1; // 1-based index for record positional fields
              final d = entry.$2;   // 2nd positional field is the domain map
              final bool isSelected = d['key'] == widget.currentDomain;

              return _StaggeredItem(
                index: idx,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : const Color(0xFF16191E),
                      borderRadius: AppRadius.borderMd,
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: 1.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Perform tactile vibrations immediately
                          HapticFeedback.lightImpact();
                          
                          // POP immediately within 150ms pop-transition window
                          Navigator.pop(context);

                          // Execute background update asynchronously without lagging UI close animations
                          Future.microtask(() => ref
                              .read(inspectionProvider.notifier)
                              .updateDomain(widget.inspectionId, d['key']!));
                        },
                        borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadius.md),
                        ),
                        splashColor: AppColors.primary.withValues(alpha: 0.15),
                        highlightColor: AppColors.primary.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: 14,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.15)
                                      : const Color(0xFF20242D),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 18,
                                  color: isSelected
                                      ? AppColors.primaryLight
                                      : AppColors.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d['title']!,
                                      style: AppTextStyles.labelMd.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? AppColors.primaryLight
                                            : Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      d['desc']!,
                                      style: AppTextStyles.bodySm.copyWith(
                                        fontSize: 11.5,
                                        color: AppColors.onSurfaceMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

// ─── Staggered transition helper following Emil Kowalski specifications ─────────
class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translate;

  @override
  void initState() {
    super.initState();
    // Emil Kowalski Motion: Smooth 300ms ease-out translateY entry
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _translate = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // 50ms stagger intervals for cascading VISCERAL feel
    final delay = Duration(milliseconds: widget.index * 50);
    Future.delayed(delay, () {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _translate.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}
