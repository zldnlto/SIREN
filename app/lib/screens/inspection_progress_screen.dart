import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../providers/inspection_provider.dart';
import '../widgets/siren_button.dart';
import '../widgets/toast.dart';

class InspectionProgressScreen extends ConsumerStatefulWidget {
  const InspectionProgressScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  ConsumerState<InspectionProgressScreen> createState() =>
      _InspectionProgressScreenState();
}

class _InspectionProgressScreenState
    extends ConsumerState<InspectionProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDetection());
  }

  void _runDetection() {
    ref.read(inspectionProvider.notifier).runDetection(widget.inspectionId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);

    ref.listen(inspectionProvider, (prev, next) {
      final route = next.nextRoute;
      if (route != null && prev?.nextRoute == null) {
        context.goNamed(route, extra: widget.inspectionId);
      }
      if (next.error != null && prev?.error == null) {
        Toast.show(context, '검사 중 오류가 발생했습니다.', type: ToastType.error);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '검사 진행 중',
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w400, // linear.app display-md/subhead weight
            letterSpacing: -0.2, // negative tracking
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isDetecting) ...[
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: AppSpacing.lg),
                  Text('AI 결함 분석 중...', style: AppTextStyles.titleSm),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '잠시만 기다려 주세요.',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ] else if (state.error != null) ...[
                  const Icon(
                    Icons.error_outline_rounded, // Rounded icon
                    size: 64,
                    color: AppColors.critical,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('검사에 실패했습니다.', style: AppTextStyles.titleSm),
                  const SizedBox(height: AppSpacing.lg),
                  SirenButton(
                    label: '다시 시도',
                    onPressed: _runDetection,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SirenButton(
                    label: '홈으로 돌아가기',
                    variant: SirenButtonVariant.ghost,
                    onPressed: () => context.go('/home'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    '준비 중...',
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
