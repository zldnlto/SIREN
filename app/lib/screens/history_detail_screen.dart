import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/history_provider.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/quality_badge.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionAsync = ref.watch(inspectionDetailProvider(inspectionId));

    return Scaffold(
      appBar: AppBar(title: const Text('검사 상세')),
      body: inspectionAsync.when(
        data: (inspection) {
          final dateStr = DateFormat('yyyy.MM.dd HH:mm')
              .format(inspection.createdAt.toLocal());
          final isDefect = inspection.status == 'defect_detected';

          return ListView(
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ImageOverlayViewer(imageUrl: inspection.thumbnailKey),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            inspection.annotationDomain,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        QualityBadge(
                          qualityState: isDefect ? 'defect' : 'good',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(label: '검사 일시', value: dateStr),
                    _InfoRow(label: '상태', value: inspection.status),
                    _InfoRow(label: '검사 ID', value: inspection.id),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('상세 정보를 불러올 수 없습니다.\n$e')),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
