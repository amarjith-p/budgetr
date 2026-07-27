import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class BudgetProgressCard extends StatelessWidget {
  final String bucketName;
  final double percentage;
  final double spent;
  final double allocated;
  final VoidCallback onTap;

  const BudgetProgressCard({
    Key? key,
    required this.bucketName,
    required this.percentage,
    required this.spent,
    required this.allocated,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final left = allocated - spent;
    final progress = allocated == 0 ? 0.0 : (spent / allocated);

    // Determine tracking colors
    Color activeColor = theme.colorScheme.primary;
    bool isWarning = false;
    bool isDanger = false;

    if (progress >= 1.0) {
      activeColor = theme.colorScheme.error; 
      isDanger = true;
    } else if (progress >= 0.85) {
      activeColor = Colors.orangeAccent.shade700; 
      isWarning = true;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12), // Tighter vertical list spacing
      child: Material(
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12), // Sleeker radius
          side: BorderSide(
            color: isDanger ? theme.colorScheme.error.withOpacity(0.4) : theme.dividerColor,
            width: 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12), // Reduced from 16 to 12
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- SLEEK SQUARE BADGE ---
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${percentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: activeColor,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // --- INLINE DETAILS & PROGRESS ---
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              bucketName.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800, 
                                fontSize: 11, 
                                letterSpacing: 0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '₹${spent.toStringAsFixed(0)} / ₹${allocated.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.w800, 
                              color: isDanger || isWarning ? activeColor : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Progress Bar
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 6.0, // Ultra-thin bar
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.black.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(3.0),
                            ),
                            child: Stack(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                                  height: 6.0,
                                  decoration: BoxDecoration(
                                    color: activeColor,
                                    borderRadius: BorderRadius.circular(3.0),
                                    boxShadow: isDanger ? [
                                      BoxShadow(color: activeColor.withOpacity(0.4), blurRadius: 4, offset: const Offset(0, 1))
                                    ] : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Footer Row (Remaining / Warnings)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            left >= 0 ? '₹${left.toStringAsFixed(0)} Left' : '₹${left.abs().toStringAsFixed(0)} Over', 
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.w800, 
                              color: left >= 0 ? theme.colorScheme.onSurfaceVariant : theme.colorScheme.error,
                            ),
                          ),
                          if (isDanger || isWarning)
                            Row(
                              children: [
                                Icon(Icons.warning_rounded, size: 10, color: activeColor),
                                const SizedBox(width: 4),
                                Text(
                                  isDanger ? 'OVER BUDGET' : 'NEAR LIMIT',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: activeColor),
                                )
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}