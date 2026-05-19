import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/guidance_provider.dart';
import '../providers/inspection_provider.dart';
import '../widgets/action_card.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/quality_badge.dart';
import '../widgets/toast.dart';

class DefectResultScreen extends ConsumerWidget {
  const DefectResultScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionProvider);
    final result = state.result;

    if (result == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final imageUrl = state.inspection?.thumbnailKey;
    final bboxes = result.defects
        .where((d) => d.bbox != null)
        .map((d) => d.bbox!)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('결함 감지됨'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            ref.read(inspectionProvider.notifier).reset();
            context.go('/home');
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ImageOverlayViewer(
                imageUrl: imageUrl,
                bboxes: bboxes,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '검출된 결함 ${result.defects.length}건',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(width: 8),
                  const QualityBadge(qualityState: 'defect'),
                ],
              ),
            ),
            ...result.defects.map(
              (defect) => _DefectCard(
                ontologyId: defect.ontologyId,
                displayLabel: defect.displayLabel,
                confidenceScore: defect.confidenceScore,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_alt),
                label: const Text('보고서 저장'),
                onPressed: () => Toast.show(context, '보고서가 저장되었습니다.',
                    type: ToastType.success),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DefectCard extends ConsumerWidget {
  const _DefectCard({
    required this.ontologyId,
    required this.displayLabel,
    required this.confidenceScore,
  });

  final String ontologyId;
  final String displayLabel;
  final double confidenceScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidanceAsync = ref.watch(guidanceProvider(ontologyId));

    return guidanceAsync.when(
      data: (guidance) => ActionCard(guidance: guidance),
      loading: () => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Text('$displayLabel 조치 정보 로딩 중...'),
            ],
          ),
        ),
      ),
      error: (_, __) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '신뢰도 ${(confidenceScore * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                '조치 정보를 불러올 수 없습니다.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
