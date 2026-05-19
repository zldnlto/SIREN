import 'package:flutter/material.dart';

import '../models/guidance_response.dart';
import 'quality_badge.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({super.key, required this.guidance});

  final GuidanceResponse guidance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    guidance.displayLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                QualityBadge(qualityState: guidance.qualityState),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '원인',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(guidance.cause, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(
              '조치 사항',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            ...guidance.actionSteps.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.key + 1}. ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child:
                              Text(e.value, style: theme.textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            Text(
              '재검사 기준',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(guidance.reinspectionCriteria,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Text(
              guidance.disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (guidance.referencedDoc != null) ...[
              const SizedBox(height: 4),
              Text(
                '참조: ${guidance.referencedDoc}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
