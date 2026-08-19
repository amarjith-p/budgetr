import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/components/futuristic_loader.dart';

import '../../accounts/providers/account_provider.dart';
import '../../accounts/providers/credit_math_provider.dart';
import '../../accounts/providers/loan_math_provider.dart';
import '../../investments/providers/investment_provider.dart';
import '../../debts/providers/debt_provider.dart';
import '../../transactions/providers/transaction_provider.dart';
import '../providers/net_worth_record_provider.dart';

class NetWorthReconciliationPage extends ConsumerStatefulWidget {
  const NetWorthReconciliationPage({Key? key}) : super(key: key);

  @override
  ConsumerState<NetWorthReconciliationPage> createState() =>
      _NetWorthReconciliationPageState();
}

class _NetWorthReconciliationPageState
    extends ConsumerState<NetWorthReconciliationPage> {
  final _formKey = GlobalKey<FormState>();

  // --- ASSET CONTROLLERS ---
  final _accBalCtrl = TextEditingController();
  final _savingsCtrl = TextEditingController();
  final _mfCtrl = TextEditingController();
  final _stocksCtrl = TextEditingController();
  final _bondsCtrl = TextEditingController();
  final _fdCtrl = TextEditingController();
  final _rdCtrl = TextEditingController();
  final _p2pCtrl = TextEditingController();
  final _otherInvCtrl = TextEditingController();
  final _lentCtrl = TextEditingController();
  final _assetExtraCtrl = TextEditingController();

  // --- LIABILITY CONTROLLERS ---
  final _ccCtrl = TextEditingController();
  final _loanCtrl = TextEditingController();
  final _borrowedCtrl = TextEditingController();
  final _liabExtraCtrl = TextEditingController();

  // --- CASHFLOW CONTROLLERS ---
  final _cfTotalIncCtrl = TextEditingController();
  final _cfTotalExpCtrl = TextEditingController();
  final _cfBudgetIncCtrl = TextEditingController();
  final _cfBudgetExpCtrl = TextEditingController();
  final _cfNonCalcIncCtrl = TextEditingController();
  final _cfNonCalcExpCtrl = TextEditingController();
  final _cfOutOfBucketCtrl = TextEditingController();
  final _cfNetTotalCtrl = TextEditingController();
  final _cfNetBudgetedCtrl = TextEditingController();

  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _accBalCtrl.dispose();
    _savingsCtrl.dispose();
    _mfCtrl.dispose();
    _stocksCtrl.dispose();
    _bondsCtrl.dispose();
    _fdCtrl.dispose();
    _rdCtrl.dispose();
    _p2pCtrl.dispose();
    _otherInvCtrl.dispose();
    _lentCtrl.dispose();
    _assetExtraCtrl.dispose();
    _ccCtrl.dispose();
    _loanCtrl.dispose();
    _borrowedCtrl.dispose();
    _liabExtraCtrl.dispose();
    _cfTotalIncCtrl.dispose();
    _cfTotalExpCtrl.dispose();
    _cfBudgetIncCtrl.dispose();
    _cfBudgetExpCtrl.dispose();
    _cfNonCalcIncCtrl.dispose();
    _cfNonCalcExpCtrl.dispose();
    _cfOutOfBucketCtrl.dispose();
    _cfNetTotalCtrl.dispose();
    _cfNetBudgetedCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PREMIUM FULL-SCREEN LOADING OVERLAY
  // ===========================================================================
  void _showLoadingOverlay(String message) {
    FocusScope.of(context).unfocus(); // Drop keyboard
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => PopScope(
        canPop: false,
        child: Center(child: FuturisticLoader(size: 80, label: message)),
      ),
    );
  }

  void _hideLoadingOverlay() {
    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  // ===========================================================================
  // ENGINE 1: NET WORTH FETCHER
  // ===========================================================================
  Future<void> _fetchLiveNetWorth() async {
    HapticFeedback.selectionClick();
    _showLoadingOverlay("FETCHING LIVE BALANCES...");

    try {
      final accounts = await ref.read(accountsStreamProvider.future);
      final investments = await ref.read(investmentsStreamProvider.future);
      final debts = await ref.read(allDebtsProvider.future);

      double accBal = 0, savingsBal = 0;
      double mf = 0,
          stocks = 0,
          bonds = 0,
          fd = 0,
          rd = 0,
          p2p = 0,
          otherInv = 0;
      double lent = 0, borrowed = 0;
      double ccOut = 0, loanOut = 0;

      for (var acc in accounts) {
        if (acc.type == 'Credit Cards') {
          ccOut += ref.read(creditCardMetricsProvider(acc)).totalOutstanding;
        } else if (acc.type == 'Loan' && !acc.isClosed) {
          loanOut -= ref.read(loanTotalOutstandingProvider(acc));
        } else if (acc.type == 'Savings Account') {
          savingsBal += acc.balance;
        } else {
          accBal += acc.balance;
        }
      }

      for (var inv in investments) {
        if (!inv.isClosed) {
          switch (inv.type) {
            case 'Mutual Fund':
              mf += inv.currentValue;
              break;
            case 'Stocks':
              stocks += inv.currentValue;
              break;
            case 'Bonds':
              bonds += inv.currentValue;
              break;
            case 'Fixed Deposit':
              fd += inv.currentValue;
              break;
            case 'Recurring Deposit':
              rd += inv.currentValue;
              break;
            case 'P2P Lending':
              p2p += inv.currentValue;
              break;
            case 'Savings Account':
              savingsBal += inv.currentValue;
              break;
            default:
              otherInv += inv.currentValue;
              break;
          }
        }
      }

      for (var d in debts) {
        if (!d.isSettled) {
          final remaining = d.amount - d.settledAmount;
          if (d.type == 'Lent')
            lent += remaining;
          else if (d.type == 'Borrowed')
            borrowed -= remaining;
        }
      }

      _accBalCtrl.text = accBal.toStringAsFixed(2);
      _savingsCtrl.text = savingsBal.toStringAsFixed(2);
      _mfCtrl.text = mf.toStringAsFixed(2);
      _stocksCtrl.text = stocks.toStringAsFixed(2);
      _bondsCtrl.text = bonds.toStringAsFixed(2);
      _fdCtrl.text = fd.toStringAsFixed(2);
      _rdCtrl.text = rd.toStringAsFixed(2);
      _p2pCtrl.text = p2p.toStringAsFixed(2);
      _otherInvCtrl.text = otherInv.toStringAsFixed(2);
      _lentCtrl.text = lent.toStringAsFixed(2);

      _ccCtrl.text = ccOut.toStringAsFixed(2);
      _loanCtrl.text = loanOut.toStringAsFixed(2);
      _borrowedCtrl.text = borrowed.toStringAsFixed(2);

      _hideLoadingOverlay();
      if (mounted) {
        CustomSnackbars.showSuccess(
          context,
          message: 'Live Net Worth Balances fetched.',
        );
      }
    } catch (e) {
      _hideLoadingOverlay();
      if (mounted) {
        CustomSnackbars.showError(
          context,
          message: 'Failed to fetch balances: $e',
        );
      }
    }
  }

  // ===========================================================================
  // ENGINE 2: MONTHLY CASHFLOW FETCHER
  // ===========================================================================
  Future<void> _fetchMonthlyCashflow() async {
    HapticFeedback.selectionClick();
    _showLoadingOverlay("CALCULATING CASHFLOW...");

    try {
      final now = DateTime.now();
      final txs = await ref.read(allTransactionsProvider.future);

      final monthTxs = txs.where(
        (t) =>
            t.transaction.date.month == now.month &&
            t.transaction.date.year == now.year,
      );

      double tInc = 0, tExp = 0, ncInc = 0, ncExp = 0, bExp = 0, outBucket = 0;

      for (var data in monthTxs) {
        final tx = data.transaction;
        if (tx.type == 'Income') {
          tInc += tx.amount;
          if (tx.subCategory == 'Non-Calculated Income') ncInc += tx.amount;
        } else if (tx.type == 'Expense') {
          tExp += tx.amount;
          if (tx.subCategory == 'Non-Calculated Expenses') {
            ncExp += tx.amount;
          } else {
            if (tx.bucketId == null || tx.bucketId == -1) {
              outBucket += tx.amount;
            } else {
              bExp += tx.amount;
            }
          }
        }
      }

      final db = ref.read(databaseProvider);
      final budget =
          await (db.select(db.monthlyBudgets)..where(
                (b) => b.month.equals(now.month) & b.year.equals(now.year),
              ))
              .getSingleOrNull();

      double bInc = 0;
      if (budget != null) {
        bInc = budget.salaryIncome + budget.extraIncome - budget.deductions;
      }

      _cfTotalIncCtrl.text = tInc.toStringAsFixed(2);
      _cfTotalExpCtrl.text = tExp.toStringAsFixed(2);
      _cfBudgetIncCtrl.text = bInc.toStringAsFixed(2);
      _cfBudgetExpCtrl.text = bExp.toStringAsFixed(2);
      _cfNonCalcIncCtrl.text = ncInc.toStringAsFixed(2);
      _cfNonCalcExpCtrl.text = ncExp.toStringAsFixed(2);
      _cfOutOfBucketCtrl.text = outBucket.toStringAsFixed(2);

      _hideLoadingOverlay();
      if (mounted) {
        CustomSnackbars.showSuccess(
          context,
          message: 'Monthly Cashflow fetched.',
        );
      }
    } catch (e) {
      _hideLoadingOverlay();
      if (mounted) {
        CustomSnackbars.showError(
          context,
          message: 'Failed to fetch cashflow: $e',
        );
      }
    }
  }

  // ===========================================================================
  // ENGINE 3: CASHFLOW CALCULATOR
  // ===========================================================================
  void _calculateCashflow() {
    HapticFeedback.mediumImpact();
    FocusScope.of(context).unfocus();

    double parseAmt(TextEditingController ctrl) =>
        double.tryParse(ctrl.text) ?? 0.0;

    final tInc = parseAmt(_cfTotalIncCtrl);
    final tExp = parseAmt(_cfTotalExpCtrl);
    final bInc = parseAmt(_cfBudgetIncCtrl);
    final bExp = parseAmt(_cfBudgetExpCtrl);

    final netTotal = tInc - tExp;
    final netBudgeted = bInc - bExp;

    _cfNetTotalCtrl.text = netTotal.toStringAsFixed(2);
    _cfNetBudgetedCtrl.text = netBudgeted.toStringAsFixed(2);
  }

  // ===========================================================================
  // SAVE & VALIDATE
  // ===========================================================================
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    double parseAmt(TextEditingController ctrl) =>
        double.tryParse(ctrl.text) ?? 0.0;

    double parseLiability(TextEditingController ctrl) {
      final val = double.tryParse(ctrl.text) ?? 0.0;
      return val > 0 ? -val : val; // Force Negative mathematically[cite: 15]
    }

    final allControllers = [
      _accBalCtrl,
      _savingsCtrl,
      _mfCtrl,
      _stocksCtrl,
      _bondsCtrl,
      _fdCtrl,
      _rdCtrl,
      _p2pCtrl,
      _otherInvCtrl,
      _lentCtrl,
      _assetExtraCtrl,
      _ccCtrl,
      _loanCtrl,
      _borrowedCtrl,
      _liabExtraCtrl,
      _cfTotalIncCtrl,
      _cfTotalExpCtrl,
      _cfBudgetIncCtrl,
      _cfBudgetExpCtrl,
      _cfNonCalcIncCtrl,
      _cfNonCalcExpCtrl,
      _cfOutOfBucketCtrl,
      _cfNetTotalCtrl,
      _cfNetBudgetedCtrl,
    ];

    double totalAbsoluteSum = 0.0;
    for (var ctrl in allControllers) {
      totalAbsoluteSum += parseAmt(ctrl).abs();
    }

    if (totalAbsoluteSum == 0.0) {
      HapticFeedback.heavyImpact();
      CustomSnackbars.showError(
        context,
        message: 'Reconciliation cannot be empty. Please fetch or enter data.',
      );
      return;
    }

    HapticFeedback.selectionClick();

    final entry = NetWorthRecordsCompanion(
      assetAccountBalance: drift.Value(parseAmt(_accBalCtrl)),
      assetSavings: drift.Value(parseAmt(_savingsCtrl)),
      assetMutualFunds: drift.Value(parseAmt(_mfCtrl)),
      assetStocks: drift.Value(parseAmt(_stocksCtrl)),
      assetBonds: drift.Value(parseAmt(_bondsCtrl)),
      assetFixedDeposits: drift.Value(parseAmt(_fdCtrl)),
      assetRecurringDeposits: drift.Value(parseAmt(_rdCtrl)),
      assetP2PLending: drift.Value(parseAmt(_p2pCtrl)),
      assetOtherInvestments: drift.Value(parseAmt(_otherInvCtrl)),
      assetLentDebts: drift.Value(parseAmt(_lentCtrl)),
      assetExtraOthers: drift.Value(parseAmt(_assetExtraCtrl)),

      liabilityCreditCards: drift.Value(parseLiability(_ccCtrl)),
      liabilityLoans: drift.Value(parseLiability(_loanCtrl)),
      liabilityBorrowedDebts: drift.Value(parseLiability(_borrowedCtrl)),
      liabilityExtraOthers: drift.Value(parseLiability(_liabExtraCtrl)),

      cashflowTotalIncome: drift.Value(parseAmt(_cfTotalIncCtrl)),
      cashflowTotalExpense: drift.Value(parseAmt(_cfTotalExpCtrl)),
      cashflowBudgetedIncome: drift.Value(parseAmt(_cfBudgetIncCtrl)),
      cashflowBudgetedExpense: drift.Value(parseAmt(_cfBudgetExpCtrl)),
      cashflowNonCalcIncome: drift.Value(parseAmt(_cfNonCalcIncCtrl)),
      cashflowNonCalcExpense: drift.Value(parseAmt(_cfNonCalcExpCtrl)),
      cashflowOutOfBucket: drift.Value(parseAmt(_cfOutOfBucketCtrl)),
      cashflowNetTotal: drift.Value(parseAmt(_cfNetTotalCtrl)),
      cashflowNetBudgeted: drift.Value(parseAmt(_cfNetBudgetedCtrl)),

      notes: drift.Value(
        _notesCtrl.text.trim().isNotEmpty ? _notesCtrl.text.trim() : null,
      ),
    );

    final success = await ref
        .read(netWorthRecordActionProvider.notifier)
        .saveRecord(entry);

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================
  Widget _buildSectionCard({
    required String title,
    required Color accentColor,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRowInput(
    String label1,
    TextEditingController ctrl1,
    String label2,
    TextEditingController ctrl2,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            child: ModernBoxyInput(
              controller: ctrl1,
              labelText: label1,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ModernBoxyInput(
              controller: ctrl2,
              labelText: label2,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBanner({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.primary.withOpacity(0.5),
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
    final actionState = ref.watch(netWorthRecordActionProvider);

    // --- KEEP ALL PROVIDERS ALIVE TO PREVENT DISPOSAL CRASHES ---
    ref.watch(accountsStreamProvider);
    ref.watch(investmentsStreamProvider);
    ref.watch(allTransactionsProvider);
    ref.watch(allDebtsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Reconciliation',
        subtitle: 'MONTHLY SNAPSHOT',
        leadingIcon: Icons.close_rounded,
      ),
      // --- STICKY BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(color: theme.dividerColor, width: 1.0),
            ),
          ),
          child: ModernBoxyButton(
            onPressed: _submit,
            label: 'SAVE SNAPSHOT',
            icon: Icons.check_circle_rounded,
            isLoading: actionState.isLoading,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(DesignTokens.spacingLg),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- NET WORTH SECTION ---
                    _buildActionBanner(
                      label: 'Auto-Fetch Live Balances',
                      icon: Icons.account_balance_wallet_rounded,
                      onTap: _fetchLiveNetWorth,
                      theme: theme,
                    ),

                    _buildSectionCard(
                      title: 'Assets',
                      accentColor: Colors.green,
                      theme: theme,
                      children: [
                        _buildRowInput(
                          'Account Balance',
                          _accBalCtrl,
                          'Savings Accounts',
                          _savingsCtrl,
                        ),
                        _buildRowInput(
                          'Mutual Funds',
                          _mfCtrl,
                          'Stocks / Equity',
                          _stocksCtrl,
                        ),
                        _buildRowInput(
                          'Bonds',
                          _bondsCtrl,
                          'Fixed Deposits',
                          _fdCtrl,
                        ),
                        _buildRowInput(
                          'Recurring Deposits',
                          _rdCtrl,
                          'P2P Lending',
                          _p2pCtrl,
                        ),
                        _buildRowInput(
                          'Other Investments',
                          _otherInvCtrl,
                          'Lent (I am owed)',
                          _lentCtrl,
                        ),
                        ModernBoxyInput(
                          controller: _assetExtraCtrl,
                          labelText: 'Any Extra Asset Value (Manual)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    ),

                    _buildSectionCard(
                      title: 'Liabilities (-ve)',
                      accentColor: theme.colorScheme.error,
                      theme: theme,
                      children: [
                        _buildRowInput(
                          'Credit Card Dues',
                          _ccCtrl,
                          'Loan Outstanding',
                          _loanCtrl,
                        ),
                        _buildRowInput(
                          'Borrowed (I owe)',
                          _borrowedCtrl,
                          'Any Extra Liability',
                          _liabExtraCtrl,
                        ),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1),
                    ),
                    const SizedBox(height: 24),

                    // --- CASHFLOW SECTION ---
                    _buildActionBanner(
                      label: 'Auto-Fetch Current Cashflow',
                      icon: Icons.sync_rounded,
                      onTap: _fetchMonthlyCashflow,
                      theme: theme,
                    ),

                    _buildSectionCard(
                      title: 'Monthly Cashflow',
                      accentColor: Colors.blueAccent,
                      theme: theme,
                      children: [
                        _buildRowInput(
                          'Total Income',
                          _cfTotalIncCtrl,
                          'Total Expense',
                          _cfTotalExpCtrl,
                        ),
                        _buildRowInput(
                          'Budgeted Income',
                          _cfBudgetIncCtrl,
                          'Budgeted Expense',
                          _cfBudgetExpCtrl,
                        ),
                        _buildRowInput(
                          'Non-Calc Income',
                          _cfNonCalcIncCtrl,
                          'Non-Calc Expense',
                          _cfNonCalcExpCtrl,
                        ),
                        ModernBoxyInput(
                          controller: _cfOutOfBucketCtrl,
                          labelText: 'Out of Bucket Expenses',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),

                        // Inline Calculation Button
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: ModernBoxyButton(
                            onPressed: _calculateCashflow,
                            label: 'Calculate Net Totals',
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            foregroundColor: theme.colorScheme.onSurface,
                            icon: Icons.calculate_rounded,
                          ),
                        ),

                        _buildRowInput(
                          'Net Total Cashflow',
                          _cfNetTotalCtrl,
                          'Net Budgeted Cashflow',
                          _cfNetBudgetedCtrl,
                        ),
                      ],
                    ),

                    // --- METADATA SECTION ---
                    _buildSectionCard(
                      title: 'Metadata',
                      accentColor: theme.colorScheme.onSurfaceVariant,
                      theme: theme,
                      children: [
                        ModernBoxyInput(
                          controller: _notesCtrl,
                          labelText: 'Reconciliation Notes (Optional)',
                          hintText: 'e.g., Q3 Financial Review',
                        ),
                      ],
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
}
