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
        title: Text('검사 이력', style: AppTextStyles.titleMd),
      ),
      body: historyAsync.when(
        data: (list) => list.isEmpty
            ? Center(
                child: Text(
                  '검사 이력이 없습니다.',
                  style: AppTextStyles.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _HistoryTile(inspection: list[i]),
              ),
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.inspection});
  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('yyyy.MM.dd HH:mm').format(inspection.createdAt.toLocal());
    final domain = AnnotationDomainX.fromString(inspection.annotationDomain);
    final status = InspectionStatusX.fromString(inspection.status);

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
