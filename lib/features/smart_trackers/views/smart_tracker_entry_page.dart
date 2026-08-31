// lib/features/smart_trackers/views/smart_tracker_entry_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../../core/components/inline_calculator_pad.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';
import '../providers/smart_tracker_provider.dart';
import '../utils/tracker_formula_evaluator.dart';

class SmartTrackerEntryPage extends ConsumerStatefulWidget {
  final SmartTrackerTemplate template;
  final int existingRecordCount;
  final SmartTrackerRecord? existingRecord;

  const SmartTrackerEntryPage({
    Key? key,
    required this.template,
    required this.existingRecordCount,
    this.existingRecord,
  }) : super(key: key);

  @override
  ConsumerState<SmartTrackerEntryPage> createState() =>
      _SmartTrackerEntryPageState();
}

class _SmartTrackerEntryPageState extends ConsumerState<SmartTrackerEntryPage> {
  final _formKey = GlobalKey<FormState>();
  late List<TrackerField> _fields;

  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};

  // --- FOCUS & KEYBOARD MANAGEMENT STATE ---
  final Map<String, FocusNode> _focusNodes = {};
  final List<String> _focusableFieldIds = [];

  // Custom Keyboard State
  String? _activeCalculatorFieldId;
  bool _showCustomKeyboard = false;

  @override
  void initState() {
    super.initState();
    final List<dynamic> decoded = jsonDecode(widget.template.schemaJson);
    _fields = decoded.map((e) => TrackerField.fromJson(e)).toList();

    Map<String, dynamic> existingData = {};
    if (widget.existingRecord != null) {
      existingData =
          jsonDecode(widget.existingRecord!.dataJson) as Map<String, dynamic>;
    }

    for (var field in _fields) {
      if (field.type == TrackerFieldType.serialNo) {
        if (widget.existingRecord != null && existingData[field.id] != null) {
          _formData[field.id] = existingData[field.id];
        } else {
          final serialNumber = (widget.existingRecordCount + 1)
              .toString()
              .padLeft(4, '0');
          _formData[field.id] =
              '${field.prefix ?? ''}$serialNumber${field.suffix ?? ''}';
        }
        _controllers[field.id] = TextEditingController(
          text: _formData[field.id],
        );
      } else if (field.type == TrackerFieldType.checkbox) {
        if (widget.existingRecord != null && existingData[field.id] != null) {
          _formData[field.id] =
              (existingData[field.id] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];
        } else {
          _formData[field.id] = <String>[];
        }
      } else if (field.type == TrackerFieldType.toggle) {
        _formData[field.id] = existingData[field.id] == true;
      } else if (field.type == TrackerFieldType.date) {
        // --- NEW: Explicit handling for Date Fields ---
        DateTime initialDate = DateTime.now();
        if (widget.existingRecord != null &&
            existingData[field.id] != null &&
            existingData[field.id].toString().isNotEmpty) {
          initialDate =
              DateTime.tryParse(existingData[field.id].toString()) ??
              DateTime.now();
        }
        _formData[field.id] = initialDate.toIso8601String();
        _controllers[field.id] = TextEditingController(
          text: DateFormat('dd MMM yyyy').format(initialDate),
        );
        _controllers[field.id]!.addListener(_recalculateFormulas);
      } else {
        final val = existingData[field.id]?.toString() ?? '';
        _formData[field.id] = val;
        _controllers[field.id] = TextEditingController(text: val);
        _controllers[field.id]!.addListener(_recalculateFormulas);

        // --- REGISTER FOCUS NODES ---
        if (field.type == TrackerFieldType.text ||
            field.type == TrackerFieldType.number ||
            field.type == TrackerFieldType.currency) {
          final node = FocusNode();

          // Intercept focus to trigger custom keyboard if it's a number/currency field
          node.addListener(() {
            if (node.hasFocus) {
              if (field.type == TrackerFieldType.number ||
                  field.type == TrackerFieldType.currency) {
                // Hide native keyboard, show custom
                SystemChannels.textInput.invokeMethod('TextInput.hide');
                setState(() {
                  _activeCalculatorFieldId = field.id;
                  _showCustomKeyboard = true;
                });
              } else {
                // Regular text field: Hide custom, allow native
                setState(() {
                  _activeCalculatorFieldId = null;
                  _showCustomKeyboard = false;
                });
              }
            }
          });

          _focusNodes[field.id] = node;
          _focusableFieldIds.add(field.id);
        }
      }
    }

    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusableFieldIds.isNotEmpty && mounted) {
        _focusNodes[_focusableFieldIds.first]?.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // --- FOCUS JUMPING LOGIC ---
  bool _isLastFocusable(String id) {
    return _focusableFieldIds.isNotEmpty && _focusableFieldIds.last == id;
  }

  void _focusNextField(String currentId) {
    final currentIndex = _focusableFieldIds.indexOf(currentId);
    if (currentIndex >= 0 && currentIndex < _focusableFieldIds.length - 1) {
      FocusScope.of(
        context,
      ).requestFocus(_focusNodes[_focusableFieldIds[currentIndex + 1]]);
    } else {
      _closeAllKeyboards();
    }
  }

  void _focusPreviousField(String currentId) {
    final currentIndex = _focusableFieldIds.indexOf(currentId);
    if (currentIndex > 0) {
      FocusScope.of(
        context,
      ).requestFocus(_focusNodes[_focusableFieldIds[currentIndex - 1]]);
    }
  }

  void _closeAllKeyboards() {
    FocusScope.of(context).unfocus();
    setState(() {
      _showCustomKeyboard = false;
      _activeCalculatorFieldId = null;
    });
  }

  void _recalculateFormulas() {
    for (var f in _fields) {
      if (f.type == TrackerFieldType.text ||
          f.type == TrackerFieldType.number ||
          f.type == TrackerFieldType.currency) {
        _formData[f.id] = _controllers[f.id]!.text;
      }
    }

    for (var field in _fields.where(
      (f) => f.type == TrackerFieldType.formula,
    )) {
      if (field.formulaConfig != null) {
        final result = TrackerFormulaEvaluator.evaluate(
          field.formulaConfig!,
          _formData,
          _fields,
        );
        if (_formData[field.id] != result) {
          setState(() {
            _formData[field.id] = result;
            _controllers[field.id]!.text = result;
          });
        }
      }
    }
  }

  Future<void> _pickDate(String fieldId) async {
    _closeAllKeyboards();
    HapticFeedback.lightImpact();

    // --- NEW: Open date picker to the currently selected date ---
    DateTime initialDate = DateTime.now();
    if (_formData[fieldId] != null &&
        _formData[fieldId].toString().isNotEmpty) {
      initialDate =
          DateTime.tryParse(_formData[fieldId].toString()) ?? DateTime.now();
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );

    if (picked != null) {
      final formatted = DateFormat('dd MMM yyyy').format(picked);
      setState(() {
        _formData[fieldId] = picked.toIso8601String();
        _controllers[fieldId]!.text = formatted;
      });
    }
  }

  Future<void> _submit() async {
    _closeAllKeyboards();

    for (var field in _fields) {
      if (field.isMandatory) {
        if (field.type == TrackerFieldType.radio) {
          if (_formData[field.id] == null ||
              _formData[field.id].toString().isEmpty) {
            CustomSnackbars.showError(
              context,
              message: '${field.name} is required.',
            );
            HapticFeedback.heavyImpact();
            return;
          }
        } else if (field.type == TrackerFieldType.checkbox) {
          final list = _formData[field.id] as List<String>?;
          if (list == null || list.isEmpty) {
            CustomSnackbars.showError(
              context,
              message: '${field.name} is required.',
            );
            HapticFeedback.heavyImpact();
            return;
          }
        }
      }
    }

    if (!_formKey.currentState!.validate()) return;

    for (var field in _fields) {
      if (field.type == TrackerFieldType.text ||
          field.type == TrackerFieldType.number ||
          field.type == TrackerFieldType.currency) {
        _formData[field.id] = _controllers[field.id]!.text.trim();
      }
    }

    HapticFeedback.selectionClick();

    bool success;
    if (widget.existingRecord != null) {
      success = await ref
          .read(smartTrackerActionProvider.notifier)
          .updateTrackerRecord(widget.existingRecord!.id, _formData);
    } else {
      success = await ref
          .read(smartTrackerActionProvider.notifier)
          .saveTrackerRecord(widget.template.id, _formData);
    }

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildDynamicField(TrackerField field, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    final displayLabel =
        field.isMandatory &&
            field.type != TrackerFieldType.serialNo &&
            field.type != TrackerFieldType.formula
        ? '${field.name} *'
        : field.name;

    switch (field.type) {
      case TrackerFieldType.serialNo:
        return ModernBoxyInput(
          controller: _controllers[field.id]!,
          labelText: displayLabel,
          readOnly: true,
          prefixIcon: Icon(
            Icons.pin_rounded,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        );

      case TrackerFieldType.text:
        return ModernBoxyInput(
          controller: _controllers[field.id]!,
          focusNode: _focusNodes[field.id],
          textInputAction: _isLastFocusable(field.id)
              ? TextInputAction.done
              : TextInputAction.next,
          onFieldSubmitted: (_) => _focusNextField(field.id),
          labelText: displayLabel,
          validator: field.isMandatory
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
        );

      case TrackerFieldType.number:
        return ModernBoxyInput(
          controller: _controllers[field.id]!,
          focusNode: _focusNodes[field.id],
          readOnly: true, // Prevents native keyboard
          onTap: () {
            if (!_focusNodes[field.id]!.hasFocus)
              _focusNodes[field.id]!.requestFocus();
            SystemChannels.textInput.invokeMethod('TextInput.hide');
          },
          labelText: displayLabel,
          validator: field.isMandatory
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
        );

      case TrackerFieldType.currency:
        return ModernBoxyInput(
          controller: _controllers[field.id]!,
          focusNode: _focusNodes[field.id],
          readOnly: true, // Prevents native keyboard
          onTap: () {
            if (!_focusNodes[field.id]!.hasFocus)
              _focusNodes[field.id]!.requestFocus();
            SystemChannels.textInput.invokeMethod('TextInput.hide');
          },
          labelText: displayLabel,
          prefixIcon: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              field.currencySymbol ?? '',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.primary,
                fontSize: 16,
              ),
            ),
          ),
          validator: field.isMandatory
              ? (v) => v == null || v.isEmpty ? 'Required' : null
              : null,
        );

      case TrackerFieldType.date:
        return GestureDetector(
          onTap: () => _pickDate(field.id),
          child: AbsorbPointer(
            child: ModernBoxyInput(
              controller: _controllers[field.id]!,
              labelText: displayLabel,
              suffixIcon: Icon(
                Icons.calendar_month_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              validator: field.isMandatory
                  ? (v) => v == null || v.isEmpty ? 'Required' : null
                  : null,
            ),
          ),
        );

      case TrackerFieldType.dropdown:
        return GestureDetector(
          onTap: () async {
            _closeAllKeyboards();
            HapticFeedback.lightImpact();
            final selected = await GlobalSelectionSheet.showSimple(
              context: context,
              title: 'Select ${field.name}',
              items: field.options ?? [],
              selectedValue: _formData[field.id] ?? '',
            );
            if (selected != null && mounted) {
              setState(() {
                _formData[field.id] = selected;
                _controllers[field.id]!.text = selected;
              });
            }
          },
          child: AbsorbPointer(
            child: ModernBoxyInput(
              controller: _controllers[field.id]!,
              labelText: displayLabel,
              suffixIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              validator: field.isMandatory
                  ? (v) => v == null || v.isEmpty ? 'Required' : null
                  : null,
            ),
          ),
        );

      case TrackerFieldType.toggle:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(
              isDark ? 0.3 : 0.5,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: _formData[field.id] ?? false,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) {
                    _closeAllKeyboards();
                    HapticFeedback.lightImpact();
                    setState(() => _formData[field.id] = val);
                  },
                ),
              ),
            ],
          ),
        );

      case TrackerFieldType.radio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: field.options!.map((opt) {
                final isSelected = _formData[field.id] == opt;
                return GestureDetector(
                  onTap: () {
                    _closeAllKeyboards();
                    HapticFeedback.selectionClick();
                    setState(() => _formData[field.id] = opt);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.15)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          opt,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 13,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );

      case TrackerFieldType.formula:
        return ModernBoxyInput(
          controller: _controllers[field.id]!,
          labelText: displayLabel,
          readOnly: true,
          prefixIcon: Icon(
            Icons.functions_rounded,
            color: theme.colorScheme.primary,
            size: 18,
          ),
        );

      case TrackerFieldType.checkbox:
        final currentList = _formData[field.id] as List<String>;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayLabel.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: field.options!.map((opt) {
                final isChecked = currentList.contains(opt);
                return GestureDetector(
                  onTap: () {
                    _closeAllKeyboards();
                    HapticFeedback.selectionClick();
                    setState(() {
                      if (isChecked)
                        currentList.remove(opt);
                      else
                        currentList.add(opt);
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isChecked
                          ? theme.colorScheme.primary.withOpacity(0.15)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isChecked
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        width: isChecked ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isChecked
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 18,
                          color: isChecked
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withOpacity(
                                  0.5,
                                ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          opt,
                          style: TextStyle(
                            fontWeight: isChecked
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 13,
                            color: isChecked
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingRecord != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: isEditing ? 'Edit Record' : 'New Entry',
        subtitle: widget.template.name.toUpperCase(),
        leadingIcon: Icons.arrow_back_rounded,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- MAIN FORM ---
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(DesignTokens.spacingLg),
                  itemCount: _fields.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RECORD DETAILS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDynamicField(_fields[index], theme),
                        ],
                      );
                    }
                    return _buildDynamicField(_fields[index], theme);
                  },
                ),
              ),
            ),

            // --- FIXED SUBMIT BUTTON (Only shows if custom keyboard is hidden) ---
            if (!_showCustomKeyboard)
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
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
                        onPressed: _submit,
                        label: isEditing ? 'UPDATE RECORD' : 'SAVE RECORD',
                      ),
                    ),
                  ],
                ),
              ),

            // --- CUSTOM INLINE CALCULATOR PAD ---
            if (_showCustomKeyboard && _activeCalculatorFieldId != null)
              InlineCalculatorPad(
                controller: _controllers[_activeCalculatorFieldId]!,
                onPrevious:
                    _focusableFieldIds.indexOf(_activeCalculatorFieldId!) > 0
                    ? () => _focusPreviousField(_activeCalculatorFieldId!)
                    : null,
                onNext: !_isLastFocusable(_activeCalculatorFieldId!)
                    ? () => _focusNextField(_activeCalculatorFieldId!)
                    : null,
                onSubmit: () {
                  if (_isLastFocusable(_activeCalculatorFieldId!)) {
                    _submit();
                  } else {
                    _focusNextField(_activeCalculatorFieldId!);
                  }
                },
                onClose: _closeAllKeyboards,
              ),
          ],
        ),
      ),
    );
  }
}
