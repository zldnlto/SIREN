import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../models/defect_severity.dart';
import '../models/guidance_response.dart';
import 'defect_badge.dart';
import 'siren_card.dart';
import 'siren_section_header.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.guidance});

  final GuidanceResponse guidance;

  @override
  Widget build(BuildContext context) {
    final severity = DefectSeverityX.fromQualityState(guidance.qualityState);

    return SirenCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  guidance.displayLabel,
                  style: AppTextStyles.titleSm,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              DefectBadge(severity: severity),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _Section(title: '원인', body: guidance.cause),
          const SizedBox(height: AppSpacing.md),
          const SirenSectionHeader(title: '조치 사항'),
          const SizedBox(height: AppSpacing.xs),
          ...guidance.actionSteps.asMap().entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}. ',
                        style: AppTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: Text(e.value, style: AppTextStyles.bodyMd),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: '재검사 기준',
            body: guidance.reinspectionCriteria,
            bodyStyle: AppTextStyles.bodySm,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            guidance.disclaimer,
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (guidance.referencedDoc != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '참조: ${guidance.referencedDoc}',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    this.bodyStyle,
  });

  final String title;
  final String body;
  final TextStyle? bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SirenSectionHeader(title: title),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: bodyStyle ?? AppTextStyles.bodyMd),
      ],
    );
  }
}
