// lib/features/smart_trackers/components/add_formula_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';

class AddFormulaBottomSheet extends StatefulWidget {
  final List<TrackerField> existingFields;
  final ValueChanged<TrackerField> onColumnAdded;

  const AddFormulaBottomSheet({
    Key? key,
    required this.existingFields,
    required this.onColumnAdded,
  }) : super(key: key);

  @override
  State<AddFormulaBottomSheet> createState() => _AddFormulaBottomSheetState();
}

class _AddFormulaBottomSheetState extends State<AddFormulaBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  bool _isMathMode = true;

  // --- Freeform Math State ---
  final _mathExprCtrl = TextEditingController();

  // --- Logic State ---
  String? _logicField;
  String _logicOp = '==';
  final _logicTargetCtrl = TextEditingController();
  final _trueResultCtrl = TextEditingController();
  final _falseResultCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _mathExprCtrl.dispose();
    _logicTargetCtrl.dispose();
    _trueResultCtrl.dispose();
    _falseResultCtrl.dispose();
    super.dispose();
  }

  // --- INSERTS SMART CHIPS INTO THE TEXT BOX ---
  void _insertTextToMath(String text) {
    HapticFeedback.lightImpact();
    final int cursorPos = _mathExprCtrl.selection.baseOffset >= 0
        ? _mathExprCtrl.selection.baseOffset
        : _mathExprCtrl.text.length;

    final String currentText = _mathExprCtrl.text;
    final String newText =
        currentText.substring(0, cursorPos) +
        text +
        currentText.substring(cursorPos);

    _mathExprCtrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursorPos + text.length),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_isMathMode && _mathExprCtrl.text.trim().isEmpty) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (!_isMathMode && _logicField == null) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.selectionClick();

    final config = FormulaConfig(
      type: _isMathMode ? 'math' : 'logic',
      mathExpression: _mathExprCtrl.text.trim(), // Saves advanced formula
      logicFieldId: _logicField,
      logicOperator: _logicOp,
      logicTargetValue: _logicTargetCtrl.text.trim(),
      trueResult: _trueResultCtrl.text.trim(),
      falseResult: _falseResultCtrl.text.trim(),
    );

    final field = TrackerField(
      id: const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      type: TrackerFieldType.formula,
      formulaConfig: config,
    );

    widget.onColumnAdded(field);
    Navigator.pop(context);
  }

  Widget _buildBoxyDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
          value: value,
          isExpanded: true,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.colorScheme.primary,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildLogicBlock(String title, Color accentColor, Widget child) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10,
                color: accentColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildSmartChip(
    String label,
    ThemeData theme, {
    bool isOperator = false,
  }) {
    return GestureDetector(
      onTap: () => _insertTextToMath(isOperator ? ' $label ' : '[$label]'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOperator
              ? theme.colorScheme.primaryContainer.withOpacity(0.5)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOperator ? theme.colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: isOperator
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final mathFields = widget.existingFields
        .where(
          (f) =>
              f.type == TrackerFieldType.number ||
              f.type == TrackerFieldType.currency ||
              f.type == TrackerFieldType.formula,
        )
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Add Formula Column',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),

              ModernBoxyInput(
                controller: _nameCtrl,
                labelText: 'New Column Name (e.g. Final Price)',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              // --- TOGGLE TABS ---
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isMathMode = true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isMathMode
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'MATH',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _isMathMode
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isMathMode = false),
                        child: Container(
                          decoration: BoxDecoration(
                            color: !_isMathMode
                                ? theme.colorScheme.primaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'LOGIC',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: !_isMathMode
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- ADVANCED MATH UI ---
              if (_isMathMode) ...[
                ModernBoxyInput(
                  controller: _mathExprCtrl,
                  labelText: 'Formula Expression',
                  hintText: 'e.g. ([Price] * [Qty]) / 100',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),

                Text(
                  'TAP TO INSERT VARIABLES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (mathFields.isEmpty)
                  Text(
                    'No numeric fields available.',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.error,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mathFields
                        .map((f) => _buildSmartChip(f.name, theme))
                        .toList(),
                  ),

                const SizedBox(height: 16),
                Text(
                  'TAP TO INSERT OPERATORS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['+', '-', '*', '/', '(', ')']
                      .map((op) => _buildSmartChip(op, theme, isOperator: true))
                      .toList(),
                ),
              ] else ...[
                // --- EXPLICIT LOGIC UI ---
                _buildLogicBlock(
                  '1. SET CONDITION (IF)',
                  theme.colorScheme.primary,
                  Column(
                    children: [
                      _buildBoxyDropdown(
                        hint: 'Select a Field...',
                        value: _logicField,
                        items: widget.existingFields
                            .map(
                              (f) => DropdownMenuItem(
                                value: f.id,
                                child: Text(
                                  f.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _logicField = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildBoxyDropdown(
                              hint: 'Condition',
                              value: _logicOp,
                              items: ['==', '!=', '>', '<', '>=', '<=']
                                  .map(
                                    (op) => DropdownMenuItem(
                                      value: op,
                                      child: Text(
                                        ' $op ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _logicOp = v!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: ModernBoxyInput(
                              controller: _logicTargetCtrl,
                              labelText: 'Target Value',
                              hintText: 'e.g. Paid, 100',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                _buildLogicBlock(
                  '2. WHAT TO SHOW IF TRUE (THEN)',
                  Colors.green,
                  ModernBoxyInput(
                    controller: _trueResultCtrl,
                    labelText: 'Result',
                    hintText: 'Type text, number, or Field ID',
                  ),
                ),

                _buildLogicBlock(
                  '3. WHAT TO SHOW IF FALSE (ELSE)',
                  theme.colorScheme.error,
                  ModernBoxyInput(
                    controller: _falseResultCtrl,
                    labelText: 'Result',
                    hintText: 'Type text, number, or Field ID',
                  ),
                ),
              ],
              const SizedBox(height: 32),

              Row(
                children: [
                  Expanded(
                    child: ModernBoxyButton(
                      onPressed: () => Navigator.pop(context),
                      label: 'CANCEL',
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ModernBoxyButton(
                      onPressed: _save,
                      label: 'ADD COLUMN',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
