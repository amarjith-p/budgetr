// lib/features/smart_trackers/components/smart_tracker_chart_sheet.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/global_selection_sheet.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/theme/design_tokens.dart';
import '../models/tracker_field_model.dart';
import 'modern_smart_chart.dart';

class SmartTrackerChartSheet extends StatefulWidget {
  final SmartTrackerTemplate template;
  final List<SmartTrackerRecord> records;

  const SmartTrackerChartSheet({
    Key? key,
    required this.template,
    required this.records,
  }) : super(key: key);

  static void show(
    BuildContext context, {
    required SmartTrackerTemplate template,
    required List<SmartTrackerRecord> records,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          SmartTrackerChartSheet(template: template, records: records),
    );
  }

  @override
  State<SmartTrackerChartSheet> createState() => _SmartTrackerChartSheetState();
}

class _SmartTrackerChartSheetState extends State<SmartTrackerChartSheet> {
  late List<TrackerField> _fields;

  TrackerField? _xAxisField;
  TrackerField? _yAxisField;
  bool _isLineChart = false;

  @override
  void initState() {
    super.initState();
    final List<dynamic> decoded = jsonDecode(widget.template.schemaJson);
    _fields = decoded.map((e) => TrackerField.fromJson(e)).toList();

    _xAxisField =
        _fields
            .where(
              (f) =>
                  f.type == TrackerFieldType.text ||
                  f.type == TrackerFieldType.date ||
                  f.type == TrackerFieldType.dropdown,
            )
            .firstOrNull ??
        _fields.firstOrNull;
    _yAxisField = _fields
        .where(
          (f) =>
              f.type == TrackerFieldType.number ||
              f.type == TrackerFieldType.currency ||
              f.type == TrackerFieldType.formula,
        )
        .firstOrNull;
  }

  String _formatValue(TrackerField field, dynamic value) {
    if (value == null || value.toString().isEmpty) return 'Empty';
    if (field.type == TrackerFieldType.date)
      return DateFormat('dd MMM').format(DateTime.parse(value.toString()));
    if (field.type == TrackerFieldType.toggle)
      return value == true ? 'Yes' : 'No';
    return value.toString();
  }

  double _parseNumber(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(
          value.toString().replaceAll(RegExp(r'[^0-9.\-]'), ''),
        ) ??
        0.0;
  }

  List<MapEntry<String, double>> _getAggregatedData() {
    if (_xAxisField == null || _yAxisField == null || widget.records.isEmpty)
      return [];

    Map<String, double> aggregated = {};

    for (var record in widget.records) {
      final data = jsonDecode(record.dataJson);
      final rawX = data[_xAxisField!.id];
      final rawY = data[_yAxisField!.id];

      String xLabel = _formatValue(_xAxisField!, rawX);
      double yValue = _parseNumber(rawY);

      aggregated[xLabel] = (aggregated[xLabel] ?? 0) + yValue;
    }

    var entries = aggregated.entries.toList();
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  Future<void> _selectAxis(bool isXAxis) async {
    HapticFeedback.lightImpact();

    List<TrackerField> validFields;
    if (isXAxis) {
      validFields = _fields;
    } else {
      validFields = _fields
          .where(
            (f) =>
                f.type == TrackerFieldType.number ||
                f.type == TrackerFieldType.currency ||
                f.type == TrackerFieldType.formula,
          )
          .toList();
    }

    final selectedName = await GlobalSelectionSheet.showSimple(
      context: context,
      title: isXAxis ? 'Select X-Axis (Labels)' : 'Select Y-Axis (Values)',
      items: validFields.map((f) => f.name).toList(),
      selectedValue: (isXAxis ? _xAxisField?.name : _yAxisField?.name) ?? '',
    );

    if (selectedName != null && mounted) {
      setState(() {
        if (isXAxis) {
          _xAxisField = validFields.firstWhere((f) => f.name == selectedName);
        } else {
          _yAxisField = validFields.firstWhere((f) => f.name == selectedName);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chartData = _getAggregatedData();
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      // --- FIXED: Strictly 60% of Screen Height ---
      height: screenHeight * 0.70,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset > 0 ? bottomInset : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- DRAG HANDLE & TITLE ---
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 16, bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Visual Analytics',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),

          // --- SCROLLABLE CONTENT ---
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // --- CONFIGURATION PANEL ---
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'X-AXIS (LABELS)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _selectAxis(true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _xAxisField?.name ?? 'Select...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Y-AXIS (VALUES)',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => _selectAxis(false),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: theme.dividerColor,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _yAxisField?.name ?? 'Select...',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color:
                                                    theme.colorScheme.primary,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: theme.colorScheme.primary,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ModernBoxyToggle(
                          labels: const ['Bar Chart', 'Line Chart'],
                          selectedIndex: _isLineChart ? 1 : 0,
                          onSelected: (i) =>
                              setState(() => _isLineChart = i == 1),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- CHART DISPLAY AREA ---
                  _yAxisField == null
                      ? Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Center(
                            child: Text(
                              'Select a numeric field for the Y-Axis.',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : ModernSmartChart(
                          data: chartData,
                          isLineChart: _isLineChart,
                          yAxisPrefix: _yAxisField!.currencySymbol ?? '',
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
