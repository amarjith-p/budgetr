// lib/features/smart_trackers/views/summary_builder/summary_card_builder_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/components/modern_app_bar.dart';
import '../../../../core/components/modern_boxy_button.dart';
import '../../../../core/components/modern_boxy_input.dart';
import '../../../../core/components/modern_boxy_toggle.dart';
import '../../../../core/components/currency_text.dart';
import '../../../../core/theme/design_tokens.dart';

import '../../models/summary_card_model.dart';
import '../../models/tracker_field_model.dart';
import '../../providers/smart_tracker_provider.dart';
import '../../utils/summary_formula_engine.dart';

class SummaryCardBuilderPage extends ConsumerStatefulWidget {
  final SmartTrackerTemplate template;
  const SummaryCardBuilderPage({Key? key, required this.template})
    : super(key: key);

  @override
  ConsumerState<SummaryCardBuilderPage> createState() =>
      _SummaryCardBuilderPageState();
}

class _SummaryCardBuilderPageState
    extends ConsumerState<SummaryCardBuilderPage> {
  late SmartSummaryCardConfig _config;
  late List<TrackerField> _fields;
  final _titleCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _config = SmartSummaryCardConfig.parse(widget.template.summaryWidgetJson);
    _titleCtrl.text = _config.title;
    final List<dynamic> decodedSchema = jsonDecode(widget.template.schemaJson);
    _fields = decodedSchema.map((e) => TrackerField.fromJson(e)).toList();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  void _openVisualEditor(SmartSummaryMetric? existingMetric, bool isMain) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VisualFormulaEditorSheet(
        templateId: widget.template.id,
        existingMetric: existingMetric,
        fields: _fields,
        isMain: isMain,
        onSave: (newMetric) {
          setState(() {
            if (isMain) {
              _config = SmartSummaryCardConfig(
                title: _titleCtrl.text,
                mainMetric: newMetric,
                subMetrics: _config.subMetrics,
              );
            } else {
              List<SmartSummaryMetric> newSubs = List.from(_config.subMetrics);
              if (existingMetric != null) {
                final idx = newSubs.indexWhere(
                  (m) => m.id == existingMetric.id,
                );
                newSubs[idx] = newMetric;
              } else {
                newSubs.add(newMetric);
              }
              _config = SmartSummaryCardConfig(
                title: _titleCtrl.text,
                mainMetric: _config.mainMetric,
                subMetrics: newSubs,
              );
            }
          });
        },
      ),
    );
  }

  Future<void> _saveConfig() async {
    HapticFeedback.selectionClick();
    _config = SmartSummaryCardConfig(
      title: _titleCtrl.text.trim().isEmpty
          ? 'SUMMARY'
          : _titleCtrl.text.trim(),
      mainMetric: _config.mainMetric,
      subMetrics: _config.subMetrics,
    );
    final jsonStr = jsonEncode(_config.toJson());
    await ref
        .read(smartTrackerActionProvider.notifier)
        .saveSummaryLayout(widget.template.id, jsonStr);
    if (mounted) Navigator.pop(context);
  }

  Widget _buildMetricTile(
    SmartSummaryMetric metric,
    ThemeData theme,
    bool isMain,
  ) {
    final cColor = metric.colorHex != null
        ? Color(int.parse(metric.colorHex!.replaceAll('#', '0xFF')))
        : theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.dark ? 0.2 : 0.02,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cColor.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isMain ? Icons.star_rounded : Icons.analytics_rounded,
            color: cColor,
            size: 20,
          ),
        ),
        title: Text(
          metric.label.toUpperCase(),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            metric.formula,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                  0.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                metric.formatAs.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.error,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  if (isMain) {
                    _config = SmartSummaryCardConfig(
                      title: _titleCtrl.text,
                      mainMetric: null,
                      subMetrics: _config.subMetrics,
                    );
                  } else {
                    _config.subMetrics.remove(metric);
                  }
                });
              },
            ),
          ],
        ),
        onTap: () => _openVisualEditor(metric, isMain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Card Builder',
        subtitle: 'SUMMARY DASHBOARD',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              children: [
                ModernBoxyInput(
                  controller: _titleCtrl,
                  labelText: 'Card Title (e.g. PORTFOLIO SUMMARY)',
                ),
                const SizedBox(height: 32),

                // --- MAIN METRIC SECTION ---
                Text(
                  'MAIN METRIC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (_config.mainMetric == null)
                  GestureDetector(
                    onTap: () => _openVisualEditor(null, true),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withOpacity(isDark ? 0.2 : 0.4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.dividerColor,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Main Metric',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildMetricTile(_config.mainMetric!, theme, true),

                const SizedBox(height: 32),

                // --- SUB METRICS SECTION ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SUB METRICS (${_config.subMetrics.length}/3)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (_config.subMetrics.length < 3)
                      GestureDetector(
                        onTap: () => _openVisualEditor(null, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: theme.colorScheme.primary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'ADD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_config.subMetrics.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No sub metrics added yet.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  ..._config.subMetrics.map(
                    (sm) => _buildMetricTile(sm, theme, false),
                  ),
              ],
            ),
          ),

          // --- FIXED FULL WIDTH ACTION BUTTON ---
          // --- ROUNDED FULL WIDTH ACTION BUTTON ---
          Container(
            padding: EdgeInsets.only(
              left: DesignTokens.spacingLg,
              right: DesignTokens.spacingLg,
              top: DesignTokens.spacingMd,
              bottom:
                  DesignTokens.spacingLg +
                  MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                top: BorderSide(color: theme.dividerColor, width: 1.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ModernBoxyButton(
                onPressed: _saveConfig,
                label: 'SAVE DASHBOARD',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// --- PROFESSIONAL TOKEN-BASED VISUAL FORMULA EDITOR (NO TYPING) ---
// ============================================================================
class _VisualFormulaEditorSheet extends ConsumerStatefulWidget {
  final String templateId;
  final SmartSummaryMetric? existingMetric;
  final List<TrackerField> fields;
  final bool isMain;
  final ValueChanged<SmartSummaryMetric> onSave;

  const _VisualFormulaEditorSheet({
    required this.templateId,
    required this.existingMetric,
    required this.fields,
    required this.isMain,
    required this.onSave,
  });

  @override
  ConsumerState<_VisualFormulaEditorSheet> createState() =>
      _VisualFormulaEditorSheetState();
}

class _VisualFormulaEditorSheetState
    extends ConsumerState<_VisualFormulaEditorSheet> {
  final _labelCtrl = TextEditingController();
  List<String> _tokens = [];

  String _format = 'number';
  String _colorHex = '#2EC4B6';
  String _currencySymbol = '₹';
  int _toolboxIndex = 0;

  final List<String> _colors = [
    '#2EC4B6',
    '#E71D36',
    '#FF9F1C',
    '#FFFFFF',
    '#011627',
    '#4361EE',
    '#7209B7',
    '#F72585',
    '#2ECC71',
  ];

  final List<String> _symbols = ['₹', '\$', '€', '£', '¥', 'د.إ'];

  @override
  void initState() {
    super.initState();
    if (widget.existingMetric != null) {
      _labelCtrl.text = widget.existingMetric!.label;
      _format = widget.existingMetric!.formatAs;
      _colorHex = widget.existingMetric!.colorHex ?? '#2EC4B6';
      _currencySymbol = widget.existingMetric!.currencySymbol ?? '₹';

      if (widget.existingMetric!.formula.isNotEmpty) {
        _tokens = [widget.existingMetric!.formula];
      }
    }
    _labelCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  void _appendToken(String token) {
    HapticFeedback.lightImpact();
    setState(() => _tokens.add(token));
  }

  void _backspace() {
    if (_tokens.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _tokens.removeLast());
  }

  void _clearAll() {
    if (_tokens.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _tokens.clear());
  }

  String get _currentFormula => _tokens.join('');

  Widget _buildLivePreview(List<SmartTrackerRecord> records, ThemeData theme) {
    final liveResult = SummaryFormulaEngine.evaluate(
      _currentFormula,
      _format,
      records,
      widget.fields,
    );

    final cColor = Color(int.parse(_colorHex.replaceAll('#', '0xFF')));
    final displayLabel = _labelCtrl.text.isEmpty
        ? 'METRIC LABEL'
        : _labelCtrl.text.toUpperCase();

    Widget displayWidget;
    if (liveResult == 'Err' || liveResult == '-') {
      displayWidget = Text(
        liveResult,
        style: TextStyle(
          fontSize: widget.isMain ? 26 : 13,
          fontWeight: FontWeight.w800,
          color: cColor,
        ),
      );
    } else if (_format == 'number') {
      final val = double.tryParse(liveResult) ?? 0.0;
      displayWidget = Text(
        val.toInt().toString(),
        style: TextStyle(
          fontSize: widget.isMain ? 26 : 13,
          fontWeight: FontWeight.w900,
          color: cColor,
          letterSpacing: -0.5,
        ),
      );
    } else if (_format == 'currency') {
      final val = double.tryParse(liveResult) ?? 0.0;
      final sign = val < 0 ? '-' : '';
      displayWidget = RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$sign$_currencySymbol ',
              style: TextStyle(
                fontSize: widget.isMain ? 16 : 10,
                fontWeight: FontWeight.w600,
                color: cColor.withOpacity(0.8),
              ),
            ),
            TextSpan(
              text: val.abs().toStringAsFixed(2),
              style: TextStyle(
                fontSize: widget.isMain ? 26 : 13,
                fontWeight: FontWeight.w900,
                color: cColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      );
    } else if (_format == 'percentage') {
      final val = double.tryParse(liveResult) ?? 0.0;
      displayWidget = Text(
        '${val.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: widget.isMain ? 26 : 13,
          fontWeight: FontWeight.w900,
          color: cColor,
          letterSpacing: -0.5,
        ),
      );
    } else {
      displayWidget = Text(
        liveResult,
        style: TextStyle(
          fontSize: widget.isMain ? 26 : 13,
          fontWeight: FontWeight.w900,
          color: cColor,
          letterSpacing: -0.5,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: cColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: widget.isMain
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          Text(
            displayLabel,
            style: TextStyle(
              fontSize: widget.isMain ? 10 : 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: widget.isMain ? 8 : 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: widget.isMain ? Alignment.center : Alignment.centerLeft,
            child: displayWidget,
          ),
        ],
      ),
    );
  }

  Widget _buildTokenChip(String label, String token, Color bg, Color fg) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg),
      ),
      backgroundColor: bg,
      side: BorderSide(color: fg.withOpacity(0.3), width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      onPressed: () => _appendToken(token),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final recordsAsync = ref.watch(
      smartTrackerRecordsProvider(widget.templateId),
    );
    final records = recordsAsync.asData?.value ?? [];
    final allFields = widget.fields.toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Configure Metric',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLivePreview(records, theme),
                  const SizedBox(height: 24),

                  ModernBoxyInput(
                    controller: _labelCtrl,
                    labelText: 'Metric Label (e.g. TOTAL RETURN)',
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'FORMULA / VALUE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 60),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(isDark ? 0.3 : 0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _currentFormula.isEmpty
                                ? 'Tap items below to build...'
                                : _currentFormula,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: _currentFormula.isEmpty
                                  ? theme.colorScheme.onSurfaceVariant
                                        .withOpacity(0.5)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (_tokens.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.backspace_rounded, size: 20),
                            color: theme.colorScheme.error,
                            onPressed: _backspace,
                            visualDensity: VisualDensity.compact,
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            color: theme.colorScheme.onSurfaceVariant,
                            onPressed: _clearAll,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ModernBoxyToggle(
                    labels: const ['Data Fields', 'Functions', 'Numpad'],
                    selectedIndex: _toolboxIndex,
                    onSelected: (i) => setState(() => _toolboxIndex = i),
                  ),
                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Container(
                      key: ValueKey(_toolboxIndex),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: _toolboxIndex == 0
                          ? (allFields.isEmpty
                                ? Text(
                                    'No fields available.',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  )
                                : Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: allFields
                                        .map(
                                          (f) => _buildTokenChip(
                                            f.name,
                                            '[${f.name}]',
                                            theme.colorScheme.primary
                                                .withOpacity(0.1),
                                            theme.colorScheme.primary,
                                          ),
                                        )
                                        .toList(),
                                  ))
                          : _toolboxIndex == 1
                          ? Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildTokenChip(
                                  'SUM(',
                                  'SUM(',
                                  Colors.blue.withOpacity(0.1),
                                  Colors.blue,
                                ),
                                _buildTokenChip(
                                  'AVG(',
                                  'AVG(',
                                  Colors.blue.withOpacity(0.1),
                                  Colors.blue,
                                ),
                                _buildTokenChip(
                                  'MAX(',
                                  'MAX(',
                                  Colors.blue.withOpacity(0.1),
                                  Colors.blue,
                                ),
                                _buildTokenChip(
                                  'MIN(',
                                  'MIN(',
                                  Colors.blue.withOpacity(0.1),
                                  Colors.blue,
                                ),
                                _buildTokenChip(
                                  'COUNT(',
                                  'COUNT(',
                                  Colors.purple.withOpacity(0.1),
                                  Colors.purple,
                                ),
                                _buildTokenChip(
                                  'FIRST (Oldest)',
                                  'FIRST(',
                                  Colors.green.withOpacity(0.1),
                                  Colors.green,
                                ),
                                _buildTokenChip(
                                  'LAST (Newest)',
                                  'LAST(',
                                  Colors.green.withOpacity(0.1),
                                  Colors.green,
                                ),
                                _buildTokenChip(
                                  'CELL(Idx, Field)',
                                  'CELL(',
                                  Colors.orange.withOpacity(0.1),
                                  Colors.orange.shade700,
                                ),
                                _buildTokenChip(
                                  'Close Bracket ")"',
                                  ')',
                                  theme.colorScheme.onSurface.withOpacity(0.1),
                                  theme.colorScheme.onSurface,
                                ),
                                _buildTokenChip(
                                  'Comma ","',
                                  ', ',
                                  theme.colorScheme.onSurface.withOpacity(0.1),
                                  theme.colorScheme.onSurface,
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildTokenChip(
                                      ' + ',
                                      ' + ',
                                      theme.colorScheme.surfaceContainerHighest,
                                      theme.colorScheme.onSurface,
                                    ),
                                    _buildTokenChip(
                                      ' - ',
                                      ' - ',
                                      theme.colorScheme.surfaceContainerHighest,
                                      theme.colorScheme.onSurface,
                                    ),
                                    _buildTokenChip(
                                      ' × ',
                                      ' * ',
                                      theme.colorScheme.surfaceContainerHighest,
                                      theme.colorScheme.onSurface,
                                    ),
                                    _buildTokenChip(
                                      ' ÷ ',
                                      ' / ',
                                      theme.colorScheme.surfaceContainerHighest,
                                      theme.colorScheme.onSurface,
                                    ),
                                    _buildTokenChip(
                                      ' ( ',
                                      '(',
                                      theme.colorScheme.surfaceContainerHighest,
                                      theme.colorScheme.onSurface,
                                    ),
                                    _buildTokenChip(
                                      ' ) ',
                                      ')',
                                      theme.colorScheme.surfaceContainerHighest,
                                      theme.colorScheme.onSurface,
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  alignment: WrapAlignment.center,
                                  children:
                                      [
                                        '1',
                                        '2',
                                        '3',
                                        '4',
                                        '5',
                                        '6',
                                        '7',
                                        '8',
                                        '9',
                                        '0',
                                        '.',
                                        '100',
                                      ].map((num) {
                                        return InkWell(
                                          onTap: () => _appendToken(num),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Container(
                                            width: 50,
                                            height: 50,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: theme.dividerColor,
                                              ),
                                            ),
                                            child: Text(
                                              num,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color:
                                                    theme.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'APPEARANCE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ModernBoxyToggle(
                    labels: const ['Number', 'Currency', 'Percent %', 'Text'],
                    selectedIndex: [
                      'number',
                      'currency',
                      'percentage',
                      'text',
                    ].indexOf(_format),
                    onSelected: (i) {
                      setState(() {
                        _format = [
                          'number',
                          'currency',
                          'percentage',
                          'text',
                        ][i];
                      });
                    },
                  ),

                  if (_format == 'currency') ...[
                    const SizedBox(height: 16),
                    Text(
                      'CURRENCY SYMBOL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: _symbols.map((sym) {
                        final isSelected = _currencySymbol == sym;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _currencySymbol = sym);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.3),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.dividerColor,
                              ),
                            ),
                            child: Text(
                              sym,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _colors.map((hex) {
                        final isSelected = _colorHex == hex;
                        final color = Color(
                          int.parse(hex.replaceAll('#', '0xFF')),
                        );
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _colorHex = hex);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? color : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              backgroundColor: color,
                              radius: 18,
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ModernBoxyButton(
                    onPressed: () {
                      if (_labelCtrl.text.isEmpty || _tokens.isEmpty) {
                        HapticFeedback.heavyImpact();
                        return;
                      }
                      HapticFeedback.selectionClick();
                      widget.onSave(
                        SmartSummaryMetric(
                          id: widget.existingMetric?.id ?? const Uuid().v4(),
                          label: _labelCtrl.text.trim(),
                          formula: _currentFormula,
                          formatAs: _format,
                          colorHex: _colorHex,
                          currencySymbol: _format == 'currency'
                              ? _currencySymbol
                              : null,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    label: 'SAVE METRIC',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
