import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';
import '../models/inspection.dart';
import '../models/inspection_status.dart';
import '../providers/history_provider.dart';
import '../widgets/domain_chip.dart';
import '../widgets/inspection_status_chip.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_card.dart';

class HistoryListScreen extends ConsumerStatefulWidget {
  const HistoryListScreen({super.key});

  @override
  ConsumerState<HistoryListScreen> createState() => _HistoryListScreenState();
}

class _HistoryListScreenState extends ConsumerState<HistoryListScreen> {
  String _selectedFilter = 'all'; // 'all' | 'today' | 'week' | 'month'

  List<Inspection> _filterList(List<Inspection> list) {
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    
    // Calculate start of this week (Monday midnight)
    final int daysToSubtract = now.weekday - 1; // Monday=1
    final weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
    
    // Calculate start of this month (1st midnight)
    final monthStart = DateTime(now.year, now.month, 1);

    return list.where((x) {
      final date = x.createdAt.toLocal();
      if (_selectedFilter == 'today') {
        return date.isAfter(todayMidnight) || date.isAtSameMomentAs(todayMidnight);
      } else if (_selectedFilter == 'week') {
        return date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart);
      } else if (_selectedFilter == 'month') {
        return date.isAfter(monthStart) || date.isAtSameMomentAs(monthStart);
      }
      return true; // 'all'
    }).toList();
  }

  void _onFilterChanged(String filter) {
    if (_selectedFilter == filter) return;
    HapticFeedback.lightImpact(); // 0ms delay light visceral impact
    setState(() {
      _selectedFilter = filter;
    });
  }

  Future<void> _handleRefresh() async {
    // Tactile pull-to-refresh tension trigger vibration
    HapticFeedback.mediumImpact();
    ref.invalidate(historyProvider);
    // Simulate network delay for premium visual feedback
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(historyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '검사 이력',
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          // ─── Ambient Auroral Glow Background ───
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -200,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Main Scaffold Body ───
          SafeArea(
            child: Builder(
              builder: (context) {
                if (list.isEmpty) {
                  return _EmptyState(onAction: () => context.go('/home'));
                }

                final filteredList = _filterList(list);
                final flaggedCount = list.where((x) => x.reportFlagged).length;
                final successRatio = list.isEmpty 
                    ? 100 
                    : ((list.length - flaggedCount) / list.length * 100).round();

                return Column(
                  children: [
                    // SaaS Observability Header Metric Banner
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, 
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.borderLg,
                          border: Border.all(color: AppColors.border, width: 1.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeaderMetric(
                              'TOTAL SCAN', 
                              '${list.length}', 
                              AppColors.primaryLight,
                            ),
                            _buildHeaderMetric(
                              'CRITICAL DEFECT', 
                              '$flaggedCount', 
                              AppColors.defect,
                            ),
                            _buildHeaderMetric(
                              'SYSTEM HEALTH', 
                              '$successRatio%', 
                              AppColors.good,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Premium Date Filter Chip Row (0ms Sync Toggle)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                      child: Row(
                        children: [
                          _buildFilterChip('all', '전체'),
                          const SizedBox(width: 8),
                          _buildFilterChip('today', '오늘'),
                          const SizedBox(width: 8),
                          _buildFilterChip('week', '이번 주'),
                          const SizedBox(width: 8),
                          _buildFilterChip('month', '이번 달'),
                        ],
                      ),
                    ),

                    // Inspection card list (infinite scroll wrapper support / Refreshable)
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _handleRefresh,
                        color: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        strokeWidth: 2.5,
                        child: filteredList.isEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.4,
                                    child: Center(
                                      child: Text(
                                        '해당 기간 내 검사 이력이 없습니다.',
                                        style: AppTextStyles.bodyMd.copyWith(
                                          color: AppColors.onSurfaceMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                key: Key('stagger_list_${_selectedFilter}_${filteredList.length}'),
                                padding: const EdgeInsets.all(AppSpacing.md),
                                itemCount: filteredList.length,
                                separatorBuilder: (_, __) => const SizedBox(
                                  height: AppSpacing.sm,
                                ),
                                itemBuilder: (context, i) => _StaggeredItem(
                                  index: i,
                                  child: _HistoryTile(inspection: filteredList[i]),
                                ),
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final bool isSelected = _selectedFilter == filterKey;
    return GestureDetector(
      onTap: () => _onFilterChanged(filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withValues(alpha: 0.1) 
              : Colors.transparent,
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMd.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primaryLight : AppColors.onSurfaceMuted,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.monoSm.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.monoSm.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
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
    // Emil Kowalski Motion: 300ms ease-out translateY entry
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _translate = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    // Stagger increments at 50ms intervals
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

// ─── History list item card with custom scale press-response feedback ────────────
class _HistoryTile extends StatefulWidget {
  const _HistoryTile({required this.inspection});
  final Inspection inspection;

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('yyyy.MM.dd HH:mm').format(widget.inspection.createdAt.toLocal());
    final domain = AnnotationDomainX.fromString(widget.inspection.annotationDomain);
    final status = InspectionStatusX.fromString(widget.inspection.status ?? 'unknown');

    // Accent line decoration based on flagged status
    final indicatorColor = widget.inspection.reportFlagged 
        ? AppColors.defect 
        : (status == InspectionStatus.completed ? AppColors.good : AppColors.onSurfaceMuted);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        context.pushNamed(
          'history-detail',
          pathParameters: {'id': widget.inspection.id},
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SirenCard(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12.0),
          child: Row(
            children: [
              // Left Status Glow Indicator Line
              Container(
                width: 3,
                height: 38,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: AppRadius.borderFull,
                  boxShadow: [
                    BoxShadow(
                      color: indicatorColor.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Mini Premium Thumbnail Image Frame
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.inspection.thumbnailKey != null
                    ? Image.asset(
                        widget.inspection.thumbnailKey!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image_rounded,
                          size: 18,
                          color: AppColors.onSurfaceMuted,
                        ),
                      )
                    : const Icon(
                        Icons.image_rounded,
                        size: 18,
                        color: AppColors.onSurfaceMuted,
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              
              // Text Meta Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DomainChip(domain: domain),
                        if (widget.inspection.reportFlagged) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.defect.withValues(alpha: 0.1),
                              borderRadius: AppRadius.borderXs,
                              border: Border.all(color: AppColors.defect.withValues(alpha: 0.3), width: 1.0),
                            ),
                            child: Text(
                              '결함 식별',
                              style: AppTextStyles.monoSm.copyWith(
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.defect,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 10, color: AppColors.onSurfaceMuted),
                        const SizedBox(width: 4),
                        Text(
                          dateStr, 
                          style: AppTextStyles.monoSm.copyWith(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Status Chip & Chevron Arrow
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InspectionStatusChip(status: status),
                  const SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.chevron_right_rounded, 
                    color: AppColors.onSurfaceMuted,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAction});
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 56,
                color: AppColors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '검사 이력이 없습니다.', 
              style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '신규 LNG 탱크 부품 스캔 및 결함 탐지를\n진행하면 이력이 자동으로 저장됩니다.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceMuted,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 160,
              height: 48,
              child: SirenButton(
                label: '검사 시작',
                size: SirenButtonSize.md,
                onPressed: onAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
