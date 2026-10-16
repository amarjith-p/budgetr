// lib/features/budgets/components/projection_mode_badge.dart
import 'package:flutter/material.dart';
import '../models/smart_projection_result.dart';
import '../providers/projection_settings_provider.dart';

class ProjectionModeBadge extends StatelessWidget {
  final ProjectionMode mode;
  final SmartProjectionResult? smartResult;
  final ThemeData theme;
  final bool isDark;
  final int unclassifiedCount;
  final VoidCallback? onReclassify;

  const ProjectionModeBadge({
    Key? key,
    required this.mode,
    required this.smartResult,
    required this.theme,
    required this.isDark,
    this.unclassifiedCount = 0,
    this.onReclassify,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLinear = mode == ProjectionMode.linear;
    final hasUnclassified = unclassifiedCount > 0 && !isLinear;

    final baseColor = isLinear
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    final color = hasUnclassified ? const Color(0xFFF5A623) : baseColor;

    return GestureDetector(
      onTap: hasUnclassified ? onReclassify : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.1 : 0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isLinear
                      ? Icons.show_chart_rounded
                      : (hasUnclassified
                            ? Icons.warning_amber_rounded
                            : Icons.psychology_rounded),
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLinear
                        ? 'Linear Projection - Simple Daily Average'
                        : (hasUnclassified
                              ? '$unclassifiedCount Auto-Classified, Needs Review'
                              : 'Smart Projection - Variable Only Extrapolated'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
                if (!isLinear && onReclassify != null && !hasUnclassified)
                  GestureDetector(
                    onTap: onReclassify,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'RE-CLASSIFY',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (hasUnclassified) ...[
              const SizedBox(height: 6),
              Text(
                'Classify first to see accurate insights',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
