import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/components/currency_text.dart';
import '../../models/summary_card_model.dart';
import '../../models/tracker_field_model.dart';
import '../../providers/smart_tracker_provider.dart';
import '../../utils/summary_formula_engine.dart';
import 'summary_card_builder_page.dart';

class SmartTrackerSummaryCard extends ConsumerWidget {
  final SmartTrackerTemplate template;

  const SmartTrackerSummaryCard({Key? key, required this.template})
    : super(key: key);

  Widget _buildSubMetric(
    String label,
    String value,
    String format,
    Color? color,
    String? customSymbol,
    ThemeData theme,
  ) {
    Color finalColor = color ?? theme.colorScheme.onSurface;
    Widget displayWidget;

    if (value == 'Err' || value == '-') {
      displayWidget = Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: finalColor,
        ),
      );
    } else if (format == 'currency') {
      final val = double.tryParse(value) ?? 0.0;
      final sign = val < 0 ? '-' : '';
      final sym = customSymbol ?? '₹';
      // --- FIX: RichText to reduce stroke weight on the currency symbol ---
      displayWidget = RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$sign$sym ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: finalColor.withOpacity(0.8),
              ),
            ),
            TextSpan(
              text: val.abs().toStringAsFixed(2),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: finalColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      );
    } else if (format == 'number') {
      final val = double.tryParse(value) ?? 0.0;
      displayWidget = Text(
        val.toInt().toString(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: finalColor,
          letterSpacing: -0.5,
        ),
      );
    } else if (format == 'percentage') {
      final val = double.tryParse(value) ?? 0.0;
      displayWidget = Text(
        '${val.toStringAsFixed(1)}%',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: finalColor,
        ),
      );
    } else {
      displayWidget = Text(
        value,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: finalColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: displayWidget,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final recordsAsync = ref.watch(smartTrackerRecordsProvider(template.id));
    final templateAsync = ref.watch(
      singleSmartTrackerTemplateProvider(template.id),
    );

    final liveTemplate = templateAsync.asData?.value ?? template;
    final records = recordsAsync.asData?.value ?? [];

    final config = SmartSummaryCardConfig.parse(liveTemplate.summaryWidgetJson);
    final List<dynamic> decodedSchema = jsonDecode(liveTemplate.schemaJson);
    final fields = decodedSchema.map((e) => TrackerField.fromJson(e)).toList();

    // 1. Evaluate Main Metric
    String mainVal = '-';
    double mainNum = 0.0;
    if (config.mainMetric != null && records.isNotEmpty) {
      mainVal = SummaryFormulaEngine.evaluate(
        config.mainMetric!.formula,
        config.mainMetric!.formatAs,
        records,
        fields,
      );
      mainNum = double.tryParse(mainVal) ?? 0.0;
    }

    // 2. Default Empty State
    if (config.mainMetric == null && config.subMetrics.isEmpty) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SummaryCardBuilderPage(template: liveTemplate),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(DesignTokens.spacingLg),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dashboard_customize_rounded,
                color: theme.colorScheme.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'DESIGN SUMMARY CARD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    Color displayColor = config.mainMetric?.colorHex != null
        ? Color(int.parse(config.mainMetric!.colorHex!.replaceAll('#', '0xFF')))
        : theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.all(DesignTokens.spacingMd),
      padding: const EdgeInsets.all(16.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                config.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SummaryCardBuilderPage(template: liveTemplate),
                    ),
                  );
                },
                child: Icon(
                  Icons.edit_rounded,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),

          if (config.mainMetric != null) ...[
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: config.mainMetric!.formatAs == 'currency'
                  // --- FIX: RichText to reduce stroke weight on the currency symbol ---
                  ? RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '${mainNum < 0 ? '-' : ''}${config.mainMetric!.currencySymbol ?? '₹'} ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: displayColor.withOpacity(0.8),
                            ),
                          ),
                          TextSpan(
                            text: mainNum.abs().toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: displayColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : config.mainMetric!.formatAs == 'number'
                  ? Text(
                      mainNum.toInt().toString(),
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: displayColor,
                        letterSpacing: -0.5,
                      ),
                    )
                  : config.mainMetric!.formatAs == 'percentage'
                  ? Text(
                      '${mainNum.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: displayColor,
                        letterSpacing: -0.5,
                      ),
                    )
                  : Text(
                      mainVal,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: displayColor,
                        letterSpacing: -0.5,
                      ),
                    ),
            ),
          ],

          if (config.subMetrics.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),
            IntrinsicHeight(
              child: Row(
                children: config.subMetrics
                    .asMap()
                    .entries
                    .map((entry) {
                      final metric = entry.value;
                      final val = SummaryFormulaEngine.evaluate(
                        metric.formula,
                        metric.formatAs,
                        records,
                        fields,
                      );
                      Color? cColor = metric.colorHex != null
                          ? Color(
                              int.parse(
                                metric.colorHex!.replaceAll('#', '0xFF'),
                              ),
                            )
                          : null;

                      Widget col = Expanded(
                        child: _buildSubMetric(
                          metric.label,
                          val,
                          metric.formatAs,
                          cColor,
                          metric.currencySymbol,
                          theme,
                        ),
                      );

                      if (entry.key < config.subMetrics.length - 1) {
                        return [
                          col,
                          VerticalDivider(
                            width: 16,
                            thickness: 1,
                            color: theme.dividerColor,
                          ),
                        ];
                      }
                      return [col];
                    })
                    .expand((x) => x)
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
