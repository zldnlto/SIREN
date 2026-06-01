import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/tokens.dart';

enum SirenButtonVariant { primary, secondary, ghost, destructive }

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
  bool _focused = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  double get _height => switch (widget.size) {
        SirenButtonSize.md => 36,
        SirenButtonSize.lg => 44, // Sentry touch target
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
        SirenButtonVariant.primary => _enabled
            ? (_pressed ? const Color(0xFFE5E7EB) : const Color(0xFFFFFFFF))
            : AppColors.disabled,
        SirenButtonVariant.destructive => _enabled
            ? (_pressed ? const Color(0xFFE74C3C) : AppColors.pink)
            : AppColors.disabled,
        SirenButtonVariant.secondary => _enabled
            ? (_pressed ? const Color(0x3BFFFFFF) : const Color(0x1AFFFFFF))
            : AppColors.disabled,
        SirenButtonVariant.ghost => _enabled
            ? (_pressed ? const Color(0x2EFFFFFF) : Colors.transparent)
            : Colors.transparent,
      };

  Color get _foregroundColor => switch (widget.variant) {
        SirenButtonVariant.primary =>
          _enabled ? AppColors.onPrimary : AppColors.onDisabled,
        SirenButtonVariant.destructive =>
          _enabled ? const Color(0xFFFFFFFF) : AppColors.onDisabled,
        SirenButtonVariant.secondary =>
          _enabled ? const Color(0xFFFFFFFF) : AppColors.onDisabled,
        SirenButtonVariant.ghost =>
          _enabled ? AppColors.onSurfaceVariant : AppColors.onDisabled,
      };

  Border? get _border {
    if (_focused && _enabled) {
      return Border.all(color: AppColors.secondary, width: 2.0); // Focus ring
    }
    return switch (widget.variant) {
      SirenButtonVariant.secondary => Border.all(
          color: _enabled ? AppColors.border : AppColors.disabled,
          width: 1.0,
        ),
      _ => null,
    };
  }

  void _handleKeyEvent(KeyEvent event) {
    if (!_enabled) return;
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onPressed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: (_, event) {
          _handleKeyEvent(event);
          return KeyEventResult.ignored;
        },
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
            scale: _pressed ? 0.97 : 1.0,
            duration: AppDurations.fast,
            curve: AppCurves.enter,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              curve: AppCurves.standard,
              height: _height,
              padding: _padding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: AppRadius.borderMd, // Sentry rounded.md (8px)
                border: _border,
                boxShadow: (!_enabled ||
                        widget.variant != SirenButtonVariant.primary ||
                        _pressed)
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x14000000), // level 1 lift
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
              ),
              child: widget.isLoading
                  ? Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
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
                            data: IconThemeData(
                                color: _foregroundColor, size: 18),
                            child: widget.icon!,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Text(
                          widget.label.toUpperCase(), // Sentry Uppercase caps
                          style: _labelStyle.copyWith(color: _foregroundColor),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
