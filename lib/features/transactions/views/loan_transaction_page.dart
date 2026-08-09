import 'dart:math';
import 'dart:ui';
import 'package:budgetr/core/components/futuristic_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/constants/date_time_constants.dart';
import '../providers/transaction_provider.dart';
import '../services/transaction_service.dart';
import '../components/transaction_card.dart';
import '../components/tax_rate_bottom_sheet.dart';
import '../components/interest_payable_bottom_sheet.dart';
import '../components/loan_payment_bottom_sheet.dart';
import '../../accounts/providers/account_provider.dart';

class LoanTransactionPage extends ConsumerWidget {
  final Account account;
  const LoanTransactionPage({Key? key, required this.account})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsStreamProvider);
    final transactionsAsync = ref.watch(
      accountTransactionsProvider(account.id),
    );
    final theme = Theme.of(context);
    final allAccounts = accountsAsync.asData?.value ?? [];
    final currentAccount =
        allAccounts.where((a) => a.id == account.id).firstOrNull ?? account;
    final bool isSettled = currentAccount.isClosed;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ModernAppBar(
        title: currentAccount.providerName.toUpperCase(),
        subtitle: isSettled
            ? '${currentAccount.name.toUpperCase()} (SETTLED)'
            : currentAccount.name.toUpperCase(),
        leadingIcon: Icons.arrow_back_rounded,
        onLeadingPressed: () => Navigator.pop(context),
      ),
      floatingActionButton: isSettled
          ? null
          : ModernSquircleFab(
              onPressed: () {
                LoanPaymentBottomSheet.show(context, currentAccount.id);
              },
              icon: Icons.add_rounded,
              label: 'Log',
            ),
      body: transactionsAsync.when(
        loading: () => const Center(
          child: FuturisticLoader(size: 80, label: "LOADING TRANSACTIONS.."),
        ),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (transactions) {
          final validTransactions = transactions
              .where(
                (txData) => !txData.transaction.id.endsWith('_SOURCETRANSFER'),
              )
              .toList();

          final groupedTransactions = <String, List<dynamic>>{};
          const fullMonths = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
          for (var txData in validTransactions) {
            final tx = txData.transaction;
            final groupKey = '${fullMonths[tx.date.month - 1]} ${tx.date.year}';
            groupedTransactions.putIfAbsent(groupKey, () => []).add(txData);
          }

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacingMd,
                    DesignTokens.spacingMd,
                    DesignTokens.spacingMd,
                    0,
                  ),
                  child: _LoanSummaryCard(
                    account: currentAccount,
                    transactions: validTransactions,
                    isSettled: isSettled,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    DesignTokens.spacingXl,
                    DesignTokens.spacingLg,
                    DesignTokens.spacingMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'REPAYMENT HISTORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (validTransactions.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${validTransactions.length} RECORD${validTransactions.length > 1 ? 'S' : ''}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (validTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'No repayments logged yet.',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                ...groupedTransactions.entries.map((entry) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _StickyLoanMonthHeaderDelegate(
                          title: entry.key,
                          theme: theme,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spacingMd,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final txData = entry.value[index];
                            return TransactionCard(
                              data: txData,
                              currentAccountId: currentAccount.id,
                            );
                          }, childCount: entry.value.length),
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: DesignTokens.spacingMd),
                      ),
                    ],
                  );
                }).toList(),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }
}

class _LoanSummaryCard extends ConsumerStatefulWidget {
  final Account account;
  final List<TransactionWithDetails> transactions;
  final bool isSettled;

  const _LoanSummaryCard({
    required this.account,
    required this.transactions,
    required this.isSettled,
  });

  @override
  ConsumerState<_LoanSummaryCard> createState() => _LoanSummaryCardState();
}

class _LoanSummaryCardState extends ConsumerState<_LoanSummaryCard> {
  bool _showOriginal = false;

  Future<void> _updateDatabase(
    WidgetRef ref, {
    double? newInterest,
    double? newTax,
    double? newBankCharges,
    bool clearInterest = false,
  }) async {
    await ref
        .read(accountActionProvider.notifier)
        .saveAccount(
          existingId: widget.account.id,
          name: widget.account.name,
          providerName: widget.account.providerName,
          type: widget.account.type,
          last4: widget.account.last4 ?? '',
          balance: widget.account.balance,
          creditLimit: widget.account.creditLimit,
          billDate: widget.account.billDate,
          dueDate: widget.account.dueDate,
          loanPurpose: widget.account.loanPurpose,
          loanPrincipal: widget.account.loanPrincipal,
          interestRate: widget.account.interestRate,
          tenureMonths: widget.account.tenureMonths,
          emiDate: widget.account.emiDate,
          loanStartDate: widget.account.loanStartDate,
          loanEndDate: widget.account.loanEndDate,
          totalInterestPayable: clearInterest
              ? null
              : (newInterest ?? widget.account.totalInterestPayable),
          totalTaxPayable: newTax ?? widget.account.totalTaxPayable,
          bankCharges:
              newBankCharges ?? (widget.account as dynamic).bankCharges,
        );
  }

