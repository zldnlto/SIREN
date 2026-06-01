import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';

class DomainChip extends StatelessWidget {
  const DomainChip({
    super.key,
    required this.domain,
    this.isSelected = false,
    this.onTap,
  });

  final AnnotationDomain domain;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Semantics(
      label: '도메인: ${domain.label}',
      selected: isSelected,
      button: onTap != null,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary // IBM Blue for selected
              : AppColors.surface, // Charcoal surface for unselected
          borderRadius: BorderRadius.zero, // IBM Carbon 0px sharp corners
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: 1, // 1px hairline
          ),
        ),
        child: Text(
          domain.label,
          style: AppTextStyles.labelMd.copyWith(
            color: isSelected
                ? AppColors.onPrimary // White text for selected
                : AppColors.onSurfaceVariant, // Muted text for unselected
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );

    if (onTap == null) return chip;

    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Align(alignment: Alignment.center, child: chip),
        ),
      ),
    );
  }
}
