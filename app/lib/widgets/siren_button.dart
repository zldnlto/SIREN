import 'package:flutter/material.dart';

import '../core/tokens.dart';

enum SirenButtonVariant { primary, secondary, ghost }

enum SirenButtonSize { md, lg }

class SirenButton extends StatefulWidget {
  const SirenButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SirenButtonVariant.primary,
    this.size = SirenButtonSize.lg,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SirenButtonVariant variant;
  final SirenButtonSize size;
  final Widget? icon;
  final bool isLoading;

  @override
  State<SirenButton> createState() => _SirenButtonState();
}

class _SirenButtonState extends State<SirenButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  double get _height => switch (widget.size) {
        SirenButtonSize.md => 48,
        SirenButtonSize.lg => 56,
      };

  EdgeInsets get _padding => switch (widget.size) {
        SirenButtonSize.md =>
          const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        SirenButtonSize.lg =>
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      };

  TextStyle get _labelStyle => switch (widget.size) {
        SirenButtonSize.md => AppTextStyles.buttonMd,
        SirenButtonSize.lg => AppTextStyles.buttonLg,
      };

  Color get _backgroundColor => switch (widget.variant) {
        SirenButtonVariant.primary =>
          _enabled ? AppColors.primary : AppColors.disabled,
        SirenButtonVariant.secondary => Colors.transparent,
        SirenButtonVariant.ghost => Colors.transparent,
      };

  Color get _foregroundColor => switch (widget.variant) {
        SirenButtonVariant.primary =>
          _enabled ? AppColors.onPrimary : AppColors.onDisabled,
        SirenButtonVariant.secondary =>
          _enabled ? AppColors.primary : AppColors.onDisabled,
        SirenButtonVariant.ghost =>
          _enabled ? AppColors.onSurface : AppColors.onDisabled,
      };

  Border? get _border => switch (widget.variant) {
        SirenButtonVariant.secondary => Border.all(
            color: _enabled ? AppColors.primary : AppColors.disabled,
            width: 1.5,
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: _enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: AppDurations.fast,
          curve: AppCurves.enter,
          child: AnimatedContainer(
            duration: AppDurations.fast,
            curve: AppCurves.standard,
            height: _height,
            padding: _padding,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: AppRadius.borderSm,
              border: _border,
              boxShadow:
                  (!_enabled || widget.variant != SirenButtonVariant.primary)
                      ? null
                      : (_pressed ? null : AppShadows.primaryGlow),
            ),
            child: widget.isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _foregroundColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        IconTheme(
                          data:
                              IconThemeData(color: _foregroundColor, size: 20),
                          child: widget.icon!,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        widget.label,
                        style: _labelStyle.copyWith(color: _foregroundColor),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
