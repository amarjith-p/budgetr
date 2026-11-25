// lib/features/analytics/components/location_analytics_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/transaction_colors.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/futuristic_loader.dart';
import '../../../core/utils/location_helper.dart';
import '../../transactions/services/transaction_service.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../../transactions/views/transaction_form_page.dart';
import 'analytics_timeframe_selector.dart';

enum _LocationMetricMode { spend, visits }

class _LocationStats {
  final String locationName;
  double expense = 0.0;
  double income = 0.0;
  double transfer = 0.0;
  int visits = 0;
  DateTime? lastVisit;
  double? latitude;
  double? longitude;
  final List<TransactionWithDetails> txs = [];

  _LocationStats({required this.locationName});

  double get totalVolume => expense + income + transfer;
  bool get hasCoordinates => latitude != null && longitude != null;
}

class LocationAnalyticsWidget extends ConsumerStatefulWidget {
  const LocationAnalyticsWidget({super.key});

  @override
  ConsumerState<LocationAnalyticsWidget> createState() =>
      _LocationAnalyticsWidgetState();
}

class _LocationAnalyticsWidgetState
    extends ConsumerState<LocationAnalyticsWidget> {
  TrendTimeframe _timeframe = TrendTimeframe.currentMonth;
  DateTime? _customStart;
  DateTime? _customEnd;

  String _typeFilter = 'Expense'; // 'Expense', 'Income', 'Transfer', 'All'
  _LocationMetricMode _metricMode = _LocationMetricMode.spend;
  int _selectedIndex = 0;
  int _locPage = 0;
  bool _showTransactions = false;
  int _txPage = 0;

  static const int _locsPerPage = 4;
  static const int _txPerPage = 4;

  static const List<Color> _palette = [
    Color(0xFF00B4D8),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
    Color(0xFFEC4899),
    Color(0xFF3B82F6),
    Color(0xFFEF4444),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF6366F1),
  ];

  Future<void> _pickCustomDateRange() async {
    HapticFeedback.selectionClick();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _timeframe = TrendTimeframe.custom;
        _customStart = picked.start;
        _customEnd = DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
        );
        _selectedIndex = 0;
        _locPage = 0;
        _txPage = 0;
      });
    }
  }

  Future<void> _openLocationInMap(_LocationStats loc) async {
    if (!loc.hasCoordinates) return;
    HapticFeedback.lightImpact();
    try {
      await LocationHelper.openMap(loc.latitude!, loc.longitude!);
    } catch (_) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open Maps. Please ensure a browser or maps app is installed.',
            ),
          ),
        );
      }
    }
  }

  (DateTime, DateTime) _resolveDateRange() {
    final now = DateTime.now();
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime start;

    if (_timeframe == TrendTimeframe.custom &&
        _customStart != null &&
        _customEnd != null) {
      start = DateTime(
        _customStart!.year,
        _customStart!.month,
        _customStart!.day,
      );
      end = _customEnd!;
      return (start, end);
    }

    switch (_timeframe) {
      case TrendTimeframe.week:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        break;
      case TrendTimeframe.month:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 29));
        break;
      case TrendTimeframe.currentMonth:
        start = DateTime(now.year, now.month, 1);
        break;
      case TrendTimeframe.lastMonth:
        final targetYear = now.month == 1 ? now.year - 1 : now.year;
        final targetMonth = now.month == 1 ? 12 : now.month - 1;
        start = DateTime(targetYear, targetMonth, 1);
        end = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);
        break;
      case TrendTimeframe.year:
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 364));
        break;
      case TrendTimeframe.allTime:
      default:
        start = DateTime(2000);
        break;
    }
    return (start, end);
  }

  double _amountForStats(_LocationStats stats) {
    switch (_typeFilter) {
      case 'Expense':
        return stats.expense;
      case 'Income':
        return stats.income;
      case 'Transfer':
        return stats.transfer;
      default:
        return stats.totalVolume;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(allTransactionsProvider);

    return transactionsAsync.when(
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: FuturisticLoader(size: 80, label: "LOADING..")),
      ),
      error: (e, st) =>
          SizedBox(height: 180, child: Center(child: Text('Error: $e'))),
      data: (transactions) {
        final (start, end) = _resolveDateRange();

        final Map<String, _LocationStats> locationMap = {};
        int totalVisits = 0;

        for (final txData in transactions) {
          final t = txData.transaction;
          if (t.id.startsWith('LOAN_TX_')) continue;
          if (t.date.isBefore(start) || t.date.isAfter(end)) continue;

          final rawLoc = t.locationName?.trim() ?? '';
          if (rawLoc.isEmpty) continue;
          if (_typeFilter != 'All' && t.type != _typeFilter) continue;

          totalVisits++;
          final key = rawLoc.toLowerCase();
          final stats = locationMap.putIfAbsent(
            key,
            () => _LocationStats(locationName: rawLoc),
          );

          stats.visits++;
          stats.txs.add(txData);
          if (stats.lastVisit == null || t.date.isAfter(stats.lastVisit!)) {
            stats.lastVisit = t.date;
          }
          if (!stats.hasCoordinates &&
              t.latitude != null &&
              t.longitude != null) {
            stats.latitude = t.latitude;
            stats.longitude = t.longitude;
          }

          if (t.type == 'Expense') {
            stats.expense += t.amount;
          } else if (t.type == 'Income') {
            stats.income += t.amount;
          } else if (t.type == 'Transfer') {
            stats.transfer += t.amount;
          }
        }

        final locations = locationMap.values.toList();
        locations.sort((a, b) {
          if (_metricMode == _LocationMetricMode.spend) {
            final cmp = _amountForStats(b).compareTo(_amountForStats(a));
            return cmp != 0 ? cmp : b.visits.compareTo(a.visits);
          } else {
            final cmp = b.visits.compareTo(a.visits);
            return cmp != 0
                ? cmp
                : _amountForStats(b).compareTo(_amountForStats(a));
          }
        });

        final double grandTotalAmount = locations.fold(
          0.0,
          (sum, loc) => sum + _amountForStats(loc),
        );
        final double totalMetric = _metricMode == _LocationMetricMode.spend
            ? grandTotalAmount
            : totalVisits.toDouble();

        final int safeSelected = locations.isNotEmpty
            ? _selectedIndex.clamp(0, locations.length - 1)
            : 0;
        final _LocationStats? activeLoc =
            locations.isNotEmpty ? locations[safeSelected] : null;
        final Color activeColor = _palette[safeSelected % _palette.length];

        // Smart pagination for locations
        final int totalLocPages =
            (locations.length / _locsPerPage).ceil().clamp(1, 999);
        final int safeLocPage = _locPage.clamp(0, totalLocPages - 1);
        final int pageStart = safeLocPage * _locsPerPage;
        final List<_LocationStats> pagedLocations = locations
            .skip(pageStart)
            .take(_locsPerPage)
            .toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.45),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HEADER ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'LOCATION INSIGHTS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: isDark ? 0.35 : 0.55),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactToggle(
                          'SPEND',
                          _metricMode == _LocationMetricMode.spend,
                          theme,
                          isDark,
                          () => setState(() {
                            _metricMode = _LocationMetricMode.spend;
                            _selectedIndex = 0;
                            _locPage = 0;
                          }),
                        ),
                        _buildCompactToggle(
                          'VISITS',
                          _metricMode == _LocationMetricMode.visits,
                          theme,
                          isDark,
                          () => setState(() {
                            _metricMode = _LocationMetricMode.visits;
                            _selectedIndex = 0;
                            _locPage = 0;
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // ── TIMEFRAME SELECTOR ──
              AnalyticsTimeframeSelector(
                selectedTimeframe: _timeframe,
                onSelected: (tf) {
                  setState(() {
                    _timeframe = tf;
                    _selectedIndex = 0;
                    _locPage = 0;
                    _txPage = 0;
                  });
                },
                onCustomTapped: _pickCustomDateRange,
              ),
              const SizedBox(height: 8),

              // ── TYPE FILTER SEGMENTED BAR ──
              _buildTypeSegmentedBar(theme, isDark),
              const SizedBox(height: 12),

              if (locations.isEmpty)
                _buildEmptyState(theme)
              else ...[
                // ── COMPACT KPI + SINGLE UNIFIED PILL CHART ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${locations.length} ${locations.length == 1 ? "PLACE" : "PLACES"} • $totalVisits ${totalVisits == 1 ? "VISIT" : "VISITS"}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: CurrencyText(
                              amount: grandTotalAmount,
                              sign: '₹ ',
                              amountStyle: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.onSurface,
                                letterSpacing: -0.4,
                              ),
                              symbolStyle: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (activeLoc != null)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            activeLoc.locationName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: activeColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Single continuous unified pill bar
                _buildUnifiedPillChart(
                  locations: locations,
                  totalMetric: totalMetric,
                  selectedIndex: safeSelected,
                  theme: theme,
                  isDark: isDark,
                ),
                const SizedBox(height: 10),

                // ── PAGINATED LOCATIONS LIST ──
                ...List.generate(pagedLocations.length, (localIdx) {
                  final globalIdx = pageStart + localIdx;
                  final loc = pagedLocations[localIdx];
                  final color = _palette[globalIdx % _palette.length];
                  final isSelected = globalIdx == safeSelected;
                  final amount = _amountForStats(loc);
                  final val = _metricMode == _LocationMetricMode.spend
                      ? amount
                      : loc.visits.toDouble();
                  final pct = totalMetric > 0
                      ? ((val / totalMetric) * 100).toStringAsFixed(0)
                      : '0';

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedIndex = globalIdx;
                        _txPage = 0;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: isDark ? 0.16 : 0.09)
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: isDark ? 0.14 : 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.45)
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.locationName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${loc.visits} ${loc.visits == 1 ? "visit" : "visits"} • $pct%',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 0,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: CurrencyText(
                                amount: amount,
                                sign: '₹ ',
                                amountStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? color
                                      : theme.colorScheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                                symbolStyle: TextStyle(
                                  fontSize: 9,
                                  color: (isSelected
                                          ? color
                                          : theme.colorScheme.onSurfaceVariant)
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Smart Location Pagination Controls
                if (totalLocPages > 1)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Showing ${pageStart + 1}-${min(pageStart + _locsPerPage, locations.length)} of ${locations.length}',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPageButton(
                              icon: Icons.chevron_left_rounded,
                              enabled: safeLocPage > 0,
                              theme: theme,
                              onTap: () => setState(() {
                                _locPage = safeLocPage - 1;
                                _selectedIndex = _locPage * _locsPerPage;
                                _txPage = 0;
                              }),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '${safeLocPage + 1}/$totalLocPages',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            _buildPageButton(
                              icon: Icons.chevron_right_rounded,
                              enabled: safeLocPage < totalLocPages - 1,
                              theme: theme,
                              onTap: () => setState(() {
                                _locPage = safeLocPage + 1;
                                _selectedIndex = _locPage * _locsPerPage;
                                _txPage = 0;
                              }),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // ── SELECTED LOCATION FOCUS CARD + MAP + LONG-PRESS TXS ──
                if (activeLoc != null) ...[
                  const SizedBox(height: 6),
                  _buildFocusedLocationCard(
                    theme,
                    isDark,
                    activeLoc,
                    activeColor,
                    grandTotalAmount,
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onTap();
            }
          : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: enabled
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildUnifiedPillChart({
    required List<_LocationStats> locations,
    required double totalMetric,
    required int selectedIndex,
    required ThemeData theme,
    required bool isDark,
  }) {
    if (locations.isEmpty || totalMetric <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.35 : 0.5,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Row(
          children: List.generate(locations.length, (i) {
            final loc = locations[i];
            final val = _metricMode == _LocationMetricMode.spend
                ? _amountForStats(loc)
                : loc.visits.toDouble();
            final flexVal = max(1, ((val / totalMetric) * 1000).round());
            final color = _palette[i % _palette.length];
            final isSelected = i == selectedIndex;

            return Expanded(
              flex: flexVal,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedIndex = i;
                    _locPage = i ~/ _locsPerPage;
                    _txPage = 0;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  color: isSelected ? color : color.withValues(alpha: 0.55),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCompactToggle(
    String label,
    bool isSelected,
    ThemeData theme,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 8.5,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            letterSpacing: 0.4,
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSegmentedBar(ThemeData theme, bool isDark) {
    const options = [
      ('Expense', 'EXPENSE'),
      ('Income', 'INCOME'),
      ('Transfer', 'TRANSFER'),
      ('All', 'ALL'),
    ];

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.25 : 0.45,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = _typeFilter == opt.$1;
          final activeColor = opt.$1 == 'All'
              ? theme.colorScheme.primary
              : TransactionColors.getTypeColor(opt.$1, theme);

          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _typeFilter = opt.$1;
                  _selectedIndex = 0;
                  _locPage = 0;
                  _txPage = 0;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.surface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  opt.$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    letterSpacing: 0.4,
                    color: isSelected
                        ? activeColor
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFocusedLocationCard(
    ThemeData theme,
    bool isDark,
    _LocationStats loc,
    Color accentColor,
    double grandTotal,
  ) {
    final amount = _amountForStats(loc);
    final avgPerVisit = loc.visits > 0 ? amount / loc.visits : 0.0;
    final sharePct = grandTotal > 0
        ? ((amount / grandTotal) * 100).toStringAsFixed(1)
        : '0';

    final sortedTxs = [...loc.txs]
      ..sort((a, b) => b.transaction.date.compareTo(a.transaction.date));
    final totalPages = (sortedTxs.length / _txPerPage).ceil().clamp(1, 999);
    final safePage = _txPage.clamp(0, totalPages - 1);
    final pageItems = sortedTxs
        .skip(safePage * _txPerPage)
        .take(_txPerPage)
        .toList();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.2 : 0.35,
        ),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3.5,
                height: 26,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.locationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${loc.visits} ${loc.visits == 1 ? "visit" : "visits"} • $sharePct% • Avg ₹ ${CurrencyFormatter.format(avgPerVisit)}${loc.lastVisit != null ? ' • ${DateFormat('dd MMM').format(loc.lastVisit!)}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (loc.hasCoordinates) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => _openLocationInMap(loc),
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'MAP',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _showTransactions = !_showTransactions);
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _showTransactions
                          ? 'HIDE TRANSACTIONS (HOLD TO EDIT)'
                          : 'VIEW ${sortedTxs.length} TRANSACTIONS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: accentColor,
                      ),
                    ),
                  ),
                  Icon(
                    _showTransactions
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
          if (_showTransactions) ...[
            Divider(height: 8, color: theme.dividerColor.withValues(alpha: 0.4)),
            ...pageItems.map((txData) {
              final t = txData.transaction;
              final typeColor = TransactionColors.getTypeColor(t.type, theme);
              final title = (t.categoryName?.isNotEmpty == true)
                  ? t.categoryName!
                  : (t.subCategory?.isNotEmpty == true
                        ? t.subCategory!
                        : t.type);

              return InkWell(
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          TransactionFormPage(existingTransaction: txData),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: typeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '${DateFormat('dd MMM, hh:mm a').format(t.date)}${(t.notes?.trim().isNotEmpty == true) ? ' • ${t.notes}' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8.5,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 0,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: CurrencyText(
                            amount: t.amount,
                            sign: t.type == 'Expense'
                                ? '-₹ '
                                : (t.type == 'Income' ? '+₹ ' : '₹ '),
                            amountStyle: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: typeColor,
                            ),
                            symbolStyle: TextStyle(
                              fontSize: 8.5,
                              color: typeColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (totalPages > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page ${safePage + 1} of $totalPages',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: safePage > 0
                            ? () => setState(() => _txPage = safePage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: safePage < totalPages - 1
                            ? () => setState(() => _txPage = safePage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 26,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 6),
            Text(
              'NO RECORDED LOCATIONS',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Save locations on your transactions to see where you spend & visit most.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
