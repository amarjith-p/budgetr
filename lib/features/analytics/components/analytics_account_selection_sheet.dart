// features/analytics/components/analytics_account_selection_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/database/app_database.dart';

class AnalyticsAccountSelectionSheet extends StatelessWidget {
  final List<Account> accounts;
  final String selectedFilterId;
  final ValueChanged<String> onSelected;

  const AnalyticsAccountSelectionSheet({
    Key? key,
    required this.accounts,
    required this.selectedFilterId,
    required this.onSelected,
  }) : super(key: key);

  static void show(
    BuildContext context,
    List<Account> accounts,
    String selectedFilterId,
    ValueChanged<String> onSelected,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AnalyticsAccountSelectionSheet(
        accounts: accounts,
        selectedFilterId: selectedFilterId,
        onSelected: onSelected,
      ),
    );
  }

  Widget _buildSheetOption(
    BuildContext ctx,
    String title,
    String value,
    IconData icon,
    ThemeData theme, {
    String? subtitle,
  }) {
    final isSelected = selectedFilterId == value;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onSelected(value);
        Navigator.pop(ctx);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.15)
            : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAccountGroup(
    BuildContext ctx,
    List<Account> accountList,
    String title,
    IconData iconData,
    ThemeData theme,
  ) {
    if (accountList.isEmpty) return [];

    List<Widget> children = [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    ];

    for (int i = 0; i < accountList.length; i++) {
      final acc = accountList[i];
      final isLast = i == accountList.length - 1;

      children.add(
        Column(
          children: [
            _buildSheetOption(
              ctx,
              acc.name,
              acc.id,
              iconData,
              theme,
              subtitle: acc.providerName,
            ),
            if (!isLast)
              Divider(
                height: 1,
                color: theme.dividerColor.withOpacity(0.4),
                indent: 24,
                endIndent: 24,
              ),
          ],
        ),
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Filter accounts into categories, intentionally excluding Loans
    final assets = accounts
        .where((a) => a.type != 'Credit Cards' && a.type != 'Loan')
        .toList();
    final creditCards = accounts
        .where((a) => a.type == 'Credit Cards')
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      maxChildSize: 0.8,
      minChildSize: 0.4,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Filter Chart',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // --- STATIC ANALYTICS FILTERS ---
                    _buildSheetOption(
                      context,
                      'All Accounts',
                      'ALL',
                      Icons.language_rounded,
                      theme,
                    ),
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.2),
                      indent: 24,
                      endIndent: 24,
                    ),
                    _buildSheetOption(
                      context,
                      'Assets Only',
                      'ASSETS',
                      Icons.account_balance_rounded,
                      theme,
                    ),
                    Divider(
                      height: 1,
                      color: theme.dividerColor.withOpacity(0.2),
                      indent: 24,
                      endIndent: 24,
                    ),
                    _buildSheetOption(
                      context,
                      'Liabilities Only',
                      'CREDIT',
                      Icons.credit_card_rounded,
                      theme,
                    ),

                    Divider(
                      height: 24,
                      thickness: 4,
                      color: theme.dividerColor.withOpacity(0.05),
                    ),

                    // --- DYNAMIC GROUPED ACCOUNTS ---
                    ..._buildAccountGroup(
                      context,
                      assets,
                      'ASSETS',
                      Icons.account_balance_wallet_rounded,
                      theme,
                    ),
                    ..._buildAccountGroup(
                      context,
                      creditCards,
                      'CREDIT CARDS',
                      Icons.credit_card_rounded,
                      theme,
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
