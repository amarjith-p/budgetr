// lib/features/smart_trackers/components/smart_tracker_table.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';
import '../providers/smart_tracker_provider.dart';
import '../views/smart_tracker_entry_page.dart';
import '../services/smart_tracker_export_service.dart';
import 'add_formula_bottom_sheet.dart';
import 'smart_tracker_filter_sheet.dart';
import 'smart_tracker_chart_sheet.dart';

class _MatchPosition {
  final int rowIndex;
  final String colId;
  final int occurrenceIndex;
  _MatchPosition(this.rowIndex, this.colId, this.occurrenceIndex);
}

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
  String? _sortColumnId;
  bool _isAscending = true;

  TrackerField? _filterField;
  String _filterOperator = '==';
  List<String> _filterValues = [];
  String _filterSingleValue = '';

  // --- SEARCH STATE ---
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, GlobalKey> _cellKeys = {};
  Timer? _debounce;
  List<_MatchPosition> _matchPositions = [];
  int _currentMatchIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  int _countOccurrences(String text, String q) {
    if (q.isEmpty || text.isEmpty) return 0;
    int count = 0;
    int index = 0;
    while (true) {
      index = text.toLowerCase().indexOf(q, index);
      if (index == -1) break;
      count++;
      index += q.length;
    }
    return count;
  }

  Map<String, String> _calculateAggregates(
    List<TrackerField> fields,
    List<SmartTrackerRecord> records,
  ) {
    Map<String, String> resultMap = {};
    for (var field in fields) {
      final canAggregate =
          field.type == TrackerFieldType.number ||
          field.type == TrackerFieldType.currency ||
          field.type == TrackerFieldType.formula;

      if (!canAggregate ||
          field.aggregate == null ||
          field.aggregate == 'NONE') {
        resultMap[field.id] = '';
        continue;
      }

      double sum = 0;
      double minVal = double.infinity;
      double maxVal = double.negativeInfinity;
      int count = 0;

      for (var record in records) {
        final dataMap = jsonDecode(record.dataJson);
        final val = double.tryParse(dataMap[field.id]?.toString() ?? '');
        if (val != null) {
          sum += val;
          count++;
          if (val < minVal) minVal = val;
          if (val > maxVal) maxVal = val;
        }
      }

      String result = '-';
      if (count > 0) {
        if (field.aggregate == 'SUM') result = sum.toStringAsFixed(2);
        if (field.aggregate == 'AVG') result = (sum / count).toStringAsFixed(2);
        if (field.aggregate == 'MAX') result = maxVal.toStringAsFixed(2);
        if (field.aggregate == 'MIN') result = minVal.toStringAsFixed(2);
        if (field.type == TrackerFieldType.currency) {
          result = '${field.currencySymbol ?? ''} $result'.trim();
        }
      }
      resultMap[field.id] = result;
    }
    return resultMap;
  }

  // --- SEARCH LOGIC ---
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      final q = query.trim().toLowerCase();
      if (q.isEmpty) {
        setState(() {
          _matchPositions.clear();
          _currentMatchIndex = 0;
        });
        return;
      }

      try {
        final List<dynamic> decodedSchema = jsonDecode(
          widget.template.schemaJson,
        );
        final fields = decodedSchema
            .map((e) => TrackerField.fromJson(e as Map<String, dynamic>))
            .toList();
        final processedRecords = _getProcessedRecords(fields);
        final aggregatesMap = _calculateAggregates(fields, processedRecords);

        final List<_MatchPosition> matches = [];

        // 1. Check Header Row (Table Row Index 1)
        int headerOccurrences = _countOccurrences('1', q);
        for (int k = 0; k < headerOccurrences; k++)
          matches.add(_MatchPosition(1, 'row_num', k));

        for (var field in fields) {
          int occ = _countOccurrences(field.name, q);
          for (int k = 0; k < occ; k++)
            matches.add(_MatchPosition(1, field.id, k));
        }

        // 2. Check Data Rows (Table Row Index 2 to N+1)
        for (int i = 0; i < processedRecords.length; i++) {
          final record = processedRecords[i];
          final Map<String, dynamic> dataMap =
              jsonDecode(record.dataJson) as Map<String, dynamic>;
          final rowIndex = i + 2;

          int rowOccurrences = _countOccurrences(rowIndex.toString(), q);
          for (int k = 0; k < rowOccurrences; k++)
            matches.add(_MatchPosition(rowIndex, 'row_num', k));

          for (var field in fields) {
            final formattedVal = _formatValue(field, dataMap[field.id]);
            int occ = _countOccurrences(formattedVal, q);
            for (int k = 0; k < occ; k++)
              matches.add(_MatchPosition(rowIndex, field.id, k));
          }
        }

        // 3. Check Footer Row (Table Row Index N+2)
        final footerIndex = processedRecords.length + 2;
        int footerOccurrences = _countOccurrences('Σ', q);
        for (int k = 0; k < footerOccurrences; k++)
          matches.add(_MatchPosition(footerIndex, 'row_num', k));

        for (var field in fields) {
          final aggType = field.aggregate ?? '';
          final aggVal = aggregatesMap[field.id] ?? '';
          if (aggType.isNotEmpty && aggType != 'NONE') {
            int occType = _countOccurrences(aggType, q);
            for (int k = 0; k < occType; k++)
              matches.add(_MatchPosition(footerIndex, '${field.id}_type', k));

            int occVal = _countOccurrences(aggVal, q);
            for (int k = 0; k < occVal; k++)
              matches.add(_MatchPosition(footerIndex, '${field.id}_val', k));
          }
        }

        setState(() {
          _matchPositions = matches;
          _currentMatchIndex = 0;
        });

        if (_matchPositions.isNotEmpty) {
          _scrollToCurrentMatch();
        }
      } catch (e) {
        debugPrint("Search parsing error: $e");
      }
    });
  }

  void _nextMatch() {
    if (_matchPositions.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _matchPositions.length;
    });
    _scrollToCurrentMatch();
  }

  void _prevMatch() {
    if (_matchPositions.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _matchPositions.length) %
          _matchPositions.length;
    });
    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_matchPositions.isEmpty || !_scrollController.hasClients) return;

    // Execute post-frame to ensure the newly active highlight is fully rendered before scrolling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetMatch = _matchPositions[_currentMatchIndex];
      // Map pseudo-columns (like _type and _val from footer) back to the base cell key
      String baseColId = targetMatch.colId
          .replaceAll('_type', '')
          .replaceAll('_val', '');
      final cellKeyStr = '${targetMatch.rowIndex}_$baseColId';
      final key = _cellKeys[cellKeyStr];

      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          alignment: 0.5, // Centers the target cell perfectly on screen
        );
      }
    });
  }

  Widget _buildHighlightedText(
    String text,
    String query,
    ThemeData theme,
    bool isCurrentCell,
    int activeOccurrenceIndex,
    TextStyle baseStyle,
  ) {
    final q = query.trim();
    if (q.isEmpty) return Text(text, style: baseStyle);

    final lowerText = text.toLowerCase();
    final lowerQuery = q.toLowerCase();

    List<TextSpan> spans = [];
    int start = 0;
    int indexOfMatch = lowerText.indexOf(lowerQuery, start);
    int currentOccurrence = 0;

    if (indexOfMatch == -1) return Text(text, style: baseStyle);

    while (indexOfMatch != -1) {
      if (indexOfMatch > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfMatch)));
      }

      bool isThisSpecificMatch =
          isCurrentCell && currentOccurrence == activeOccurrenceIndex;

      spans.add(
        TextSpan(
          text: text.substring(indexOfMatch, indexOfMatch + lowerQuery.length),
          style: TextStyle(
            backgroundColor: isThisSpecificMatch
                ? Colors.orangeAccent.shade400
                : theme.colorScheme.primary.withOpacity(0.3),
            color: isThisSpecificMatch
                ? Colors.black
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
      );

      start = indexOfMatch + lowerQuery.length;
      indexOfMatch = lowerText.indexOf(lowerQuery, start);
      currentOccurrence++;
    }

    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }

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
    return SmartTrackerExportService.formatValue(field, value);
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
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
                    borderRadius: BorderRadius.circular(8),
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
                    borderRadius: BorderRadius.circular(8),
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

  void _onSortTapped(TrackerField field) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_sortColumnId == field.id) {
        if (_isAscending)
          _isAscending = false;
        else {
          _sortColumnId = null;
          _isAscending = true;
        }
      } else {
        _sortColumnId = field.id;
        _isAscending = true;
      }

      // Clear search to avoid index out of bounds exceptions
      _searchCtrl.clear();
      _matchPositions.clear();
      _currentMatchIndex = 0;
    });
  }

  List<SmartTrackerRecord> _getProcessedRecords(List<TrackerField> fields) {
    var filteredList = widget.records.where((record) {
      if (_filterField == null) return true;
      final dataMap = jsonDecode(record.dataJson);
      final rawVal = dataMap[_filterField!.id];
      final formattedVal = _formatValue(_filterField!, rawVal);

      if (['>', '<', '>=', '<='].contains(_filterOperator)) {
        if (_filterSingleValue.isEmpty) return true;
        double actual =
            double.tryParse(
              rawVal?.toString().replaceAll(RegExp(r'[^0-9.\-]'), '') ?? '',
            ) ??
            0.0;
        double target =
            double.tryParse(
              _filterSingleValue.replaceAll(RegExp(r'[^0-9.\-]'), ''),
            ) ??
            0.0;
        switch (_filterOperator) {
          case '>':
            return actual > target;
          case '<':
            return actual < target;
          case '>=':
            return actual >= target;
          case '<=':
            return actual <= target;
        }
      } else if ([
        'Contains',
        'Starts With',
        'Ends With',
      ].contains(_filterOperator)) {
        if (_filterSingleValue.isEmpty) return true;
        final actualStr = formattedVal.toLowerCase();
        final targetStr = _filterSingleValue.toLowerCase();
        switch (_filterOperator) {
          case 'Contains':
            return actualStr.contains(targetStr);
          case 'Starts With':
            return actualStr.startsWith(targetStr);
          case 'Ends With':
            return actualStr.endsWith(targetStr);
        }
      } else {
        if (_filterValues.isEmpty) return true;
        bool isMatch = _filterValues.contains(formattedVal);
        return _filterOperator == '==' ? isMatch : !isMatch;
      }
      return true;
    }).toList();

    if (_sortColumnId == null) return filteredList.reversed.toList();

    final field = fields.firstWhere((f) => f.id == _sortColumnId);
    filteredList.sort((a, b) {
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

    return filteredList;
  }

  Widget _buildFieldHeaderCell(
    ThemeData theme,
    TrackerField field,
    String cellRef,
    bool isCurrentCell,
    int activeOccurrenceIndex, {
    Key? key,
  }) {
    final isSorted = _sortColumnId == field.id;
    return Material(
      key: key,
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
                : Colors.transparent,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHighlightedText(
                field.name,
                _searchCtrl.text,
                theme,
                isCurrentCell,
                activeOccurrenceIndex,
                TextStyle(
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
    bool isCurrentCell = false,
    int activeOccurrenceIndex = -1,
    Key? key,
  }) => Container(
    key: key,
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
    child: _buildHighlightedText(
      number,
      _searchCtrl.text,
      theme,
      isCurrentCell,
      activeOccurrenceIndex,
      TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: isHeaderRow
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _buildDataCell(
    ThemeData theme,
    String value,
    String cellRef,
    bool isCurrentCell,
    int activeOccurrenceIndex, {
    Key? key,
  }) => Material(
    key: key,
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
        child: _buildHighlightedText(
          value,
          _searchCtrl.text,
          theme,
          isCurrentCell,
          activeOccurrenceIndex,
          TextStyle(
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

  Widget _buildAggregateCornerCell(
    ThemeData theme,
    bool isCurrentCell,
    int activeOccIndex, {
    Key? key,
  }) => Container(
    key: key,
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
    child: _buildHighlightedText(
      'Σ',
      _searchCtrl.text,
      theme,
      isCurrentCell,
      activeOccIndex,
      TextStyle(
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
    bool isCurrentCellType,
    int activeOccType,
    bool isCurrentCellVal,
    int activeOccVal, {
    Key? key,
  }) => Container(
    key: key,
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
              _buildHighlightedText(
                aggType.toUpperCase(),
                _searchCtrl.text,
                theme,
                isCurrentCellType,
                activeOccType,
                TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              _buildHighlightedText(
                value,
                _searchCtrl.text,
                theme,
                isCurrentCellVal,
                activeOccVal,
                TextStyle(
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

    final processedRecords = _getProcessedRecords(fields);
    final aggregatesMap = _calculateAggregates(fields, processedRecords);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // --- INTELLIGENT COMPACT SEARCH BAR ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            height: 48,
            padding: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor, width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search keyword...',
                      border: InputBorder.none,
                      isDense: true,
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.5,
                        ),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (_searchCtrl.text.isNotEmpty) ...[
                  if (_matchPositions.isNotEmpty) ...[
                    Text(
                      '${_currentMatchIndex + 1}/${_matchPositions.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _prevMatch,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2.0,
                          vertical: 6.0,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_up_rounded,
                          size: 22,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _nextMatch,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 2.0,
                          vertical: 6.0,
                        ),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: theme.dividerColor.withOpacity(0.5),
                    ),
                  ],
                  InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _searchCtrl.clear();
                      _onSearchChanged('');
                      FocusScope.of(context).unfocus();
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 6.0,
                      ),
                      child: Icon(
                        Icons.cancel_rounded,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.6,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // --- TOOLBAR (EXPORT, CHART, FILTER) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Text(
                  '${processedRecords.length} ROWS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),

                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    SmartTrackerExportUI.show(
                      context,
                      template: widget.template,
                      fields: fields,
                      records: processedRecords,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amberAccent.shade400.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.amberAccent.shade400.withOpacity(0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.file_download_rounded,
                          size: 14,
                          color: Colors.amberAccent.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'EXPORT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.amberAccent.shade700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    SmartTrackerChartSheet.show(
                      context,
                      template: widget.template,
                      records: processedRecords,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CHART',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                if (_filterField != null) ...[
                  GestureDetector(
                    onTap: () {
                      SmartTrackerFilterSheet.show(
                        context,
                        fields: fields,
                        records: widget.records,
                        initialField: _filterField,
                        initialOperator: _filterOperator,
                        initialValues: _filterValues,
                        initialSingleValue: _filterSingleValue,
                        onApplyFilter: (f, op, values, singleVal) =>
                            setState(() {
                              _filterField = f;
                              _filterOperator = op;
                              _filterValues = values;
                              _filterSingleValue = singleVal;

                              // Clear search when filters are modified
                              _searchCtrl.clear();
                              _matchPositions.clear();
                              _currentMatchIndex = 0;
                            }),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt_rounded,
                            size: 12,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_filterField!.name} $_filterOperator ${['==', '!='].contains(_filterOperator) ? '${_filterValues.length} Vals' : _filterSingleValue}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _filterField = null;
                                _filterValues = [];
                                _filterSingleValue = '';

                                // Clear search when filters are cleared
                                _searchCtrl.clear();
                                _matchPositions.clear();
                                _currentMatchIndex = 0;
                              });
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  GestureDetector(
                    onTap: () {
                      SmartTrackerFilterSheet.show(
                        context,
                        fields: fields,
                        records: widget.records,
                        initialField: null,
                        initialOperator: '==',
                        initialValues: [],
                        initialSingleValue: '',
                        onApplyFilter: (f, op, values, singleVal) =>
                            setState(() {
                              _filterField = f;
                              _filterOperator = op;
                              _filterValues = values;
                              _filterSingleValue = singleVal;

                              // Clear search when filters are applied
                              _searchCtrl.clear();
                              _matchPositions.clear();
                              _currentMatchIndex = 0;
                            }),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'FILTER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // --- THE TABLE ---
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(
              left: 4,
              right: 4,
              bottom: 24,
              top: 4,
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
            // Removed InteractiveViewer to fix gesture interference
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
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

                    // --- HEADER ROW (INDEX 1) ---
                    TableRow(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withOpacity(
                          isDark ? 0.2 : 0.1,
                        ),
                      ),
                      children: [
                        _buildRowNumberCell(
                          theme,
                          '1',
                          isHeaderRow: true,
                          isCurrentCell:
                              _matchPositions.isNotEmpty &&
                              _matchPositions[_currentMatchIndex].rowIndex ==
                                  1 &&
                              _matchPositions[_currentMatchIndex].colId ==
                                  'row_num',
                          activeOccurrenceIndex:
                              _matchPositions.isNotEmpty &&
                                  _matchPositions[_currentMatchIndex]
                                          .rowIndex ==
                                      1 &&
                                  _matchPositions[_currentMatchIndex].colId ==
                                      'row_num'
                              ? _matchPositions[_currentMatchIndex]
                                    .occurrenceIndex
                              : -1,
                          key: _cellKeys.putIfAbsent(
                            '1_row_num',
                            () => GlobalKey(),
                          ),
                        ),
                        ...fields.map((f) {
                          final isCurrentCell =
                              _matchPositions.isNotEmpty &&
                              _matchPositions[_currentMatchIndex].rowIndex ==
                                  1 &&
                              _matchPositions[_currentMatchIndex].colId == f.id;
                          return _buildFieldHeaderCell(
                            theme,
                            f,
                            '${_getExcelColumnName(fields.indexOf(f))}1',
                            isCurrentCell,
                            isCurrentCell
                                ? _matchPositions[_currentMatchIndex]
                                      .occurrenceIndex
                                : -1,
                            key: _cellKeys.putIfAbsent(
                              '1_${f.id}',
                              () => GlobalKey(),
                            ),
                          );
                        }).toList(),
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
                                      .addFormulaColumn(
                                        widget.template,
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
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.4,
                                  ),
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
                    if (processedRecords.isEmpty)
                      TableRow(
                        children: [
                          _buildRowNumberCell(theme, '-'),
                          Container(
                            padding: const EdgeInsets.all(24),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No results match your filter.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ...List.generate(
                            fields.length - 1,
                            (index) => const SizedBox.shrink(),
                          ),
                          const SizedBox.shrink(),
                        ],
                      )
                    else
                      // --- DATA ROWS (INDEX 2 to N+1) ---
                      ...processedRecords.asMap().entries.map((rowEntry) {
                        final listIndex = rowEntry.key;
                        final rowIndex = listIndex + 2;
                        final Map<String, dynamic> dataMap =
                            jsonDecode(rowEntry.value.dataJson)
                                as Map<String, dynamic>;

                        final isMatchInRow = _matchPositions.any(
                          (m) => m.rowIndex == rowIndex,
                        );
                        final isCurrentMatchInRow =
                            _matchPositions.isNotEmpty &&
                            _matchPositions[_currentMatchIndex].rowIndex ==
                                rowIndex;

                        final rowBgColor = isCurrentMatchInRow
                            ? theme.colorScheme.primary.withOpacity(
                                0.1,
                              ) // Subtle highlight for the active row
                            : isMatchInRow
                            ? theme.colorScheme.primary.withOpacity(
                                0.03,
                              ) // Very subtle highlight for rows with matches
                            : (rowIndex % 2 == 0)
                            ? Colors.transparent
                            : theme.colorScheme.surfaceContainerHighest
                                  .withOpacity(isDark ? 0.2 : 0.4);

                        return TableRow(
                          decoration: BoxDecoration(color: rowBgColor),
                          children: [
                            _buildRowNumberCell(
                              theme,
                              rowIndex.toString(),
                              isCurrentCell:
                                  _matchPositions.isNotEmpty &&
                                  _matchPositions[_currentMatchIndex]
                                          .rowIndex ==
                                      rowIndex &&
                                  _matchPositions[_currentMatchIndex].colId ==
                                      'row_num',
                              activeOccurrenceIndex:
                                  _matchPositions.isNotEmpty &&
                                      _matchPositions[_currentMatchIndex]
                                              .rowIndex ==
                                          rowIndex &&
                                      _matchPositions[_currentMatchIndex]
                                              .colId ==
                                          'row_num'
                                  ? _matchPositions[_currentMatchIndex]
                                        .occurrenceIndex
                                  : -1,
                              key: _cellKeys.putIfAbsent(
                                '${rowIndex}_row_num',
                                () => GlobalKey(),
                              ),
                            ),
                            ...fields.asMap().entries.map((colEntry) {
                              final field = colEntry.value;
                              final isCurrentCell =
                                  _matchPositions.isNotEmpty &&
                                  _matchPositions[_currentMatchIndex]
                                          .rowIndex ==
                                      rowIndex &&
                                  _matchPositions[_currentMatchIndex].colId ==
                                      field.id;

                              return _buildDataCell(
                                theme,
                                _formatValue(field, dataMap[field.id]),
                                '${_getExcelColumnName(colEntry.key)}$rowIndex',
                                isCurrentCell,
                                isCurrentCell
                                    ? _matchPositions[_currentMatchIndex]
                                          .occurrenceIndex
                                    : -1,
                                key: _cellKeys.putIfAbsent(
                                  '${rowIndex}_${field.id}',
                                  () => GlobalKey(),
                                ),
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

                    // --- FOOTER AGGREGATE ROW (INDEX N+2) ---
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
                        _buildAggregateCornerCell(
                          theme,
                          _matchPositions.isNotEmpty &&
                              _matchPositions[_currentMatchIndex].rowIndex ==
                                  processedRecords.length + 2 &&
                              _matchPositions[_currentMatchIndex].colId ==
                                  'row_num',
                          _matchPositions.isNotEmpty &&
                                  _matchPositions[_currentMatchIndex]
                                          .rowIndex ==
                                      processedRecords.length + 2 &&
                                  _matchPositions[_currentMatchIndex].colId ==
                                      'row_num'
                              ? _matchPositions[_currentMatchIndex]
                                    .occurrenceIndex
                              : -1,
                          key: _cellKeys.putIfAbsent(
                            '${processedRecords.length + 2}_row_num',
                            () => GlobalKey(),
                          ),
                        ),
                        ...fields.map((field) {
                          String result = aggregatesMap[field.id] ?? '';
                          String aggType = field.aggregate ?? '';

                          if (result.isEmpty && aggType != 'NONE') {
                            return _buildAggregateDataCell(
                              theme,
                              '',
                              '',
                              false,
                              -1,
                              false,
                              -1,
                            );
                          }

                          final isCurrentCellType =
                              _matchPositions.isNotEmpty &&
                              _matchPositions[_currentMatchIndex].rowIndex ==
                                  processedRecords.length + 2 &&
                              _matchPositions[_currentMatchIndex].colId ==
                                  '${field.id}_type';
                          final isCurrentCellVal =
                              _matchPositions.isNotEmpty &&
                              _matchPositions[_currentMatchIndex].rowIndex ==
                                  processedRecords.length + 2 &&
                              _matchPositions[_currentMatchIndex].colId ==
                                  '${field.id}_val';

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
                              aggType == 'NONE' ? 'Tap to Set' : aggType,
                              isCurrentCellType,
                              isCurrentCellType
                                  ? _matchPositions[_currentMatchIndex]
                                        .occurrenceIndex
                                  : -1,
                              isCurrentCellVal,
                              isCurrentCellVal
                                  ? _matchPositions[_currentMatchIndex]
                                        .occurrenceIndex
                                  : -1,
                              key: _cellKeys.putIfAbsent(
                                '${processedRecords.length + 2}_${field.id}',
                                () => GlobalKey(),
                              ),
                            ),
                          );
                        }).toList(),
                        _buildAggregateDataCell(
                          theme,
                          '',
                          '',
                          false,
                          -1,
                          false,
                          -1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
