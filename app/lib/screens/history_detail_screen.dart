import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';
import '../models/inspection_status.dart';
import '../providers/history_provider.dart';
import '../widgets/domain_chip.dart';
import '../widgets/image_overlay_viewer.dart';
import '../widgets/inspection_status_chip.dart';
import '../widgets/siren_card.dart';
import '../widgets/siren_section_header.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectionAsync = ref.watch(inspectionDetailProvider(inspectionId));
    final isTablet =
        MediaQuery.of(context).size.shortestSide >= AppBreakpoints.tablet;

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
          // ─── Ambient Auroral Glow Background ───
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
                    AppColors.primary.withOpacity(0.04),
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
                    AppColors.primary.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ─── Main Scaffold Body ───
          SafeArea(
            child: inspectionAsync.when(
              data: (inspection) {
                final dateStr = DateFormat('yyyy.MM.dd HH:mm')
                    .format(inspection.createdAt.toLocal());
                final domain =
                    AnnotationDomainX.fromString(inspection.annotationDomain);
                final status =
                    InspectionStatusX.fromString(inspection.status ?? 'unknown');

                // 16px rounded + 1px hairline screenshot viewer
                final imageViewer = Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.borderXl,
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ImageOverlayViewer(imageUrl: inspection.thumbnailKey),
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
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return GridView.count(
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
                              inspection.id,
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
                        );
                      },
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
                            inspection.reportFlagged
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
                  ],
                );

                return Padding(
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
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: AppColors.critical,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        '이력 상세 정보를 불러올 수 없습니다.',
                        style: AppTextStyles.headlineSm.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        e.toString(),
                        style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
