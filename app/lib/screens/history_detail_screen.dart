import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';
import '../models/inspection_status.dart';
import '../providers/history_provider.dart';
import '../widgets/domain_chip.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/inspection_status_chip.dart';
import '../widgets/siren_section_header.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionAsync = ref.watch(inspectionDetailProvider(inspectionId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '검사 상세',
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w300,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: inspectionAsync.when(
        data: (inspection) {
          final dateStr = DateFormat('yyyy.MM.dd HH:mm')
              .format(inspection.createdAt.toLocal());
          final domain =
              AnnotationDomainX.fromString(inspection.annotationDomain);
          final status =
              InspectionStatusX.fromString(inspection.status ?? 'unknown');

          return ListView(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ImageOverlayViewer(imageUrl: inspection.thumbnailKey),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        DomainChip(domain: domain),
                        const Spacer(),
                        InspectionStatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const SirenSectionHeader(
                      title: '검사 정보',
                      showDivider: true,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _InfoRow(label: '검사 일시', value: dateStr, mono: true),
                    _InfoRow(
                      label: '상태',
                      value: status.label,
                    ),
                    _InfoRow(
                      label: '검사 ID',
                      value: inspection.id,
                      mono: true,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Text(
            '상세 정보를 불러올 수 없습니다.\n$e',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(label, style: AppTextStyles.labelMd),
          ),
          Expanded(
            child: Text(
              value,
              style: mono ? AppTextStyles.monoSm : AppTextStyles.bodyMd,
            ),
          ),
        ],
      ),
    );
  }
}
