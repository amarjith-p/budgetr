// lib/features/investments/views/investment_dashboard_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/theme/design_tokens.dart';
import '../providers/investment_provider.dart';
import '../components/investment_tile.dart';
import '../components/global_investment_summary_card.dart';
import 'investment_details_page.dart';
import 'investment_form_page.dart';

enum InvestmentSortOption {
  groupByType, // Default
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
  // --- INVERTED: Use Expanded Groups so default state is Collapsed ---
  final Set<String> _expandedGroups = {};

  bool _viewClosed = false;
  String _selectedTag = 'All';
  InvestmentSortOption _currentSort = InvestmentSortOption.groupByType;

  // --- SEARCH BAR CONTROLLERS ---
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleGroup(String groupName) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedGroups.contains(groupName)) {
        _expandedGroups.remove(groupName);
      } else {
        _expandedGroups.add(groupName);
      }
    });
  }

  void _sortInvestments(List<Investment> list) {
    if (_currentSort == InvestmentSortOption.groupByType) return;

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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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

    // Forced grouping logic: Group by type if a tag is active, OR if sort option is groupByType
    final bool isGrouped =
        _currentSort == InvestmentSortOption.groupByType ||
        _selectedTag != 'All';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: 'Investments',
        subtitle: 'PORTFOLIO TRACKER',
        leadingIcon: Icons.arrow_back_rounded,
        trailingIcon: isGrouped && _selectedTag == 'All'
            ? Icons.sort_rounded
            : Icons.filter_list_alt,
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
              title: 'No Investments Found',
              subtitle: 'No investments found,Add your first Investment',
              icon: Icons.search_off_rounded,
            );
          }

          // 1. Filter by Active vs Closed Status
          final statusFilteredInvestments = _viewClosed
              ? investments.where((inv) => inv.isClosed).toList()
              : investments.where((inv) => !inv.isClosed).toList();

          // 2. Extract unique tags dynamically based on the current view
          final uniqueTags = [
            'All',
            ...statusFilteredInvestments
                .map((e) => e.specialTag?.trim().toUpperCase() ?? 'UNTAGGED')
                .toSet()
                .toList()
              ..sort(),
          ];

          // 3. Apply Special ID / Tag Filter
          final tagFilteredInvestments = _selectedTag == 'All'
              ? statusFilteredInvestments
              : statusFilteredInvestments.where((inv) {
                  final tag =
                      inv.specialTag?.trim().toUpperCase() ?? 'UNTAGGED';
                  return tag == _selectedTag;
                }).toList();

          // 4. Apply Dynamic Search Query Filter (Influences Summary Card)
          final finalInvestments = _searchQuery.isEmpty
              ? tagFilteredInvestments
              : tagFilteredInvestments.where((inv) {
                  return inv.name.toLowerCase().contains(_searchQuery) ||
                      inv.type.toLowerCase().contains(_searchQuery) ||
                      (inv.specialTag?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

          // 5. Apply Sorting (Only for flat list. Grouped items are sorted inside their slivers)
          if (!isGrouped) {
            _sortInvestments(finalInvestments);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(height: DesignTokens.spacingMd),
              ),

              // --- GLOBAL SUMMARY CARD ---
              if (finalInvestments.isNotEmpty ||
                  _selectedTag != 'All' ||
                  _searchQuery.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingMd,
                    ),
                    child: GlobalInvestmentSummaryCard(
                      investments: finalInvestments,
                    ),
                  ),
                ),

              if (finalInvestments.isNotEmpty ||
                  _selectedTag != 'All' ||
                  _searchQuery.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spacingMd),
                ),

              // --- SEARCH BAR ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingMd,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search portfolio...',
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.5,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: theme.colorScheme.error,
                                  size: 18,
                                ),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _searchCtrl.clear();
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: DesignTokens.spacingMd),
              ),

              // --- STATUS & TAG CONTROLS ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingMd,
                  ),
                  child: Column(
                    children: [
                      // Active / Closed Segmented Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _viewClosed = false;
                                    _selectedTag = 'All';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_viewClosed
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: !_viewClosed
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _viewClosed = true;
                                    _selectedTag = 'All';
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _viewClosed
                                        ? theme.colorScheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'CLOSED',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: _viewClosed
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Special ID / Tag Filter Pills
                      if (uniqueTags.length > 1)
                        SizedBox(
                          height: 32,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: uniqueTags.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final tag = uniqueTags[index];
                              final isSelected = _selectedTag == tag;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedTag = tag);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? theme.colorScheme.primary.withOpacity(
                                            0.15,
                                          )
                                        : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.dividerColor,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: DesignTokens.spacingMd),
                    ],
                  ),
                ),
              ),

              // --- ACTIVE SORT BANNER ---
              if (_currentSort != InvestmentSortOption.groupByType &&
                  finalInvestments.isNotEmpty)
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

              // --- INVESTMENTS GRID ---
              if (finalInvestments.isNotEmpty) ...[
                if (isGrouped)
                  ...() {
                    final groupedData = <String, List<Investment>>{};
                    for (var inv in finalInvestments) {
                      String key = inv.type.toUpperCase();
                      groupedData.putIfAbsent(key, () => []).add(inv);
                    }
                    final sortedGroupNames = groupedData.keys.toList()..sort();

                    return sortedGroupNames.map((groupName) {
                      final groupItems = groupedData[groupName]!;
                      // --- INVERTED: True if NOT explicitly expanded ---
                      final isCollapsed = !_expandedGroups.contains(groupName);

                      // --- INNER SORTING ---
                      _sortInvestments(groupItems);

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
                              isErrorColor: _viewClosed,
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
                                  return Opacity(
                                    opacity: _viewClosed ? 0.6 : 1.0,
                                    child: InvestmentTile(
                                      investment: inv,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                InvestmentDetailsPage(
                                                  investment: inv,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }, childCount: groupItems.length),
                              ),
                            ),
                        ],
                      );
                    }).toList();
                  }()
                else
                  // FLAT SORTED LIST
                  ...() {
                    final groupName = _viewClosed
                        ? 'ALL CLOSED ASSETS'
                        : 'ALL ACTIVE ASSETS';
                    // --- INVERTED: True if NOT explicitly expanded ---
                    final isCollapsed = !_expandedGroups.contains(groupName);

                    double gInv = 0;
                    double gCur = 0;
                    for (var item in finalInvestments) {
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
                              itemCount: finalInvestments.length,
                              isCollapsed: isCollapsed,
                              onTap: () => _toggleGroup(groupName),
                              theme: theme,
                              isErrorColor: _viewClosed,
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
                                  final inv = finalInvestments[index];
                                  return Opacity(
                                    opacity: _viewClosed ? 0.6 : 1.0,
                                    child: InvestmentTile(
                                      investment: inv,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                InvestmentDetailsPage(
                                                  investment: inv,
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }, childCount: finalInvestments.length),
                              ),
                            ),
                        ],
                      ),
                    ];
                  }(),
              ] else ...[
                // --- PREMIUM EMPTY STATE FOR FILTERS & SEARCH ---
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: PremiumEmptyState(
                    title: 'No Results Found',
                    subtitle: _searchQuery.isNotEmpty
                        ? 'No investments match "$_searchQuery".'
                        : 'No ${_viewClosed ? "closed" : "active"} investments found for $_selectedTag.',
                    icon: Icons.search_off_rounded,
                  ),
                ),
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

  Widget _buildMiniMetric(
    String label,
    double value,
    bool isPct,
    ThemeData theme, {
    double? compareValue,
  }) {
    final isPositive = value >= 0;

    // --- COLOUR COMPARISON LOGIC ---
    Color color;
    if (isPct) {
      color = isPositive ? Colors.green : theme.colorScheme.error;
    } else if (label == 'CURRENT' && compareValue != null) {
      // Dynamic highlighting: Current vs Invested
      color = value >= compareValue ? Colors.green : theme.colorScheme.error;
    } else {
      color = theme.colorScheme.onSurface;
    }

    // --- FIXED: Explicitly include the Rupee (₹) symbol so it isn't overwritten ---
    final sign = isPct
        ? (isPositive ? '+' : '')
        : (value < 0 ? '- ₹ ' : (value > 0 ? '+ ₹ ' : '₹ '));

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
        // --- ADDED FITTEDBOX TO DYNAMICALLY SHRINK HUGE NUMBERS ---
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: isPct
              ? Text(
                  '$sign${value.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                )
              : CurrencyText(
                  amount: value.abs(),
                  sign: sign,
                  amountStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: -0.5,
                  ),
                  symbolStyle: TextStyle(
                    fontSize: 9,
                    color: color.withOpacity(0.8),
                  ),
                ),
        ),
      ],
    );
  }

  // --- INTELLIGENT COMBINED GAIN/LOSS & RETURN % METRIC ---
  Widget _buildCombinedReturnMetric(
    double invested,
    double current,
    ThemeData theme,
  ) {
    final double returnAmt = current - invested;
    final double returnPct = invested > 0 ? (returnAmt / invested) * 100 : 0.0;
    final bool isPositive = returnAmt >= 0;
    final Color color = isPositive ? Colors.green : theme.colorScheme.error;

    final String amtSign = returnAmt < 0 ? '- ₹ ' : '+ ₹ ';
    final String pctSign = isPositive ? '+' : '';

    // Intelligent Label logic
    final String label = isPositive ? 'GAIN' : 'LOSS';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
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
        // --- ADDED FITTEDBOX TO DYNAMICALLY SHRINK HUGE NUMBERS ---
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              CurrencyText(
                amount: returnAmt.abs(),
                sign: amtSign,
                amountStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: -0.5,
                ),
                symbolStyle: TextStyle(
                  fontSize: 9,
                  color: color.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($pctSign${returnPct.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: color.withOpacity(0.8),
                  letterSpacing: -0.2,
                ),
              ),
            ],
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
                if (totalInvested != null &&
                    totalCurrent != null &&
                    returnPct != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // --- ADDED EXPANDED WRAPPERS TO PREVENT HORIZONTAL OVERFLOW ---
                        Expanded(
                          flex: 4,
                          child: _buildMiniMetric(
                            'INVESTED',
                            totalInvested!,
                            false,
                            theme,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 4,
                          child: _buildMiniMetric(
                            'CURRENT',
                            totalCurrent!,
                            false,
                            theme,
                            compareValue: totalInvested!,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex:
                              5, // Given slightly more flex as it holds Amount + %
                          child: _buildCombinedReturnMetric(
                            totalInvested!,
                            totalCurrent!,
                            theme,
                          ),
                        ),
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
