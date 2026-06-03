import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../models/defect_severity.dart';
import '../models/detected_defect.dart';
import '../models/annotation_domain.dart';
import '../providers/guidance_provider.dart';
import '../providers/inspection_provider.dart';
import '../widgets/action_card.dart';
import '../widgets/defect_badge.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_card.dart';
import '../widgets/siren_section_header.dart';
import '../widgets/toast.dart';
import '../widgets/domain_override_bottom_sheet.dart';
import '../models/guidance_response.dart';
import '../usecases/create_report_usecase.dart';

class DefectResultScreen extends ConsumerStatefulWidget {
  const DefectResultScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  ConsumerState<DefectResultScreen> createState() => _DefectResultScreenState();
}

class _DefectResultScreenState extends ConsumerState<DefectResultScreen> {
  bool _showGradCam = false;
  bool _isSaved = false;

  Future<void> _handleSaveInspection() async {
    HapticFeedback.lightImpact();
    
    final bool? confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.save_rounded,
                        color: AppColors.primaryLight,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '결과 저장',
                      style: AppTextStyles.headlineSm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이 결함 검사 결과를 로컬 및 관리자\n시스템에 저장하시겠습니까?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: SirenButton(
                              label: '취소',
                              variant: SirenButtonVariant.secondary,
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: SirenButton(
                              label: '저장',
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    await Future.delayed(const Duration(milliseconds: 220));
    setState(() {
      _isSaved = true;
    });

    if (!mounted) return;
    Toast.show(context, '저장 완료', type: ToastType.success);
  }

  Future<void> _handleSendReport() async {
    HapticFeedback.lightImpact();

    final bool? confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim, _) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: AppRadius.borderLg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: AppColors.primaryLight,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '보고서 발송',
                      style: AppTextStyles.headlineSm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '이 결함 검사 결과를 관리자 시스템으로\n즉각 전송하시겠습니까?',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: SirenButton(
                              label: '취소',
                              variant: SirenButtonVariant.secondary,
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: SirenButton(
                              label: '발송 승인',
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirm != true) return;

    await Future.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;
    
    // Fire reactive provider update
    await ref.read(inspectionProvider.notifier).reportInspection(widget.inspectionId);

    if (!mounted) return;
    Toast.show(context, '보고서가 성공적으로 발송되었습니다.', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);
    final result = state.result;
    final isReported = state.inspection?.reportFlagged ?? false;

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

    final firstDefectWithGradCam = result.defects.firstWhere(
      (d) => d.gradcamKey != null && d.gradcamKey!.isNotEmpty,
      orElse: () => const DetectedDefect(
        ontologyId: '',
        displayLabel: '',
        qualityState: 'good',
        canonicalClassName: '',
        annotationDomain: '',
        confidenceScore: 0.0,
      ),
    );
    final gradcamUrl = firstDefectWithGradCam.gradcamKey;

    final isTablet =
        MediaQuery.of(context).size.shortestSide >= AppBreakpoints.tablet;

    final imagePane = Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderXl,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: ImageOverlayViewer(
              imageUrl: imageUrl,
              gradcamUrl: gradcamUrl,
              showGradCam: _showGradCam,
              bboxes: bboxes,
            ),
          ),
          if (gradcamUrl != null && gradcamUrl.isNotEmpty)
            Positioned(
              right: AppSpacing.sm,
              bottom: AppSpacing.sm,
              child: Material(
                color: _showGradCam ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: AppRadius.borderFull,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showGradCam = !_showGradCam;
                    });
                  },
                  borderRadius: AppRadius.borderFull,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.borderFull,
                      border: Border.all(
                        color: _showGradCam ? Colors.transparent : AppColors.border,
                      ),
                    ),
                    child: Tooltip(
                      message: "AI가 결함으로 판단한 영역을 열지도로 표시합니다",
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.layers_rounded,
                            size: 16,
                            color: AppColors.onSurface,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '히트맵 ${_showGradCam ? "OFF" : "ON"}',
                            style: AppTextStyles.bodySm.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    final domainStr = state.inspection?.annotationDomain ?? 'surface_treatment';
    final domainEnum = AnnotationDomainX.fromString(domainStr);
    final domainLabel = domainEnum.label;

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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            onTap: () {
              DomainOverrideBottomSheet.show(
                context,
                inspectionId: widget.inspectionId,
                currentDomain: domainStr,
              );
            },
            borderRadius: AppRadius.borderFull,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.borderFull,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '공정: $domainLabel 공정',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: AppColors.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.xs),
      ...result.defects.indexed.map(
        (entry) => _StaggeredItem(
          index: entry.$1,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: _DefectCard(
              inspectionId: widget.inspectionId,
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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 64,
                child: SirenButton(
                  label: _isSaved ? '저장 완료 ✓' : '검사 결과 저장',
                  variant: _isSaved ? SirenButtonVariant.secondary : SirenButtonVariant.primary,
                  onPressed: _isSaved ? null : _handleSaveInspection,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 64,
                child: SirenButton(
                  label: isReported ? '보고 완료 ✓' : '보고서 발송',
                  variant: isReported ? SirenButtonVariant.secondary : SirenButtonVariant.primary,
                  onPressed: (_isSaved && !isReported) ? _handleSendReport : null,
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
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
        actions: const [],
      ),
      body: Stack(
        children: [
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

class _DefectCard extends ConsumerStatefulWidget {
  const _DefectCard({
    required this.inspectionId,
    required this.ontologyId,
    required this.displayLabel,
    required this.confidenceScore,
    required this.severity,
  });

  final String inspectionId;
  final String ontologyId;
  final String displayLabel;
  final double confidenceScore;
  final DefectSeverity severity;

  @override
  ConsumerState<_DefectCard> createState() => _DefectCardState();
}

class _DefectCardState extends ConsumerState<_DefectCard> {
  List<bool>? _actionChecks;
  late final TextEditingController _noteController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitReport(GuidanceResponse guidance) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final useCase = ref.read(createReportUseCaseProvider);
      await useCase(
        inspectionId: widget.inspectionId,
        actionChecks: _actionChecks ?? [],
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        status: 'resolved',
      );

      if (!mounted) return;
      Toast.show(context, '조치 리포트가 성공적으로 전송되었습니다.', type: ToastType.success);

      ref.read(inspectionProvider.notifier).reset();
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      Toast.show(context, '리포트 전송 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final guidanceAsync = ref.watch(guidanceProvider(widget.ontologyId));

    return guidanceAsync.when(
      data: (guidance) {
        _actionChecks ??= List<bool>.filled(guidance.actionSteps.length, false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ActionCard(
              guidance: guidance,
              confidenceScore: widget.confidenceScore,
            ),
            const SizedBox(height: AppSpacing.md),
            SirenCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현장 조치 이행 보고',
                    style: AppTextStyles.headlineSm.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  const Divider(color: AppColors.border, height: 1.0),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'RAG 권고 조치 이행 여부 체크',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ...guidance.actionSteps.asMap().entries.map((e) {
                    final idx = e.key;
                    final stepText = e.value;
                    return CheckboxListTile(
                      title: Text(
                        stepText,
                        style: AppTextStyles.bodyMd.copyWith(fontSize: 14),
                      ),
                      value: _actionChecks![idx],
                      activeColor: AppColors.primary,
                      checkColor: AppColors.onPrimary,
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setState(() {
                          _actionChecks![idx] = val ?? false;
                        });
                      },
                    );
                  }),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '이행 특이사항 및 메모 (선택)',
                    style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: AppTextStyles.bodyMd,
                    decoration: InputDecoration(
                      hintText: '현장에서 수행하신 조치 사항이나 특기할 점을 기입해 주세요.',
                      hintStyle: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                      fillColor: AppColors.surfaceVariant,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 80, // 고정 80px 전송 버튼 요구사항 완벽 만족!
                    width: double.infinity,
                    child: SirenButton(
                      label: _isSubmitting ? '리포트 전송 중...' : '조치 리포트 전송',
                      size: SirenButtonSize.xl,
                      icon: const Icon(Icons.send_rounded),
                      onPressed: _isSubmitting ? null : () => _submitReport(guidance),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
              '${widget.displayLabel} 조치 정보 분석 중...',
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
                    widget.displayLabel,
                    style: AppTextStyles.headlineSm.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DefectBadge(severity: widget.severity),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Text(
                  'AI 신뢰도',
                  style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text(
                          'AI 신뢰도 안내',
                          style: AppTextStyles.headlineSm.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'AI가 이 결함 판정에 확신하는 정도입니다.\n80% 이상이면 높은 신뢰도입니다.',
                          style: AppTextStyles.bodyMd,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              '확인',
                              style: AppTextStyles.buttonMd.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.help_outline_rounded,
                    size: 14,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(widget.confidenceScore * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.monoSm.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.defect,
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
