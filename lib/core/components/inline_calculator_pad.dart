import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/bodmas_calculator.dart';

class InlineCalculatorPad extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onClose;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  const InlineCalculatorPad({
    Key? key,
    required this.controller,
    required this.onSubmit,
    required this.onClose,
    this.onNext,
    this.onPrevious,
  }) : super(key: key);

  @override
  State<InlineCalculatorPad> createState() => _InlineCalculatorPadState();
}

class _InlineCalculatorPadState extends State<InlineCalculatorPad> {
  String _expression = '';
  String _liveResult = '0';

  @override
  void initState() {
    super.initState();
    _expression = widget.controller.text.isEmpty ? '' : widget.controller.text;
    _updateResult();
  }

  // --- FIX: Intelligent Cursor Binding ---
  void _onKeyPress(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      int cursorPosition = widget.controller.selection.baseOffset;
      if (cursorPosition < 0) cursorPosition = widget.controller.text.length;

      String currentText = widget.controller.text;

      if (key == 'C') {
        widget.controller.clear();
        _expression = '';
        _liveResult = '0';
        return;
      } else if (key == '⌫') {
        if (cursorPosition > 0) {
          final newText = currentText.substring(0, cursorPosition - 1) + currentText.substring(cursorPosition);
          widget.controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorPosition - 1),
          );
        }
      } else if (key == '=') {
        widget.controller.text = _liveResult;
        widget.controller.selection = TextSelection.collapsed(offset: _liveResult.length);
      } else {
        final isOperator = ['+', '-', '×', '÷'].contains(key);
        if (isOperator && cursorPosition > 0) {
          final prevChar = currentText[cursorPosition - 1];
          if (['+', '-', '×', '÷'].contains(prevChar)) {
            // Replace existing operator
            final newText = currentText.substring(0, cursorPosition - 1) + key + currentText.substring(cursorPosition);
            widget.controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursorPosition),
            );
          } else {
            // Insert normally
            final newText = currentText.substring(0, cursorPosition) + key + currentText.substring(cursorPosition);
            widget.controller.value = TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: cursorPosition + 1),
            );
          }
        } else {
          final newText = currentText.substring(0, cursorPosition) + key + currentText.substring(cursorPosition);
          widget.controller.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: cursorPosition + 1),
          );
        }
      }

      _expression = widget.controller.text;
      _updateResult();
    });
  }

  void _updateResult() {
    setState(() {
      _liveResult = BodmasCalculator.evaluate(_expression);
    });
  }

  void _lockAndNavigate(VoidCallback action) {
    widget.controller.text = _expression.isEmpty ? '' : _liveResult;
    action();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE RESULT',
                            style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _liveResult, 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: -1.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (widget.onPrevious != null)
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_up_rounded, color: theme.colorScheme.primary),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _lockAndNavigate(widget.onPrevious!),
                      ),
                    if (widget.onNext != null)
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _lockAndNavigate(widget.onNext!),
                      ),
                    const SizedBox(width: 4),
                    Container(width: 1, height: 24, color: theme.dividerColor),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.keyboard_hide_rounded, color: theme.colorScheme.onSurfaceVariant),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _lockAndNavigate(widget.onClose),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // --- FIX: Restored Missing Unicode Operators ---
              _buildRow(['C', '(', ')', '÷'], theme),
              const SizedBox(height: 6),
              _buildRow(['7', '8', '9', '×'], theme),
              const SizedBox(height: 6),
              _buildRow(['4', '5', '6', '⌫'], theme),
              const SizedBox(height: 6),
              _buildRow(['1', '2', '3', '-'], theme),
              const SizedBox(height: 6),
              _buildRow(['.', '0', '=', '+'], theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) {
        final isAction = ['C', '⌫'].contains(key);
        final isMathAction = ['=', '(', ')'].contains(key);
        final isOperator = ['÷', '×', '-', '+'].contains(key);
        
        Color textColor = theme.colorScheme.onSurface;
        if (isAction) textColor = theme.colorScheme.error;
        if (isOperator || isMathAction) textColor = theme.colorScheme.primary;
        
        if (key == '=') {
          textColor = theme.brightness == Brightness.dark ? Colors.black : Colors.white;
        }

        final bgColor = key == '=' 
            ? theme.colorScheme.primary 
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
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _onKeyPress(key),
                child: SizedBox(
                  height: 46, 
                  child: Center(
                    child: Text(
                      key,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textColor),
                    ),
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