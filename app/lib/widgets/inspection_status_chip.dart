import 'package:flutter/material.dart';

import '../core/tokens.dart';
import '../models/inspection_status.dart';

class InspectionStatusChip extends StatelessWidget {
  const InspectionStatusChip({
    super.key,
    required this.status,
  });

  final InspectionStatus status;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '검사 상태: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: status.color.withAlpha(26),
          borderRadius: AppRadius.borderFull,
          border: Border.all(color: status.color.withAlpha(77), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _indicator(),
            const SizedBox(width: AppSpacing.xs),
            Text(
              status.label,
              style: AppTextStyles.labelMd.copyWith(color: status.color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _indicator() {
    if (status.isInProgress) {
      return SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          color: status.color,
        ),
      );
    }
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
      ),
    );
  }
}
