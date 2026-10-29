// lib/features/investments/components/investment_live_tracker_sheet.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../models/market_data_models.dart';
import '../providers/investment_provider.dart';

class InvestmentLiveTrackerSheet extends ConsumerStatefulWidget {
  final Investment investment;
  final InvestmentLiveTracker? existingTracker;

  const InvestmentLiveTrackerSheet({
    super.key,
    required this.investment,
    this.existingTracker,
  });

  static Future<void> show(
    BuildContext context, {
    required Investment investment,
    InvestmentLiveTracker? existingTracker,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InvestmentLiveTrackerSheet(
        investment: investment,
        existingTracker: existingTracker,
      ),
    );
  }

  @override
  ConsumerState<InvestmentLiveTrackerSheet> createState() =>
      _InvestmentLiveTrackerSheetState();
}

class _InvestmentLiveTrackerSheetState
    extends ConsumerState<InvestmentLiveTrackerSheet> {
  late String _assetType; // 'mutual_fund' or 'stock'

  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  Timer? _debounceTimer;
  bool _isSearching = false;
  List<MarketSearchResult> _searchResults = [];

  MarketSearchResult? _selectedItem;
  double? _livePrice;
  double? _changePercent;
  bool _isFetchingPrice = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTracker;
    if (existing != null) {
      _assetType = existing.assetType;
      _qtyCtrl.text = existing.quantity.toString();
      _selectedItem = MarketSearchResult(
        symbol: existing.symbol,
        name: existing.name,
        type: existing.assetType,
        currency: existing.currency,
      );
      _livePrice = existing.lastPrice;
      _changePercent = existing.changePercent;
    } else {
      _assetType = widget.investment.type == 'Mutual Fund'
          ? 'mutual_fund'
          : 'stock';
      if (widget.investment.units != null && widget.investment.units! > 0) {
        _qtyCtrl.text = widget.investment.units!.toString();
      } else {
        _qtyCtrl.text = '1';
      }
      // Pre-fill search with investment name for user convenience
      _searchCtrl.text = widget.investment.name;
      _performSearch(widget.investment.name);
    }

    if (_selectedItem != null && _livePrice == null) {
      _fetchQuoteForSelected();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      if (mounted) {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
      return;
    }

    setState(() => _isSearching = true);
    final service = ref.read(marketDataServiceProvider);

    List<MarketSearchResult> results;
    if (_assetType == 'mutual_fund') {
      results = await service.searchMutualFunds(q);
    } else {
      results = await service.searchStocks(q);
    }

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _selectItem(MarketSearchResult item) async {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedItem = item;
      _searchResults = [];
      _isFetchingPrice = true;
      _livePrice = null;
      _changePercent = null;
    });

    await _fetchQuoteForSelected();
  }

  Future<void> _fetchQuoteForSelected() async {
    if (_selectedItem == null) return;
    setState(() => _isFetchingPrice = true);

    final service = ref.read(marketDataServiceProvider);
    final quote = await service.getQuote(
      symbol: _selectedItem!.symbol,
      assetType: _assetType,
    );

    if (mounted) {
      setState(() {
        _isFetchingPrice = false;
        if (quote != null) {
          _livePrice = quote.price;
          _changePercent = quote.changePercent;
        }
      });
    }
  }

  Future<void> _save() async {
    if (_selectedItem == null) {
      CustomSnackbars.showError(
        context,
        message: 'Please select a Ticker / Fund',
      );
      return;
    }

    final qty = double.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      CustomSnackbars.showError(
        context,
        message: 'Please enter a valid quantity / units greater than 0',
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final success = await ref
        .read(investmentActionProvider.notifier)
        .saveLiveTracker(
          investmentId: widget.investment.id,
          symbol: _selectedItem!.symbol,
          name: _selectedItem!.name,
          assetType: _assetType,
          quantity: qty,
          lastPrice: _livePrice,
          changePercent: _changePercent,
        );

    if (success && mounted) {
      CustomSnackbars.showSuccess(
        context,
        message: 'Live tracker saved successfully!',
      );
      Navigator.pop(context);
    }
  }

  void _confirmDelete() {
    ConfirmationBottomSheet.show(
      context,
      title: 'Remove Live Tracker?',
      description:
          'This will disconnect live valuation from this investment. Your recorded portfolio value remains unchanged.',
      confirmText: 'REMOVE',
      isDestructive: true,
      onConfirm: () async {
        final success = await ref
            .read(investmentActionProvider.notifier)
            .deleteLiveTracker(widget.investment.id);
        if (success && mounted) {
          CustomSnackbars.showSuccess(
            context,
            message: 'Live tracking removed.',
          );
          Navigator.pop(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.existingTracker != null;
    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    final totalLiveVal = (_livePrice != null) ? (_livePrice! * qty) : null;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusLg),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing
                              ? 'Edit Live Tracking'
                              : 'Setup Live Tracking',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.investment.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: theme.colorScheme.error,
                      tooltip: 'Remove tracker',
                      onPressed: _confirmDelete,
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Asset Type Selector Toggle (Mutual Fund vs Stock/ETF)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTypePill(
                              label: 'Mutual Fund',
                              icon: Icons.pie_chart_rounded,
                              type: 'mutual_fund',
                              theme: theme,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _buildTypePill(
                              label: 'Stock / ETF',
                              icon: Icons.trending_up_rounded,
                              type: 'stock',
                              theme: theme,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Selected Item Card or Unified Search Box
                    if (_selectedItem != null) ...[
                      _buildSelectedItemCard(theme, isDark),
                    ] else ...[
                      _buildSearchSection(theme),
                    ],

                    const SizedBox(height: 16),

                    // Quantity / Units Input
                    Text(
                      'QUANTITY / UNITS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'e.g. 250.50',
                        prefixIcon: const Icon(
                          Icons.pin_outlined,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: theme.dividerColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Calculated Total Value Preview Card
                    if (totalLiveVal != null && qty > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CALCULATED LIVE VALUE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$qty units × ₹${CurrencyFormatter.format(_livePrice!)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            CurrencyText(
                              amount: totalLiveVal,
                              sign: '₹ ',
                              amountStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Action Button
                    ModernBoxyButton(
                      onPressed: _save,
                      label: isEditing ? 'UPDATE TRACKER' : 'SAVE TRACKER',
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Selected Item Card ──────────────────────────────────────────

  Widget _buildSelectedItemCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer
            .withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _assetType == 'mutual_fund'
                      ? 'AMFI'
                      : (_selectedItem!.exchange ?? 'STOCK'),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedItem!.symbol,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () {
                  setState(() {
                    _selectedItem = null;
                    _livePrice = null;
                    _searchResults = [];
                  });
                },
                child: const Text('Change'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _selectedItem!.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (_assetType == 'mutual_fund') ...[
            const SizedBox(height: 4),
            _buildMfSchemeBadges(_selectedItem!.name),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _assetType == 'mutual_fund' ? 'NAV: ' : 'Live Price: ',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (_isFetchingPrice)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (_livePrice != null) ...[
                Text(
                  '₹ ${CurrencyFormatter.format(_livePrice!)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (_changePercent != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${_changePercent! >= 0 ? '+' : ''}${_changePercent!.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _changePercent! >= 0
                          ? Colors.green.shade600
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ] else ...[
                Text(
                  'Unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _fetchQuoteForSelected,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  // ─── Unified Search Section ──────────────────────────────────────

  Widget _buildSearchSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: _assetType == 'mutual_fund'
                ? 'Search by name or AMFI code (e.g. Parag, 122639)'
                : 'Search by name or ticker (e.g. TCS, NIFTYBEES.NS)',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : (_searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null),
            filled: true,
            fillColor: theme.colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),

        if (_searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final item = _searchResults[i];
                final isMf = item.type == 'mutual_fund';
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  title: Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isMf) _buildMfSchemeBadges(item.name),
                        const SizedBox(height: 2),
                        Text(
                          isMf
                              ? 'AMFI Code: ${item.symbol}'
                              : '${item.symbol}${item.exchange != null ? " • ${item.exchange}" : ""}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                  ),
                  onTap: () => _selectItem(item),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ─── Mutual Fund Attribute Badges (Direct, Regular, Growth, IDCW) ──

  Widget _buildMfSchemeBadges(String schemeName) {
    final upper = schemeName.toUpperCase();
    final isDirect = upper.contains('DIRECT');
    final isRegular = upper.contains('REGULAR');
    final isGrowth = upper.contains('GROWTH');
    final isIdcw = upper.contains('IDCW') || upper.contains('DIVIDEND');

    if (!isDirect && !isRegular && !isGrowth && !isIdcw) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        children: [
          if (isDirect)
            _buildBadge('DIRECT', Colors.green.shade800, Colors.green.shade100),
          if (isRegular)
            _buildBadge('REGULAR', Colors.orange.shade900, Colors.orange.shade100),
          if (isGrowth)
            _buildBadge('GROWTH', Colors.blue.shade900, Colors.blue.shade100),
          if (isIdcw)
            _buildBadge('IDCW', Colors.purple.shade900, Colors.purple.shade100),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: textColor.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.4,
          color: textColor,
        ),
      ),
    );
  }

  // ─── Type Toggle Pill ────────────────────────────────────────────

  Widget _buildTypePill({
    required String label,
    required IconData icon,
    required String type,
    required ThemeData theme,
  }) {
    final isSelected = _assetType == type;
    return InkWell(
      onTap: () {
        if (_assetType != type) {
          HapticFeedback.selectionClick();
          setState(() {
            _assetType = type;
            _selectedItem = null;
            _livePrice = null;
            _searchResults = [];
            _searchCtrl.clear();
          });
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
