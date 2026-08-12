// lib/features/smart_trackers/views/smart_tracker_detail_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';
import '../providers/smart_tracker_provider.dart';
import '../components/add_formula_bottom_sheet.dart';
import 'smart_tracker_entry_page.dart';

class SmartTrackerDetailPage extends ConsumerWidget {
  final SmartTrackerTemplate template;

  const SmartTrackerDetailPage({Key? key, required this.template})
    : super(key: key);

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final recordsAsync = ref.watch(smartTrackerRecordsProvider(template.id));

    // --- FIXED: INSTANT LIVE WATCHER FOR SCHEMA CHANGES ---
    final templateAsync = ref.watch(
      singleSmartTrackerTemplateProvider(template.id),
    );
    final liveTemplate = templateAsync.asData?.value ?? template;

    final List<dynamic> decodedSchema = jsonDecode(liveTemplate.schemaJson);
    final fields = decodedSchema.map((e) => TrackerField.fromJson(e)).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: liveTemplate.name,
        subtitle: 'SMART TRACKER LEDGER',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          final count = recordsAsync.asData?.value.length ?? 0;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SmartTrackerEntryPage(
                template: liveTemplate,
                existingRecordCount: count,
              ),
            ),
          );
        },
        icon: Icons.add_rounded,
        label: 'Log Data',
      ),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (records) {
          if (records.isEmpty) {
            return PremiumEmptyState(
              title: 'Ledger is Empty',
              subtitle:
                  'Tap Log Data to create your first entry in ${liveTemplate.name}.',
              icon: Icons.grid_on_rounded,
            );
          }

          final ascendingRecords = records.reversed.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 4,
                    right: 4,
                    top: 8,
                    bottom: 24,
                  ),
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
                          defaultVerticalAlignment:
                              TableCellVerticalAlignment.middle,
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
                            // --- ROW 1: TABLE HEADERS ---
                            TableRow(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(isDark ? 0.2 : 0.1),
                              ),
                              children: [
                                _buildRowNumberCell(
                                  theme,
                                  '1',
                                  isHeaderRow: true,
                                ),
                                ...fields
                                    .asMap()
                                    .entries
                                    .map(
                                      (e) => _buildFieldHeaderCell(
                                        context,
                                        theme,
                                        e.value.name,
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
                                              .read(
                                                smartTrackerActionProvider
                                                    .notifier,
                                              )
                                              .addFormulaColumn(
                                                liveTemplate,
                                                newField,
                                              );
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
                                          color: theme.colorScheme.primary
                                              .withOpacity(0.4),
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
                            ...ascendingRecords.asMap().entries.map((rowEntry) {
                              final rowIndex = rowEntry.key + 2;
                              final Map<String, dynamic> dataMap = jsonDecode(
                                rowEntry.value.dataJson,
                              );
                              final rowBgColor = (rowIndex % 2 == 0)
                                  ? Colors.transparent
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(isDark ? 0.2 : 0.4);

                              return TableRow(
                                decoration: BoxDecoration(color: rowBgColor),
                                children: [
                                  _buildRowNumberCell(
                                    theme,
                                    rowIndex.toString(),
                                  ),
                                  ...fields.asMap().entries.map((colEntry) {
                                    return _buildDataCell(
                                      context,
                                      theme,
                                      _formatValue(
                                        colEntry.value,
                                        dataMap[colEntry.value.id],
                                      ),
                                      '${_getExcelColumnName(colEntry.key)}$rowIndex',
                                    );
                                  }).toList(),
                                  _buildDataCell(context, theme, '', ''),
                                ],
                              );
                            }).toList(),

                            // --- FOOTER ROW: TABLE AGGREGATES ---
                            TableRow(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withOpacity(isDark ? 0.3 : 0.1),
                                border: Border(
                                  top: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.6),
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
                                    return _buildAggregateDataCell(
                                      theme,
                                      '',
                                      '',
                                    );

                                  double sum = 0;
                                  double minVal = double.infinity;
                                  double maxVal = double.negativeInfinity;
                                  int count = 0;

                                  for (var record in ascendingRecords) {
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
                                      result =
                                          '${field.currencySymbol ?? ''} $result'
                                              .trim();
                                  }

                                  return GestureDetector(
                                    onTap: () async {
                                      HapticFeedback.lightImpact();
                                      final selected =
                                          await GlobalSelectionSheet.showSimple(
                                            context: context,
                                            title:
                                                'Set Aggregate for ${field.name}',
                                            items: [
                                              'NONE',
                                              'SUM',
                                              'AVG',
                                              'MAX',
                                              'MIN',
                                            ],
                                            selectedValue:
                                                field.aggregate ?? 'NONE',
                                          );

                                      if (selected != null) {
                                        ref
                                            .read(
                                              smartTrackerActionProvider
                                                  .notifier,
                                            )
                                            .updateColumnAggregate(
                                              liveTemplate,
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
                                _buildAggregateDataCell(theme, '', ''),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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

  Widget _buildFieldHeaderCell(
    BuildContext context,
    ThemeData theme,
    String fieldName,
    String cellRef,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      onLongPress: () => _showCellReference(context, cellRef),
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
        ),
        child: Text(
          fieldName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.5,
          ),
        ),
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

  Widget _buildDataCell(
    BuildContext context,
    ThemeData theme,
    String value,
    String cellRef,
  ) => Material(
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
}
