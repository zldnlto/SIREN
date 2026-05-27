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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final imageUrl = state.inspection?.thumbnailKey;
    final bboxes = result.defects
        .where((d) => d.bbox != null)
        .map((d) => d.bbox!)
        .toList();

    final isTablet =
        MediaQuery.of(context).size.shortestSide >= AppBreakpoints.tablet;

    final imagePane = AspectRatio(
      aspectRatio: 4 / 3,
      child: ImageOverlayViewer(imageUrl: imageUrl, bboxes: bboxes),
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
        child: SirenButton(
          label: '보고서 저장',
          icon: const Icon(Icons.save_alt_rounded),
          onPressed: () =>
              Toast.show(context, '보고서가 저장되었습니다.', type: ToastType.success),
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('결함 감지됨', style: AppTextStyles.titleMd),
        leading: IconButton(
          icon: const Icon(Icons.home_rounded, color: AppColors.onSurface),
          onPressed: () {
            ref.read(inspectionProvider.notifier).reset();
            context.go('/home');
          },
        ),
      ),
      body: SafeArea(
        child: isTablet
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: imagePane),
                  Expanded(
                    flex: 4,
                    child: ListView(children: defectList),
                  ),
                ],
              )
            : ListView(children: [imagePane, ...defectList]),
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
      data: (guidance) => ActionCard(guidance: guidance),
      loading: () => SirenCard(
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '$displayLabel 조치 정보 로딩 중...',
              style: AppTextStyles.bodyMd,
            ),
          ],
        ),
      ),
      error: (_, __) => SirenCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(displayLabel, style: AppTextStyles.titleSm),
                ),
                const SizedBox(width: AppSpacing.sm),
                DefectBadge(severity: severity),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '신뢰도 ${(confidenceScore * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.monoSm,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '조치 정보를 불러올 수 없습니다.',
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
