// lib/features/smart_trackers/components/smart_tracker_filter_sheet.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/global_selection_sheet.dart'; // <-- Added GlobalSelectionSheet
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';
import '../../../core/database/app_database.dart';

class SmartTrackerFilterSheet extends StatefulWidget {
  final List<TrackerField> fields;
  final List<SmartTrackerRecord> records;
  final TrackerField? initialField;
  final String initialOperator;
  final List<String> initialValues; // For '==' and '!='
  final String initialSingleValue; // For '>', '<', 'Contains', etc.
  final Function(TrackerField?, String, List<String>, String) onApplyFilter;

  const SmartTrackerFilterSheet({
    Key? key,
    required this.fields,
    required this.records,
    this.initialField,
    required this.initialOperator,
    required this.initialValues,
    required this.initialSingleValue,
    required this.onApplyFilter,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required List<TrackerField> fields,
    required List<SmartTrackerRecord> records,
    required TrackerField? initialField,
    required String initialOperator,
    required List<String> initialValues,
    required String initialSingleValue,
    required Function(TrackerField?, String, List<String>, String)
    onApplyFilter,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SmartTrackerFilterSheet(
        fields: fields,
        records: records,
        initialField: initialField,
        initialOperator: initialOperator,
        initialValues: initialValues,
        initialSingleValue: initialSingleValue,
        onApplyFilter: onApplyFilter,
      ),
    );
  }

  @override
  State<SmartTrackerFilterSheet> createState() =>
      _SmartTrackerFilterSheetState();
}

class _SmartTrackerFilterSheetState extends State<SmartTrackerFilterSheet> {
  TrackerField? _selectedField;
  late String _selectedOperator;

  List<String> _uniqueValues = [];
  Set<String> _selectedValues = {};
  late TextEditingController _singleValueCtrl;

  @override
  void initState() {
    super.initState();
    _selectedField = widget.initialField;
    _selectedOperator = widget.initialOperator;
    _singleValueCtrl = TextEditingController(text: widget.initialSingleValue);

    if (_selectedField != null) {
      _uniqueValues = _extractUniqueValues(_selectedField!);
      _selectedValues = widget.initialValues.isNotEmpty
          ? widget.initialValues.toSet()
          : _uniqueValues.toSet();
    }
  }

  @override
  void dispose() {
    _singleValueCtrl.dispose();
    super.dispose();
  }

  List<String> _getOperators(TrackerField? field) {
    if (field == null) return ['=='];
    if (field.type == TrackerFieldType.number ||
        field.type == TrackerFieldType.currency ||
        field.type == TrackerFieldType.formula ||
        field.type == TrackerFieldType.date) {
      return ['==', '!=', '>', '<', '>=', '<='];
    }
    return ['==', '!=', 'Contains', 'Starts With', 'Ends With'];
  }

  String _formatValue(TrackerField field, dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    try {
      if (field.type == TrackerFieldType.checkbox && value is List)
        return value.join(', ');
      if (field.type == TrackerFieldType.currency)
        return '${field.currencySymbol ?? ''} $value'.trim();
      if (field.type == TrackerFieldType.date)
        return DateFormat(
          'dd MMM yyyy',
        ).format(DateTime.parse(value.toString()));
      if (field.type == TrackerFieldType.toggle)
        return value == true ? 'Yes' : 'No';
      return value.toString();
    } catch (e) {
      return value.toString();
    }
  }

  List<String> _extractUniqueValues(TrackerField field) {
    final Set<String> values = {};
    for (var record in widget.records) {
      final dataMap = jsonDecode(record.dataJson);
      final rawVal = dataMap[field.id];
      values.add(_formatValue(field, rawVal));
    }
    final sortedList = values.toList();
    sortedList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return sortedList;
  }

  // --- Uses GlobalSelectionSheet ---
  Future<void> _selectField() async {
    HapticFeedback.lightImpact();
    final selectedName = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Column',
      items: widget.fields.map((f) => f.name).toList(),
      selectedValue: _selectedField?.name ?? '',
    );

