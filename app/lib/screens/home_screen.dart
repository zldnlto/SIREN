import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';
import '../providers/history_provider.dart';
import '../providers/inspection_provider.dart';
import '../widgets/siren_button.dart';
import '../widgets/toast.dart';
import '../widgets/siren_section_header.dart';
import '../models/inspection_status.dart';
import '../widgets/inspection_status_chip.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AnnotationDomain _selectedDomain = AnnotationDomain.surfaceTreatment;

  @override
  Widget build(BuildContext context) {
    final inspectionState = ref.watch(inspectionProvider);

    ref.listen(inspectionProvider, (prev, next) {
      if (next.inspection != null &&
          prev?.inspection == null &&
          !next.isCreating) {
        context.pushNamed('progress', extra: next.inspection!.id);
      }
      if (next.error != null && prev?.error == null) {
        Toast.show(context, '검사 생성에 실패했습니다.', type: ToastType.error);
      }
    });

    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isTablet = shortestSide >= AppBreakpoints.tablet;

    // Responsive grid layout values
    final crossAxisCount = isTablet ? 3 : 1;
    final childAspectRatio = isTablet ? 1.6 : 3.5;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'SIREN',
          style: AppTextStyles.headlineMd.copyWith(
            color: AppColors.primary, // Signature Lavender
            fontWeight: FontWeight.w600, // Linear custom display weight
            letterSpacing: -0.4, // Linear Display negative tracking
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.onSurface),
            onPressed: () => context.go('/history'),
            tooltip: '검사 이력',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient glow accent
            Positioned(
              top: -150,
              right: -150,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.03),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Connection and profile bar
                  const _OperatorStatusBar(),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Domain Selection Section Header
                  const SirenSectionHeader(
                    title: '검사 영역 선택 (Bento Grid)',
                    showDivider: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Bento Grid Selector
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: _kDomainMetadataList.length,
                    itemBuilder: (context, index) {
                      final meta = _kDomainMetadataList[index];
                      return _BentoDomainCard(
                        meta: meta,
                        isSelected: meta.domain == _selectedDomain,
                        onTap: () => setState(() => _selectedDomain = meta.domain),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // 4. Recent Inspection Summary Widget
                  const _RecentInspectionPanel(),
                  const SizedBox(height: 80), // extra padding for bottom FAB
                ],
              ),
            ),
            // Floating bottom actions with smooth glass gradient backdrop
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withValues(alpha: 0.0),
                      AppColors.background.withValues(alpha: 0.85),
                      AppColors.background,
                    ],
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 560 : double.infinity,
                    ),
                    child: SirenButton(
                      label: '새 검사 시작 (Start)',
                      icon: const Icon(Icons.camera_alt_rounded),
                      onPressed:
                          inspectionState.isLoading ? null : _startInspection,
                      isLoading: inspectionState.isCreating,
                      size: SirenButtonSize.lg,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startInspection() {
    ref.read(inspectionProvider.notifier).start(_selectedDomain.apiValue);
  }
}

// ─── Pulsing LED Indicator ──────────────────────────────────────────────────
class _PulsingStatusLed extends StatefulWidget {
  const _PulsingStatusLed();

  @override
  State<_PulsingStatusLed> createState() => _PulsingStatusLedState();
}

class _PulsingStatusLedState extends State<_PulsingStatusLed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.good,
          shape: BoxShape.circle,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.good,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.good.withValues(alpha: 0.5 * _animation.value),
              blurRadius: 6 * _animation.value,
              spreadRadius: 2 * _animation.value,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Operator Status Bar ─────────────────────────────────────────────────────
