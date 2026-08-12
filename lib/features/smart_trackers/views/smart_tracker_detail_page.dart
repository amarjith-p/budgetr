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
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';
import '../providers/smart_tracker_provider.dart';
import 'smart_tracker_entry_page.dart';

class SmartTrackerDetailPage extends ConsumerWidget {
  final SmartTrackerTemplate template;

  const SmartTrackerDetailPage({Key? key, required this.template})
    : super(key: key);

  // --- EXCEL COLUMN NAMING LOGIC (0 = A, 1 = B, 26 = AA, etc.) ---
  String _getExcelColumnName(int columnIndex) {
    String columnName = "";
    int temp = columnIndex;
    while (temp >= 0) {
      columnName = String.fromCharCode((temp % 26) + 65) + columnName;
      temp = (temp ~/ 26) - 1;
    }
    return columnName;
  }

  // --- DATA FORMATTER ---
  String _formatValue(TrackerField field, dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';

    try {
      if (field.type == TrackerFieldType.checkbox && value is List) {
        return value.join(', ');
      } else if (field.type == TrackerFieldType.currency) {
        return '${field.currencySymbol ?? ''} $value'.trim();
      } else if (field.type == TrackerFieldType.date) {
        return DateFormat(
          'dd MMM yyyy',
        ).format(DateTime.parse(value.toString()));
      } else if (field.type == TrackerFieldType.toggle) {
        return value == true ? 'Yes' : 'No';
      }
      return value.toString();
    } catch (e) {
      return value.toString();
    }
  }

  // --- CELL REFERENCE TOOLTIP / SNACKBAR ---
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

    // Watch records for THIS specific template
    final recordsAsync = ref.watch(smartTrackerRecordsProvider(template.id));

    // Parse Schema to get Field Names for columns
    final List<dynamic> decodedSchema = jsonDecode(template.schemaJson);
    final fields = decodedSchema.map((e) => TrackerField.fromJson(e)).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: template.name,
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
                template: template,
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
                  'Tap Log Data to create your first entry in ${template.name}.',
              icon: Icons.grid_on_rounded,
            );
          }

          // ASCENDING ORDER (Oldest at the top, Newest at the bottom)
          final ascendingRecords = records.reversed.toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  // Minimized margins for edge-to-edge feel
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
                  // BIDIRECTIONAL SCROLLING
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
                            // --- ROW 0: PURE EXCEL COLUMN LETTERS (A, B, C...) ---
                            TableRow(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withOpacity(isDark ? 0.4 : 0.2),
                              ),
                              children: [
                                _buildCornerCell(theme),
                                ...fields.asMap().entries.map((entry) {
                                  final colLetter = _getExcelColumnName(
                                    entry.key,
                                  );
                                  return _buildAxisLetterCell(theme, colLetter);
                                }).toList(),
                              ],
                            ),

                            // --- ROW 1: TABLE HEADERS / FIELD NAMES (A1, B1, C1...) ---
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
                                ...fields.asMap().entries.map((entry) {
                                  final colLetter = _getExcelColumnName(
                                    entry.key,
                                  );
                                  return _buildFieldHeaderCell(
                                    context,
                                    theme,
                                    entry.value.name,
                                    '${colLetter}1',
                                  );
                                }).toList(),
                              ],
                            ),

                            // --- ROWS 2..N: DATA RECORDS ---
                            ...ascendingRecords.asMap().entries.map((rowEntry) {
                              final record = rowEntry.value;
                              // Data starts at Row 2 mathematically
                              final rowIndex = rowEntry.key + 2;
                              final Map<String, dynamic> dataMap = jsonDecode(
                                record.dataJson,
                              );

                              // ZEBRA STRIPING
                              final isEvenRow = rowIndex % 2 == 0;
                              final rowBgColor = isEvenRow
                                  ? Colors.transparent
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(isDark ? 0.2 : 0.4);

                              return TableRow(
                                decoration: BoxDecoration(color: rowBgColor),
                                children: [
                                  // Row Number Column (2, 3, 4...)
                                  _buildRowNumberCell(
                                    theme,
                                    rowIndex.toString(),
                                  ),

                                  // Data Cells (A2, B2, C2...)
                                  ...fields.asMap().entries.map((colEntry) {
                                    final colIndex = colEntry.key;
                                    final field = colEntry.value;

                                    final colLetter = _getExcelColumnName(
                                      colIndex,
                                    );
                                    final cellRef = '$colLetter$rowIndex';

                                    final rawValue = dataMap[field.id];
                                    final displayValue = _formatValue(
                                      field,
                                      rawValue,
                                    );

                                    return _buildDataCell(
                                      context,
                                      theme,
                                      displayValue,
                                      cellRef,
                                    );
                                  }).toList(),
                                ],
                              );
                            }).toList(),
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

  // --- TABLE CELL BUILDERS ---

  Widget _buildCornerCell(ThemeData theme) {
    return Container(
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
  }

  Widget _buildAxisLetterCell(ThemeData theme, String letter) {
    return Container(
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
          fontSize: 11, // Very small, purely reference
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildFieldHeaderCell(
    BuildContext context,
    ThemeData theme,
    String fieldName,
    String cellRef,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _showCellReference(context, cellRef),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(
              // Noticeable border to separate Header Row 1 from Data Row 2
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
  }

  Widget _buildRowNumberCell(
    ThemeData theme,
    String number, {
    bool isHeaderRow = false,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isHeaderRow
            ? Colors.transparent
            : theme.colorScheme.surfaceContainerHighest.withOpacity(
                isDark ? 0.3 : 0.1,
              ),
        border: Border(
          // THICK RIGHT BORDER defines the vertical axis line
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
  }

  Widget _buildDataCell(
    BuildContext context,
    ThemeData theme,
    String value,
    String cellRef,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: () => _showCellReference(context, cellRef),
        splashColor: theme.colorScheme.primary.withOpacity(0.1),
        highlightColor: theme.colorScheme.primary.withOpacity(0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: Border(
              // Faint grid lines for the data cells
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
  }
}
