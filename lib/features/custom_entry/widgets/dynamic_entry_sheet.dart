import 'package:budget/core/widgets/calculator_keyboard.dart';
import 'package:budget/core/widgets/modern_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/custom_data_models.dart';
import '../../../core/services/firestore_service.dart';
import '../services/custom_entry_service.dart';

class DynamicEntrySheet extends StatefulWidget {
  final CustomTemplate template;
  final List<CustomRecord> existingRecords; // Used for calculating next serial
  final CustomRecord? recordToEdit;

  const DynamicEntrySheet({
    super.key,
    required this.template,
    this.existingRecords = const [], // Default empty
    this.recordToEdit,
  });

  @override
  State<DynamicEntrySheet> createState() => _DynamicEntrySheetState();
}

class _DynamicEntrySheetState extends State<DynamicEntrySheet> {
  final Map<String, dynamic> _formData = {};
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController? _activeCalcController;
  bool _isKeyboardVisible = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.recordToEdit != null;
    _initializeFields();
  }

  void _initializeFields() {
    for (var field in widget.template.fields) {
      dynamic initialVal;
      if (_isEditing && widget.recordToEdit!.data.containsKey(field.name)) {
        initialVal = widget.recordToEdit!.data[field.name];
      }

      if (field.type == CustomFieldType.date) {
        if (initialVal is Timestamp)
          _formData[field.name] = initialVal.toDate();
        else if (initialVal is DateTime)
          _formData[field.name] = initialVal;
        else
          _formData[field.name] = DateTime.now();
      } else if (field.type == CustomFieldType.dropdown) {
        _formData[field.name] = initialVal;
      } else if (field.type == CustomFieldType.serial) {
        // AUTO GENERATE SERIAL (If New)
        if (_isEditing) {
          _controllers[field.name] = TextEditingController(
            text: initialVal?.toString() ?? '',
          );
          // For serial, we might store just the number, but display prefix+num+suffix.
          // Editor displays what is stored. Assuming integer stored.
        } else {
          // Calculate max serial
          int maxSerial = 0;
          for (var r in widget.existingRecords) {
            var val = r.data[field.name];
            if (val is int) {
              if (val > maxSerial) maxSerial = val;
            }
          }
          int next = maxSerial + 1;
          _controllers[field.name] = TextEditingController(
            text: next.toString(),
          );
          _formData[field.name] = next;
        }
      } else {
        _controllers[field.name] = TextEditingController(
          text: initialVal?.toString() ?? '',
        );
      }
    }
  }

  Future<void> _save() async {
    for (var field in widget.template.fields) {
      if (field.type == CustomFieldType.number ||
          field.type == CustomFieldType.currency) {
        _formData[field.name] =
            double.tryParse(_controllers[field.name]!.text) ?? 0.0;
      } else if (field.type == CustomFieldType.string) {
        _formData[field.name] = _controllers[field.name]!.text;
      } else if (field.type == CustomFieldType.serial) {
        // Ensure serial is stored as INT if possible
        _formData[field.name] =
            int.tryParse(_controllers[field.name]!.text) ?? 1;
      }
    }

    final record = CustomRecord(
      id: widget.recordToEdit?.id ?? '',
      templateId: widget.template.id,
      data: _formData,
      createdAt: widget.recordToEdit?.createdAt ?? DateTime.now(),
    );

    if (_isEditing) {
      await CustomEntryService().updateCustomRecord(record);
    } else {
      await CustomEntryService().addCustomRecord(record);
    }

    if (mounted) Navigator.pop(context);
  }

  void _reset() {
    _controllers.values.forEach((c) => c.clear());
    setState(() {
      _formData.clear();
      _initializeFields(); // Re-calc serials and dates
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Entry' : widget.template.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (!_isEditing)
                  TextButton(
                    onPressed: _reset,
                    child: const Text(
                      'Reset',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),
          ),

          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: widget.template.fields
                  .map((field) => _buildFieldInput(field))
                  .toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: Text(_isEditing ? 'Update' : 'Record Entry'),
                  ),
                ),
              ],
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _isKeyboardVisible
                ? CalculatorKeyboard(
                    onKeyPress: (v) => CalculatorKeyboard.handleKeyPress(
                      _activeCalcController!,
                      v,
                    ),
                    onBackspace: () => CalculatorKeyboard.handleBackspace(
                      _activeCalcController!,
                    ),
                    onClear: () => _activeCalcController!.clear(),
                    onEquals: () =>
                        CalculatorKeyboard.handleEquals(_activeCalcController!),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldInput(CustomFieldConfig field) {
    if (field.type == CustomFieldType.date) {
      final val = _formData[field.name] as DateTime? ?? DateTime.now();
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: val,
              firstDate: DateTime(1900),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _formData[field.name] = picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 12),
                Text(DateFormat('dd MMM yyyy').format(val)),
                const Spacer(),
                Text(
                  field.name,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (field.type == CustomFieldType.dropdown) {
      final val = _formData[field.name];
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: ModernDropdownPill<String>(
          label: val ?? 'Select ${field.name}',
          isActive: val != null,
          icon: Icons.arrow_drop_down_circle_outlined,
          onTap: () => showSelectionSheet<String>(
            context: context,
            title: 'Select ${field.name}',
            items: field.dropdownOptions ?? [],
            labelBuilder: (s) => s,
            onSelect: (v) => setState(() => _formData[field.name] = v),
            selectedItem: val,
          ),
        ),
      );
    }

    // SERIAL NUMBER: Read-Only with Visual Prefix/Suffix
    if (field.type == CustomFieldType.serial) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: TextFormField(
          controller: _controllers[field.name],
          readOnly: true,
          style: const TextStyle(color: Colors.grey),
          decoration: InputDecoration(
            labelText: field.name,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.tag),
            prefixText: field.serialPrefix,
            suffixText: field.serialSuffix,
            filled: true,
            fillColor: Colors.black12,
          ),
        ),
      );
    }

    final isNum =
        field.type == CustomFieldType.number ||
        field.type == CustomFieldType.currency;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: _controllers[field.name],
        readOnly: isNum,
        onTap: isNum
            ? () {
                setState(() {
                  _activeCalcController = _controllers[field.name];
                  _isKeyboardVisible = true;
                });
              }
            : () => setState(() => _isKeyboardVisible = false),
        decoration: InputDecoration(
          labelText: field.name,
          border: const OutlineInputBorder(),
          prefixText: field.type == CustomFieldType.currency
              ? '${field.currencySymbol} '
              : null,
          prefixIcon: Icon(isNum ? Icons.onetwothree : Icons.text_fields),
        ),
      ),
    );
  }
}