  Future<void> _triggerInterestEdit(
    BuildContext context,
    WidgetRef ref,
    double currentAmount,
    bool isCustom,
  ) async {
    HapticFeedback.lightImpact();
    final result = await InterestPayableBottomSheet.show(
      context,
      currentAmount,
      isCustom,
    );
    if (result != null) {
      if (result == -1.0) {
        await _updateDatabase(ref, clearInterest: true);
      } else {
        await _updateDatabase(ref, newInterest: result);
      }
    }
  }

  Future<void> _triggerTaxCalculation(
    BuildContext context,
    WidgetRef ref,
    double currentInterest,
  ) async {
    HapticFeedback.lightImpact();
    final rate = await TaxRateBottomSheet.show(context);
    if (rate != null) {
      final calculatedTax = currentInterest * (rate / 100);
      await _updateDatabase(ref, newTax: calculatedTax);
    }
  }

  Future<void> _triggerBankChargesEdit(
    BuildContext context,
    WidgetRef ref,
  ) async {
    HapticFeedback.lightImpact();
    final result = await _BankChargesBottomSheet.show(context);
    if (result != null) {
      await _updateDatabase(ref, newBankCharges: result);
    }
  }

  Widget _buildDateMini(String label, String value, ThemeData theme) {
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
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // --- STATIC ORIGINAL METRICS ---
    final double principal = widget.account.loanPrincipal ?? 0.0;
    final double rate = widget.account.interestRate ?? 0.0;
    final int months = widget.account.tenureMonths ?? 0;
    final double currentBalance = widget.account.balance;

    double totalInterest = widget.account.totalInterestPayable ?? 0.0;
    bool isCustomInterest = widget.account.totalInterestPayable != null;
    if (!isCustomInterest && principal > 0 && rate > 0 && months > 0) {
      double r = rate / 12 / 100;
      double emi =
          principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
      totalInterest = (emi * months) - principal;
    }

    double? taxAmount = widget.account.totalTaxPayable;

    double? bankChargesAmount;
    try {
      bankChargesAmount = (widget.account as dynamic).bankCharges;
    } catch (_) {}

    // --- DYNAMIC LIVE METRICS ---
    double interestPaid = 0.0;
    double taxPaid = 0.0;
    double chargesPaid = 0.0;

    for (final item in widget.transactions) {
      if (item.transaction.subCategory == 'Loan Interest') {
        interestPaid += item.transaction.amount;
      } else if (item.transaction.subCategory == 'Tax on Interest') {
        taxPaid += item.transaction.amount;
      } else if (item.transaction.subCategory == 'Bank Charges on Loan') {
        chargesPaid += item.transaction.amount;
      }
    }

    double remainingInterest = totalInterest - interestPaid;
    double remainingTax = (taxAmount ?? 0.0) - taxPaid;
    double remainingCharges = (bankChargesAmount ?? 0.0) - chargesPaid;

    final double totalOutstanding =
        currentBalance + remainingInterest + remainingTax + remainingCharges;
    final double totalLoanAmount =
        principal +
        totalInterest +
        (taxAmount ?? 0.0) +
        (bankChargesAmount ?? 0.0);

    double progress = 0.0;
    if (totalLoanAmount > 0) {
      double paid = totalLoanAmount - totalOutstanding;
      progress = (paid / totalLoanAmount).clamp(0.0, 1.0);
    }

    // --- RESTORED SIGNS AND FORMATTING ---
    final outstandingSign = totalOutstanding > 0
        ? '-₹ '
        : (totalOutstanding < 0 ? '+₹ ' : '₹ ');
    final outstandingColor = (totalOutstanding <= 0 || widget.isSettled)
        ? Colors.green
        : theme.colorScheme.onSurface;
    final outstandingLabel = widget.isSettled
        ? 'SETTLED LOAN'
        : (totalOutstanding <= 0 ? 'CLEARED / SURPLUS' : 'TOTAL OUTSTANDING');

    final principalSign = currentBalance > 0
        ? '-₹ '
        : (currentBalance < 0 ? '+₹ ' : '₹ ');
    final principalColor = currentBalance <= 0
        ? Colors.green
        : theme.colorScheme.onSurface;

    final interestSign = remainingInterest > 0
        ? '-₹ '
        : (remainingInterest < 0 ? '+₹ ' : '₹ ');
    final interestColor = remainingInterest <= 0
        ? Colors.green
        : theme.colorScheme.error;

    final taxSign = remainingTax > 0
        ? '-₹ '
        : (remainingTax < 0 ? '+₹ ' : '₹ ');
    final taxColor = remainingTax <= 0
        ? Colors.green
        : Colors.orangeAccent.shade700;

    final chargesSign = remainingCharges > 0
        ? '-₹ '
        : (remainingCharges < 0 ? '+₹ ' : '₹ ');
    final chargesColor = remainingCharges <= 0
        ? Colors.green
        : Colors.orangeAccent.shade700;

    // View-Dependent Values
    final double displayTotal = _showOriginal
        ? totalLoanAmount
        : totalOutstanding.abs();
    final String displayTotalSign = _showOriginal ? '₹ ' : outstandingSign;
    final Color displayTotalColor = _showOriginal
        ? theme.colorScheme.onSurface
        : outstandingColor;

    final double displayPrincipal = _showOriginal
        ? principal
        : currentBalance.abs();
    final String displayPrincipalSign = _showOriginal ? '₹ ' : principalSign;
    final Color displayPrincipalColor = _showOriginal
        ? theme.colorScheme.onSurface
        : principalColor;

    final double displayInterest = _showOriginal
        ? totalInterest
        : remainingInterest.abs();
    final String displayInterestSign = _showOriginal ? '₹ ' : interestSign;
    final Color displayInterestColor = _showOriginal
        ? theme.colorScheme.onSurface
        : interestColor;

    final double displayTax = _showOriginal
        ? (taxAmount ?? 0.0)
        : remainingTax.abs();
    final String displayTaxSign = _showOriginal ? '₹ ' : taxSign;
    final Color displayTaxColor = _showOriginal
        ? theme.colorScheme.onSurface
        : taxColor;

    final double displayCharges = _showOriginal
        ? (bankChargesAmount ?? 0.0)
        : remainingCharges.abs();
    final String displayChargesSign = _showOriginal ? '₹ ' : chargesSign;
    final Color displayChargesColor = _showOriginal
        ? theme.colorScheme.onSurface
        : chargesColor;

    final labelStyle = TextStyle(
      fontSize: 8,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
      color: theme.colorScheme.onSurfaceVariant,
    );
    final valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: theme.colorScheme.onSurface,
      letterSpacing: -0.5,
    );
    final symbolStyle = TextStyle(
      fontSize: 9,
      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
    );

