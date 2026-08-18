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
import '../../../core/components/confirmation_bottom_sheet.dart';
import '../../../core/components/modern_boxy_toggle.dart';
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
      // Sleeker padding for the badge
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
          final activeDebts = debts.where((d) => !d.isSettled).toList();

          double totalBorrowed = 0;
          double totalLent = 0;
          for (var d in activeDebts) {
            if (d.type == 'Borrowed') totalBorrowed += d.amount;
            if (d.type == 'Lent') totalLent += d.amount;
          }

          final double netBalance = totalLent - totalBorrowed;
          final displayList = activeDebts
              .where((d) => d.type == (_tabIndex == 0 ? 'Borrowed' : 'Lent'))
              .toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- SMART NET SUMMARY CARD ---
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spacingLg,
                    DesignTokens.spacingLg,
                    DesignTokens.spacingLg,
                    0,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16.0,
                    ),
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
                        Text(
                          'NET DEBT BALANCE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CurrencyText(
                            amount: netBalance.abs(),
                            sign: netBalance < 0
                                ? '- ₹ '
                                : (netBalance > 0 ? '+ ₹ ' : '₹ '),
                            amountStyle: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: netBalance < 0
                                  ? theme.colorScheme.error
                                  : (netBalance > 0
                                        ? Colors.green
                                        : theme.colorScheme.onSurface),
                              letterSpacing: -0.5,
                            ),
                            symbolStyle: TextStyle(
                              fontSize: 14,
                              color:
                                  (netBalance < 0
                                          ? theme.colorScheme.error
                                          : (netBalance > 0
                                                ? Colors.green
                                                : theme.colorScheme.onSurface))
                                      .withOpacity(0.7),
                            ),
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
                                  children: [
                                    Text(
                                      'TO PAY (BORROWED)',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: CurrencyText(
                                        amount: totalBorrowed,
                                        sign: '₹ ',
                                        amountStyle: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: theme.colorScheme.error,
                                          letterSpacing: -0.5,
                                        ),
                                        symbolStyle: TextStyle(
                                          fontSize: 10,
                                          color: theme.colorScheme.error
                                              .withOpacity(0.8),
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TO GET (LENT)',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: CurrencyText(
                                        amount: totalLent,
                                        sign: '₹ ',
                                        amountStyle: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.green,
                                          letterSpacing: -0.5,
                                        ),
                                        symbolStyle: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green.withOpacity(0.8),
                                        ),
                                      ),
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
                    subtitle: 'You have no unsettled debts in this category.',
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

                      // Formatting dates with year included
                      final issueStr = DateFormat('dd MMM yyyy').format(d.date);
                      final dueStr = DateFormat(
                        'dd MMM yyyy',
                      ).format(d.dueDate);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: BoxySlidableCard(
                          key: ValueKey(d.id),
                          onEdit: () {
                            HapticFeedback.lightImpact();
                            DebtFormBottomSheet.show(context, existingDebt: d);
                          },
                          onSettle: () {
                            HapticFeedback.mediumImpact();
                            ConfirmationBottomSheet.show(
                              context,
                              title: 'Settle Debt?',
                              description:
                                  'Mark this debt as fully paid? This removes it from active tracking and disables alerts.',
                              confirmText: 'SETTLE',
                              onConfirm: () => ref
                                  .read(debtActionProvider.notifier)
                                  .settleDebt(d),
                            );
                          },
                          onDelete: () {
                            HapticFeedback.mediumImpact();
                            ConfirmationBottomSheet.show(
                              context,
                              title: 'Delete Record?',
                              description:
                                  'Are you sure you want to permanently delete this record?',
                              confirmText: 'DELETE',
                              isDestructive: true,
                              onConfirm: () => ref
                                  .read(debtActionProvider.notifier)
                                  .deleteDebt(d),
                            );
                          },
                          child: Container(
                            // Condensed padding for a sleeker look
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.dividerColor,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // SQUIRCLE ICON (Scaled down slightly)
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
                                    mainAxisSize:
                                        MainAxisSize.min, // shrink-wrap
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

                                      // SLEEK SINGLE-LINE TIMELINE WITH YEAR
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
                                      sign: _tabIndex == 0 ? '- ' : '+ ',
                                      amountStyle: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: amountColor,
                                        letterSpacing: -0.5,
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
                                        if (d.isPushEnabled)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 4.0,
                                            ),
                                            child: Icon(
                                              Icons
                                                  .notifications_active_rounded,
                                              size: 10, // scaled down bell icon
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        _DebtCountdownBadge(
                                          targetDate: d.dueDate,
                                          theme: theme,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
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
}
