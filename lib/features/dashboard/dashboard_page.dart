// features/dashboard/views/dashboard_page.dart
import 'package:budgetr/features/developer/views/developer_support_page.dart';
import 'package:budgetr/features/investments/views/investment_dashboard_page.dart';
import 'package:budgetr/features/money_tracker/views/money_tracker_base_page.dart';
import 'package:flutter/material.dart';
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

// --- ADDED: Investment Provider Import ---
import '../investments/providers/investment_provider.dart';

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

    // The iconic Metro UI spacing (narrow hairline gap)
    const double tileGap = 2.0;

    // Uniform Dark Color for all secondary tiles
    final Color darkTileColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFF1E1E1E);

    // --- LIVE NET WORTH CALCULATION ---
    final accountsAsync = ref.watch(accountsStreamProvider);
    final rawAccounts = accountsAsync.asData?.value ?? [];

    double totalAssets = 0.0;
    double totalLiabilities = 0.0;

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
      }
    }

    final double netBalance = totalAssets - totalLiabilities;
    final String netSign = netBalance < 0 ? '-₹ ' : '₹ ';

    // --- LIVE BUCKET COUNT ---
    final bucketsAsync = ref.watch(bucketsStreamProvider);
    final int liveBucketsCount = bucketsAsync.asData?.value.length ?? 0;

    // --- LIVE INVESTMENT CALCULATION ---
    final investmentsAsync = ref.watch(investmentsStreamProvider);
    final rawInvestments = investmentsAsync.asData?.value ?? [];

    double totalInvestmentValue = 0.0;
    double totalInvestedAmount = 0.0;

    // Only calculate active (open) investments for the dashboard summary
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0, // Prevents native shadow on scroll
        centerTitle: false,
        titleSpacing: 0,
        leading: const Padding(
          padding: EdgeInsets.all(10.0),
          child: CircleAvatar(
            backgroundColor: Colors
                .transparent, // Ensures no boxy background shows behind transparent PNGs
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
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              // Outer padding frames the entire metro grid
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: [
                    // --- ROW 1: Money Tracker (Left) & Add/Buckets/Categories (Right) ---
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          // --- FIXED: Money Tracker stays surfaceLight across BOTH themes ---
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
                                height: 240,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  // Add a border in Light Mode so it doesn't blend into the white scaffold
                                  border: isDark
                                      ? null
                                      : Border.all(
                                          color: theme.dividerColor,
                                          width: 1.0,
                                        ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet_rounded,
                                          color: Colors
                                              .black, // Always black for light tile
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
                                                color: Colors
                                                    .black54, // Always dark text
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: CurrencyText(
                                            amount: netBalance.abs(),
                                            sign: netSign,
                                            amountStyle:
                                                valueStyle?.copyWith(
                                                  fontSize: 28,
                                                  color: Colors
                                                      .black, // Always black
                                                ) ??
                                                const TextStyle(),
                                            symbolStyle: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            // Pass true so bars are always dark against the light tile
                                            _buildFlatBar(40, true),
                                            _buildFlatBar(60, true),
                                            _buildFlatBar(30, true),
                                            _buildFlatBar(80, true),
                                            _buildFlatBar(50, true),
                                          ],
                                        ),
                                      ],
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
                                title: 'ADD LOG',
                                icon: Icons.add_rounded,
                                height: (240 - tileGap) / 2,
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
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildMetroTile(
                                      title: 'BUCKETS',
                                      icon: Icons.donut_small_rounded,
                                      badge: liveBucketsCount > 0
                                          ? liveBucketsCount.toString()
                                          : '-',
                                      height: (240 - tileGap) / 2,
                                      color: darkTileColor,
                                      verticalText: true,
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
                                      title: 'CATEGORIES',
                                      icon: Icons.category_rounded,
                                      height: (240 - tileGap) / 2,
                                      color: darkTileColor,
                                      verticalText: true,
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
                      height: 120,
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
                            amount: totalInvestmentValue
                                .abs(), // --- UPDATED TO LIVE DATA ---
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
                                '$invReturnSign${invReturnPct.toStringAsFixed(1)}% Return', // --- DYNAMIC RETURN PERCENTAGE ---
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

                    // --- ROW 3: History & Settings ---
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetroTile(
                            title: 'HISTORY',
                            icon: Icons.receipt_long_rounded,
                            height: 120,
                            color: darkTileColor,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: tileGap),
                        Expanded(
                          child: _buildMetroTile(
                            title: 'SETTINGS',
                            icon: Icons.settings_rounded,
                            height: 120,
                            color: darkTileColor,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              Align(
                alignment: Alignment.center,
                child: badge != null
                    ? Text(
                        badge,
                        style: TextStyle(
                          fontSize: verticalText ? 32 : 48,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      )
                    : Icon(
                        icon,
                        size: verticalText ? 28 : 36,
                        color: Colors.white,
                      ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: verticalText
                      ? RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 10,
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
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
                  alignment: Alignment.center,
                  child: Icon(icon, size: 36, color: Colors.white),
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
