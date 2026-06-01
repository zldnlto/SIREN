import 'package:flutter/material.dart';

import '../core/tokens.dart';

class SirenSectionHeader extends StatelessWidget {
  const SirenSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.showDivider = false,
  });

  final String title;
  final Widget? trailing;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title, // Carbon sentence case
                style: AppTextStyles.sectionHeader,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: AppSpacing.sm),
          const Divider(
            color: AppColors.border,
            height: 1,
            thickness: 1,
          ),
        ],
      ],
    );
  }
}
