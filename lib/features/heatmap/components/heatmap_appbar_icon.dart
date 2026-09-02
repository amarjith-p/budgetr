// lib/features/heatmap/components/heatmap_appbar_icon.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/date_time_constants.dart';
import '../views/heatmap_page.dart';

class HeatmapAppbarIcon extends StatelessWidget {
  const HeatmapAppbarIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HeatmapPage()),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 40,
        decoration: BoxDecoration(
          // --- WHITE BACKGROUND FOR DATE ---
          color: isDark ? const Color(0xFFE2E8F0) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          // --- FIX: Removed Border.all to allow the red header to sit perfectly flush with the edges ---
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- RED BACKGROUND FOR MONTH ---
            Container(
              color: const Color(0xFFE71D36), // A premium, vibrant red
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                DateTimeConstants.shortMonths[now.month - 1].toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  height: 1.0,
                ),
              ),
            ),
            // --- DATE TEXT ---
            Expanded(
              child: Center(
                child: Text(
                  '${now.day}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A), // Slate 900 for crisp contrast
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
