import 'package:flutter/material.dart';
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

class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

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
            child: historyAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return _EmptyState(onAction: () => context.go('/home'));
                }

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

                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(
                          height: AppSpacing.sm,
                        ),
                        itemBuilder: (context, i) => _HistoryTile(inspection: list[i]),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: AppColors.critical,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '이력을 불러올 수 없습니다.',
                        style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        e.toString(), 
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SirenButton(
                        label: '다시 시도',
                        size: SirenButtonSize.md,
                        onPressed: () => ref.invalidate(historyProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.inspection});
  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('yyyy.MM.dd HH:mm').format(inspection.createdAt.toLocal());
    final domain = AnnotationDomainX.fromString(inspection.annotationDomain);
    final status = InspectionStatusX.fromString(inspection.status ?? 'unknown');

    // Accent line decoration based on flagged status
    final indicatorColor = inspection.reportFlagged 
        ? AppColors.defect 
        : (status == InspectionStatus.completed ? AppColors.good : AppColors.onSurfaceMuted);

    return SirenCard(
      onTap: () => context.pushNamed(
        'history-detail',
        pathParameters: {'id': inspection.id},
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
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
            
            // Text Meta Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DomainChip(domain: domain),
                      if (inspection.reportFlagged) ...[
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
    );
  }
}
