import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../accounts/providers/account_provider.dart';

// --- IMPORT THE PINNED WIDGETS PROVIDER ---
import '../../analytics/providers/pinned_widgets_provider.dart';

class _WidgetOption {
  final String id;
  final String title;
  final IconData icon;

  _WidgetOption(this.id, this.title, this.icon);
}

final _availableWidgets = [
  _WidgetOption('BALANCE_TREND', 'Balance Trend', Icons.show_chart_rounded),
  _WidgetOption('CASH_FLOW', 'Cash Flow', Icons.swap_vert_rounded),
  _WidgetOption('SPENDING', 'Spending Donut', Icons.pie_chart_rounded),
  _WidgetOption('CREDIT_TRACKER', 'Credit Tracker', Icons.credit_card_rounded),
  _WidgetOption('BUDGET_SIMULATOR', 'Budget Simulator', Icons.memory_rounded),
];

class ManageAccountsBottomSheet extends ConsumerStatefulWidget {
  final List<Account> allAccounts;

  const ManageAccountsBottomSheet({Key? key, required this.allAccounts})
    : super(key: key);

  @override
  ConsumerState<ManageAccountsBottomSheet> createState() =>
      _ManageAccountsBottomSheetState();
}

class _ManageAccountsBottomSheetState
    extends ConsumerState<ManageAccountsBottomSheet> {
  late List<Account> _draftBanks;
  late List<Account> _draftCards;
  late List<Account> _draftLoans;

  late List<String> _draftPinnedWidgets;

  @override
  void initState() {
    super.initState();

    _draftBanks = widget.allAccounts
        .where((a) => a.type != 'Credit Cards' && a.type != 'Loan')
        .toList();
    _draftBanks.sort(
      (a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0),
    );

    _draftCards = widget.allAccounts
        .where((a) => a.type == 'Credit Cards')
        .toList();
    _draftCards.sort(
      (a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0),
    );

    _draftLoans = widget.allAccounts
        .where((a) => a.type == 'Loan' && !a.isClosed)
        .toList();
    _draftLoans.sort(
      (a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0),
    );

    _draftPinnedWidgets = List.from(ref.read(pinnedWidgetsProvider));
  }

  void _onReorderBanks(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final Account item = _draftBanks.removeAt(oldIndex);
      _draftBanks.insert(newIndex, item);
    });
  }

  void _onReorderCards(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final Account item = _draftCards.removeAt(oldIndex);
      _draftCards.insert(newIndex, item);
    });
  }

  void _onReorderLoans(int oldIndex, int newIndex) {
    HapticFeedback.lightImpact();
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final Account item = _draftLoans.removeAt(oldIndex);
      _draftLoans.insert(newIndex, item);
    });
  }

  void _toggleVisibility(Account acc, bool newValue) {
    HapticFeedback.selectionClick();
    setState(() {
      if (acc.type == 'Credit Cards') {
        final index = _draftCards.indexWhere((a) => a.id == acc.id);
        if (index != -1) _draftCards[index] = acc.copyWith(isHidden: newValue);
      } else if (acc.type == 'Loan') {
        final index = _draftLoans.indexWhere((a) => a.id == acc.id);
        if (index != -1) _draftLoans[index] = acc.copyWith(isHidden: newValue);
      } else {
        final index = _draftBanks.indexWhere((a) => a.id == acc.id);
        if (index != -1) _draftBanks[index] = acc.copyWith(isHidden: newValue);
      }
    });
  }

  void _toggleWidget(String id, bool isSelected) {
    setState(() {
      if (isSelected) {
        if (_draftPinnedWidgets.length < 2) {
          _draftPinnedWidgets.add(id);
          HapticFeedback.selectionClick();
        } else {
          HapticFeedback.heavyImpact();
        }
      } else {
        _draftPinnedWidgets.remove(id);
        HapticFeedback.selectionClick();
      }
    });
  }

  Future<void> _savePreferences() async {
    final combined = [..._draftBanks, ..._draftCards, ..._draftLoans];
    await ref
        .read(accountActionProvider.notifier)
        .updateAccountPreferences(combined);

    ref
        .read(pinnedWidgetsProvider.notifier)
        .updatePinnedWidgets(_draftPinnedWidgets);

    if (mounted) Navigator.pop(context);
  }

  // --- REDESIGNED ACCOUNT ITEM ---
  Widget _buildListItem(
    Account acc,
    int index,
    int totalLength,
    ThemeData theme,
  ) {
    final isHidden = acc.isHidden;
    final isDark = theme.brightness == Brightness.dark;
    final isLast = index == totalLength - 1;

    IconData cardIcon = Icons.account_balance_wallet_rounded;
    if (acc.type == 'Credit Cards') cardIcon = Icons.credit_card_rounded;
    if (acc.type == 'Loan') cardIcon = Icons.account_balance_rounded;

    return Material(
      key: ValueKey(acc.id),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // Beautiful soft icon pill
              AnimatedOpacity(
                opacity: isHidden ? 0.4 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(
                      isDark ? 0.15 : 0.1,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cardIcon,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: AnimatedOpacity(
                  opacity: isHidden ? 0.4 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        acc.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        acc.providerName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              // Controls
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 0.8, // Sleeker switch size
                    child: Switch(
                      value: !isHidden,
                      activeColor: theme.colorScheme.primary,
                      onChanged: (val) => _toggleVisibility(acc, !val),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ReorderableDragStartListener(
                    index: index,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      color:
                          Colors.transparent, // Increases touch target safely
                      child: Icon(
                        Icons.drag_handle_rounded,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- REDESIGNED WIDGET ITEM ---
  Widget _buildWidgetListItem(
    _WidgetOption w,
    int index,
    int totalLength,
    ThemeData theme,
  ) {
    final isSelected = _draftPinnedWidgets.contains(w.id);
    final isDark = theme.brightness == Brightness.dark;
    final isLast = index == totalLength - 1;

    return Material(
      key: ValueKey(w.id),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: theme.dividerColor.withOpacity(0.4),
                    width: 0.5,
                  ),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withOpacity(
                            isDark ? 0.15 : 0.1,
                          )
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    w.icon,
                    size: 18,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.6,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    w.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.8, // Sleeker switch size
                child: Switch(
                  value: isSelected,
                  activeColor: theme.colorScheme.primary,
                  onChanged: (val) => _toggleWidget(w.id, val),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    ThemeData theme, {
    String? trailingText,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: theme.colorScheme.primary,
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: trailingText.startsWith('2')
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusLg),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DRAG HANDLE
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: DesignTokens.spacingMd,
                    top: DesignTokens.spacingMd,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize Dashboard',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage accounts and pin analytics widgets to your Home tab.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // SCROLLABLE LISTS (FLAT DESIGN)
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // --- PINNED WIDGETS ---
                    _buildSectionHeader(
                      'PINNED WIDGETS',
                      theme,
                      trailingText: '${_draftPinnedWidgets.length} / 2',
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildWidgetListItem(
                          _availableWidgets[index],
                          index,
                          _availableWidgets.length,
                          theme,
                        ),
                        childCount: _availableWidgets.length,
                      ),
                    ),

                    // --- ACCOUNTS ---
                    if (_draftBanks.isNotEmpty) ...[
                      _buildSectionHeader('ACCOUNTS', theme),
                      SliverReorderableList(
                        itemCount: _draftBanks.length,
                        onReorder: _onReorderBanks,
                        itemBuilder: (context, index) => _buildListItem(
                          _draftBanks[index],
                          index,
                          _draftBanks.length,
                          theme,
                        ),
                      ),
                    ],

                    // --- CREDIT CARDS ---
                    if (_draftCards.isNotEmpty) ...[
                      _buildSectionHeader('CREDIT CARDS', theme),
                      SliverReorderableList(
                        itemCount: _draftCards.length,
                        onReorder: _onReorderCards,
                        itemBuilder: (context, index) => _buildListItem(
                          _draftCards[index],
                          index,
                          _draftCards.length,
                          theme,
                        ),
                      ),
                    ],

                    // --- LOANS ---
                    if (_draftLoans.isNotEmpty) ...[
                      _buildSectionHeader('ACTIVE LOANS', theme),
                      SliverReorderableList(
                        itemCount: _draftLoans.length,
                        onReorder: _onReorderLoans,
                        itemBuilder: (context, index) => _buildListItem(
                          _draftLoans[index],
                          index,
                          _draftLoans.length,
                          theme,
                        ),
                      ),
                    ],

                    const SliverToBoxAdapter(
                      child: SizedBox(height: DesignTokens.spacingXl),
                    ),
                  ],
                ),
              ),

              // FOOTER
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor, // Seamless blend
                  border: Border(
                    top: BorderSide(color: theme.dividerColor, width: 1.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
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
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      flex: 2,
                      child: ModernBoxyButton(
                        onPressed: _savePreferences,
                        label: 'SAVE CHANGES',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
