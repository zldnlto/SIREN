import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../models/defect_severity.dart';
import '../models/guidance_response.dart';
import 'defect_badge.dart';
import 'siren_card.dart';
import 'siren_section_header.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key, 
    required this.guidance,
    this.confidenceScore,
  });

  final GuidanceResponse guidance;
  final double? confidenceScore;

  @override
  Widget build(BuildContext context) {
    final severity = DefectSeverityX.fromQualityState(guidance.qualityState);
    
    // Choose theme colors based on severity
    final accentColor = severity == DefectSeverity.defect 
        ? AppColors.defect 
        : (severity == DefectSeverity.warning ? AppColors.warning : AppColors.primary);

    return SirenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Title & Severity Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  guidance.displayLabel,
                  style: AppTextStyles.headlineSm.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DefectBadge(severity: severity),
            ],
          ),
          
          // 2. Confidence Metric and Visual Gauge Bar
          if (confidenceScore != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.query_stats_rounded, size: 13, color: AppColors.onSurfaceMuted),
                    const SizedBox(width: 4),
                    Text(
                      'AI 분석 신뢰도',
                      style: AppTextStyles.labelSm.copyWith(color: AppColors.onSurfaceMuted),
                    ),
                  ],
                ),
                Text(
                  '${(confidenceScore! * 100).toStringAsFixed(1)}%',
                  style: AppTextStyles.monoSm.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Custom precise gauge bar
            ClipRRect(
              borderRadius: AppRadius.borderFull,
              child: SizedBox(
                height: 4,
                child: LinearProgressIndicator(
                  value: confidenceScore,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1.0),
          const SizedBox(height: AppSpacing.md),

          // 3. Cause Section
          _buildDetailSection('발생 원인', guidance.cause, Icons.info_outline_rounded),
          const SizedBox(height: AppSpacing.md),

          // 4. Action Steps Section
          const SirenSectionHeader(title: '조치 권고 사항'),
          const SizedBox(height: AppSpacing.xs),
          ...guidance.actionSteps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Circular Index Badge for professional look
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${e.key + 1}',
                          style: AppTextStyles.monoSm.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          e.value, 
                          style: AppTextStyles.bodyMd.copyWith(
                            fontSize: 14.5,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          const Divider(color: AppColors.border, height: 1.0),
          const SizedBox(height: AppSpacing.md),

          // 5. Reinspection Criteria Section
          _buildDetailSection(
            '재검사 합격 기준', 
            guidance.reinspectionCriteria, 
            Icons.fact_check_outlined,
            isSubtleBody: true,
          ),
          const SizedBox(height: AppSpacing.md),

          // 6. Footer Disclaimer & Referenced docs
          Text(
            guidance.disclaimer,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (guidance.referencedDoc != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: AppRadius.borderXs,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.menu_book_rounded, size: 13, color: AppColors.onSurfaceMuted),
                  const SizedBox(width: 6),
                  Text(
                    '참조 문서: ${guidance.referencedDoc}',
                    style: AppTextStyles.monoSm.copyWith(
                      fontSize: 10.5,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon, {bool isSubtleBody = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              title,
              style: AppTextStyles.sectionHeader.copyWith(fontSize: 11.5, color: AppColors.onSurfaceMuted),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          content, 
          style: (isSubtleBody ? AppTextStyles.bodySm : AppTextStyles.bodyMd).copyWith(
            fontSize: isSubtleBody ? 13.5 : 14.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