    // Format Strings for Dates
    String startDateStr = widget.account.loanStartDate != null
        ? '${widget.account.loanStartDate!.day} ${DateTimeConstants.shortMonths[widget.account.loanStartDate!.month - 1]} ${widget.account.loanStartDate!.year}'
        : '--';
    String endDateStr = widget.account.loanEndDate != null
        ? '${widget.account.loanEndDate!.day} ${DateTimeConstants.shortMonths[widget.account.loanEndDate!.month - 1]} ${widget.account.loanEndDate!.year}'
        : '--';
    String emiDayStr = widget.account.emiDate != null
        ? '${widget.account.emiDate!.day}'
        : '--';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _showOriginal ? 'ORIGINAL TERMS' : outstandingLabel,
                  key: ValueKey(_showOriginal),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: _showOriginal
                        ? theme.colorScheme.onSurfaceVariant
                        : (outstandingColor == Colors.green
                              ? Colors.green
                              : theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),

              // --- VIEW TOGGLE PILL ---
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showOriginal = !_showOriginal);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _showOriginal ? 'LIVE VIEW' : 'ORIGINAL TERMS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.swap_horiz_rounded,
                        size: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: FittedBox(
              key: ValueKey(_showOriginal),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CurrencyText(
                amount: displayTotal,
                sign: displayTotalSign,
                amountStyle: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: displayTotalColor,
                  letterSpacing: -0.5,
                ),
                symbolStyle: TextStyle(
                  fontSize: 14,
                  color: displayTotalColor.withOpacity(0.7),
                ),
              ),
            ),
          ),

          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _showOriginal
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Column(
              children: [
                if (totalLoanAmount > 0) ...[
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 4,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: widget.isSettled ? 1.0 : progress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: widget.isSettled
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            secondChild: Column(
              children: [
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDateMini('START DATE', startDateStr, theme),
                    _buildDateMini('END DATE', endDateStr, theme),
                    _buildDateMini('EMI DAY', emiDayStr, theme),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Divider(height: 1),
          ),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text('PRINCIPAL', style: labelStyle),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: CurrencyText(
                            key: ValueKey(_showOriginal),
                            amount: displayPrincipal,
                            sign: displayPrincipalSign,
                            amountStyle: valueStyle.copyWith(
                              color: displayPrincipalColor,
                            ),
                            symbolStyle: symbolStyle.copyWith(
                              color: displayPrincipalColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 16,
                  thickness: 1,
                  color: theme.dividerColor,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('INTEREST', style: labelStyle),
                          if (!widget.isSettled)
                            GestureDetector(
                              onTap: () => _triggerInterestEdit(
                                context,
                                ref,
                                totalInterest,
                                isCustomInterest,
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 4.0,
                                  bottom: 2.0,
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: CurrencyText(
                            key: ValueKey(_showOriginal),
                            amount: displayInterest,
                            sign: displayInterestSign,
                            amountStyle: valueStyle.copyWith(
                              color: displayInterestColor,
                            ),
                            symbolStyle: symbolStyle.copyWith(
                              color: displayInterestColor.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),

          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TAX', style: labelStyle),
                          if (!widget.isSettled)
                            GestureDetector(
                              onTap: () => _triggerTaxCalculation(
                                context,
                                ref,
                                totalInterest,
                              ),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 4.0,
                                  bottom: 2.0,
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (taxAmount != null || widget.isSettled) ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: CurrencyText(
                              key: ValueKey(_showOriginal),
                              amount: displayTax,
                              sign: displayTaxSign,
                              amountStyle: valueStyle.copyWith(
                                color: displayTaxColor,
                              ),
                              symbolStyle: symbolStyle.copyWith(
                                color: displayTaxColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: () => _triggerTaxCalculation(
                            context,
                            ref,
                            totalInterest,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Set Rate',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                VerticalDivider(
                  width: 16,
                  thickness: 1,
                  color: theme.dividerColor,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('BANK CHARGES', style: labelStyle),
                          if (!widget.isSettled)
                            GestureDetector(
                              onTap: () =>
                                  _triggerBankChargesEdit(context, ref),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 4.0,
                                  bottom: 2.0,
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (bankChargesAmount != null || widget.isSettled) ...[
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: CurrencyText(
                              key: ValueKey(_showOriginal),
                              amount: displayCharges,
                              sign: displayChargesSign,
                              amountStyle: valueStyle.copyWith(
                                color: displayChargesColor,
                              ),
                              symbolStyle: symbolStyle.copyWith(
                                color: displayChargesColor.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: () => _triggerBankChargesEdit(context, ref),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Add Fee',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyLoanMonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final ThemeData theme;
  _StickyLoanMonthHeaderDelegate({required this.title, required this.theme});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          color: theme.scaffoldBackgroundColor.withOpacity(0.85),
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 40.0;
  @override
  double get minExtent => 40.0;
  @override
  bool shouldRebuild(covariant _StickyLoanMonthHeaderDelegate oldDelegate) =>
      title != oldDelegate.title;
}

class _BankChargesBottomSheet extends StatefulWidget {
  const _BankChargesBottomSheet({Key? key}) : super(key: key);

  static Future<double?> show(BuildContext context) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => const _BankChargesBottomSheet(),
    );
  }

  @override
  State<_BankChargesBottomSheet> createState() =>
      _BankChargesBottomSheetState();
}

class _BankChargesBottomSheetState extends State<_BankChargesBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _apply() {
    if (!_formKey.currentState!.validate()) return;
    final val = double.tryParse(_ctrl.text);
    if (val != null && val >= 0) {
      Navigator.pop(context, val);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset + DesignTokens.spacingLg,
        left: DesignTokens.spacingLg,
        right: DesignTokens.spacingLg,
        top: DesignTokens.spacingSm,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Bank / Processing Charges',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              ModernBoxyInput(
                controller: _ctrl,
                labelText: 'Expected Total Fee (₹)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
                onFieldSubmitted: (_) => _apply(),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              Row(
                children: [
                  Expanded(
                    child: ModernBoxyButton(
                      onPressed: () => Navigator.pop(context),
                      label: 'Cancel',
                      isOutlined: true,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    flex: 2,
                    child: ModernBoxyButton(
                      onPressed: _apply,
                      label: 'Save Fee',
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
}
