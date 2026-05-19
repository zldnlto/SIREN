import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../providers/inspection_provider.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/quality_badge.dart';
import '../widgets/toast.dart';

class NormalResultScreen extends ConsumerWidget {
  const NormalResultScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionProvider);
    final imageUrl = state.inspection?.thumbnailKey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('검사 완료'),
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            ref.read(inspectionProvider.notifier).reset();
            context.go('/home');
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: ImageOverlayViewer(imageUrl: imageUrl),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: kGoodColor,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '결함이 감지되지 않았습니다.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const QualityBadge(qualityState: 'good'),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt),
                    label: const Text('보고서 저장'),
                    onPressed: () => Toast.show(
                      context,
                      '보고서가 저장되었습니다.',
                      type: ToastType.success,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      ref.read(inspectionProvider.notifier).reset();
                      context.go('/home');
                    },
                    child: const Text('홈으로 돌아가기'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
