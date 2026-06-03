import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';
import '../models/inspection_detail.dart';
import '../models/inspection_status.dart';
import '../providers/history_provider.dart';
import '../widgets/action_card.dart';
import '../widgets/domain_chip.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/inspection_status_chip.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_card.dart';
import '../widgets/siren_section_header.dart';
import '../widgets/toast.dart';

class HistoryDetailScreen extends ConsumerStatefulWidget {
  const HistoryDetailScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  ConsumerState<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends ConsumerState<HistoryDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _showGradCam = false;
  late final AnimationController _dialogAnimCtrl;

  @override
  void initState() {
    super.initState();
    _dialogAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _dialogAnimCtrl.dispose();
    super.dispose();
  }

  void _toggleGradCam() {
    HapticFeedback.lightImpact();
    setState(() {
      _showGradCam = !_showGradCam;
    });
  }

  Future<void> _handleSendReport() async {
    HapticFeedback.lightImpact();

    // Custom dialog transition using Offset(0, 0.04) slide-fade
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

    // Asymmetric delay timing (220ms) to simulate background RAG orchestration
    await Future.delayed(const Duration(milliseconds: 220));

    if (!mounted) return;
    
    // Fire reactive background provider state update
    ref.read(historyProvider.notifier).reportInspection(widget.inspectionId);
    ref.invalidate(historyDetailProvider(widget.inspectionId));
    
    Toast.show(context, '보고서가 성공적으로 발송되었습니다.', type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(historyDetailProvider(widget.inspectionId));
    final isTablet =
        MediaQuery.of(context).size.shortestSide >= AppBreakpoints.tablet;

    return detailAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('검사 상세 리포트'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('검사 상세 리포트'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.defect),
              const SizedBox(height: 16),
              Text(
                '상세 정보를 불러오지 못했습니다.',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurfaceMuted),
              ),
              const SizedBox(height: 16),
              SirenButton(
                label: '다시 시도',
                onPressed: () => ref.refresh(historyDetailProvider(widget.inspectionId)),
              ),
            ],
          ),
        ),
      ),
      data: (InspectionDetail inspection) {
        final list = ref.watch(historyProvider);
        final match = list.where((x) => x.id == widget.inspectionId);
        final isReported = match.isNotEmpty ? match.first.reportFlagged : false;

        final dateStr = DateFormat('yyyy.MM.dd HH:mm').format(inspection.createdAt.toLocal());
        final domain = AnnotationDomainX.fromString(inspection.annotationDomain);
        final status = InspectionStatusX.fromString(inspection.status ?? 'unknown');

        // Premium 16px rounded original/heat overlay viewer with custom HUD
        final imageViewer = Container(
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
                  imageUrl: inspection.imageUrl,
                  gradcamUrl: inspection.overlayImageUrl,
                  showGradCam: _showGradCam,
                ),
              ),
              
              // Eye heatmap toggle HUD with 150ms response
              if (inspection.overlayImageUrl != null && inspection.overlayImageUrl!.isNotEmpty)
                Positioned(
                  top: AppSpacing.sm,
                  right: AppSpacing.sm,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: AppRadius.borderXs,
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleGradCam,
                        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xs)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showGradCam ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                size: 13,
                                color: _showGradCam ? AppColors.defect : AppColors.primaryLight,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'GRAD-CAM: ${_showGradCam ? 'ON' : 'OFF'}',
                                style: AppTextStyles.monoSm.copyWith(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
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

        // SaaS Observability Metadata Grid Panel (Bento Grid)
        final bentoMetadataGrid = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SirenSectionHeader(
              title: 'SYSTEM METADATA',
              showDivider: true,
            ),
            const SizedBox(height: AppSpacing.sm),
            
            // Grid Layout of Info blocks
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              children: [
                _buildBentoCell('검사 영역 도메인', Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DomainChip(domain: domain),
                  ],
                )),
                _buildBentoCell('시스템 판정 결과', Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InspectionStatusChip(status: status),
                  ],
                )),
                _buildBentoCell('검사 고유 ID', Text(
                  inspection.inspectionId,
                  style: AppTextStyles.monoSm.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                )),
                _buildBentoCell('진단 계측 일시', Text(
                  dateStr,
                  style: AppTextStyles.monoSm.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
            
            const SizedBox(height: AppSpacing.lg),
            
            // Inspection Summary Info List
            SirenCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '결과 리포트 요약',
                        style: AppTextStyles.sectionHeader.copyWith(fontSize: 11.5, color: AppColors.onSurfaceMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isReported
                        ? '본 검사 대상(용접선/표면)에서 허용치 이상의 앵커 결함이 식별되었습니다. RAG 조치 시놉시스에 기초하여 현장 즉각 조치를 권고합니다.'
                        : '본 검사 대상의 정밀 스캐닝 결과 완벽한 기밀성이 유지되고 있으며 결함이 검출되지 않았습니다.',
                    style: AppTextStyles.bodyMd.copyWith(
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            if (inspection.qualityState == 'defect' && inspection.guidance != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ActionCard(
                guidance: inspection.guidance!.toGuidanceResponse(
                  ontologyId: inspection.ontologyId ?? '',
                  displayLabel: inspection.canonicalClassName ?? '미분류 결함',
                  qualityState: inspection.qualityState ?? 'defect',
                ),
                confidenceScore: inspection.confidenceScore,
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Action Report send button (64dp, SirenButtonSize.xl)
            SizedBox(
              height: 64, // glove touch optimization size
              child: SirenButton(
                label: isReported ? '보고 완료 ✓' : '보고서 발송',
                size: SirenButtonSize.xl,
                variant: isReported ? SirenButtonVariant.secondary : SirenButtonVariant.primary,
                icon: Icon(
                  isReported ? Icons.check_circle_rounded : Icons.send_rounded,
                  size: 22,
                ),
                onPressed: isReported ? null : _handleSendReport,
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
              '검사 상세 리포트',
              style: AppTextStyles.headlineSm.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
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
                                child: imageViewer,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              flex: 4,
                              child: ListView(
                                physics: const BouncingScrollPhysics(),
                                children: [bentoMetadataGrid],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4,
                              child: imageViewer,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            bentoMetadataGrid,
                          ],
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBentoCell(String label, Widget content) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTextStyles.sectionHeader.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(child: content),
        ],
      ),
    );
  }
}
