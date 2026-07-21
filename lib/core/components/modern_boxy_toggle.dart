import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ModernBoxyToggle extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const ModernBoxyToggle({
    Key? key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Using the same boxy radius established in the Slidable cards
    final boxyRadius = BorderRadius.circular(DesignTokens.spacingXs);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: boxyRadius,
        // Added the architectural border to match Bento cards
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5), width: 1.2),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tabWidth = constraints.maxWidth / labels.length;

          return Stack(
            children: [
              // The Animated Active Box Background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                left: tabWidth * selectedIndex,
                width: tabWidth,
                child: Container(
                  margin: const EdgeInsets.all(3), // Inner padding
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer, // Contrast color
                    borderRadius: BorderRadius.circular(DesignTokens.spacingXs - 1),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.4), width: 1.2),
                    // Hard shadow for a brutalist, tactile feel
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 0, 
                        offset: const Offset(2, 2), 
                      ),
                    ],
                  ),
                ),
              ),
              // The Text Labels
              Row(
                children: List.generate(labels.length, (index) {
                  final isSelected = selectedIndex == index;
                  
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelected(index),
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            color: isSelected 
                                ? colorScheme.onPrimaryContainer 
                                : colorScheme.onSurfaceVariant,
                          ),
                          child: Text(labels[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        }
      ),
    );
  }
}