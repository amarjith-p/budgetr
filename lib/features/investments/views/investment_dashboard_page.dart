// lib/features/investments/views/investment_dashboard_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/investment_provider.dart';
import '../components/investment_tile.dart';
import '../components/global_investment_summary_card.dart';
import 'investment_details_page.dart';
import 'investment_form_page.dart';

enum InvestmentSortOption {
  groupByType, // Default
  groupByTag, // New Tag Grouping
  highestValue,
  lowestValue,
  highestReturn,
  lowestReturn,
  newest,
  oldest,
  nameAZ,
}

class InvestmentDashboardPage extends ConsumerStatefulWidget {
  const InvestmentDashboardPage({Key? key}) : super(key: key);

  @override
  ConsumerState<InvestmentDashboardPage> createState() =>
      _InvestmentDashboardPageState();
}

class _InvestmentDashboardPageState
    extends ConsumerState<InvestmentDashboardPage> {
  final Set<String> _collapsedGroups = {};
  bool _showClosedInvestments = false;

  InvestmentSortOption _currentSort = InvestmentSortOption.groupByType;

  void _toggleGroup(String groupName) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_collapsedGroups.contains(groupName)) {
        _collapsedGroups.remove(groupName);
      } else {
        _collapsedGroups.add(groupName);
      }
    });
  }

  void _sortInvestments(List<Investment> list) {
    if (_currentSort == InvestmentSortOption.groupByType ||
        _currentSort == InvestmentSortOption.groupByTag)
      return;

    list.sort((a, b) {
      switch (_currentSort) {
        case InvestmentSortOption.highestValue:
          return b.currentValue.compareTo(a.currentValue);
        case InvestmentSortOption.lowestValue:
          return a.currentValue.compareTo(b.currentValue);
        case InvestmentSortOption.newest:
          return b.startDate.compareTo(a.startDate);
        case InvestmentSortOption.oldest:
          return a.startDate.compareTo(b.startDate);
        case InvestmentSortOption.highestReturn:
          final aRet = a.initialAmount > 0
              ? ((a.currentValue - a.initialAmount) / a.initialAmount)
              : 0.0;
          final bRet = b.initialAmount > 0
              ? ((b.currentValue - b.initialAmount) / b.initialAmount)
              : 0.0;
          return bRet.compareTo(aRet);
        case InvestmentSortOption.lowestReturn:
          final aRet = a.initialAmount > 0
              ? ((a.currentValue - a.initialAmount) / a.initialAmount)
              : 0.0;
          final bRet = b.initialAmount > 0
              ? ((b.currentValue - b.initialAmount) / b.initialAmount)
              : 0.0;
          return aRet.compareTo(bRet);
        case InvestmentSortOption.nameAZ:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        default:
          return 0;
      }
    });
  }

  String _getSortName(InvestmentSortOption option) {
    switch (option) {
      case InvestmentSortOption.groupByType:
        return 'Group by Type (Default)';
      case InvestmentSortOption.groupByTag:
        return 'Group by Tag';
      case InvestmentSortOption.highestValue:
        return 'Highest Value';
      case InvestmentSortOption.lowestValue:
        return 'Lowest Value';
      case InvestmentSortOption.highestReturn:
        return 'Highest Return %';
      case InvestmentSortOption.lowestReturn:
        return 'Lowest Return %';
      case InvestmentSortOption.newest:
        return 'Newest First';
      case InvestmentSortOption.oldest:
        return 'Oldest First';
      case InvestmentSortOption.nameAZ:
        return 'Name (A-Z)';
    }
  }

  IconData _getSortIcon(InvestmentSortOption option) {
    switch (option) {
      case InvestmentSortOption.groupByType:
        return Icons.category_rounded;
      case InvestmentSortOption.groupByTag:
        return Icons.sell_rounded;
      case InvestmentSortOption.highestValue:
        return Icons.keyboard_double_arrow_up_rounded;
      case InvestmentSortOption.lowestValue:
        return Icons.keyboard_double_arrow_down_rounded;
      case InvestmentSortOption.highestReturn:
        return Icons.trending_up_rounded;
      case InvestmentSortOption.lowestReturn:
        return Icons.trending_down_rounded;
      case InvestmentSortOption.newest:
        return Icons.new_releases_rounded;
      case InvestmentSortOption.oldest:
        return Icons.history_rounded;
      case InvestmentSortOption.nameAZ:
        return Icons.sort_by_alpha_rounded;
    }
  }

  void _showSortMenu() {
    HapticFeedback.lightImpact();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 16,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Organize Portfolio',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: InvestmentSortOption.values.map((option) {
                      final isSelected = _currentSort == option;
                      final iconColor = isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant;

                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _currentSort = option);
                          Navigator.pop(ctx);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: iconColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: iconColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Icon(
                                  _getSortIcon(option),
                                  color: iconColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _getSortName(option),
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final investmentsAsync = ref.watch(investmentsStreamProvider);
    final bool isGrouped =
        _currentSort == InvestmentSortOption.groupByType ||
        _currentSort == InvestmentSortOption.groupByTag;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: 'Investments',
        subtitle: 'PORTFOLIO TRACKER',
        leadingIcon: Icons.arrow_back_rounded,
        // --- DYNAMIC SORT ICON ---
        trailingIcon: isGrouped ? Icons.sort_rounded : Icons.filter_list_alt,
        onTrailingPressed: _showSortMenu,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const InvestmentFormPage()),
          );
        },
        icon: Icons.add_rounded,
        label: 'Add',
      ),
      body: investmentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (investments) {
          if (investments.isEmpty) {
            return const PremiumEmptyState(
              title: 'No Investments Yet',
              subtitle:
                  'Tap + to add your first asset and start tracking your portfolio.',
              icon: Icons.stacked_line_chart_rounded,
            );
          }

          final activeInvestments = investments
              .where((inv) => !inv.isClosed)
              .toList();
          final closedInvestments = investments
              .where((inv) => inv.isClosed)
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: DesignTokens.spacingMd),
              ),

              if (activeInvestments.isNotEmpty) ...[
                // --- GLOBAL SUMMARY CARD ---
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingMd,
                    ),
                    child: GlobalInvestmentSummaryCard(
                      investments: activeInvestments,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacingMd),
                ),

                // --- ACTIVE FILTER BANNER ---
                if (!isGrouped)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spacingMd,
                        0,
                        DesignTokens.spacingMd,
                        DesignTokens.spacingMd,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _getSortIcon(_currentSort),
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sorted: ${_getSortName(_currentSort)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(
                                  () => _currentSort =
                                      InvestmentSortOption.groupByType,
                                );
                              },
                              child: Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],

              // --- ACTIVE INVESTMENTS GRID ---
              if (activeInvestments.isNotEmpty) ...[
                if (isGrouped)
                  ...() {
                    final groupedData = <String, List<Investment>>{};
                    for (var inv in activeInvestments) {
                      String key =
                          _currentSort == InvestmentSortOption.groupByTag
                          ? (inv.specialTag?.trim().isNotEmpty == true
                                ? inv.specialTag!.toUpperCase()
                                : 'UNTAGGED')
                          : inv.type.toUpperCase();
                      groupedData.putIfAbsent(key, () => []).add(inv);
                    }
                    final sortedGroupNames = groupedData.keys.toList()..sort();

                    return sortedGroupNames.map((groupName) {
                      final groupItems = groupedData[groupName]!;
                      final isCollapsed = _collapsedGroups.contains(groupName);

                      // Calculate Dynamic Group Header Metrics
                      double gInv = 0;
                      double gCur = 0;
                      for (var item in groupItems) {
                        gInv += item.initialAmount;
                        gCur += item.currentValue;
                      }
                      double gRet = gInv > 0
                          ? ((gCur - gInv) / gInv) * 100
                          : 0.0;

                      return SliverMainAxisGroup(
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickySectionHeaderDelegate(
                              title: groupName,
                              itemCount: groupItems.length,
                              isCollapsed: isCollapsed,
                              onTap: () => _toggleGroup(groupName),
                              theme: theme,
                              totalInvested: gInv,
                              totalCurrent: gCur,
                              returnPct: gRet,
                            ),
                          ),
                          if (!isCollapsed)
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                left: DesignTokens.spacingMd,
                                right: DesignTokens.spacingMd,
                                top: DesignTokens.spacingMd,
                                bottom: DesignTokens.spacingXl,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.85,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final inv = groupItems[index];
                                  return InvestmentTile(
                                    investment: inv,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InvestmentDetailsPage(
                                            investment: inv,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }, childCount: groupItems.length),
                              ),
                            ),
                        ],
                      );
                    }).toList();
                  }()
                else
                  // FLAT SORTED LIST (ALL ACTIVE ASSETS)
                  ...() {
                    _sortInvestments(activeInvestments);
                    const groupName = 'ALL ACTIVE ASSETS';
                    final isCollapsed = _collapsedGroups.contains(groupName);

                    double gInv = 0;
                    double gCur = 0;
                    for (var item in activeInvestments) {
                      gInv += item.initialAmount;
                      gCur += item.currentValue;
                    }
                    double gRet = gInv > 0 ? ((gCur - gInv) / gInv) * 100 : 0.0;

                    return [
                      SliverMainAxisGroup(
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickySectionHeaderDelegate(
                              title: groupName,
                              itemCount: activeInvestments.length,
                              isCollapsed: isCollapsed,
                              onTap: () => _toggleGroup(groupName),
                              theme: theme,
                              totalInvested: gInv,
                              totalCurrent: gCur,
                              returnPct: gRet,
                            ),
                          ),
                          if (!isCollapsed)
                            SliverPadding(
                              padding: const EdgeInsets.only(
                                left: DesignTokens.spacingMd,
                                right: DesignTokens.spacingMd,
                                top: DesignTokens.spacingMd,
                                bottom: DesignTokens.spacingXl,
                              ),
                              sliver: SliverGrid(
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 8,
                                      crossAxisSpacing: 8,
                                      childAspectRatio: 0.85,
                                    ),
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final inv = activeInvestments[index];
                                  return InvestmentTile(
                                    investment: inv,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InvestmentDetailsPage(
                                            investment: inv,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }, childCount: activeInvestments.length),
                              ),
                            ),
                        ],
                      ),
                    ];
                  }(),
              ],

              // --- CLOSED INVESTMENTS SECTION ---
              if (closedInvestments.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingLg,
                      vertical: DesignTokens.spacingXl,
                    ),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(
                          () =>
                              _showClosedInvestments = !_showClosedInvestments,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showClosedInvestments
                                  ? Icons.visibility_off_rounded
                                  : Icons.history_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showClosedInvestments
                                  ? 'HIDE CLOSED ASSETS'
                                  : 'VIEW ${closedInvestments.length} CLOSED ASSETS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_showClosedInvestments)
                  ...() {
                    _sortInvestments(closedInvestments);

                    double cInv = 0;
                    double cCur = 0;
                    for (var item in closedInvestments) {
                      cInv += item.initialAmount;
                      cCur += item.currentValue;
                    }
                    double cRet = cInv > 0 ? ((cCur - cInv) / cInv) * 100 : 0.0;

                    return [
                      SliverMainAxisGroup(
                        slivers: [
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickySectionHeaderDelegate(
                              title: 'CLOSED INVESTMENTS',
                              itemCount: closedInvestments.length,
                              isCollapsed: false,
                              onTap: () {},
                              theme: theme,
                              isErrorColor: true,
                              totalInvested: cInv,
                              totalCurrent: cCur,
                              returnPct: cRet,
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.only(
                              left: DesignTokens.spacingMd,
                              right: DesignTokens.spacingMd,
                              top: DesignTokens.spacingMd,
                              bottom: DesignTokens.spacingXl,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    mainAxisSpacing: 8,
                                    crossAxisSpacing: 8,
                                    childAspectRatio: 0.85,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final inv = closedInvestments[index];
                                return Opacity(
                                  opacity: 0.6,
                                  child: InvestmentTile(
                                    investment: inv,
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => InvestmentDetailsPage(
                                            investment: inv,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }, childCount: closedInvestments.length),
                            ),
                          ),
                        ],
                      ),
                    ];
                  }(),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _StickySectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final int itemCount;
  final bool isCollapsed;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool isErrorColor;
  final double? totalInvested;
  final double? totalCurrent;
  final double? returnPct;

  _StickySectionHeaderDelegate({
    required this.title,
    required this.itemCount,
    required this.isCollapsed,
    required this.onTap,
    required this.theme,
    this.isErrorColor = false,
    this.totalInvested,
    this.totalCurrent,
    this.returnPct,
  });

  // Smart localized formatter to prevent text overflow in the tight header
  Widget _buildMiniMetric(
    String label,
    double value,
    bool isPct,
    ThemeData theme,
  ) {
    final isPositive = value >= 0;
    final color = isPct
        ? (isPositive ? Colors.green : theme.colorScheme.error)
        : theme.colorScheme.onSurface;
    final sign = isPct ? (isPositive ? '+' : '') : (value < 0 ? '-' : '');

    String formatted;
    if (isPct) {
      formatted = '$sign${value.toStringAsFixed(1)}%';
    } else {
      if (value.abs() >= 100000) {
        formatted = '${sign}₹${(value.abs() / 100000).toStringAsFixed(2)}L';
      } else if (value.abs() >= 1000) {
        formatted = '${sign}₹${(value.abs() / 1000).toStringAsFixed(1)}K';
      } else {
        formatted = '${sign}₹${value.abs().toStringAsFixed(0)}';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatted,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final activeColor = isErrorColor
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: theme.scaffoldBackgroundColor.withOpacity(0.85),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLg,
            ),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3,
                            height: 14,
                            decoration: BoxDecoration(
                              color: activeColor,
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 1.5,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: activeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              itemCount.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: activeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isErrorColor)
                        Icon(
                          isCollapsed
                              ? Icons.add_circle_outline_rounded
                              : Icons.remove_circle_outline_rounded,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.7,
                          ),
                          size: 20,
                        ),
                    ],
                  ),
                ),

                // --- DYNAMIC GROUP HEADER METRICS ---
                if (totalInvested != null &&
                    totalCurrent != null &&
                    returnPct != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMiniMetric(
                          'INVESTED',
                          totalInvested!,
                          false,
                          theme,
                        ),
                        _buildMiniMetric(
                          'CURRENT',
                          totalCurrent!,
                          false,
                          theme,
                        ),
                        _buildMiniMetric('RETURN', returnPct!, true, theme),
                      ],
                    ),
                  ),
                ],

                Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => totalInvested != null ? 88.0 : 52.0;
  @override
  double get minExtent => totalInvested != null ? 88.0 : 52.0;
  @override
  bool shouldRebuild(covariant _StickySectionHeaderDelegate oldDelegate) {
    return title != oldDelegate.title ||
        isCollapsed != oldDelegate.isCollapsed ||
        itemCount != oldDelegate.itemCount ||
        totalInvested != oldDelegate.totalInvested ||
        totalCurrent != oldDelegate.totalCurrent;
  }
}
