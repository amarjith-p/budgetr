import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:budgetr/core/components/premium_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../accounts/providers/account_provider.dart';
import '../../accounts/providers/loan_math_provider.dart';
import '../../accounts/providers/credit_math_provider.dart';
import '../../transactions/views/account_transactions_page.dart';
import '../../transactions/views/credit_transaction_page.dart';
import '../../transactions/views/loan_transaction_page.dart';
import '../components/mini_account_card.dart';
import '../components/manage_accounts_bottom_sheet.dart';
import '../components/credit_payable_bottom_sheet.dart';

import '../../analytics/components/pinned_widgets_display.dart';
import '../../analytics/providers/pinned_widgets_provider.dart';

class MoneyTrackerHomeTab extends ConsumerWidget {
  const MoneyTrackerHomeTab({Key? key}) : super(key: key);

  void _openManageSheet(BuildContext context, List<Account> allAccounts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManageAccountsBottomSheet(allAccounts: allAccounts),
    );
  }

  void _openPayableSheet(
    BuildContext context,
    List<Account> bankAccounts,
    double crBalance,
  ) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreditPayableBottomSheet(
        bankAccounts: bankAccounts,
        totalCreditLiability: crBalance,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final pinnedWidgets = ref.watch(pinnedWidgetsProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: accountsAsync.when(
        loading: () =>
            const Center(child: FuturisticLoader(size: 80, label: "LOADING..")),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (accounts) {
          final visibleAccounts = accounts.where((a) => !a.isHidden).toList();

          final bankAccounts = visibleAccounts
              .where((a) => a.type != 'Credit Cards' && a.type != 'Loan')
              .toList();
          final creditCards = visibleAccounts
              .where((a) => a.type == 'Credit Cards')
              .toList();
          final loans = visibleAccounts
              .where((a) => a.type == 'Loan' && !a.isClosed)
              .toList();

          final double drBalance = bankAccounts.fold(
            0.0,
            (sum, acc) => sum + acc.balance,
          );

          double crBalance = 0.0;
          for (var acc in creditCards) {
            final metrics = ref.watch(creditCardMetricsProvider(acc));
            if (metrics.totalOutstanding < 0) {
              crBalance += metrics.totalOutstanding.abs();
            }
          }
          for (var loan in loans) {
            final out = ref.watch(loanTotalOutstandingProvider(loan));
            if (out > 0) crBalance += out;
          }

          final double allocatedFunds = bankAccounts
              .where((a) => a.isCreditPayable)
              .fold(
                0.0,
                (sum, acc) => sum + (acc.balance > 0 ? acc.balance : 0.0),
              );

          final double difference = allocatedFunds - crBalance;
          final debtAccounts = [...creditCards, ...loans];

          if (accounts.isEmpty) {
            return const PremiumEmptyState(
              title: 'Dashboard is Empty',
              subtitle:
                  'Add your first bank account, credit card, or loan to unlock insights and populate your dashboard.',
              icon: Icons.dashboard_customize_rounded,
            );
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    8.0,
                    DesignTokens.spacingLg,
                    8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: _buildSummaryPill(
                              context,
                              drBalance,
                              crBalance,
                              difference,
                              bankAccounts,
                              theme,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _openManageSheet(context, accounts),
                          icon: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          tooltip: 'Customize Dashboard',
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: theme.dividerColor,
                                width: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (bankAccounts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildAccountCarousel(context, bankAccounts),
                ),
              ],

              if (bankAccounts.isNotEmpty && debtAccounts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Divider(
                      indent: DesignTokens.spacingLg,
                      endIndent: DesignTokens.spacingLg,
                      color: theme.dividerColor.withOpacity(isDark ? 0.3 : 0.5),
                      thickness: 1.5,
                    ),
                  ),
                ),
              ],

              if (debtAccounts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildAccountCarousel(context, debtAccounts),
                ),
              ],

              if (pinnedWidgets.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: PinnedWidgetsDisplay(),
                  ),
                ),

              // Smart Spatially Aware Filling Sliver
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    bottom: 120.0,
                  ), // Preserves NavBar clearance
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (bankAccounts.isEmpty &&
                          debtAccounts.isEmpty &&
                          accounts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: TextButton.icon(
                            onPressed: () =>
                                _openManageSheet(context, accounts),
                            icon: const Icon(Icons.visibility_off_rounded),
                            label: const Text(
                              'All accounts hidden. Tap to manage.',
                            ),
                          ),
                        ),

                      if (pinnedWidgets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spacingLg,
                          ),
                          child: _buildBoxyWidgetPrompt(
                            context,
                            accounts,
                            theme,
                            isDark,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- REDESIGNED: Boxy, sleek, and professional workspace prompt ---
  Widget _buildBoxyWidgetPrompt(
    BuildContext context,
    List<Account> accounts,
    ThemeData theme,
    bool isDark,
  ) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _openManageSheet(context, accounts);
      },
      borderRadius: BorderRadius.circular(8), // Boxy sharpness
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8), // Boxy sharpness
          border: Border.all(color: theme.dividerColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Structured Inner Icon Block
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(
                  isDark ? 0.15 : 0.08,
                ),
                borderRadius: BorderRadius.circular(6), // Harder inner corner
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(
                    isDark ? 0.3 : 0.2,
                  ),
                  width: 1.0,
                ),
              ),
              child: Icon(
                Icons.widgets_outlined,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),

            // Professional Typography Layout
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'CUSTOMIZE DASHBOARD',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pin analytics widgets here',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),

            // High-Contrast Sleek Action Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme
                    .colorScheme
                    .onSurface, // Inverted for punchy modern contrast
                borderRadius: BorderRadius.circular(6), // Boxy button
              ),
              child: Text(
                'ADD',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.surface,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPill(
    BuildContext context,
    double drBalance,
    double crBalance,
    double difference,
    List<Account> bankAccounts,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    Color diffColor = Colors.blueAccent.shade700;
    String diffLabel = 'Tally:';
    if (difference > 0) {
      diffColor = Colors.green.shade600;
      diffLabel = 'Surplus:';
    } else if (difference < 0) {
      diffColor = theme.colorScheme.error;
      diffLabel = 'Short:';
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openPayableSheet(context, bankAccounts, crBalance),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPillMetric(
                  'Dr:',
                  drBalance,
                  theme.colorScheme.primary,
                  theme,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: 14,
                  width: 1.5,
                  color: theme.dividerColor,
                ),
                _buildPillMetric(
                  'Cr:',
                  crBalance > 0 ? -crBalance : 0.0,
                  theme.colorScheme.error,
                  theme,
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: 14,
                  width: 1.5,
                  color: theme.dividerColor,
                ),
                _buildPillMetric(
                  diffLabel,
                  difference,
                  diffColor,
                  theme,
                  showPlus: difference > 0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillMetric(
    String label,
    double amount,
    Color color,
    ThemeData theme, {
    bool showPlus = false,
  }) {
    String sign = amount < 0 ? '-₹ ' : (showPlus && amount > 0 ? '+₹ ' : '₹ ');
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 4),
        CurrencyText(
          amount: amount.abs(),
          sign: sign,
          amountStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.2,
          ),
          symbolStyle: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _buildAccountCarousel(BuildContext context, List<Account> accounts) {
    if (accounts.isEmpty) return const SizedBox.shrink();
    int mid = (accounts.length / 2).ceil();
    final topRow = accounts.sublist(0, mid);
    final bottomRow = accounts.sublist(mid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
          ),
          child: Row(
            children: topRow
                .map(
                  (acc) => Padding(
                    padding: const EdgeInsets.only(right: 12.0, bottom: 8.0),
                    child: MiniAccountCard(
                      account: acc,
                      onTap: () => _navigateToAccount(context, acc),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (bottomRow.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLg,
            ),
            child: Row(
              children: bottomRow
                  .map(
                    (acc) => Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: MiniAccountCard(
                        account: acc,
                        onTap: () => _navigateToAccount(context, acc),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _navigateToAccount(BuildContext context, Account acc) {
    HapticFeedback.lightImpact();
    if (acc.type == 'Credit Cards') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CreditTransactionPage(account: acc)),
      );
    } else if (acc.type == 'Loan') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LoanTransactionPage(account: acc)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AccountTransactionsPage(account: acc),
        ),
      );
    }
  }
}
