import 'dart:async';
import 'package:budgetr/features/debts/components/debt_form_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_squircle_fab.dart';
import '../../../core/components/boxy_slidable_card.dart';
import '../../../core/components/premium_empty_state.dart';
import '../../../core/components/currency_text.dart';
import '../../../core/components/modern_boxy_toggle.dart';
import '../../../core/components/modern_boxy_input.dart';
import '../../../core/components/modern_boxy_button.dart';
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/database/app_database.dart';
import '../../transactions/views/transaction_form_page.dart';
import '../providers/debt_provider.dart';

// --- PREMIUM COUNTDOWN BADGE ---
class _DebtCountdownBadge extends StatefulWidget {
  final DateTime targetDate;
  final ThemeData theme;
  const _DebtCountdownBadge({required this.targetDate, required this.theme});
  @override
  State<_DebtCountdownBadge> createState() => _DebtCountdownBadgeState();
}

class _DebtCountdownBadgeState extends State<_DebtCountdownBadge> {
  late Timer _timer;
  late Duration _diff;

  @override
  void initState() {
    super.initState();
    _updateDiff();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateDiff());
  }

  void _updateDiff() {
    final now = DateTime.now();
    setState(() => _diff = widget.targetDate.difference(now));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isOverdue = _diff.isNegative;
    Duration absDiff = isOverdue ? -_diff : _diff;
    String text;

    if (absDiff.inHours >= 24) {
      text = isOverdue
          ? 'Overdue by ${absDiff.inDays}d'
          : 'Due in ${absDiff.inDays}d';
    } else {
      final h = absDiff.inHours.toString().padLeft(2, '0');
      final m = absDiff.inMinutes.remainder(60).toString().padLeft(2, '0');
      text = isOverdue ? 'Overdue $h:$m' : 'Due in $h:$m';
    }

    final color = isOverdue
        ? widget.theme.colorScheme.error
        : widget.theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.schedule_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class DebtDashboardPage extends ConsumerStatefulWidget {
  const DebtDashboardPage({super.key});
  @override
  ConsumerState<DebtDashboardPage> createState() => _DebtDashboardPageState();
}

class _DebtDashboardPageState extends ConsumerState<DebtDashboardPage> {
  int _tabIndex = 0; // 0 = Borrowed (Payable), 1 = Lent (Receivable)

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final debtsAsync = ref.watch(allDebtsProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModernAppBar(
        title: 'Debts & IOUs',
        subtitle: 'PERSON-TO-PERSON',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      floatingActionButton: ModernSquircleFab(
        onPressed: () {
          HapticFeedback.selectionClick();
          DebtFormBottomSheet.show(context);
        },
        icon: Icons.add_rounded,
        label: 'Add Debt',
      ),
      body: debtsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (debts) {
          double totalBorrowed = 0;
          double totalLent = 0;
          double interestPaid = 0;
          double interestEarned = 0;

          for (var d in debts) {
            final remainingPrincipal = d.amount - d.settledAmount;
            if (d.type == 'Borrowed') {
              if (!d.isSettled) totalBorrowed += remainingPrincipal;
              interestPaid += d.interestAccumulated;
            } else if (d.type == 'Lent') {
              if (!d.isSettled) totalLent += remainingPrincipal;
              interestEarned += d.interestAccumulated;
            }
          }

          final double netBalance = totalLent - totalBorrowed;
          final double netInterest = interestEarned - interestPaid;

          final displayList = debts
              .where((d) => d.type == (_tabIndex == 0 ? 'Borrowed' : 'Lent'))
              .toList();

          displayList.sort((a, b) {
            if (a.isSettled && !b.isSettled) return 1;
            if (!a.isSettled && b.isSettled) return -1;
            return a.dueDate.compareTo(b.dueDate);
          });

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- PREMIUM SPLIT-LEDGER SUMMARY CARD ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    DesignTokens.spacingLg,
                    DesignTokens.spacingLg,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
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
                        // --- PRIMARY METRICS ---
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NET DEBT BALANCE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: CurrencyText(
                                        amount: netBalance.abs(),
                                        sign: netBalance < 0
                                            ? '- ₹ '
                                            : (netBalance > 0 ? '+ ₹ ' : '₹ '),
                                        amountStyle: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.w900,
                                          color: netBalance < 0
                                              ? theme.colorScheme.error
                                              : (netBalance > 0
                                                    ? Colors.green
                                                    : theme
                                                          .colorScheme
                                                          .onSurface),
                                          letterSpacing: -1.0,
                                        ),
                                        symbolStyle: TextStyle(
                                          fontSize: 14,
                                          color:
                                              (netBalance < 0
                                                      ? theme.colorScheme.error
                                                      : (netBalance > 0
                                                            ? Colors.green
                                                            : theme
                                                                  .colorScheme
                                                                  .onSurface))
                                                  .withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              VerticalDivider(
                                width: 32,
                                thickness: 1,
                                color: theme.dividerColor,
                              ),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NET INTEREST',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.0,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: CurrencyText(
                                        amount: netInterest.abs(),
                                        sign: netInterest < 0
                                            ? '- ₹ '
                                            : (netInterest > 0 ? '+ ₹ ' : '₹ '),
                                        amountStyle: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: netInterest < 0
                                              ? theme.colorScheme.error
                                              : (netInterest > 0
                                                    ? Colors.green
                                                    : theme
                                                          .colorScheme
                                                          .onSurface),
                                          letterSpacing: -0.5,
                                        ),
                                        symbolStyle: TextStyle(
                                          fontSize: 12,
                                          color:
                                              (netInterest < 0
                                                      ? theme.colorScheme.error
                                                      : (netInterest > 0
                                                            ? Colors.green
                                                            : theme
                                                                  .colorScheme
                                                                  .onSurface))
                                                  .withOpacity(0.7),
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
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Divider(height: 1),
                        ),

                        // --- SECONDARY BREAKDOWN ---
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildSleekRow(
                                      'Borrowed',
                                      totalBorrowed,
                                      theme.colorScheme.error,
                                      theme,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSleekRow(
                                      'Lent',
                                      totalLent,
                                      Colors.green,
                                      theme,
                                    ),
                                  ],
                                ),
                              ),
                              VerticalDivider(
                                width: 32,
                                thickness: 1,
                                color: theme.dividerColor,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildSleekRow(
                                      'Int. Paid',
                                      interestPaid,
                                      theme.colorScheme.error,
                                      theme,
                                    ),
                                    const SizedBox(height: 8),
                                    _buildSleekRow(
                                      'Int. Earned',
                                      interestEarned,
                                      Colors.green,
                                      theme,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- TOGGLE TABS ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingLg,
                    vertical: DesignTokens.spacingMd,
                  ),
                  child: ModernBoxyToggle(
                    labels: const ['I Borrowed', 'I Lent'],
                    selectedIndex: _tabIndex,
                    onSelected: (idx) {
                      HapticFeedback.selectionClick();
                      setState(() => _tabIndex = idx);
                    },
                  ),
                ),
              ),

              // --- TRANSACTION LIST ---
              if (displayList.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: PremiumEmptyState(
                    title: 'No Active Records',
                    subtitle: 'You have no records in this category.',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spacingLg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final d = displayList[index];
                      final amountColor = _tabIndex == 0
                          ? theme.colorScheme.error
                          : Colors.green;

                      final issueStr = DateFormat('dd MMM yyyy').format(d.date);
                      final dueStr = DateFormat(
                        'dd MMM yyyy',
                      ).format(d.dueDate);
                      final isOverdue =
                          !d.isSettled && d.dueDate.isBefore(DateTime.now());
                      final remainingAmount = d.amount - d.settledAmount;

                      return Padding(
                        // --- 60% REDUCED SPACING ---
                        padding: const EdgeInsets.symmetric(vertical: 3.5),
                        child: BoxySlidableCard(
                          key: ValueKey(d.id),
                          onEdit: d.isSettled
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  DebtFormBottomSheet.show(
                                    context,
                                    existingDebt: d,
                                  );
                                },
                          onInterest: d.isSettled
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  DebtInterestBottomSheet.show(context, d);
                                },
                          onSettle: d.isSettled
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  DebtSettleBottomSheet.show(context, d);
                                },
                          onDelete: () {
                            HapticFeedback.mediumImpact();
                            ConfirmationBottomSheet.show(
                              context,
                              title: 'Delete Record?',
                              description: 'Permanently delete this record?',
                              confirmText: 'DELETE',
                              isDestructive: true,
                              onConfirm: () => ref
                                  .read(debtActionProvider.notifier)
                                  .deleteDebt(d),
                            );
                          },
                          child: Opacity(
                            opacity: d.isSettled ? 0.6 : 1.0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOverdue
                                      ? theme.colorScheme.error.withOpacity(0.5)
                                      : theme.dividerColor,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // SQUIRCLE ICON
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: amountColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: amountColor.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Icon(
                                      _tabIndex == 0
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: amountColor,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // DETAILS COLUMN
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          d.person,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: -0.2,
                                            color: theme.colorScheme.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          d.purpose,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),

                                        // TIMELINE
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today_rounded,
                                                size: 10,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.8),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$issueStr  ➔  $dueStr',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.2,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurfaceVariant
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // ACCUMULATED INTEREST INDICATOR
                                        if (d.interestAccumulated > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Interest: ₹${CurrencyFormatter.format(d.interestAccumulated)}',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: amountColor.withOpacity(
                                                0.8,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 8),

                                  // AMOUNT & STATUS COLUMN
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CurrencyText(
                                        amount: d.amount,
                                        // --- RUPEE SYMBOL ADDED ---
                                        sign: _tabIndex == 0 ? '- ₹ ' : '+ ₹ ',
                                        amountStyle: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                          color: amountColor,
                                          letterSpacing: -0.5,
                                          decoration: d.isSettled
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                        symbolStyle: TextStyle(
                                          fontSize: 12,
                                          color: amountColor.withOpacity(0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (d.isSettled)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Text(
                                                'SETTLED',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.green,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            )
                                          else if (d.settledAmount > 0)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 3,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orangeAccent
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'PARTIAL (₹${CurrencyFormatter.format(remainingAmount)} LEFT)',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors
                                                      .orangeAccent
                                                      .shade700,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            )
                                          else ...[
                                            if (d.isPushEnabled)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 4.0,
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .notifications_active_rounded,
                                                  size: 10,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                            _DebtCountdownBadge(
                                              targetDate: d.dueDate,
                                              theme: theme,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: displayList.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
    );
  }

  // --- SLEEK LIST ROW BUILDER FOR SUMMARY ---
  Widget _buildSleekRow(
    String label,
    double amount,
    Color amountColor,
    ThemeData theme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: CurrencyText(
              amount: amount,
              sign: '₹ ',
              amountStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: amountColor,
                letterSpacing: -0.2,
              ),
              symbolStyle: TextStyle(
                fontSize: 10,
                color: amountColor.withOpacity(0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =========================================================================
// ACTION BOTTOM SHEETS (INTEREST & SETTLEMENT)
// =========================================================================

class DebtInterestBottomSheet extends ConsumerStatefulWidget {
  final Debt debt;
  const DebtInterestBottomSheet({Key? key, required this.debt})
    : super(key: key);

  static void show(BuildContext context, Debt debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => DebtInterestBottomSheet(debt: debt),
    );
  }

  @override
  ConsumerState<DebtInterestBottomSheet> createState() =>
      _DebtInterestBottomSheetState();
}

class _DebtInterestBottomSheetState
    extends ConsumerState<DebtInterestBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  bool _logToLedger = true;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.selectionClick();

    final amt = double.parse(_amountCtrl.text.trim());
    final debtType = widget.debt.type;
    final person = widget.debt.person;

    await ref.read(debtActionProvider.notifier).addInterest(widget.debt, amt);
    if (!mounted) return;

    if (_logToLedger) {
      final staged = StagedTransaction(
        id: 'INT_${DateTime.now().millisecondsSinceEpoch}',
        rawText: 'Debt Interest Sync',
        sourceName: 'FinStack 360',
        packageName: 'com.finstack',
        extractedAmount: amt,
        inferredType: debtType == 'Borrowed' ? 'Expense' : 'Income',
        date: DateTime.now(),
        merchantName: 'Interest: $person',
        isApproved: false,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionFormPage(stagedTransaction: staged),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBorrowed = widget.debt.type == 'Borrowed';

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
                isBorrowed ? 'Log Interest Paid' : 'Log Interest Earned',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This accumulates on the dashboard. You can also push it directly to your main ledger.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              ModernBoxyInput(
                controller: _amountCtrl,
                labelText: 'Interest Amount',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null || double.parse(v) <= 0)
                    return 'Invalid amount';
                  return null;
                },
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    isDark ? 0.3 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sync to Ledger',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Log this in your main accounts',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: _logToLedger,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _logToLedger = val);
                        },
                      ),
                    ),
                  ],
                ),
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
                      onPressed: _submit,
                      label: 'Save Interest',
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

class DebtSettleBottomSheet extends ConsumerStatefulWidget {
  final Debt debt;
  const DebtSettleBottomSheet({Key? key, required this.debt}) : super(key: key);

  static void show(BuildContext context, Debt debt) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: DesignTokens.bottomSheetShape,
      builder: (ctx) => DebtSettleBottomSheet(debt: debt),
    );
  }

  @override
  ConsumerState<DebtSettleBottomSheet> createState() =>
      _DebtSettleBottomSheetState();
}

