import 'package:flutter/material.dart';

import '../core/tokens.dart';
import 'siren_button.dart';

class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = '확인',
    this.cancelLabel = '취소',
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = '확인',
    String cancelLabel = '취소',
    bool destructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.borderXl),
      title: Text(title, style: AppTextStyles.titleSm),
      content: Text(message, style: AppTextStyles.bodyMd),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      actions: [
        SirenButton(
          label: cancelLabel,
          variant: SirenButtonVariant.ghost,
          size: SirenButtonSize.md,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        const SizedBox(width: AppSpacing.sm),
        SirenButton(
          label: confirmLabel,
          variant: destructive
              ? SirenButtonVariant.destructive
              : SirenButtonVariant.primary,
          size: SirenButtonSize.md,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
