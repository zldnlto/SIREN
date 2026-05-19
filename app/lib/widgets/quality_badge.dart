import 'package:flutter/material.dart';

import '../core/theme.dart';

class QualityBadge extends StatelessWidget {
  const QualityBadge({super.key, required this.qualityState});

  final String qualityState; // "defect" | "good"

  @override
  Widget build(BuildContext context) {
    final isDefect = qualityState == 'defect';
    final color = isDefect ? kDefectColor : kGoodColor;
    final label = isDefect ? '결함' : '양호';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