    if (selectedName != null && mounted) {
      setState(() {
        _selectedField = widget.fields.firstWhere(
          (f) => f.name == selectedName,
        );
        _selectedOperator = _getOperators(
          _selectedField,
        ).first; // Reset Operator
        _uniqueValues = _extractUniqueValues(_selectedField!);
        _selectedValues = _uniqueValues.toSet(); // Select all by default
        _singleValueCtrl.clear();
      });
    }
  }

  // --- Uses GlobalSelectionSheet ---
  Future<void> _selectOperator() async {
    if (_selectedField == null) return;
    HapticFeedback.lightImpact();
    final operators = _getOperators(_selectedField);

    final selectedOp = await GlobalSelectionSheet.showSimple(
      context: context,
      title: 'Select Condition',
      items: operators,
      selectedValue: _selectedOperator,
    );

    if (selectedOp != null && mounted) {
      setState(() => _selectedOperator = selectedOp);
    }
  }

  void _apply() {
    HapticFeedback.selectionClick();
    widget.onApplyFilter(
      _selectedField,
      _selectedOperator,
      _selectedValues.toList(),
      _singleValueCtrl.text.trim(),
    );
    Navigator.pop(context);
  }

  void _clear() {
    HapticFeedback.lightImpact();
    widget.onApplyFilter(null, '==', [], '');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final isMultiSelectMode =
        _selectedOperator == '==' || _selectedOperator == '!=';

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: EdgeInsets.only(
        bottom: bottomInset + 24,
        left: 24,
        right: 24,
        top: 16,
      ),
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
            'Advanced Filter',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),

          // 1. SELECT FIELD
          Text(
            '1. FILTER BY COLUMN',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _selectField,
            child: AbsorbPointer(
              child: ModernBoxyInput(
                controller: TextEditingController(
                  text: _selectedField?.name ?? '',
                ),
                hintText: 'Choose a column...',
                suffixIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.primary,
                ),
                labelText: '',
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_selectedField != null) ...[
            // 2. SET CONDITION
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. CONDITION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectOperator,
                        child: AbsorbPointer(
                          child: ModernBoxyInput(
                            controller: TextEditingController(
                              text: _selectedOperator,
                            ),
                            suffixIcon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: theme.colorScheme.primary,
                            ),
                            labelText: '',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. SINGLE VALUE INPUT (If Not Multi-Select)
                if (!isMultiSelectMode)
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '3. TARGET VALUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ModernBoxyInput(
                          controller: _singleValueCtrl,
                          hintText: 'e.g. 100, Paid...',
                          keyboardType:
                              ['>', '<', '>=', '<='].contains(_selectedOperator)
                              ? const TextInputType.numberWithOptions(
                                  decimal: true,
                                )
                              : TextInputType.text,
                          labelText: '',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // 3. MULTI-SELECT CHECKLIST (If == or !=)
            if (isMultiSelectMode) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '3. SELECT VALUES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        if (_selectedValues.length == _uniqueValues.length) {
                          _selectedValues.clear(); // Deselect All
                        } else {
                          _selectedValues = _uniqueValues.toSet(); // Select All
                        }
                      });
                    },
                    child: Text(
                      _selectedValues.length == _uniqueValues.length
                          ? 'DESELECT ALL'
                          : 'SELECT ALL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.30,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _uniqueValues.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                    itemBuilder: (context, index) {
                      final val = _uniqueValues[index];
                      final isChecked = _selectedValues.contains(val);

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (isChecked)
                              _selectedValues.remove(val);
                            else
                              _selectedValues.add(val);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isChecked
                                    ? Icons.check_box_rounded
                                    : Icons.check_box_outline_blank_rounded,
                                color: isChecked
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.5),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  val,
                                  style: TextStyle(
                                    fontWeight: isChecked
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isChecked
                                        ? theme.colorScheme.onSurface
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ],

          Row(
            children: [
              Expanded(
                child: ModernBoxyButton(
                  onPressed: _clear,
                  label: 'CLEAR',
                  isOutlined: true,
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ModernBoxyButton(
                  onPressed:
                      (_selectedField == null ||
                          (isMultiSelectMode && _selectedValues.isEmpty))
                      ? null
                      : _apply,
                  label: 'APPLY FILTER',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
