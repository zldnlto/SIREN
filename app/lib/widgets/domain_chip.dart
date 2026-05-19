import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';

class DomainChip extends StatelessWidget {
  const DomainChip({
    super.key,
    required this.domain,
    this.onTap,
  });

  final AnnotationDomain domain;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Semantics(
      label: '도메인: ${domain.label}',
      button: onTap != null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceTertiary,
          borderRadius: AppRadius.borderFull,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(
          domain.label,
          style: AppTextStyles.labelMd.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );

    if (onTap == null) return chip;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(cursor: SystemMouseCursors.click, child: chip),
    );
  }
}
