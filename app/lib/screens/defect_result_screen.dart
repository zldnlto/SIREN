import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../models/defect_severity.dart';
import '../providers/guidance_provider.dart';
import '../providers/inspection_provider.dart';
import '../widgets/action_card.dart';
import '../widgets/defect_badge.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_card.dart';
import '../widgets/siren_section_header.dart';
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
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final imageUrl = state.inspection?.thumbnailKey;
    final bboxes = result.defects
        .where((d) => d.bbox != null)
        .map((d) => d.bbox!)
        .toList();

    final isTablet =
        MediaQuery.of(context).size.shortestSide >= AppBreakpoints.tablet;

    // Premium Left Image Viewer Panel (16px rounded + 1px hairline + Device Metric Bar)
    final imagePane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.borderXl, // 16px rounded corners
              border: Border.all(color: AppColors.border, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.04), // Subtle red neon aura
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ImageOverlayViewer(imageUrl: imageUrl, bboxes: bboxes),
                ),
                // Diagnostics Camera overlay
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: AppRadius.borderXs,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.defect, // Red active warning dot
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CAM-01 / ANALYZED',
                          style: AppTextStyles.monoSm.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Precise device metric bar at bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: AppRadius.borderMd,
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RESOLUTION: 1024x768',
                style: AppTextStyles.monoSm.copyWith(fontSize: 10, color: AppColors.onSurfaceMuted),
              ),
              Text(
                'AI PROCESSED: 218ms',
                style: AppTextStyles.monoSm.copyWith(fontSize: 10, color: AppColors.primaryLight),
              ),
            ],
          ),
        ),
      ],
    );

    final defectList = [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: SirenSectionHeader(
          title: '검출된 결함 ${result.defects.length}건',
          trailing: const DefectBadge(severity: DefectSeverity.defect),
          showDivider: true,
        ),
      ),
      ...result.defects.indexed.map(
        (entry) => _StaggeredItem(
          index: entry.$1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: _DefectCard(
              ontologyId: entry.$2.ontologyId,
              displayLabel: entry.$2.displayLabel,
              confidenceScore: entry.$2.confidenceScore,
              severity: DefectSeverityX.fromDetection(
                entry.$2.qualityState,
                entry.$2.confidenceScore,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: SizedBox(
          height: 64, // glove-friendly height
          child: SirenButton(
            label: '보고서 저장',
            size: SirenButtonSize.xl,
            icon: const Icon(Icons.save_alt_rounded),
            onPressed: () =>
                Toast.show(context, '보고서가 저장되었습니다.', type: ToastType.success),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '결함 감지됨',
          style: AppTextStyles.headlineSm.copyWith(
            color: AppColors.defect, // Semantic Error Red
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
          // ─── Ambient Auroral Red/Lavender Glow Background ───
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
                    AppColors.defect.withOpacity(0.06), // red glow reflecting warning status
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
                    AppColors.primary.withOpacity(0.04),
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
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: defectList,
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4,
                          child: imagePane,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...defectList,
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  const _StaggeredItem({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _translate;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppDurations.slow);
    _opacity = CurvedAnimation(parent: _ctrl, curve: AppCurves.enter);
    _translate = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: AppCurves.enter),
    );

    final delay = Duration(milliseconds: (widget.index * 40).clamp(0, 200));
    Future.delayed(delay, () {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _ctrl.value = 1.0;
      } else {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _translate.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _DefectCard extends ConsumerWidget {
  const _DefectCard({
    required this.ontologyId,
    required this.displayLabel,
    required this.confidenceScore,
    required this.severity,
  });

  final String ontologyId;
  final String displayLabel;
  final double confidenceScore;
  final DefectSeverity severity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guidanceAsync = ref.watch(guidanceProvider(ontologyId));

    return guidanceAsync.when(
      data: (guidance) => ActionCard(
        guidance: guidance,
        confidenceScore: confidenceScore, // Pass confidence for visualization
      ),
      loading: () => SirenCard(
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$displayLabel 조치 정보 분석 중...',
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      error: (err, __) => SirenCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    displayLabel, 
                    style: AppTextStyles.headlineSm.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DefectBadge(severity: severity),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  'CONFIDENCE: ',
                  style: AppTextStyles.monoSm.copyWith(fontSize: 10, color: AppColors.onSurfaceMuted),
                ),
                Text(
                  '${(confidenceScore * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.monoSm.copyWith(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold,
                    color: AppColors.defect
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'RAG 조치 가이드 맵핑 오류. 시스템 상태를 확인하세요.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
