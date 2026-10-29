import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/currency_text.dart';
import '../providers/account_provider.dart';
import '../providers/loan_math_provider.dart';
import '../providers/credit_math_provider.dart';

class AccountBalanceVisibilitySheet extends ConsumerStatefulWidget {
  final Account account;

  const AccountBalanceVisibilitySheet({
    Key? key,
    required this.account,
  }) : super(key: key);

  static Future<void> show(BuildContext context, Account account) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AccountBalanceVisibilitySheet(account: account),
    );
  }

  @override
  ConsumerState<AccountBalanceVisibilitySheet> createState() =>
      _AccountBalanceVisibilitySheetState();
}

class _AccountBalanceVisibilitySheetState
    extends ConsumerState<AccountBalanceVisibilitySheet> {
  late bool _masterHide;
  late bool _hideInDashboard;
  late bool _hideInHome;
  late bool _hideInAccounts;

  @override
  void initState() {
    super.initState();
    _hideInDashboard = widget.account.hideBalanceInDashboard;
    _hideInHome = widget.account.hideBalanceInHome;
    _hideInAccounts = widget.account.hideBalanceInAccounts;
    _masterHide = _hideInDashboard || _hideInHome || _hideInAccounts;
  }

  void _onMasterToggle(bool val) {
    HapticFeedback.selectionClick();
    setState(() {
      _masterHide = val;
      if (val) {
        // By default when turning on master hide, enable all three if none was set
        if (!_hideInDashboard && !_hideInHome && !_hideInAccounts) {
          _hideInDashboard = true;
          _hideInHome = true;
          _hideInAccounts = true;
        }
      } else {
        _hideInDashboard = false;
        _hideInHome = false;
        _hideInAccounts = false;
      }
    });
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    final success = await ref
        .read(accountActionProvider.notifier)
        .updateAccountBalanceHiding(
          accountId: widget.account.id,
          hideBalanceInDashboard: _masterHide && _hideInDashboard,
          hideBalanceInHome: _masterHide && _hideInHome,
          hideBalanceInAccounts: _masterHide && _hideInAccounts,
        );

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLoading = ref.watch(accountActionProvider).isLoading;

    IconData typeIcon = Icons.account_balance_wallet_rounded;
    if (widget.account.type == 'Credit Cards') {
      typeIcon = Icons.credit_card_rounded;
    } else if (widget.account.type == 'Loan') {
      typeIcon = Icons.account_balance_rounded;
    }

    final isCreditCard = widget.account.type == 'Credit Cards';
    final isLoan = widget.account.type == 'Loan';
    final isSettled = widget.account.isClosed;

    double displayBalance = widget.account.balance;
    String signText = '₹ ';
    String labelText = 'CURRENT BALANCE';

    if (isLoan) {
      displayBalance = ref.watch(loanTotalOutstandingProvider(widget.account));
      signText = displayBalance > 0 ? '-₹ ' : (displayBalance < 0 ? '+₹ ' : '₹ ');
      labelText = isSettled
          ? 'SETTLED LOAN'
          : (displayBalance <= 0 ? 'CLEARED / SURPLUS' : 'TOTAL OUTSTANDING');
    } else if (isCreditCard) {
      final metrics = ref.watch(creditCardMetricsProvider(widget.account));
      displayBalance = metrics.totalOutstanding;
      signText = displayBalance < 0 ? '-₹ ' : (displayBalance > 0 ? '+₹ ' : '₹ ');
      labelText = displayBalance < 0
          ? 'TOTAL OUTSTANDING'
          : (displayBalance > 0 ? 'SURPLUS' : 'OUTSTANDING BALANCE');
    } else {
      signText = displayBalance < 0 ? '-₹ ' : '₹ ';
    }

    Color balanceColor = theme.colorScheme.onSurface;
    if (isLoan) {
      balanceColor = displayBalance > 0 ? theme.colorScheme.error : Colors.green;
    } else if (isCreditCard) {
      balanceColor = displayBalance < 0 ? theme.colorScheme.error : Colors.green;
    } else if (displayBalance < 0) {
      balanceColor = theme.colorScheme.error;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.4),
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    typeIcon,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.account.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.account.providerName} • ${widget.account.type}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Visual balance tag showing the exact mathematical outstanding
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        labelText,
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      CurrencyText(
                        amount: displayBalance.abs(),
                        sign: signText,
                        amountStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: balanceColor,
                        ),
                        symbolStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: balanceColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Master Switch Card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _masterHide
                    ? theme.colorScheme.primary.withOpacity(isDark ? 0.15 : 0.08)
                    : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _masterHide
                      ? theme.colorScheme.primary.withOpacity(0.4)
                      : theme.dividerColor.withOpacity(0.5),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _masterHide
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: _masterHide
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hide Balance from Totals',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Exclude this account from specific total balance displays',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _masterHide,
                    activeColor: theme.colorScheme.primary,
                    onChanged: _onMasterToggle,
                  ),
                ],
              ),
            ),
          ),

          // Detailed Options
          AnimatedCrossFade(
            crossFadeState: _masterHide
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'CUSTOMIZE WHERE TO HIDE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  _buildOptionTile(
                    theme: theme,
                    icon: Icons.dashboard_rounded,
                    title: "Dashboard's Money Tracker",
                    subtitle: "Hides balance inside Dashboard's Money Tracker tile",
                    value: _hideInDashboard,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _hideInDashboard = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildOptionTile(
                    theme: theme,
                    icon: Icons.view_carousel_rounded,
                    title: "Home Tab's Total Pill",
                    subtitle: "Hides balance inside Dr / Cr / Tally summary pill",
                    value: _hideInHome,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _hideInHome = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildOptionTile(
                    theme: theme,
                    icon: Icons.account_balance_wallet_rounded,
                    title: "Account Tab's Summary Card",
                    subtitle: "Hides balance inside Net Balance summary card",
                    value: _hideInAccounts,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      setState(() => _hideInAccounts = val);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Info Callout
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(isDark ? 0.15 : 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This setting strictly affects selected total displays. Net Worth, budgets, analytics, and transaction workflows are never altered.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ModernBoxyButton(
                    onPressed: () => Navigator.pop(context),
                    label: 'Cancel',
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ModernBoxyButton(
                    onPressed: _save,
                    label: 'Save Preferences',
                    isLoading: isLoading,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? theme.colorScheme.surfaceContainerHighest.withOpacity(isDark ? 0.4 : 0.6)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? theme.colorScheme.primary.withOpacity(0.5)
                : theme.dividerColor.withOpacity(0.4),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: value,
              activeColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (val) => onChanged(val ?? false),
            ),
          ],
        ),
      ),
    );
  }
}
