// lib/features/smart_trackers/views/smart_tracker_builder_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';
import '../providers/smart_tracker_provider.dart';
import '../components/add_field_bottom_sheet.dart';
import '../utils/tracker_field_ui_helper.dart';

class SmartTrackerBuilderPage extends ConsumerStatefulWidget {
  final SmartTrackerTemplate? existingTemplate;

  const SmartTrackerBuilderPage({Key? key, this.existingTemplate})
    : super(key: key);

  @override
  ConsumerState<SmartTrackerBuilderPage> createState() =>
      _SmartTrackerBuilderPageState();
}

class _SmartTrackerBuilderPageState
    extends ConsumerState<SmartTrackerBuilderPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  List<TrackerField> _fields = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.existingTemplate?.name ?? '',
    );

    if (widget.existingTemplate != null) {
      final List<dynamic> decoded = jsonDecode(
        widget.existingTemplate!.schemaJson,
      );
      _fields = decoded.map((e) => TrackerField.fromJson(e)).toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _openAddFieldSheet({int? editIndex}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddFieldBottomSheet(
        existingField: editIndex != null ? _fields[editIndex] : null,
        // --- REMOVED existingSchemaFields AS FORMULAS ARE NOW IN THE DETAIL PAGE ---
        onFieldAdded: (field) {
          setState(() {
            if (editIndex != null) {
              _fields[editIndex] = field;
            } else {
              _fields.add(field);
            }
          });
        },
      ),
    );
  }

  void _removeField(int index) {
    HapticFeedback.lightImpact();
    setState(() => _fields.removeAt(index));
  }

  Future<void> _saveTracker() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fields.isEmpty) {
      CustomSnackbars.showError(
        context,
        message: 'Add at least one custom field.',
      );
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.selectionClick();
    final success = await ref
        .read(smartTrackerActionProvider.notifier)
        .saveTrackerTemplate(
          existingId: widget.existingTemplate?.id,
          name: _nameCtrl.text.trim(),
          fields: _fields,
        );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  String _buildMetadataString(TrackerField field) {
    if (field.type == TrackerFieldType.formula) {
      return 'FORMULA: ${field.formulaConfig?.type.toUpperCase() ?? "COMPUTED"}';
    }
    if (field.type == TrackerFieldType.currency) {
      return '${TrackerFieldUIHelper.formatEnumName(field.type.name).toUpperCase()} (${field.currencySymbol})';
    }
    if (field.type == TrackerFieldType.serialNo) {
      String meta = 'AUTO-GENERATED';
      if (field.prefix != null && field.prefix!.isNotEmpty)
        meta += ' | Prefix: ${field.prefix}';
      if (field.suffix != null && field.suffix!.isNotEmpty)
        meta += ' | Suffix: ${field.suffix}';
      return meta;
    }
    return '${TrackerFieldUIHelper.formatEnumName(field.type.name).toUpperCase()} FIELD${field.options != null ? ' • ${field.options!.length} OPTIONS' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingTemplate != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: isEditing ? 'Edit Tracker' : 'Form Builder',
        subtitle: 'SMART TRACKERS',
        leadingIcon: Icons.close_rounded,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ReorderableListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                onReorder: (oldIndex, newIndex) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _fields.removeAt(oldIndex);
                    _fields.insert(newIndex, item);
                  });
                },
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TRACKER CONFIGURATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),
                    ModernBoxyInput(
                      controller: _nameCtrl,
                      labelText: 'Tracker Name (e.g., Warranty Log)',
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: DesignTokens.spacingXl),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CUSTOM SCHEMA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${_fields.length} FIELDS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spacingMd),

                    if (_fields.isEmpty)
                      GestureDetector(
                        onTap: () => _openAddFieldSheet(),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withOpacity(isDark ? 0.2 : 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Schema is Empty',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap here to add your first data field.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                footer: _fields.isNotEmpty
                    ? InkWell(
                        onTap: () => _openAddFieldSheet(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(
                              isDark ? 0.1 : 0.05,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'ADD ANOTHER FIELD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : null,
                children: _fields.asMap().entries.map((entry) {
                  final index = entry.key;
                  final field = entry.value;
                  final typeColor = TrackerFieldUIHelper.getTypeColor(
                    field.type,
                  );

                  return Container(
                    key: ValueKey(field.id),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Container(width: 6, color: typeColor),
                          Expanded(
                            child: InkWell(
                              onTap: () => _openAddFieldSheet(editIndex: index),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: typeColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        TrackerFieldUIHelper.getTypeIcon(
                                          field.type,
                                        ),
                                        color: typeColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            field.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              color:
                                                  theme.colorScheme.onSurface,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _buildMetadataString(field),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5,
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontSize: 9,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline_rounded,
                                        color: theme.colorScheme.error
                                            .withOpacity(0.8),
                                        size: 20,
                                      ),
                                      onPressed: () => _removeField(index),
                                    ),
                                    Icon(
                                      Icons.drag_indicator_rounded,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.3),
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
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
                      onPressed: _saveTracker,
                      label: isEditing ? 'UPDATE TEMPLATE' : 'SAVE TEMPLATE',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