class _OperatorStatusBar extends StatelessWidget {
  const _OperatorStatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
            ),
            child: const Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '사원번호: 084920 (현장 세션)',
                  style: AppTextStyles.bodyStrong.copyWith(
                    fontSize: 13,
                    color: AppColors.onBackground,
                  ),
                ),
                Row(
                  children: [
                    const _PulsingStatusLed(),
                    const SizedBox(width: 6),
                    Text(
                      '기기 연결 상태 양호 (Standby)',
                      style: AppTextStyles.labelSm.copyWith(
                        fontSize: 10.5,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: AppRadius.borderSm,
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: Text(
              'TERM-X9',
              style: AppTextStyles.monoSm.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bento Card Metadata ─────────────────────────────────────────────────────
class _DomainMetadata {
  final AnnotationDomain domain;
  final IconData icon;
  final String subtitle;
  final String desc;

  const _DomainMetadata({
    required this.domain,
    required this.icon,
    required this.subtitle,
    required this.desc,
  });
}

const _kDomainMetadataList = [
  _DomainMetadata(
    domain: AnnotationDomain.surfaceTreatment,
    icon: Icons.layers_rounded,
    subtitle: "균열·스크래치·도막",
    desc: "표면 코팅 상태, 스크래치 및 도막 분리 여부를 분석합니다.",
  ),
  _DomainMetadata(
    domain: AnnotationDomain.welding,
    icon: Icons.fireplace_rounded,
    subtitle: "용접 비드·기공·균열",
    desc: "접합 용접부 표면 기공 및 비드 정렬 상태를 검증합니다.",
  ),
  _DomainMetadata(
    domain: AnnotationDomain.cutting,
    icon: Icons.content_cut_rounded,
    subtitle: "절단 치수·조도 이상",
    desc: "모재 절단 단면 거칠기 및 기하학적 치수를 감지합니다.",
  ),
  _DomainMetadata(
    domain: AnnotationDomain.cable,
    icon: Icons.cable_rounded,
    subtitle: "피복 손상·배선 불량",
    desc: "통신 및 전력선 피복 피탈, 정렬 이상을 진단합니다.",
  ),
  _DomainMetadata(
    domain: AnnotationDomain.pipe,
    icon: Icons.plumbing_rounded,
    subtitle: "배관 누설·부식·접합",
    desc: "LNG 밸브/관로 누설 징후 및 플랜지 접합 결함을 식별합니다.",
  ),
  _DomainMetadata(
    domain: AnnotationDomain.foamSpray,
    icon: Icons.bubble_chart_rounded,
    subtitle: "단열 두께·발포 밀도",
    desc: "단열재 우레탄 발포 두께 및 내부 보이드(공동)를 탐지합니다.",
  ),
];

// ─── Bento Domain Card ────────────────────────────────────────────────────────
class _BentoDomainCard extends StatelessWidget {
  const _BentoDomainCard({
    required this.meta,
    required this.isSelected,
    required this.onTap,
  });

  final _DomainMetadata meta;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '검사 도메인 선택: ${meta.domain.label}',
      selected: isSelected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppDurations.normal,
            curve: AppCurves.standard,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.04)
                  : AppColors.surface,
              borderRadius: AppRadius.borderLg,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 12,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : AppColors.surfaceVariant,
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        meta.icon,
                        color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meta.domain.label,
                            style: AppTextStyles.bodyStrong.copyWith(
                              fontSize: 15,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.onBackground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            meta.subtitle,
                            style: AppTextStyles.labelSm.copyWith(
                              fontSize: 11,
                              color: isSelected
                                  ? AppColors.primaryLight.withValues(alpha: 0.8)
                                  : AppColors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  meta.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMd.copyWith(
                    fontSize: 12,
                    height: 1.35,
                    color: isSelected
                        ? AppColors.onSurface.withValues(alpha: 0.9)
                        : AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Recent Inspection Panel ─────────────────────────────────────────────────
class _RecentInspectionPanel extends ConsumerWidget {
  const _RecentInspectionPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '최근 검사 이력',
              style: AppTextStyles.labelLg.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurfaceMuted,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/history'),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  '전체 보기 →',
                  style: AppTextStyles.labelMd.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        historyAsync.when(
          data: (list) {
            if (list.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_toggle_off_rounded,
                      color: AppColors.onSurfaceMuted,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '최근 검사 이력이 없습니다. 새 검사를 실행해 보세요.',
                        style: AppTextStyles.labelMd.copyWith(
                          fontSize: 12,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final recentList = list.take(2).toList();
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = recentList[index];
                final dateStr = DateFormat('MM.dd HH:mm').format(item.createdAt.toLocal());
                final domain = AnnotationDomainX.fromString(item.annotationDomain);
                final status = InspectionStatusX.fromString(item.status ?? 'unknown');

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.borderLg,
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: AppRadius.borderXs,
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Text(
                          domain.label,
                          style: AppTextStyles.labelMd.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        dateStr,
                        style: AppTextStyles.monoSm.copyWith(
                          fontSize: 11,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                      const Spacer(),
                      InspectionStatusChip(status: status),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.onSurfaceMuted,
                        size: 16,
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => Container(
            height: 60,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: AppColors.primary,
              ),
            ),
          ),
          error: (e, _) => Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderLg,
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Text(
              '이력 로드 실패',
              style: AppTextStyles.labelMd.copyWith(color: AppColors.critical),
            ),
          ),
        ),
      ],
    );
  }
}
