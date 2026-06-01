import 'package:flutter/material.dart';

import '../core/tokens.dart';

class SirenCard extends StatelessWidget {
  const SirenCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  bool get _tappable => onTap != null;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: AppDurations.fast,
      curve: AppCurves.standard,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface, // Inverse Surface 1
        borderRadius: BorderRadius.zero, // IBM Carbon 0px sharp corners
        border: Border.all(color: AppColors.border, width: 1), // 1px hairline Gray-80
      ),
      child: child,
    );

    if (!_tappable) return card;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: card,
        ),
      ),
    );
  }
}
