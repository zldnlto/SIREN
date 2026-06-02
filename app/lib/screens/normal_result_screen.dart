import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../models/defect_severity.dart';
import '../providers/inspection_provider.dart';
import '../widgets/defect_badge.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_card.dart';
import '../widgets/toast.dart';

class NormalResultScreen extends ConsumerWidget {
  const NormalResultScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inspectionProvider);
    final imageUrl = state.inspection?.thumbnailKey;

    final isTablet =
        MediaQuery.of(context).size.shortestSide >= AppBreakpoints.tablet;

    // Premium Image Viewer Panel (16px rounded + 1px hairline)
    final imagePane = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderXl, // 16px rounded corners
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.good.withOpacity(0.04), // Subtle green neon aura
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ImageOverlayViewer(imageUrl: imageUrl),
    );

    // Premium All Systems Operational Ribbon
    final statusRibbon = SirenCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PulsingStatusLed(), // Glowing pulses Green LED
                const SizedBox(width: AppSpacing.md),
                Text(
                  'ALL SYSTEMS OPERATIONAL',
                  style: AppTextStyles.monoLg.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppColors.good,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.border, height: 1.0),
            const SizedBox(height: AppSpacing.md),
            Text(
              'AI 스캐닝 검사 완결. 용접선 결함 및 누설 취약 부품이 존재하지 않습니다.',
              style: AppTextStyles.bodyMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 14.5,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            const DefectBadge(severity: DefectSeverity.good),
          ],
        ),
      ),
    );

    final controlButtons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 50, // 50px sporty height
          child: SirenButton(
            label: '보고서 저장',
            icon: const Icon(Icons.save_alt_rounded),
            onPressed: () => Toast.show(
              context,
              '보고서가 저장되었습니다.',
              type: ToastType.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 50, // 50px sporty height
          child: SirenButton(
            label: '홈으로 돌아가기',
            variant: SirenButtonVariant.secondary,
            onPressed: () {
              ref.read(inspectionProvider.notifier).reset();
              context.go('/home');
            },
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '검사 완료',
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded, color: AppColors.onSurface),
          onPressed: () {
            ref.read(inspectionProvider.notifier).reset();
            context.go('/home');
          },
        ),
      ),
      body: Stack(
        children: [
          // ─── Ambient Auroral Green/Lavender Glow Background ───
          Positioned(
            top: -150,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.good.withOpacity(0.06), // green operational aura
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
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Main Scaffold Content ───
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: isTablet
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: imagePane,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              statusRibbon,
                              const Spacer(),
                              controlButtons,
                              const SizedBox(height: AppSpacing.lg),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: imagePane,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        statusRibbon,
                        const Spacer(),
                        controlButtons,
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Led Indicator Widget ─────────────────────────────────────────────
class _PulsingStatusLed extends StatefulWidget {
  @override
  State<_PulsingStatusLed> createState() => _PulsingStatusLedState();
}

class _PulsingStatusLedState extends State<_PulsingStatusLed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              const Color(0xFF27A644).withOpacity(0.3),
              const Color(0xFF27A644),
              _pulseController.value,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF27A644).withOpacity(0.7 * _pulseController.value),
                blurRadius: 10 * _pulseController.value,
                spreadRadius: 3 * _pulseController.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