class _DebtSettleBottomSheetState extends ConsumerState<DebtSettleBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountCtrl;
  bool _logToLedger = true;

  @override
  void initState() {
    super.initState();
    final remaining = widget.debt.amount - widget.debt.settledAmount;
    _amountCtrl = TextEditingController(text: remaining.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.selectionClick();

    final amt = double.parse(_amountCtrl.text.trim());
    final debtType = widget.debt.type;
    final person = widget.debt.person;

    await ref
        .read(debtActionProvider.notifier)
        .recordSettlement(widget.debt, amt);
    if (!mounted) return;

    if (_logToLedger) {
      final staged = StagedTransaction(
        id: 'SETTLE_${DateTime.now().millisecondsSinceEpoch}',
        rawText: 'Debt Settlement Sync',
        sourceName: 'FinStack 360',
        packageName: 'com.finstack',
        extractedAmount: amt,
        inferredType: debtType == 'Borrowed' ? 'Expense' : 'Income',
        date: DateTime.now(),
        merchantName: 'Settlement: $person',
        isApproved: false,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionFormPage(stagedTransaction: staged),
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final remaining = widget.debt.amount - widget.debt.settledAmount;

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
                'Settle Record',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the amount being settled. If it covers the remaining principal, the debt will be closed.',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.spacingLg),
              ModernBoxyInput(
                controller: _amountCtrl,
                labelText:
                    'Amount (Max ₹${CurrencyFormatter.format(remaining)})',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icon(
                  Icons.currency_rupee_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) return 'Invalid amount';
                  if (parsed > remaining)
                    return 'Cannot exceed remaining amount';
                  return null;
                },
              ),
              const SizedBox(height: DesignTokens.spacingMd),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withOpacity(
                    isDark ? 0.3 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sync to Ledger',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Log this in your main accounts',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: _logToLedger,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          setState(() => _logToLedger = val);
                        },
                      ),
                    ),
                  ],
                ),
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
                      onPressed: _submit,
                      label: 'Record Settlement',
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
