import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/constants/date_time_constants.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/custom_snackbars.dart';
import '../../../core/components/futuristic_loader.dart';
import '../../../core/components/inline_calculator_pad.dart';
import '../../../core/utils/bodmas_calculator.dart';

import '../../accounts/providers/account_provider.dart';
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

  // --- TIME TRAVEL & TRANSPARENCY STATE ---
  DateTime _targetMonth = DateTime.now();

  bool _hasComputedData = false;
  int _rolledBackTxCount = 0;
  double _rolledBackNetFlow = 0.0;
  int _omittedInvestmentCount = 0;
  double _omittedInvestmentsValue = 0.0;
  int _omittedDebtCount = 0;
  double _omittedDebtsValue = 0.0;

  List<String> _omittedTxDetails = [];
  List<String> _omittedInvDetails = [];
  List<String> _omittedDebtDetails = [];

  DateTime get _endOfTargetMonth {
    final now = DateTime.now();
    if (_targetMonth.year == now.year && _targetMonth.month == now.month) {
      return now; // If current month, use exactly now
    }
    // Last millisecond of the selected month
    return DateTime(_targetMonth.year, _targetMonth.month + 1, 0, 23, 59, 59);
  }

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

  // --- CALCULATOR ENGINE ---
  TextEditingController? _activeCalcController;
  final Map<TextEditingController, FocusNode> _focusNodes = {};
  final FocusNode _notesFocus = FocusNode();

  late final List<TextEditingController> _orderedCalcCtrls = [
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

  @override
  void initState() {
    super.initState();
    // Initialize focus nodes and listeners for the calculator
    for (var ctrl in _orderedCalcCtrls) {
      _focusNodes[ctrl] = FocusNode();
      _focusNodes[ctrl]!.addListener(() {
        if (_focusNodes[ctrl]!.hasFocus && _activeCalcController != ctrl) {
          _openCalculatorFor(ctrl);
        }
      });
    }

    _notesFocus.addListener(() {
      if (_notesFocus.hasFocus) {
        _closeCalculatorSafely();
      }
    });
  }

  @override
  void dispose() {
    _closeCalculatorSafely();
    for (var node in _focusNodes.values) {
      node.dispose();
    }
    _notesFocus.dispose();
    for (var ctrl in _orderedCalcCtrls) {
      ctrl.dispose();
    }
    _notesCtrl.dispose();
    super.dispose();
  }

  // ===========================================================================
  // CALCULATOR NAVIGATION & FOCUS ENGINE
  // ===========================================================================
  void _openCalculatorFor(TextEditingController controller) {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    if (_activeCalcController != null && _activeCalcController != controller) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty
          ? ''
          : BodmasCalculator.evaluate(text);
    }
    setState(() => _activeCalcController = controller);
    if (!_focusNodes[controller]!.hasFocus) {
      _focusNodes[controller]!.requestFocus();
    }

    // Ensure the field scrolls perfectly into the center of the viewport
    Future.delayed(const Duration(milliseconds: 150), () {
      final context = _focusNodes[controller]?.context;
      if (context != null && mounted) {
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _closeCalculatorSafely() {
    if (_activeCalcController != null) {
      final text = _activeCalcController!.text.trim();
      _activeCalcController!.text = text.isEmpty
          ? ''
          : BodmasCalculator.evaluate(text);
      setState(() => _activeCalcController = null);
    }
  }

  void _handleCalcNext() {
    if (_activeCalcController == null) return;
    final currentIndex = _orderedCalcCtrls.indexOf(_activeCalcController!);
    if (currentIndex >= 0 && currentIndex < _orderedCalcCtrls.length - 1) {
      _openCalculatorFor(_orderedCalcCtrls[currentIndex + 1]);
    } else {
      // Reached the end of numerical inputs, jump to Notes
      _closeCalculatorSafely();
      _notesFocus.requestFocus();
      SystemChannels.textInput.invokeMethod('TextInput.show');
    }
  }

  void _handleCalcPrev() {
    if (_activeCalcController == null) return;
    final currentIndex = _orderedCalcCtrls.indexOf(_activeCalcController!);
    if (currentIndex > 0) {
      _openCalculatorFor(_orderedCalcCtrls[currentIndex - 1]);
    }
  }

  void _showLoadingOverlay(String message) {
    _closeCalculatorSafely();
    FocusScope.of(context).unfocus();
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
  // MODERN DIALOG MONTH PICKER
  // ===========================================================================
  Future<void> _pickTargetMonth() async {
    HapticFeedback.selectionClick();
    DateTime tempDate = _targetMonth;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final theme = Theme.of(context);
            final isDark = theme.brightness == Brightness.dark;

            return Dialog(
              backgroundColor: theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.chevron_left_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setDialogState(
                              () => tempDate = DateTime(
                                tempDate.year - 1,
                                tempDate.month,
                              ),
                            );
                          },
                        ),
                        Text(
                          '${tempDate.year}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setDialogState(
                              () => tempDate = DateTime(
                                tempDate.year + 1,
                                tempDate.month,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: List.generate(12, (index) {
                        final m = index + 1;
                        final isSelected =
                            tempDate.year == _targetMonth.year &&
                            m == _targetMonth.month;

                        return InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.pop(ctx, DateTime(tempDate.year, m));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(isDark ? 0.3 : 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                DateTimeConstants.shortMonths[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _targetMonth = picked;
        _hasComputedData = false;
      });
    }
  }

  // ===========================================================================
  // MATHEMATICAL INVERSE: COMPUTES THE ROLLBACK AMOUNT FOR ANY GIVEN ACCOUNT
  // ===========================================================================
  double _computeRollback(TransactionRecord t, String accountId) {
    double rollbackAmt = 0.0;
    if (t.accountId == accountId) {
      bool isLoanFee =
          t.subCategory == 'Loan Interest' ||
          t.subCategory == 'Tax on Interest' ||
          t.subCategory == 'Bank Charges on Loan' ||
          t.subCategory == 'Bank Charges';

      if (t.type == 'Expense' && !isLoanFee) rollbackAmt += t.amount;
      if (t.type == 'Income') rollbackAmt -= t.amount;
      if (t.type == 'Transfer') {
        if (t.toAccountId == 'EXTERNAL_IN')
          rollbackAmt -= t.amount;
        else if (t.toAccountId == 'EXTERNAL_OUT')
          rollbackAmt += t.amount;
        else
          rollbackAmt += t.amount;
      }
    }
    if (t.toAccountId == accountId && t.type == 'Transfer') {
      rollbackAmt -= t.amount;
    }
    return rollbackAmt;
  }

  // ===========================================================================
  // ENGINE 1: "TIME TRAVEL" NET WORTH FETCHER
  // ===========================================================================
  Future<void> _fetchComputedNetWorth() async {
    HapticFeedback.selectionClick();
    _showLoadingOverlay("COMPUTING HISTORICAL BALANCES...");

    try {
      final accounts = await ref.read(accountsStreamProvider.future);
      final investments = await ref.read(investmentsStreamProvider.future);
      final invLogs = await ref.read(allInvestmentLogsStreamProvider.future);
      final debts = await ref.read(allDebtsProvider.future);
      final txs = await ref.read(allTransactionsProvider.future);

      final endOfMonth = _endOfTargetMonth;
      final now = DateTime.now();
      final isPastMonth =
          endOfMonth.year < now.year ||
          (endOfMonth.year == now.year && endOfMonth.month < now.month);

      final Map<String, double> rollbacks = {};

      _rolledBackTxCount = 0;
      _rolledBackNetFlow = 0.0;
      _omittedInvestmentCount = 0;
      _omittedInvestmentsValue = 0.0;
      _omittedDebtCount = 0;
      _omittedDebtsValue = 0.0;

      _omittedTxDetails.clear();
      _omittedInvDetails.clear();
      _omittedDebtDetails.clear();

      String getAccName(String id) {
        return accounts.where((a) => a.id == id).firstOrNull?.name ??
            'Unknown Account';
      }

      // 1. REVERSE ROLLBACK FOR CORE ACCOUNTS (Assets & Credit Cards)
      for (var data in txs) {
        final t = data.transaction;
        if (t.date.isAfter(endOfMonth)) {
          _rolledBackTxCount++;
          final dateStr = DateFormat('dd MMM').format(t.date);
          String detailStr = '$dateStr: ';

          final rollAmt = _computeRollback(t, t.accountId);
          if (rollAmt != 0) {
            rollbacks[t.accountId] = (rollbacks[t.accountId] ?? 0) + rollAmt;
          }
          if (t.toAccountId != null) {
            final toRollAmt = _computeRollback(t, t.toAccountId!);
            if (toRollAmt != 0) {
              rollbacks[t.toAccountId!] =
                  (rollbacks[t.toAccountId!] ?? 0) + toRollAmt;
            }
          }

          // Build Transparency Note
          if (t.type == 'Expense') {
            _rolledBackNetFlow -= t.amount;
            detailStr +=
                'Expense of ${CurrencyFormatter.format(t.amount)} from ${getAccName(t.accountId)}';
            if (t.subCategory != null) detailStr += ' (${t.subCategory})';
          } else if (t.type == 'Income') {
            _rolledBackNetFlow += t.amount;
            detailStr +=
                'Income of ${CurrencyFormatter.format(t.amount)} to ${getAccName(t.accountId)}';
          } else if (t.type == 'Transfer') {
            if (t.toAccountId == 'EXTERNAL_IN') {
              _rolledBackNetFlow += t.amount;
              detailStr +=
                  'Transfer In of ${CurrencyFormatter.format(t.amount)} to ${getAccName(t.accountId)}';
            } else if (t.toAccountId == 'EXTERNAL_OUT') {
              _rolledBackNetFlow -= t.amount;
              detailStr +=
                  'Transfer Out of ${CurrencyFormatter.format(t.amount)} from ${getAccName(t.accountId)}';
            } else {
              detailStr +=
                  'Transfer of ${CurrencyFormatter.format(t.amount)} from ${getAccName(t.accountId)} to ${getAccName(t.toAccountId!)}';
            }
          }
          _omittedTxDetails.add(detailStr);
        }
      }

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
        if (acc.type == 'Loan' && !acc.isClosed) {
          final loanTxsData = await ref.read(
            accountTransactionsProvider(acc.id).future,
          );

          double loanRollback = 0.0;
          for (var d in loanTxsData) {
            final t = d.transaction;
            if (t.date.isAfter(endOfMonth)) {
              final amt = _computeRollback(t, acc.id);
              if (amt != 0) {
                loanRollback += amt;
                _rolledBackTxCount++;
                _omittedTxDetails.add(
                  '${DateFormat('dd MMM').format(t.date)}: Rolled back ${CurrencyFormatter.format(t.amount)} for Loan ${acc.name}',
                );
              }
            }
          }

          final historicalBal = acc.balance + loanRollback;

          final double principal = acc.loanPrincipal ?? 0.0;
          final double rate = acc.interestRate ?? 0.0;
          final int months = acc.tenureMonths ?? 0;

          double totalInterest = acc.totalInterestPayable ?? 0.0;
          bool isCustomInterest = acc.totalInterestPayable != null;

          if (!isCustomInterest && principal > 0 && rate > 0 && months > 0) {
            double r = rate / 12 / 100;
            double emi =
                principal * r * pow(1 + r, months) / (pow(1 + r, months) - 1);
            totalInterest = (emi * months) - principal;
          }

          double? taxAmount = acc.totalTaxPayable;
          double? bankChargesAmount = acc.bankCharges;

          double interestPaid = 0.0;
          double taxPaid = 0.0;
          double chargesPaid = 0.0;

          final pastLoanTxs = loanTxsData.where(
            (d) => !d.transaction.date.isAfter(endOfMonth),
          );

          for (var d in pastLoanTxs) {
            final t = d.transaction;
            if (t.accountId == acc.id) {
              if (t.subCategory == 'Loan Interest')
                interestPaid += t.amount;
              else if (t.subCategory == 'Tax on Interest')
                taxPaid += t.amount;
              else if (t.subCategory == 'Bank Charges on Loan' ||
                  t.subCategory == 'Bank Charges')
                chargesPaid += t.amount;
            }
          }

          double remainingInterest = totalInterest - interestPaid;
          double remainingTax = 0.0;
          if (taxAmount != null) remainingTax = taxAmount - taxPaid;

          double remainingCharges = 0.0;
          if (bankChargesAmount != null)
            remainingCharges = bankChargesAmount - chargesPaid;

          final totalOutstanding =
              historicalBal +
              remainingInterest +
              remainingTax +
              remainingCharges;
          loanOut -= totalOutstanding;
        } else {
          final rollbackAmt = rollbacks[acc.id] ?? 0.0;
          final historicalBal = acc.balance + rollbackAmt;

          if (acc.type == 'Credit Cards') {
            ccOut += historicalBal;
          } else if (acc.type == 'Savings Account') {
            savingsBal += historicalBal;
          } else if (acc.type != 'Loan') {
            accBal += historicalBal;
          }
        }
      }

      // 2. CHRONOLOGICAL RECONSTRUCTION FOR INVESTMENTS
      for (var inv in investments) {
        if (inv.startDate.isAfter(endOfMonth)) {
          _omittedInvestmentCount++;
          _omittedInvestmentsValue += inv.currentValue;
          _omittedInvDetails.add(
            '${inv.name}: Created in future (Value: ${CurrencyFormatter.format(inv.currentValue)})',
          );
          continue;
        }

        double historicalVal = 0.0;
        final allLogsForInv = invLogs
            .where((l) => l.investmentId == inv.id)
            .toList();

        if (allLogsForInv.isEmpty) {
          historicalVal = inv.currentValue;
        } else {
          historicalVal = inv.initialAmount;
          final pastLogs = allLogsForInv
              .where((l) => !l.date.isAfter(endOfMonth))
              .toList();
          pastLogs.sort((a, b) => a.date.compareTo(b.date));

          // FIX: Smart Deduplication safeguard for older databases where initial amount and deposit log mirrored each other
          if (pastLogs.isNotEmpty &&
              pastLogs.first.type == 'Deposit' &&
              pastLogs.first.amount == inv.initialAmount &&
              inv.initialAmount > 0) {
            final diff = pastLogs.first.date
                .difference(inv.startDate)
                .inHours
                .abs();
            if (diff < 24) {
              historicalVal =
                  0.0; // The deposit log will naturally add the initial amount
            }
          }

          for (var log in pastLogs) {
            if (log.type == 'Update')
              historicalVal = log.amount;
            else if (log.type == 'Deposit')
              historicalVal += log.amount;
            else if (log.type == 'Withdrawal')
              historicalVal -= log.amount;
          }

          final futureLogs = allLogsForInv
              .where((l) => l.date.isAfter(endOfMonth))
              .toList();
          for (var log in futureLogs) {
            _omittedInvDetails.add(
              '${inv.name}: Future ${log.type} of ${CurrencyFormatter.format(log.amount)} omitted',
            );
          }
        }

        // FIX: Investment Savings Accounts explicitly drop to default (Other Investments) to prevent visual combining with Tracker Accounts
        switch (inv.type) {
          case 'Mutual Fund':
            mf += historicalVal;
            break;
          case 'Stocks':
            stocks += historicalVal;
            break;
          case 'Bonds':
            bonds += historicalVal;
            break;
          case 'Fixed Deposit':
            fd += historicalVal;
            break;
          case 'Recurring Deposit':
            rd += historicalVal;
            break;
          case 'P2P Lending':
            p2p += historicalVal;
            break;
          default:
            otherInv += historicalVal;
            break;
        }
      }

      // 3. DATE-FILTERED APPROXIMATION FOR DEBTS
      for (var d in debts) {
        if (d.date.isAfter(endOfMonth)) {
          _omittedDebtCount++;
          final remaining = d.amount - d.settledAmount;
          _omittedDebtsValue += (remaining > 0 ? remaining : 0.0);
          _omittedDebtDetails.add(
            '${d.person} (${d.type}): Created in future (Amount: ${CurrencyFormatter.format(d.amount)})',
          );
          continue;
        }

        double remaining = d.amount;

        if (!isPastMonth) {
          remaining = d.amount - d.settledAmount;
        } else if (d.settledAmount > 0) {
          _omittedDebtDetails.add(
            '${d.person} (${d.type}): Settlement of ${CurrencyFormatter.format(d.settledAmount)} omitted',
          );
        }

        if (remaining > 0) {
          if (d.type == 'Lent') {
            lent += remaining;
          } else if (d.type == 'Borrowed') {
            borrowed -= remaining;
          }
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

      setState(() => _hasComputedData = true);
      _hideLoadingOverlay();

      if (mounted) {
        CustomSnackbars.showSuccess(
          context,
          message:
              'Computed Balances for ${DateFormat('MMM yyyy').format(_targetMonth)} fetched.',
        );
      }
    } catch (e) {
      _hideLoadingOverlay();
      if (mounted) {
        CustomSnackbars.showError(
          context,
          message: 'Failed to compute balances: $e',
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
      final txs = await ref.read(allTransactionsProvider.future);
      final accounts = await ref.read(accountsStreamProvider.future);

      bool isLoanAcc(String id) =>
          accounts.any((a) => a.id == id && a.type == 'Loan');

      final monthTxs = txs.where(
        (t) =>
            t.transaction.date.month == _targetMonth.month &&
            t.transaction.date.year == _targetMonth.year,
      );

      double tInc = 0, tExp = 0, ncInc = 0, ncExp = 0, bExp = 0, outBucket = 0;

      for (var data in monthTxs) {
        final tx = data.transaction;

        if (isLoanAcc(tx.accountId)) continue;

        if (tx.type == 'Income') {
          tInc += tx.amount;
          if (tx.subCategory == 'Non-Calculated Income') ncInc += tx.amount;
        } else if (tx.type == 'Expense') {
          bool isLoanTx = tx.id.startsWith('LOAN_TX_');
          tExp += tx.amount;

          if (tx.subCategory == 'Non-Calculated Expenses') {
            ncExp += tx.amount;
          }

          if (!isLoanTx) {
            // FIX: Identical match to monthly_budget_transactions_page.dart out-of-bucket logic
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
                (b) =>
                    b.month.equals(_targetMonth.month) &
                    b.year.equals(_targetMonth.year),
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
    _closeCalculatorSafely();
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
    _closeCalculatorSafely();
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    double parseAmt(TextEditingController ctrl) =>
        double.tryParse(ctrl.text) ?? 0.0;

    double parseLiability(TextEditingController ctrl) {
      final val = double.tryParse(ctrl.text) ?? 0.0;
      return val > 0 ? -val : val; // Force Negative mathematically
    }

    double totalAbsoluteSum = 0.0;
    for (var ctrl in _orderedCalcCtrls) {
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
      recordedAt: drift.Value(_endOfTargetMonth),
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
        borderRadius: BorderRadius.circular(8),
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
              focusNode: _focusNodes[ctrl1],
              labelText: label1,
              readOnly: true,
              onTap: () => _openCalculatorFor(ctrl1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ModernBoxyInput(
              controller: ctrl2,
              focusNode: _focusNodes[ctrl2],
              labelText: label2,
              readOnly: true,
              onTap: () => _openCalculatorFor(ctrl2),
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
        onTap: () {
          _closeCalculatorSafely();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05),
            borderRadius: BorderRadius.circular(8),
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

  Widget _buildOmissionCategoryHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildOmissionItem(String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(color: theme.colorScheme.primary, fontSize: 12),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransparencyBanner(ThemeData theme) {
    if (!_hasComputedData) return const SizedBox.shrink();
    if (_omittedTxDetails.isEmpty &&
        _omittedInvDetails.isEmpty &&
        _omittedDebtDetails.isEmpty)
      return const SizedBox.shrink();

    final isDark = theme.brightness == Brightness.dark;
    final totalOmissions =
        _omittedTxDetails.length +
        _omittedInvDetails.length +
        _omittedDebtDetails.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(
          isDark ? 0.2 : 0.4,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            Icons.history_toggle_off_rounded,
            color: theme.colorScheme.primary,
          ),
          title: Text(
            'TIME-TRAVEL AUDIT TRAIL',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: theme.colorScheme.primary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              '$totalOmissions future records reversed',
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          children: [
            if (_omittedTxDetails.isNotEmpty) ...[
              _buildOmissionCategoryHeader(
                'FUTURE TRANSACTIONS ROLLED BACK',
                theme,
              ),
              ..._omittedTxDetails.map((d) => _buildOmissionItem(d, theme)),
              const SizedBox(height: 12),
            ],
            if (_omittedInvDetails.isNotEmpty) ...[
              _buildOmissionCategoryHeader('NEWER INVESTMENTS EXCLUDED', theme),
              ..._omittedInvDetails.map((d) => _buildOmissionItem(d, theme)),
              const SizedBox(height: 12),
            ],
            if (_omittedDebtDetails.isNotEmpty) ...[
              _buildOmissionCategoryHeader(
                'NEWER DEBTS & SETTLEMENTS EXCLUDED',
                theme,
              ),
              ..._omittedDebtDetails.map((d) => _buildOmissionItem(d, theme)),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actionState = ref.watch(netWorthRecordActionProvider);

    ref.watch(accountsStreamProvider);
    ref.watch(investmentsStreamProvider);
    ref.watch(allInvestmentLogsStreamProvider);
    ref.watch(allTransactionsProvider);
    ref.watch(allDebtsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Reconciliation',
        subtitle: 'MONTHLY SNAPSHOT',
        leadingIcon: Icons.close_rounded,
      ),
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
      body: Column(
        children: [
          Expanded(
            child: Form(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.analytics_rounded,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'RECONCILIATION MONTH',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.0,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: _pickTargetMonth,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_month_rounded,
                                        size: 12,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${DateTimeConstants.shortMonths[_targetMonth.month - 1]} ${_targetMonth.year}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          _buildActionBanner(
                            label: 'Auto-Compute Balances',
                            icon: Icons.account_balance_wallet_rounded,
                            onTap: _fetchComputedNetWorth,
                            theme: theme,
                          ),

                          _buildTransparencyBanner(theme),

                          _buildSectionCard(
                            title: 'Assets',
                            accentColor: Colors.green,
                            theme: theme,
                            children: [
                              _buildRowInput(
                                'Cash,Wallets & Others',
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
                                focusNode: _focusNodes[_assetExtraCtrl],
                                labelText: 'Any Extra Asset Value (Manual)',
                                readOnly: true,
                                onTap: () =>
                                    _openCalculatorFor(_assetExtraCtrl),
                              ),
                            ],
                          ),

                          _buildSectionCard(
                            title: 'Liabilities',
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

                          _buildActionBanner(
                            label: 'Auto-Fetch Monthly Cashflow',
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
                                focusNode: _focusNodes[_cfOutOfBucketCtrl],
                                labelText: 'Out of Bucket Expenses',
                                readOnly: true,
                                onTap: () =>
                                    _openCalculatorFor(_cfOutOfBucketCtrl),
                              ),

                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                ),
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

                          _buildSectionCard(
                            title: 'Metadata',
                            accentColor: theme.colorScheme.onSurfaceVariant,
                            theme: theme,
                            children: [
                              ModernBoxyInput(
                                controller: _notesCtrl,
                                focusNode: _notesFocus,
                                labelText: 'Reconciliation Notes (Optional)',
                                hintText: 'e.g., Q3 Financial Review',
                                onTap: _closeCalculatorSafely,
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
          ),

          if (_activeCalcController != null)
            InlineCalculatorPad(
              key: ValueKey(_activeCalcController.hashCode),
              controller: _activeCalcController!,
              onNext: _handleCalcNext,
              onPrevious: _orderedCalcCtrls.indexOf(_activeCalcController!) > 0
                  ? _handleCalcPrev
                  : null,
              onSubmit: () {
                _closeCalculatorSafely();
                FocusScope.of(context).unfocus();
              },
              onClose: () {
                _closeCalculatorSafely();
                FocusScope.of(context).unfocus();
              },
            ),
        ],
      ),
    );
  }
}
