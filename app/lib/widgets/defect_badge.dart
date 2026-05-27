import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../models/defect_severity.dart';

enum DefectBadgeSize { sm, md }

class DefectBadge extends StatelessWidget {
  const DefectBadge({
    super.key,
    required this.severity,
    this.size = DefectBadgeSize.md,
    this.onTap,
  });

  final DefectSeverity severity;
  final DefectBadgeSize size;
  final VoidCallback? onTap;

  EdgeInsets get _padding => switch (size) {
        DefectBadgeSize.sm =>
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
        DefectBadgeSize.md => const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      };

  TextStyle get _textStyle => switch (size) {
        DefectBadgeSize.sm => AppTextStyles.labelSm,
        DefectBadgeSize.md => AppTextStyles.labelMd,
      };

  @override
  Widget build(BuildContext context) {
    final badge = Semantics(
      label: '결함 상태: ${severity.label}',
      child: Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: severity.containerColor,
          borderRadius: AppRadius.borderXs,
          border: Border.all(color: severity.color, width: 1),
        ),
        child: Text(
          severity.label,
          style: _textStyle.copyWith(
            color: severity.color,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );

    if (onTap == null) return badge;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Align(alignment: Alignment.center, child: badge),
        ),
      ),
    );
  }
}
