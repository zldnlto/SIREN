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
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: historyAsync.when(
        data: (list) => list.isEmpty
            ? _EmptyState(onAction: () => context.go('/home'))
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(
                  color: AppColors.border,
                  height: AppSpacing.md,
                  thickness: 1,
                ),
                itemBuilder: (context, i) => _HistoryTile(inspection: list[i]),
              ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline, // Sharp icon
                size: 48,
                color: AppColors.critical,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '이력을 불러올 수 없습니다.',
                style: AppTextStyles.bodyMd,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('$e', style: AppTextStyles.bodySm),
              const SizedBox(height: AppSpacing.md),
              SirenButton(
                label: '다시 시도',
                size: SirenButtonSize.md,
                onPressed: () => ref.invalidate(historyProvider),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_toggle_off, // Sharp icon
              size: 64,
              color: AppColors.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('검사 이력이 없습니다.', style: AppTextStyles.titleSm),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '검사를 실행하면 이력이 자동으로 저장됩니다.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            SirenButton(
              label: '검사 시작',
              size: SirenButtonSize.md,
              onPressed: onAction,
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

    return SirenCard(
      onTap: () => context.pushNamed(
        'history-detail',
        pathParameters: {'id': inspection.id},
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DomainChip(domain: domain),
                const SizedBox(height: AppSpacing.xs),
                Text(dateStr, style: AppTextStyles.monoSm),
              ],
            ),
          ),
          InspectionStatusChip(status: status),
        ],
      ),
    );
  }
}
