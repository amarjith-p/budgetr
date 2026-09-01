// lib/features/dashboard/dashboard_page.dart
import 'package:budgetr/features/backup/views/backup_page.dart';
import 'package:budgetr/features/debts/views/debt_dashboard_page.dart';
import 'package:budgetr/features/developer/views/developer_support_page.dart';
import 'package:budgetr/features/investments/views/investment_dashboard_page.dart';
import 'package:budgetr/features/money_tracker/views/money_tracker_base_page.dart';
import 'package:budgetr/features/net_worth/views/net_worth_page.dart';
import 'package:budgetr/features/smart_trackers/views/smart_trackers_dashboard_page.dart';
import 'package:budgetr/features/trips/views/trip_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/modern_app_bar.dart';
import '../../core/components/currency_text.dart';
import '../category_manager/views/category_manager_page.dart';
import '../settings/views/settings_page.dart';
import '../budget_buckets/views/budget_buckets_page.dart';

import '../transactions/views/transaction_form_page.dart';

import '../accounts/providers/account_provider.dart';
import '../accounts/providers/credit_math_provider.dart';
import '../accounts/providers/loan_math_provider.dart';
import '../transactions/providers/transaction_provider.dart';
import '../investments/providers/investment_provider.dart';
import '../notifications/components/notification_bell_widget.dart';
import '../automation/views/automation_dashboard_page.dart';

// --- BUDGET PROVIDER IMPORTS ---
import '../../../core/database/app_database.dart';
import '../budgets/providers/budget_provider.dart';

import '../automation/views/smart_inbox_page.dart';
import '../automation/providers/smart_inbox_provider.dart';

import '../trips/providers/trip_provider.dart';
import '../reminders/views/reminder_dashboard_page.dart';
import '../reminders/providers/reminder_provider.dart';

import '../secure_vault/views/vault_auth_page.dart';

import '../debts/providers/debt_provider.dart';

import '../net_worth/providers/net_worth_provider.dart';

import 'package:share_plus/share_plus.dart';
import '../backup/services/backup_service.dart';
import '../backup/providers/backup_reminder_provider.dart';
import '../../core/components/futuristic_loader.dart';
import '../../core/components/custom_snackbars.dart';

