// lib/features/investments/components/investment_live_valuation_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../settings/providers/investment_settings_provider.dart';
import '../providers/investment_provider.dart';
import 'investment_live_tracker_sheet.dart';

class InvestmentLiveValuationCard extends ConsumerStatefulWidget {
  final Investment investment;

  const InvestmentLiveValuationCard({Key? key, required this.investment})
    : super(key: key);

  @override
  ConsumerState<InvestmentLiveValuationCard> createState() =>
      _InvestmentLiveValuationCardState();
}

class _InvestmentLiveValuationCardState
    extends ConsumerState<InvestmentLiveValuationCard> {
  bool _isRefreshing = false;

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    HapticFeedback.lightImpact();
    setState(() => _isRefreshing = true);

    try {
      final quote = await ref
          .read(investmentActionProvider.notifier)
          .refreshLivePrice(widget.investment.id);
      if (mounted) {
        if (quote != null) {
          CustomSnackbars.showSuccess(
            context,
            message: 'Price updated: ₹${CurrencyFormatter.format(quote.price)}',
          );
        } else {
          CustomSnackbars.showError(
            context,
            message: 'Could not fetch live price. Please try again.',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        CustomSnackbars.showError(
          context,
          message: 'Failed to refresh price. Check connection.',
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _applyLiveValue(double liveValue) async {
    HapticFeedback.mediumImpact();
    final success = await ref
        .read(investmentActionProvider.notifier)
        .applyLiveValueToInvestment(
          investmentId: widget.investment.id,
          liveValue: liveValue,
        );

    if (success && mounted) {
      CustomSnackbars.showSuccess(
        context,
        message:
            'Portfolio value updated to ₹${CurrencyFormatter.format(liveValue)}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Check if the feature is enabled in Settings
    final isEnabled = ref.watch(liveMarketValuationSettingsProvider);
    if (!isEnabled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 2. Watch tracker data for this investment
    final trackerAsync = ref.watch(
      liveTrackerStreamProvider(widget.investment.id),
    );

    return trackerAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tracker) {
        if (tracker == null) {
          return _buildSetupCard(context, theme, isDark);
        }
        return _buildActiveTrackerCard(context, tracker, theme, isDark);
      },
    );
  }

  // --- STATE A: SETUP PROMPT BLOCK ---
  Widget _buildSetupCard(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(isDark ? 0.3 : 0.2),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE MARKET VALUATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track Live NAV & Stock Price',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Link to official free AMFI mutual fund NAV or stock ticker to track real-time valuations and update your portfolio with one tap.',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              InvestmentLiveTrackerSheet.show(
                context,
                investment: widget.investment,
              );
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(
                  isDark ? 0.2 : 0.1,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_link_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SETUP LIVE TRACKING',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STATE B: ACTIVE LIVE TRACKER BLOCK ---
  Widget _buildActiveTrackerCard(
    BuildContext context,
    InvestmentLiveTracker tracker,
    ThemeData theme,
    bool isDark,
  ) {
    final livePrice = tracker.lastPrice ?? 0.0;
    final totalLiveValue = tracker.quantity * livePrice;
    final recordedValue = widget.investment.currentValue;
    final diff = totalLiveValue - recordedValue;
    final isMf = tracker.assetType == 'mutual_fund';
    final hasPrice = tracker.lastPrice != null && tracker.lastPrice! > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(isDark ? 0.35 : 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isMf
                      ? Colors.indigo.shade600
                      : Colors.teal.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isMf ? 'MUTUAL FUND' : 'STOCK / ETF',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'LIVE VALUATION',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              // Refresh Icon
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                  tooltip: 'Refresh price',
                  onPressed: _isRefreshing ? null : _refresh,
                ),
              ),
              // Edit Icon
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  iconSize: 18,
                  icon: const Icon(Icons.tune_rounded),
                  tooltip: 'Configure tracker',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    InvestmentLiveTrackerSheet.show(
                      context,
                      investment: widget.investment,
                      existingTracker: tracker,
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Ticker & Asset Name
          Text(
            tracker.name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${tracker.symbol} • ${tracker.quantity} units',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),

          // Price & Total Live Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMf ? 'LATEST NAV' : 'MARKET PRICE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        hasPrice
                            ? '₹ ${CurrencyFormatter.format(livePrice)}'
                            : 'Fetching...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (tracker.changePercent != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: (tracker.changePercent! >= 0
                                    ? Colors.green.shade600
                                    : theme.colorScheme.error)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${tracker.changePercent! >= 0 ? '+' : ''}${tracker.changePercent!.toStringAsFixed(2)}%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: tracker.changePercent! >= 0
                                  ? Colors.green.shade600
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL LIVE VALUE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  CurrencyText(
                    amount: totalLiveValue,
                    sign: '₹ ',
                    amountStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Comparison vs Recorded Portfolio Value
          if (hasPrice) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (diff.abs() < 1
                        ? theme.colorScheme.surfaceContainerHighest
                        : (diff > 0
                            ? Colors.green.shade600
                            : theme.colorScheme.error))
                    .withOpacity(isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    diff.abs() < 1
                        ? Icons.check_circle_outline_rounded
                        : (diff > 0
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded),
                    size: 14,
                    color: diff.abs() < 1
                        ? theme.colorScheme.onSurfaceVariant
                        : (diff > 0
                            ? Colors.green.shade600
                            : theme.colorScheme.error),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      diff.abs() < 1
                          ? 'Portfolio is fully up-to-date with market'
                          : 'Live value is ₹${CurrencyFormatter.format(diff.abs())} ${diff > 0 ? "higher" : "lower"} than recorded',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: diff.abs() < 1
                            ? theme.colorScheme.onSurfaceVariant
                            : (diff > 0
                                ? Colors.green.shade600
                                : theme.colorScheme.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Quick Action: Update Portfolio Value
          if (hasPrice && !widget.investment.isClosed && diff.abs() >= 1) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _applyLiveValue(totalLiveValue),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'UPDATE VALUE TO ₹${CurrencyFormatter.format(totalLiveValue)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
