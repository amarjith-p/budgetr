// lib/features/smart_trackers/components/smart_tracker_table.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../models/tracker_field_model.dart';
import '../providers/smart_tracker_provider.dart';
import '../views/smart_tracker_entry_page.dart';
import 'add_formula_bottom_sheet.dart';

class SmartTrackerTable extends ConsumerStatefulWidget {
  final SmartTrackerTemplate template;
  final List<SmartTrackerRecord> records;

  const SmartTrackerTable({
    Key? key,
    required this.template,
    required this.records,
  }) : super(key: key);

  @override
  ConsumerState<SmartTrackerTable> createState() => _SmartTrackerTableState();
}

class _SmartTrackerTableState extends ConsumerState<SmartTrackerTable> {
  // --- SORTING STATE ---
  String? _sortColumnId;
  bool _isAscending = true;

  String _getExcelColumnName(int columnIndex) {
    String columnName = "";
    int temp = columnIndex;
    while (temp >= 0) {
      columnName = String.fromCharCode((temp % 26) + 65) + columnName;
      temp = (temp ~/ 26) - 1;
    }
    return columnName;
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

  void _showCellReference(BuildContext context, String cellRef) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(16.0),
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            const Icon(Icons.grid_on_rounded, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cell Reference: $cellRef',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRowActions(
    ThemeData theme,
    SmartTrackerRecord record,
    String rowIndex,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Row $rowIndex Actions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: theme.colorScheme.surface,
                  leading: Icon(
                    Icons.edit_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text(
                    'Edit Record',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SmartTrackerEntryPage(
                          template: widget.template,
                          existingRecordCount: 0,
                          existingRecord: record,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: theme.colorScheme.error.withOpacity(0.1),
                  leading: Icon(
                    Icons.delete_rounded,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Delete Record',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ConfirmationBottomSheet.show(
                      context,
                      title: 'Delete Record?',
                      description:
                          'This will permanently remove Row $rowIndex. This action cannot be undone.',
                      confirmText: 'DELETE',
                      isDestructive: true,
                      onConfirm: () {
                        ref
                            .read(smartTrackerActionProvider.notifier)
                            .deleteTrackerRecord(record.id);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- CORE SORTING ENGINE ---
  void _onSortTapped(TrackerField field) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sortColumnId == field.id) {
        if (_isAscending) {
          _isAscending = false; // Switch to descending
        } else {
          _sortColumnId = null; // 3rd tap removes sorting (Default view)
          _isAscending = true;
        }
      } else {
        _sortColumnId = field.id;
        _isAscending = true;
      }
    });
  }

  List<SmartTrackerRecord> _getSortedRecords(List<TrackerField> fields) {
    if (_sortColumnId == null) {
      // Default: Newest first (chronological entry)
      return widget.records.reversed.toList();
    }

    final field = fields.firstWhere((f) => f.id == _sortColumnId);
    final sortedList = List<SmartTrackerRecord>.from(widget.records);

    sortedList.sort((a, b) {
      final aMap = jsonDecode(a.dataJson);
      final bMap = jsonDecode(b.dataJson);
      final aVal = aMap[_sortColumnId]?.toString() ?? '';
      final bVal = bMap[_sortColumnId]?.toString() ?? '';

      int comparison = 0;

      if (field.type == TrackerFieldType.number ||
          field.type == TrackerFieldType.currency ||
          field.type == TrackerFieldType.formula) {
        final aNum =
            double.tryParse(aVal.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0.0;
        final bNum =
            double.tryParse(bVal.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0.0;
        comparison = aNum.compareTo(bNum);
      } else if (field.type == TrackerFieldType.date) {
        final aDate =
            DateTime.tryParse(aVal) ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate =
            DateTime.tryParse(bVal) ?? DateTime.fromMillisecondsSinceEpoch(0);
        comparison = aDate.compareTo(bDate);
      } else {
        comparison = aVal.toLowerCase().compareTo(bVal.toLowerCase());
      }

      return _isAscending ? comparison : -comparison;
    });

    return sortedList;
  }

  // --- UI BUILDERS ---
  Widget _buildFieldHeaderCell(
    ThemeData theme,
    TrackerField field,
    String cellRef,
  ) {
    final isSorted = _sortColumnId == field.id;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _showCellReference(context, cellRef),
        onTap: () => _onSortTapped(field),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.4),
                width: 2.0,
              ),
              right: BorderSide(
                color: theme.dividerColor.withOpacity(0.3),
                width: 1.0,
              ),
            ),
            color: isSorted
                ? theme.colorScheme.primary.withOpacity(0.1)
                : Colors.transparent, // Highlight sorted column
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                field.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isSorted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  letterSpacing: 0.5,
                ),
              ),
              if (isSorted) ...[
                const SizedBox(width: 8),
                Icon(
                  _isAscending
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ... (Other helper cells remain the same, just extracted into component)
  Widget _buildCornerCell(ThemeData theme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 2.0,
        ),
        right: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 2.0,
        ),
      ),
    ),
    child: Icon(
      Icons.grid_3x3_rounded,
      size: 14,
      color: theme.colorScheme.primary.withOpacity(0.6),
    ),
  );

  Widget _buildAxisLetterCell(ThemeData theme, String letter) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 2.0,
        ),
        right: BorderSide(
          color: theme.dividerColor.withOpacity(0.4),
          width: 1.0,
        ),
      ),
    ),
    child: Text(
      letter,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.primary.withOpacity(0.7),
      ),
    ),
  );

  Widget _buildRowNumberCell(
    ThemeData theme,
    String number, {
    bool isHeaderRow = false,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: isHeaderRow
          ? Colors.transparent
          : theme.colorScheme.surfaceContainerHighest.withOpacity(
              theme.brightness == Brightness.dark ? 0.3 : 0.1,
            ),
      border: Border(
        right: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 2.0,
        ),
        bottom: BorderSide(
          color: isHeaderRow
              ? theme.colorScheme.primary.withOpacity(0.4)
              : theme.dividerColor.withOpacity(0.4),
          width: isHeaderRow ? 2.0 : 1.0,
        ),
      ),
    ),
    child: Text(
      number,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: isHeaderRow
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _buildDataCell(ThemeData theme, String value, String cellRef) =>
      Material(
        color: Colors.transparent,
        child: InkWell(
          onLongPress: () =>
              cellRef.isEmpty ? null : _showCellReference(context, cellRef),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: theme.dividerColor.withOpacity(0.3),
                  width: 1.0,
                ),
                bottom: BorderSide(
                  color: theme.dividerColor.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );

  Widget _buildActionCell(
    ThemeData theme,
    SmartTrackerRecord record,
    String rowIndex,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _showRowActions(theme, record, rowIndex);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: theme.dividerColor.withOpacity(0.3),
              width: 1.0,
            ),
            bottom: BorderSide(
              color: theme.dividerColor.withOpacity(0.3),
              width: 1.0,
            ),
          ),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );

  Widget _buildAggregateCornerCell(ThemeData theme) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border(
        right: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.6),
          width: 2.0,
        ),
      ),
    ),
    child: Text(
      'Σ',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: theme.colorScheme.primary,
      ),
    ),
  );

  Widget _buildAggregateDataCell(
    ThemeData theme,
    String value,
    String aggType,
  ) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      border: Border(
        right: BorderSide(
          color: theme.dividerColor.withOpacity(0.3),
          width: 1.0,
        ),
      ),
    ),
    child: aggType.isEmpty
        ? const SizedBox.shrink()
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                aggType.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<dynamic> decodedSchema = jsonDecode(widget.template.schemaJson);
    final fields = decodedSchema.map((e) => TrackerField.fromJson(e)).toList();

    // Process records through sorting engine
    final processedRecords = _getSortedRecords(fields);

    return Container(
      margin: const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        constrained: false,
        boundaryMargin: const EdgeInsets.all(0),
        minScale: 1.0,
        maxScale: 1.0,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                // --- ROW 0: PURE EXCEL COLUMN LETTERS ---
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withOpacity(isDark ? 0.4 : 0.2),
                  ),
                  children: [
                    _buildCornerCell(theme),
                    ...fields
                        .asMap()
                        .entries
                        .map(
                          (e) => _buildAxisLetterCell(
                            theme,
                            _getExcelColumnName(e.key),
                          ),
                        )
                        .toList(),
                    _buildAxisLetterCell(theme, '+'),
                  ],
                ),

                // --- ROW 1: TABLE HEADERS (Interactive) ---
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(
                      isDark ? 0.2 : 0.1,
                    ),
                  ),
                  children: [
                    _buildRowNumberCell(theme, '1', isHeaderRow: true),
                    ...fields
                        .asMap()
                        .entries
                        .map(
                          (e) => _buildFieldHeaderCell(
                            theme,
                            e.value,
                            '${_getExcelColumnName(e.key)}1',
                          ),
                        )
                        .toList(),

                    // --- + ADD COLUMN BUTTON ---
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => AddFormulaBottomSheet(
                            existingFields: fields,
                            onColumnAdded: (newField) {
                              ref
                                  .read(smartTrackerActionProvider.notifier)
                                  .addFormulaColumn(widget.template, newField);
                            },
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: theme.colorScheme.primary.withOpacity(0.4),
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                // --- ROWS 2..N: DATA RECORDS ---
                ...processedRecords.asMap().entries.map((rowEntry) {
                  final rowIndex = rowEntry.key + 2;
                  final Map<String, dynamic> dataMap = jsonDecode(
                    rowEntry.value.dataJson,
                  );
                  final rowBgColor = (rowIndex % 2 == 0)
                      ? Colors.transparent
                      : theme.colorScheme.surfaceContainerHighest.withOpacity(
                          isDark ? 0.2 : 0.4,
                        );

                  return TableRow(
                    decoration: BoxDecoration(color: rowBgColor),
                    children: [
                      _buildRowNumberCell(theme, rowIndex.toString()),
                      ...fields.asMap().entries.map((colEntry) {
                        return _buildDataCell(
                          theme,
                          _formatValue(
                            colEntry.value,
                            dataMap[colEntry.value.id],
                          ),
                          '${_getExcelColumnName(colEntry.key)}$rowIndex',
                        );
                      }).toList(),
                      _buildActionCell(
                        theme,
                        rowEntry.value,
                        rowIndex.toString(),
                      ),
                    ],
                  );
                }).toList(),

                // --- FOOTER ROW: TABLE AGGREGATES ---
                TableRow(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(
                      isDark ? 0.3 : 0.1,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(0.6),
                        width: 2.0,
                      ),
                    ),
                  ),
                  children: [
                    _buildAggregateCornerCell(theme),
                    ...fields.map((field) {
                      final canAggregate =
                          field.type == TrackerFieldType.number ||
                          field.type == TrackerFieldType.currency ||
                          field.type == TrackerFieldType.formula;
                      if (!canAggregate)
                        return _buildAggregateDataCell(theme, '', '');

                      double sum = 0;
                      double minVal = double.infinity;
                      double maxVal = double.negativeInfinity;
                      int count = 0;

                      for (var record in widget.records) {
                        final dataMap = jsonDecode(record.dataJson);
                        final val = double.tryParse(
                          dataMap[field.id]?.toString() ?? '',
                        );
                        if (val != null) {
                          sum += val;
                          count++;
                          if (val < minVal) minVal = val;
                          if (val > maxVal) maxVal = val;
                        }
                      }

                      String result = '-';
                      if (count > 0 &&
                          field.aggregate != null &&
                          field.aggregate != 'NONE') {
                        if (field.aggregate == 'SUM')
                          result = sum.toStringAsFixed(2);
                        if (field.aggregate == 'AVG')
                          result = (sum / count).toStringAsFixed(2);
                        if (field.aggregate == 'MAX')
                          result = maxVal.toStringAsFixed(2);
                        if (field.aggregate == 'MIN')
                          result = minVal.toStringAsFixed(2);
                        if (field.type == TrackerFieldType.currency)
                          result = '${field.currencySymbol ?? ''} $result'
                              .trim();
                      }

                      return GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          final selected =
                              await GlobalSelectionSheet.showSimple(
                                context: context,
                                title: 'Set Aggregate for ${field.name}',
                                items: ['NONE', 'SUM', 'AVG', 'MAX', 'MIN'],
                                selectedValue: field.aggregate ?? 'NONE',
                              );
                          if (selected != null) {
                            ref
                                .read(smartTrackerActionProvider.notifier)
                                .updateColumnAggregate(
                                  widget.template,
                                  field.id,
                                  selected,
                                );
                          }
                        },
                        child: _buildAggregateDataCell(
                          theme,
                          result,
                          field.aggregate ?? 'Tap to Set',
                        ),
                      );
                    }).toList(),
                    _buildAggregateDataCell(
                      theme,
                      '',
                      '',
                    ), // Empty space under Actions
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
