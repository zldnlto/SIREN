import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../models/defect_severity.dart';
import '../providers/inspection_provider.dart';
import '../widgets/defect_badge.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/siren_button.dart';
import '../widgets/toast.dart';

class NormalResultScreen extends ConsumerWidget {
  const NormalResultScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionProvider);
    final imageUrl = state.inspection?.thumbnailKey;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '검사 완료',
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w400, // linear.app display-md/subhead weight
            letterSpacing: -0.2, // negative letterSpacing
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded, color: AppColors.onSurface), // Rounded icon
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
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded, // Rounded icon
                    size: 64,
                    color: AppColors.good,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '결함이 감지되지 않았습니다.',
                    style: AppTextStyles.titleMd,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const DefectBadge(severity: DefectSeverity.good),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SirenButton(
                    label: '보고서 저장',
                    icon: const Icon(Icons.save_alt_rounded), // Rounded icon
                    onPressed: () => Toast.show(
                      context,
                      '보고서가 저장되었습니다.',
                      type: ToastType.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SirenButton(
                    label: '홈으로 돌아가기',
                    variant: SirenButtonVariant.secondary,
                    onPressed: () {
                      ref.read(inspectionProvider.notifier).reset();
                      context.go('/home');
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}
