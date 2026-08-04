import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../accounts/providers/account_provider.dart';

class ManageAccountsBottomSheet extends ConsumerStatefulWidget {
  final List<Account> allAccounts;
  
  const ManageAccountsBottomSheet({
    Key? key,
    required this.allAccounts,
  }) : super(key: key);

  @override
  ConsumerState<ManageAccountsBottomSheet> createState() => _ManageAccountsBottomSheetState();
}

class _ManageAccountsBottomSheetState extends ConsumerState<ManageAccountsBottomSheet> {
  late List<Account> _draftBanks;
  late List<Account> _draftCards;
  late List<Account> _draftLoans; // <-- NEW: Dedicated Loan List

  @override
  void initState() {
    super.initState();
    
    // Split into 3 strictly isolated lists and sort by their existing displayOrder
    _draftBanks = widget.allAccounts.where((a) => a.type != 'Credit Cards' && a.type != 'Loan').toList();
    _draftBanks.sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
    
    _draftCards = widget.allAccounts.where((a) => a.type == 'Credit Cards').toList();
    _draftCards.sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));

    _draftLoans = widget.allAccounts.where((a) => a.type == 'Loan' && !a.isClosed).toList();
    _draftLoans.sort((a, b) => (a.displayOrder ?? 0).compareTo(b.displayOrder ?? 0));
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

  Future<void> _savePreferences() async {
    // Recombine all three lists. This keeps the global ordering clean and intact.
    final combined = [..._draftBanks, ..._draftCards, ..._draftLoans];
    await ref.read(accountActionProvider.notifier).updateAccountPreferences(combined);
    if (mounted) Navigator.pop(context);
  }

  Widget _buildListItem(Account acc, int index, ThemeData theme) {
    final isHidden = acc.isHidden;

    IconData cardIcon = Icons.account_balance_wallet_rounded;
    if (acc.type == 'Credit Cards') cardIcon = Icons.credit_card_rounded;
    if (acc.type == 'Loan') cardIcon = Icons.account_balance_rounded;
    
    return Material(
      key: ValueKey(acc.id),
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg, vertical: 4),
        decoration: BoxDecoration(
          color: isHidden ? theme.colorScheme.surface.withOpacity(0.5) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isHidden ? Colors.transparent : theme.dividerColor),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(
            cardIcon, 
            color: isHidden ? theme.dividerColor : theme.colorScheme.primary
          ),
          title: Text(
            acc.name, 
            style: TextStyle(fontWeight: FontWeight.w800, color: isHidden ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5) : theme.colorScheme.onSurface)
          ),
          subtitle: Text(
            acc.providerName, 
            style: TextStyle(fontSize: 11, color: isHidden ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4) : theme.colorScheme.onSurfaceVariant)
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: !isHidden, 
                activeColor: theme.colorScheme.primary,
                onChanged: (val) => _toggleVisibility(acc, !val), 
              ),
              const SizedBox(width: 8),
              ReorderableDragStartListener(
                index: index,
                child: Icon(Icons.drag_handle_rounded, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5)),
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.radiusLg)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // DRAG HANDLE
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd, top: DesignTokens.spacingMd),
                  decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // HEADER
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customize Dashboard', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('Drag to reorder or toggle to hide accounts. Sections are managed separately.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              const Divider(height: 1),

              // SCROLLABLE LISTS
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    if (_draftBanks.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingSm),
                          child: Text(
                            'ACCOUNTS', 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)
                          ),
                        ),
                      ),
                      SliverReorderableList(
                        itemCount: _draftBanks.length,
                        onReorder: _onReorderBanks,
                        itemBuilder: (context, index) => _buildListItem(_draftBanks[index], index, theme),
                      ),
                    ],

                    if (_draftCards.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingSm),
                          child: Text(
                            'CREDIT CARDS', 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)
                          ),
                        ),
                      ),
                      SliverReorderableList(
                        itemCount: _draftCards.length,
                        onReorder: _onReorderCards,
                        itemBuilder: (context, index) => _buildListItem(_draftCards[index], index, theme),
                      ),
                    ],

                    if (_draftLoans.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingLg, DesignTokens.spacingSm),
                          child: Text(
                            'ACTIVE LOANS', 
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: theme.colorScheme.primary)
                          ),
                        ),
                      ),
                      SliverReorderableList(
                        itemCount: _draftLoans.length,
                        onReorder: _onReorderLoans,
                        itemBuilder: (context, index) => _buildListItem(_draftLoans[index], index, theme),
                      ),
                    ],
                    
                    const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spacingXl)),
                  ],
                ),
              ),

              // FOOTER
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(top: BorderSide(color: theme.dividerColor, width: 1.0)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, -4))],
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
                        label: 'SAVE',
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}