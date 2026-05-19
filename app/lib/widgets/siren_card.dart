import 'package:flutter/material.dart';

import '../core/tokens.dart';

class SirenCard extends StatefulWidget {
  const SirenCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  State<SirenCard> createState() => _SirenCardState();
}

class _SirenCardState extends State<SirenCard> {
  bool _pressed = false;

  bool get _tappable => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: AppDurations.fast,
      curve: AppCurves.enter,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        padding: widget.padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: AppRadius.borderXl,
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.md,
        ),
        child: widget.child,
      ),
    );

    if (!_tappable) return card;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: card,
        ),
      ),
    );
  }
}