// --- NEW: STRICT LOCAL PROVIDER ---
// This ensures the dashboard NEVER travels back in time when the user explores old budgets elsewhere
final _dashboardBudgetProvider = StreamProvider.autoDispose<MonthlyBudget?>((
  ref,
) {
  final now = DateTime.now();
  return ref
      .watch(budgetServiceProvider)
      .watchBudgetForMonth(now.month, now.year);
});

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  DateTime? _lastPressedAt;

  Future<void> _handleQuickBackup(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();

    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: FuturisticLoader(size: 80, label: "PREPARING BACKUP..."),
          ),
        ),
      ),
    );

    final result = await ref
        .read(backupServiceProvider)
        .exportDatabaseExternal();

    navigator.pop();

    if (result != null && result.startsWith('ERROR:')) {
      if (context.mounted) {
        CustomSnackbars.showError(
          context,
          message: result.replaceFirst('ERROR: ', ''),
        );
      }
    } else if (result != null) {
      final shareResult = await Share.shareXFiles([
        XFile(result),
      ], subject: 'FinStack 360 Daily Backup');

      if (shareResult.status == ShareResultStatus.success) {
        await ref.read(backupReminderProvider.notifier).recordBackup();

        if (context.mounted) {
          CustomSnackbars.showSuccess(
            context,
            message: 'Backup secured successfully.',
          );
        }
      } else if (shareResult.status == ShareResultStatus.dismissed) {
        if (context.mounted) {
          CustomSnackbars.showError(
            context,
            message:
                'Backup cancelled. Please complete the backup to stay safe.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final valueStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: Colors.white,
    );

    const double tileGap = 2.0;

    final Color darkTileColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFF1E1E1E);

    final accountsAsync = ref.watch(accountsStreamProvider);
    final rawAccounts = accountsAsync.asData?.value ?? [];

    double totalAssets = 0.0;
    double totalLiabilities = 0.0;
    double allocatedFunds = 0.0;

    for (var acc in rawAccounts) {
      if (acc.type == 'Credit Cards') {
        final metrics = ref.watch(creditCardMetricsProvider(acc));
        if (metrics.totalOutstanding < 0) {
          totalLiabilities += metrics.totalOutstanding.abs();
        }
      } else if (acc.type == 'Loan' && !acc.isClosed) {
        final out = ref.watch(loanTotalOutstandingProvider(acc));
        if (out > 0) totalLiabilities += out;
      } else if (acc.type != 'Credit Cards' && acc.type != 'Loan') {
        totalAssets += acc.balance;

        if (acc.isCreditPayable) {
          allocatedFunds += (acc.balance > 0 ? acc.balance : 0.0);
        }
      }
    }

    final double netBalance = totalAssets - totalLiabilities;
    final String netSign = netBalance < 0 ? '-₹ ' : '₹ ';

    final double difference = allocatedFunds - totalLiabilities;
    final bool hasPayableShortage = difference < 0;

    final bucketsAsync = ref.watch(bucketsStreamProvider);
    final int liveBucketsCount = bucketsAsync.asData?.value.length ?? 0;

    // --- LIVE BUDGET MATH (NOW LOCKED STRICTLY TO CURRENT MONTH) ---
    final budgetAsync = ref.watch(_dashboardBudgetProvider);
    final currentBudget = budgetAsync.asData?.value;
    double totalBudget = 0.0;
    double budgetedSpend = 0.0;
    final now = DateTime.now();

    if (currentBudget != null) {
      totalBudget =
          currentBudget.salaryIncome +
          currentBudget.extraIncome -
          currentBudget.deductions;

      if (currentBudget.isClosed) {
        budgetedSpend =
            (currentBudget.closedTotalSpent ?? 0.0) -
            (currentBudget.closedOutOfBucket ?? 0.0);
      } else {
        final allTxs = ref.watch(allTransactionsProvider).asData?.value ?? [];
        for (var txData in allTxs) {
          final tx = txData.transaction;
          // Confined absolutely to the actual real-world month
          if (tx.date.year == now.year && tx.date.month == now.month) {
            if (tx.type == 'Expense') {
              bool isLoanTx = tx.id.startsWith('LOAN_TX_');
              bool isNonCalc = tx.subCategory == 'Non-Calculated Expenses';

              if (!isLoanTx &&
                  !isNonCalc &&
                  tx.bucketId != null &&
                  tx.bucketId != -1) {
                budgetedSpend += tx.amount;
              }
            }
          }
        }
      }
    }

    double budgetProgress = totalBudget > 0
        ? (budgetedSpend / totalBudget)
        : 0.0;

    // --- DYNAMIC COLOR THRESHOLDS ---
    Color progressColor;
    if (budgetProgress > 1.0) {
      progressColor = Colors.redAccent.shade700;
    } else if (budgetProgress >= 0.75) {
      progressColor = Colors.orange.shade800;
    } else {
      progressColor = Colors.green.shade700;
    }

    final investmentsAsync = ref.watch(investmentsStreamProvider);
    final rawInvestments = investmentsAsync.asData?.value ?? [];

    double totalInvestmentValue = 0.0;
    double totalInvestedAmount = 0.0;

    for (var inv in rawInvestments) {
      if (!inv.isClosed) {
        totalInvestmentValue += inv.currentValue;
        totalInvestedAmount += inv.initialAmount;
      }
    }

    final double invGainLoss = totalInvestmentValue - totalInvestedAmount;
    final double invReturnPct = totalInvestedAmount > 0
        ? (invGainLoss / totalInvestedAmount) * 100
        : 0.0;
    final String invReturnSign = invReturnPct >= 0 ? '+' : '';

    final tripsAsync = ref.watch(allTripsProvider);
    final rawTrips = tripsAsync.asData?.value ?? [];
    final bool hasActiveTrip = rawTrips.any((t) => t.status == 'ACTIVE');
    final bool hasPausedTrip = rawTrips.any((t) => t.status == 'PAUSED');

    final remindersAsync = ref.watch(allRemindersProvider);
    final dismissedReminders = ref.watch(dismissedRemindersProvider);
    final rawReminders = remindersAsync.asData?.value ?? [];

    final triggeredReminders = rawReminders.where((r) {
      if (dismissedReminders.contains(r.id)) return false;
      final triggerDate = r.isPushEnabled
          ? r.targetDate.subtract(Duration(days: r.priorDays ?? 0))
          : r.targetDate;
      return now.isAfter(triggerDate) || now.isAtSameMomentAs(triggerDate);
    }).toList();

    final stagedTxsAsync = ref.watch(stagedTransactionsProvider);
    final int stagedCount = stagedTxsAsync.asData?.value.length ?? 0;

    final debtsAsync = ref.watch(allDebtsProvider);
    final rawDebts = debtsAsync.asData?.value ?? [];

    double totalBorrowed = 0.0;
    double totalLent = 0.0;

    for (var d in rawDebts) {
      if (!d.isSettled) {
        final remainingPrincipal = d.amount - d.settledAmount;
        if (d.type == 'Borrowed') {
          totalBorrowed += remainingPrincipal;
        } else if (d.type == 'Lent') {
          totalLent += remainingPrincipal;
        }
      }
    }

    final double netDebtBalance = totalLent - totalBorrowed;

    final netWorthAsync = ref.watch(netWorthMetricsProvider);
    final double liveNetWorth = netWorthAsync.asData?.value.netWorth ?? 0.0;
    final bool isNwPositive = liveNetWorth >= 0;

    final bool isBackupDue = ref.watch(backupReminderProvider);

    final bool hasBanner = triggeredReminders.isNotEmpty;
    final double barScale = hasBanner ? 0.6 : 1.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        final currentTime = DateTime.now();
        final maxDuration = const Duration(seconds: 2);
        final isWarning =
            _lastPressedAt == null ||
            currentTime.difference(_lastPressedAt!) > maxDuration;

        if (isWarning) {
          _lastPressedAt = currentTime;
          HapticFeedback.lightImpact();

          CustomSnackbars.showSuccess(
            context,
            message: 'Press back again to exit',
          );
          return;
        }

        SystemNavigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          leading: const Padding(
            padding: EdgeInsets.all(10.0),
            child: CircleAvatar(
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('assets/icon/fs360.png'),
            ),
          ),
          title: GestureDetector(
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DeveloperSupportPage(),
                ),
              );
            },
            child: Text(
              'FINSTACK 360',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          actions: [
            if (isBackupDue)
              IconButton(
                icon: const Icon(
                  Icons.cloud_sync_rounded,
                  color: Colors.redAccent,
                ),
                tooltip: 'Backup Overdue',
                onPressed: () => _handleQuickBackup(context, ref),
              ),
            IconButton(
              icon: Badge(
                isLabelVisible: stagedCount > 0,
                label: Text(stagedCount.toString()),
                backgroundColor: theme.colorScheme.error,
                child: const Icon(Icons.all_inbox_rounded),
              ),
              color: theme.colorScheme.onSurface,
              tooltip: 'Smart Inbox',
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SmartInboxPage(),
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: NotificationBellWidget(),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (hasBanner)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0),
                  child: Column(
                    children: triggeredReminders
                        .map(
                          (r) => _buildReminderBanner(
                            context,
                            ref,
                            r,
                            theme,
                            isDark,
                          ),
                        )
                        .toList(),
                  ),
                ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- ROW 1: Money Tracker (Left) & Dynamic 2x2 Grid (Right) ---
                      Expanded(
                        flex: 2,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Material(
                                color: AppTokens.surfaceLight,
                                borderRadius: BorderRadius.zero,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MoneyTrackerBasePage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    padding: EdgeInsets.all(
                                      hasBanner ? 12.0 : 16.0,
                                    ),
                                    decoration: BoxDecoration(
                                      border: isDark
                                          ? null
                                          : Border.all(
                                              color: theme.dividerColor,
                                              width: 1.0,
                                            ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .account_balance_wallet_outlined,
                                                  color: Colors.black,
                                                ),
                                                // --- BUDGET PROGRESS VISUALIZER IN TOP ROW ---
                                                if (totalBudget > 0)
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 5.0,
                                                          ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          // 1. Spend % directly above
                                                          Text(
                                                            '${(budgetProgress * 100).toStringAsFixed(2)}%',
                                                            textAlign:
                                                                TextAlign.right,
                                                            style: TextStyle(
                                                              fontSize: 7,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  progressColor,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          // 2. Progress Bar
                                                          Container(
                                                            height: 4,
                                                            width:
                                                                double.infinity,
                                                            decoration: BoxDecoration(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    2,
                                                                  ),
                                                            ),
                                                            child: FractionallySizedBox(
                                                              alignment: Alignment
                                                                  .centerLeft,
                                                              widthFactor:
                                                                  budgetProgress
                                                                      .clamp(
                                                                        0.0,
                                                                        1.0,
                                                                      ),
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      progressColor,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        2,
                                                                      ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          // 3. Spend amount directly below (FittedBox to prevent overflow)
                                                          FittedBox(
                                                            fit: BoxFit
                                                                .scaleDown,
                                                            alignment: Alignment
                                                                .centerRight,
                                                            child: Text(
                                                              '₹${CurrencyFormatter.format(budgetedSpend)} / ₹${CurrencyFormatter.format(totalBudget)}',
                                                              style: const TextStyle(
                                                                fontSize: 7,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                else
                                                  const Spacer(),
                                                const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: Colors.black,
                                                  size: 18,
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'MONEY TRACKER',
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        letterSpacing: 0.5,
                                                        color: Colors.black54,
                                                      ),
                                                ),
                                                SizedBox(
                                                  height: hasBanner ? 4 : 8,
                                                ),
                                                FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: CurrencyText(
                                                    amount: netBalance.abs(),
                                                    sign: netSign,
                                                    amountStyle:
                                                        valueStyle?.copyWith(
                                                          fontSize: 26,
                                                          color: Colors.black,
                                                        ) ??
                                                        const TextStyle(),
                                                    symbolStyle:
                                                        const TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.black87,
                                                        ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: hasBanner ? 8 : 16,
                                                ),
                                                // --- ORIGINAL VERTICAL BARS ---
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    _buildFlatBar(
                                                      40 * barScale,
                                                      true,
                                                    ),
                                                    _buildFlatBar(
                                                      60 * barScale,
                                                      true,
                                                    ),
                                                    _buildFlatBar(
                                                      30 * barScale,
                                                      true,
                                                    ),
                                                    _buildFlatBar(
                                                      80 * barScale,
                                                      true,
                                                    ),
                                                    _buildFlatBar(
                                                      50 * barScale,
                                                      true,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (hasPayableShortage)
                                                const Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.redAccent,
                                                  size: 24,
                                                ),
                                              if (hasPayableShortage &&
                                                  (hasActiveTrip ||
                                                      hasPausedTrip))
                                                const SizedBox(width: 8),
                                              if (hasActiveTrip ||
                                                  hasPausedTrip)
                                                Icon(
                                                  Icons.flight_takeoff_rounded,
                                                  color: hasActiveTrip
                                                      ? Colors.green
                                                      : Colors.orangeAccent,
                                                  size: 24,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: tileGap),

                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: 70,
                                    child: _buildMetroTile(
                                      title: 'ADD TRANSACTION',
                                      icon: Icons.add_rounded,
                                      height: double.infinity,
                                      color: darkTileColor,
                                      topLeftContent: const _LiveClockWidget(),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TransactionFormPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: tileGap),
                                  // 2x2 Grid - Row 1
                                  Expanded(
                                    flex: 65,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _buildMetroTile(
                                            title: 'BUCKETS',
                                            icon: Icons.donut_small_rounded,
                                            verticalText: true,
                                            badge: liveBucketsCount > 0
                                                ? liveBucketsCount.toString()
                                                : '-',
                                            height: double.infinity,
                                            color: darkTileColor,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const BudgetBucketsPage(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: tileGap),
                                        Expanded(
                                          child: _buildMetroTile(
                                            title: 'SETTINGS',
                                            icon: Icons.settings_rounded,
                                            verticalText: true,
                                            height: double.infinity,
                                            color: darkTileColor,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const SettingsPage(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: tileGap),
                                  // 2x2 Grid - Row 2
                                  Expanded(
                                    flex: 65,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: _buildMetroTile(
                                            title: 'REMINDER',
                                            icon: Icons
                                                .notifications_active_rounded,
                                            verticalText: true,
                                            height: double.infinity,
                                            color: darkTileColor,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ReminderDashboardPage(),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: tileGap),
                                        Expanded(
                                          child: _buildMetroTile(
                                            title: 'BACKUP',
                                            icon: Icons.cloud_sync_rounded,
                                            verticalText: true,
                                            height: double.infinity,
                                            color: darkTileColor,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const BackupPage(),
                                                ),
                                              );
                                            },
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

                      const SizedBox(height: tileGap),

                      // --- ROW 2: INVESTMENT TRACKER ---
                      Expanded(
                        flex: 1,
                        child: _buildWideMetroTile(
                          title: 'INVESTMENT TRACKER',
                          icon: Icons.trending_up_rounded,
                          height: double.infinity,
                          color: darkTileColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const InvestmentDashboardPage(),
                              ),
                            );
                          },
                          customContent: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: CurrencyText(
                                  amount: totalInvestmentValue.abs(),
                                  sign: totalInvestmentValue < 0 ? '-₹ ' : '₹ ',
                                  amountStyle: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -1.0,
                                  ),
                                  symbolStyle: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (totalInvestedAmount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: invReturnPct >= 0
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.redAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Text(
                                    '$invReturnSign${invReturnPct.toStringAsFixed(1)}% Return',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: invReturnPct >= 0
                                          ? Colors.greenAccent
                                          : Colors.redAccent,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: tileGap),

                      // --- ROW 3: Automation & Categories ---
                      Expanded(
                        flex: 1,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildMetroTile(
                                title: 'RECURRING RULES',
                                icon: Icons.autorenew_rounded,
                                height: double.infinity,
                                color: darkTileColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AutomationDashboardPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: tileGap),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _buildMetroTile(
                                      title: 'TRIP MODE',
                                      icon: hasActiveTrip || hasPausedTrip
                                          ? Icons.flight_takeoff_rounded
                                          : Icons.flight_land_rounded,
                                      swapPositions: false,
                                      iconColor: hasActiveTrip
                                          ? Colors.green
                                          : (hasPausedTrip
                                                ? Colors.orangeAccent
                                                : Colors.white),
                                      height: double.infinity,
                                      color: darkTileColor,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const TripDashboardPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: tileGap),
                                  Expanded(
                                    child: _buildMetroTile(
                                      title: 'CATEGORIES',
                                      icon: Icons.category_rounded,
                                      swapPositions: false,
                                      height: double.infinity,
                                      color: darkTileColor,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const CategoryManagerPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: tileGap),

                      // --- ROW 4: VAULT (60%) & SMART TRACKERS (40%) ---
                      Expanded(
                        flex: 1,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6, // 60% Width
                              child: _buildWideMetroTile(
                                title: 'VAULT',
                                icon: Icons.security_rounded,
                                height: double.infinity,
                                color: darkTileColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const VaultAuthPage(),
                                    ),
                                  );
                                },
                                customContent: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.lock_outline_rounded,
                                      color: Colors.white70,
                                      size: 28,
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                      child: const Text(
                                        'AES-256 ENCRYPTED',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.blueAccent,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: tileGap),
                            Expanded(
                              flex: 4, // 40% Width
                              child: _buildMetroTile(
                                title: 'SMART TRACKERS',
                                icon: Icons.post_add_rounded,
                                height: double.infinity,
                                color: darkTileColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SmartTrackersDashboardPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: tileGap),

                      // --- ROW 5: DEBTS & NET WORTH ---
                      Expanded(
                        flex: 1,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 6, // 60% Width
                              child: _buildWideMetroTile(
                                title: 'NET WORTH',
                                icon: Icons.diamond_rounded,
                                height: double.infinity,
                                color: darkTileColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const NetWorthPage(),
                                    ),
                                  );
                                },
                                customContent: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: CurrencyText(
                                        amount: liveNetWorth.abs(),
                                        sign: liveNetWorth < 0
                                            ? ' -₹ '
                                            : (liveNetWorth > 0
                                                  ? ' +₹ '
                                                  : ' ₹ '),
                                        amountStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                        ),
                                        symbolStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isNwPositive
                                            ? Colors.green.withOpacity(0.2)
                                            : Colors.redAccent.withOpacity(0.2),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Text(
                                        isNwPositive ? 'POSITIVE' : 'NEGATIVE',
                                        style: TextStyle(
                                          fontSize: 6,
                                          fontWeight: FontWeight.w700,
                                          color: isNwPositive
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: tileGap),

                            Expanded(
                              flex: 4, // 40% Width
                              child: _buildWideMetroTile(
                                title: 'DEBTS',
                                icon: Icons.money_off_rounded,
                                height: double.infinity,
                                color: darkTileColor,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const DebtDashboardPage(),
                                    ),
                                  );
                                },
                                customContent: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: CurrencyText(
                                        amount: netDebtBalance.abs(),
                                        sign: netDebtBalance < 0
                                            ? ' -₹ '
                                            : (netDebtBalance > 0
                                                  ? ' +₹ '
                                                  : ' ₹ '),
                                        amountStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          letterSpacing: -1.0,
                                        ),
                                        symbolStyle: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: netDebtBalance < 0
                                            ? Colors.redAccent.withOpacity(0.2)
                                            : (netDebtBalance > 0
                                                  ? Colors.green.withOpacity(
                                                      0.2,
                                                    )
                                                  : Colors.white.withOpacity(
                                                      0.1,
                                                    )),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Text(
                                        'NET BALANCE',
                                        style: TextStyle(
                                          fontSize: 6,
                                          fontWeight: FontWeight.w700,
                                          color: netDebtBalance < 0
                                              ? Colors.redAccent
                                              : (netDebtBalance > 0
                                                    ? Colors.greenAccent
                                                    : Colors.white70),
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderBanner(
    BuildContext context,
    WidgetRef ref,
    reminder,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(
          isDark ? 0.2 : 0.5,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.alarm_on_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REMINDER: ${reminder.title.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  reminder.notes?.isNotEmpty == true
                      ? reminder.notes!
                      : 'It is time for your scheduled reminder.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              ref
                  .read(dismissedRemindersProvider.notifier)
                  .dismiss(reminder.id);
            },
            icon: Icon(
              Icons.close_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatBar(double height, bool useDarkColor) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 12,
      height: height,
      color: useDarkColor
          ? Colors.black.withOpacity(0.2)
          : Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildMetroTile({
    required String title,
    required IconData icon,
    required double height,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    bool verticalText = false,
    bool swapPositions = false,
    Color? iconColor,
    Widget? topLeftContent,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxHeight < 85;

              return Stack(
                children: [
                  if (topLeftContent != null)
                    Positioned(
                      top: isSmall ? 8.0 : 12.0,
                      left: isSmall ? 8.0 : 12.0,
                      child: topLeftContent,
                    ),
                  Positioned(
                    top: swapPositions ? null : (isSmall ? 8.0 : 10.0),
                    bottom: swapPositions ? (isSmall ? 8.0 : 10.0) : null,
                    left: swapPositions ? (isSmall ? 8.0 : 10.0) : null,
                    right: swapPositions ? null : (isSmall ? 8.0 : 10.0),
                    child: badge != null
                        ? Text(
                            badge,
                            style: TextStyle(
                              fontSize: verticalText ? 20 : 24,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          )
                        : Icon(
                            icon,
                            size: verticalText
                                ? isSmall
                                      ? 24
                                      : 26
                                : isSmall
                                ? 26
                                : 28,
                            color: iconColor ?? Colors.white,
                          ),
                  ),
                  Positioned(
                    top: swapPositions
                        ? (isSmall ? 8.0 : 12.0)
                        : (verticalText ? (isSmall ? 8.0 : 12.0) : null),
                    bottom: swapPositions ? null : (isSmall ? 8.0 : 12.0),
                    left: swapPositions
                        ? (isSmall ? 8.0 : 12.0)
                        : (isSmall ? 8.0 : 12.0),
                    right: verticalText ? null : (isSmall ? 8.0 : 12.0),
                    child: verticalText
                        ? RotatedBox(
                            quarterTurns: 3,
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: isSmall ? 9 : 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Text(
                            title,
                            textAlign: swapPositions
                                ? TextAlign.right
                                : TextAlign.left,
                            style: TextStyle(
                              fontSize: isSmall ? 9 : 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWideMetroTile({
    required String title,
    required IconData icon,
    required double height,
    required Color color,
    required VoidCallback onTap,
    Widget? customContent,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              if (customContent != null) ...[
                Positioned(
                  right: 24,
                  bottom: -16,
                  child: Icon(
                    icon,
                    size: 90,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: customContent,
                  ),
                ),
              ] else ...[
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Icon(icon, size: 22, color: Colors.white),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveClockWidget extends StatefulWidget {
  const _LiveClockWidget({Key? key}) : super(key: key);

  @override
  State<_LiveClockWidget> createState() => _LiveClockWidgetState();
}

class _LiveClockWidgetState extends State<_LiveClockWidget> {
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _clockStream,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final time = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              DateFormat('EEE, dd MMM yyyy').format(time).toUpperCase(),
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('hh:mm:ss a').format(time),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        );
      },
    );
  }
}
