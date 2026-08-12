// lib/features/smart_trackers/components/add_field_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';
import '../utils/tracker_field_ui_helper.dart';

class AddFieldBottomSheet extends StatefulWidget {
  final TrackerField?
  existingField; // <-- NEW: Allows editing an existing field
  final ValueChanged<TrackerField> onFieldAdded;

  const AddFieldBottomSheet({
    Key? key,
    this.existingField,
    required this.onFieldAdded,
  }) : super(key: key);

  @override
  State<AddFieldBottomSheet> createState() => _AddFieldBottomSheetState();
}

class _AddFieldBottomSheetState extends State<AddFieldBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _optionsCtrl;
  late TextEditingController _prefixCtrl;
  late TextEditingController _suffixCtrl;

  late TrackerFieldType _selectedType;
  late String _selectedCurrency;

  final List<String> _currencySymbols = ['₹', '\$', '€', '£', '¥'];

  bool get _requiresOptions =>
      _selectedType == TrackerFieldType.dropdown ||
      _selectedType == TrackerFieldType.radio ||
      _selectedType == TrackerFieldType.checkbox;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if editing
    _nameCtrl = TextEditingController(text: widget.existingField?.name ?? '');
    _optionsCtrl = TextEditingController(
      text: widget.existingField?.options?.join(', ') ?? '',
    );
    _prefixCtrl = TextEditingController(
      text: widget.existingField?.prefix ?? '',
    );
    _suffixCtrl = TextEditingController(
      text: widget.existingField?.suffix ?? '',
    );

    _selectedType = widget.existingField?.type ?? TrackerFieldType.text;
    _selectedCurrency = widget.existingField?.currencySymbol ?? '₹';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _optionsCtrl.dispose();
    _prefixCtrl.dispose();
    _suffixCtrl.dispose();
    super.dispose();
  }

  void _addField() {
    if (!_formKey.currentState!.validate()) return;

    List<String>? parsedOptions;
    if (_requiresOptions) {
      if (_optionsCtrl.text.trim().isEmpty) {
        CustomSnackbars.showError(
          context,
          message: 'Please provide options separated by commas.',
        );
        HapticFeedback.heavyImpact();
        return;
      }
      parsedOptions = _optionsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    HapticFeedback.selectionClick();
    final newField = TrackerField(
      // --- CRITICAL: Must preserve original ID when editing so old records retain data ---
      id: widget.existingField?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      type: _selectedType,
      options: parsedOptions,
      prefix:
          _selectedType == TrackerFieldType.serialNo &&
              _prefixCtrl.text.isNotEmpty
          ? _prefixCtrl.text.trim()
          : null,
      suffix:
          _selectedType == TrackerFieldType.serialNo &&
              _suffixCtrl.text.isNotEmpty
          ? _suffixCtrl.text.trim()
          : null,
      currencySymbol: _selectedType == TrackerFieldType.currency
          ? _selectedCurrency
          : null,
    );

    widget.onFieldAdded(newField);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // ... Keep exact same UI build method from your previous AddFieldBottomSheet ...
    // Note: Change the button label at the bottom to reflect edit mode:
    // label: widget.existingField != null ? 'UPDATE FIELD' : 'ADD FIELD',

    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

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
                widget.existingField != null ? 'Edit Field' : 'Build Field',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              ModernBoxyInput(
                controller: _nameCtrl,
                labelText: 'Field Name (e.g. Serial Number)',
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              Text(
                'SELECT DATA TYPE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.4,
                ),
                itemCount: TrackerFieldType.values.length,
                itemBuilder: (context, index) {
                  final type = TrackerFieldType.values[index];
                  final isSelected = _selectedType == type;

                  return Material(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedType = type);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : theme.dividerColor,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              TrackerFieldUIHelper.getTypeIcon(type),
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              TrackerFieldUIHelper.formatEnumName(type.name),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              if (_requiresOptions) ...[
                const SizedBox(height: 24),
                ModernBoxyInput(
                  controller: _optionsCtrl,
                  labelText: 'Options (Comma separated)',
                  hintText: 'e.g. Yes, No, Maybe',
                ),
              ],

              if (_selectedType == TrackerFieldType.currency) ...[
                const SizedBox(height: 24),
                Text(
                  'CURRENCY SYMBOL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      dropdownColor: theme.colorScheme.surfaceContainerHighest,
                      items: _currencySymbols.map((sym) {
                        return DropdownMenuItem(
                          value: sym,
                          child: Text(
                            sym,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null)
                          setState(() => _selectedCurrency = val);
                      },
                    ),
                  ),
                ),
              ],

              if (_selectedType == TrackerFieldType.serialNo) ...[
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ModernBoxyInput(
                        controller: _prefixCtrl,
                        labelText: 'Prefix (Optional)',
                        hintText: 'e.g. INV-',
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      child: ModernBoxyInput(
                        controller: _suffixCtrl,
                        labelText: 'Suffix (Optional)',
                        hintText: 'e.g. -2026',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Format: Prefix + [Auto Number] + Suffix',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
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
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    flex: 2,
                    child: ModernBoxyButton(
                      onPressed: _addField,
                      label: widget.existingField != null
                          ? 'UPDATE FIELD'
                          : 'ADD FIELD',
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
