import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DockedCalculatorPad extends StatelessWidget {
  final void Function(String) onKeyPress;
  final Color backgroundColor;
  final Color actionColor; // <-- NEW: Injected color

  const DockedCalculatorPad({
    Key? key,
    required this.onKeyPress,
    required this.backgroundColor,
    required this.actionColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Column(
        children: [
          Expanded(child: _buildRow(['C', '(', ')', '⌫'], theme)),
          const SizedBox(height: 6),
          Expanded(child: _buildRow(['7', '8', '9', '÷'], theme)),
          const SizedBox(height: 6),
          Expanded(child: _buildRow(['4', '5', '6', '×'], theme)),
          const SizedBox(height: 6),
          Expanded(child: _buildRow(['1', '2', '3', '-'], theme)),
          const SizedBox(height: 6),
          Expanded(child: _buildRow(['.', '0', '=', '+'], theme)),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: keys.map((key) {
        final isAction = ['C', '⌫'].contains(key);
        final isMathAction = ['=', '(', ')'].contains(key);
        final isOperator = ['÷', '×', '-', '+'].contains(key);
        
        Color textColor = theme.colorScheme.onSurface;
        if (isAction) textColor = theme.colorScheme.error;
        if (isOperator || isMathAction) textColor = actionColor; // <-- Uses active color
        
        if (key == '=') {
          textColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
        }

        final bgColor = key == '=' 
            ? actionColor // <-- Uses active color for the equals button
            : (isAction || isOperator || isMathAction
                ? textColor.withOpacity(0.1) 
                : theme.colorScheme.surface);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Material(
              color: bgColor,
              elevation: key == '=' ? 4 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onKeyPress(key);
                },
                child: Center(
                  child: Text(
                    key,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textColor),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}