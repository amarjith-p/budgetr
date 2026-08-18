import 'package:budgetr/features/backup/views/backup_page.dart';
import 'package:budgetr/features/developer/views/developer_support_page.dart';
import 'package:budgetr/features/investments/views/investment_dashboard_page.dart';
import 'package:budgetr/features/money_tracker/views/money_tracker_base_page.dart';
import 'package:budgetr/features/smart_trackers/views/smart_trackers_dashboard_page.dart';
import 'package:budgetr/features/trips/views/trip_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

// --- SMART INBOX IMPORTS ---
import '../automation/views/smart_inbox_page.dart';
import '../automation/providers/smart_inbox_provider.dart';

import '../trips/providers/trip_provider.dart';
import '../reminders/views/reminder_dashboard_page.dart';
import '../reminders/providers/reminder_provider.dart';

// --- SECURE VAULT IMPORT ---
import '../secure_vault/views/vault_auth_page.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final now = DateTime.now();

    final triggeredReminders = rawReminders.where((r) {
      if (dismissedReminders.contains(r.id)) return false;
      final triggerDate = r.isPushEnabled
          ? r.targetDate.subtract(Duration(days: r.priorDays ?? 0))
          : r.targetDate;
      return now.isAfter(triggerDate) || now.isAtSameMomentAs(triggerDate);
    }).toList();

    // --- SMART INBOX LIVE COUNT ---
    final stagedTxsAsync = ref.watch(stagedTransactionsProvider);
    final int stagedCount = stagedTxsAsync.asData?.value.length ?? 0;

    // --- DYNAMIC METRO GRID SIZING & SCALING ---
    final bool hasBanner = triggeredReminders.isNotEmpty;
    final double baseTileHeight = hasBanner ? 100.0 : 120.0;
    final double largeTileHeight = (baseTileHeight * 2) + tileGap;

    // Scale down internal elements if the tiles shrink to prevent overflow
    final double barScale = hasBanner ? 0.6 : 1.0;

    // --- 2x2 GRID SIZING CALCULATIONS ---
    final double addTransHeight = baseTileHeight * 0.70; // 70% height
    final double smallGridTileHeight =
        (largeTileHeight - addTransHeight - (tileGap * 2)) / 2;

    return Scaffold(
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
          // --- SMART INBOX ENTRY POINT WITH BADGE ---
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
                MaterialPageRoute(builder: (context) => const SmartInboxPage()),
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // --- POPUP BANNERS FOR TRIGGERED REMINDERS ---
            if (hasBanner)
              SliverToBoxAdapter(
                child: Padding(
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
              ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // --- ROW 1: Money Tracker (Left) & Dynamic 2x2 Grid (Right) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                height: largeTileHeight,
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
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(
                                              Icons
                                                  .account_balance_wallet_rounded,
                                              color: Colors.black,
                                            ),
                                            Icon(
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
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                    color: Colors.black54,
                                                  ),
                                            ),
                                            SizedBox(height: hasBanner ? 4 : 8),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              alignment: Alignment.centerLeft,
                                              child: CurrencyText(
                                                amount: netBalance.abs(),
                                                sign: netSign,
                                                amountStyle:
                                                    valueStyle?.copyWith(
                                                      fontSize: 28,
                                                      color: Colors.black,
                                                    ) ??
                                                    const TextStyle(),
                                                symbolStyle: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              height: hasBanner ? 8 : 16,
                                            ),
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
                                              (hasActiveTrip || hasPausedTrip))
                                            const SizedBox(width: 8),
                                          if (hasActiveTrip || hasPausedTrip)
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
                            children: [
                              _buildMetroTile(
                                title: 'ADD TRANSACTION',
                                icon: Icons.add_rounded,
                                height: addTransHeight, // 70% height
                                color: darkTileColor,
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
                              const SizedBox(height: tileGap),
                              // 2x2 Grid - Row 1
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetroTile(
                                      title: 'BUCKETS',
                                      icon: Icons.donut_small_rounded,
                                      badge: liveBucketsCount > 0
                                          ? liveBucketsCount.toString()
                                          : '-',
                                      height: smallGridTileHeight,
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
                                      title:
                                          'SETTINGS', // Swapped from Categories
                                      icon: Icons.settings_rounded,
                                      height: smallGridTileHeight,
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
                              const SizedBox(height: tileGap),
                              // 2x2 Grid - Row 2
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetroTile(
                                      title: 'REMINDERS',
                                      icon: Icons.notifications_active_rounded,
                                      height: smallGridTileHeight,
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
                                      height: smallGridTileHeight,
                                      color: darkTileColor,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const BackupPage(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: tileGap),

                    // --- ROW 2: INVESTMENT TRACKER ---
                    _buildWideMetroTile(
                      title: 'INVESTMENT TRACKER',
                      icon: Icons.trending_up_rounded,
                      height: baseTileHeight,
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
                          CurrencyText(
                            amount: totalInvestmentValue.abs(),
                            sign: totalInvestmentValue < 0 ? '-₹ ' : '₹ ',
                            amountStyle: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1.0,
                            ),
                            symbolStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
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
                                  fontSize: 10,
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

                    const SizedBox(height: tileGap),

                    // --- ROW 3: Automation & Categories ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetroTile(
                            title: 'RECURRING RULES',
                            icon: Icons.autorenew_rounded,
                            height: baseTileHeight,
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
                            children: [
                              _buildMetroTile(
                                title: 'TRIP MODE',
                                icon: hasActiveTrip || hasPausedTrip
                                    ? Icons.flight_takeoff_rounded
                                    : Icons.flight_land_rounded,
                                iconColor: hasActiveTrip
                                    ? Colors.green
                                    : (hasPausedTrip
                                          ? Colors.orangeAccent
                                          : Colors.white),
                                height: (baseTileHeight - tileGap) / 2,
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
                              const SizedBox(height: tileGap),
                              _buildMetroTile(
                                title:
                                    'CATEGORIES', // Swapped from Settings to get wider horizontal space
                                icon: Icons.category_rounded,
                                height: (baseTileHeight - tileGap) / 2,
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
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: tileGap),

                    // --- ROW 4: VAULT (60%) & SMART TRACKERS (40%) ---
                    Row(
                      children: [
                        Expanded(
                          flex: 6, // 60% Width
                          child: _buildWideMetroTile(
                            title: 'VAULT',
                            icon: Icons.security_rounded,
                            height: baseTileHeight,
                            color: darkTileColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const VaultAuthPage(),
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
                                    color: Colors.blueAccent.withOpacity(0.2),
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
                            title:
                                'SMART TRACKERS', // Uses standard tile to prevent overlap in smaller space
                            icon: Icons.post_add_rounded,
                            height: baseTileHeight,
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

                    const SizedBox(
                      height: 32,
                    ), // Row 5 removed, keeping standard bottom spacing
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RENDER DASHBOARD REMINDER BANNER ---
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

  // --- METRO UI TILE ENGINE ---
  Widget _buildMetroTile({
    required String title,
    required IconData icon,
    required double height,
    required Color color,
    required VoidCallback onTap,
    String? badge,
    bool verticalText = false,
    Color? iconColor,
  }) {
    // Increased threshold to correctly identify the new 2x2 square tiles
    final bool isSmall = height < 85;

    return Material(
      color: color,
      borderRadius: BorderRadius.zero,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(isSmall ? 8.0 : 10.0), // Scaled
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
                              : 28, // Scaled icon size
                          color: iconColor ?? Colors.white,
                        ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.all(isSmall ? 8.0 : 12.0), // Scaled
                  child: verticalText
                      ? RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isSmall ? 9 : 10, // Scaled
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
                          style: TextStyle(
                            fontSize: isSmall ? 9 : 11, // Scaled
                            fontWeight: FontWeight.w800,
                            letterSpacing:
                                0.5, // Reduced letter spacing slightly for narrow tiles
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ),
            ],
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
}
