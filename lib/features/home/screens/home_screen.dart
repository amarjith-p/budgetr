import 'package:flutter/material.dart';

import '../../custom_entry/screens/custom_entry_dashboard.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../net_worth/screens/net_worth_screen.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../../credit_tracker/screens/credit_tracker_screen.dart';
import '../../investment/screens/investment_screen.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/aurora_scaffold.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/home_bottom_bar.dart';
import '../widgets/home_feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuroraScaffold(
      // The centralized scaffold handles the gradient orbs and background
      accentColor1: AppColors.royalBlue,
      accentColor2: AppColors.deepPurple,
      appBar: const HomeAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),

          // --- Dashboard Grid ---
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              children: [
                HomeFeatureCard(
                  title: "Budgets",
                  subtitle: "Allocation & Analysis",
                  icon: Icons.pie_chart_outline_rounded,
                  gradientColors: [
                    AppColors.royalBlue.withOpacity(0.2),
                    AppColors.royalBlue.withOpacity(0.05),
                  ],
                  iconColor: AppColors.royalBlue,
                  destination: const DashboardScreen(),
                ),
                HomeFeatureCard(
                  title: "Investments",
                  subtitle: "Portfolio Growth",
                  icon: Icons.candlestick_chart_rounded,
                  gradientColors: [
                    AppColors.vibrantOrange.withOpacity(0.2),
                    AppColors.vibrantOrange.withOpacity(0.05),
                  ],
                  iconColor: AppColors.vibrantOrange,
                  destination: const InvestmentScreen(),
                ),
                HomeFeatureCard(
                  title: "Net Worth",
                  subtitle: "Total Asset Value",
                  icon: Icons.account_balance_wallet_outlined,
                  gradientColors: [
                    AppColors.tealGreen.withOpacity(0.2),
                    AppColors.tealGreen.withOpacity(0.05),
                  ],
                  iconColor: AppColors.tealGreen,
                  destination: const NetWorthScreen(),
                ),
                HomeFeatureCard(
                  title: "Settlements",
                  subtitle: "Clearance & Debts",
                  icon: Icons.handshake_outlined,
                  gradientColors: [
                    AppColors.deepPurple.withOpacity(0.2),
                    AppColors.deepPurple.withOpacity(0.05),
                  ],
                  iconColor: AppColors.deepPurple,
                  destination: const SettlementScreen(),
                ),
                HomeFeatureCard(
                  title: "Credit Cards",
                  subtitle: "Usage & Payments",
                  icon: Icons.credit_card_rounded,
                  gradientColors: [
                    AppColors.dangerRed.withOpacity(0.2),
                    AppColors.dangerRed.withOpacity(0.05),
                  ],
                  iconColor: AppColors.dangerRed,
                  destination: const CreditTrackerScreen(),
                ),
                HomeFeatureCard(
                  title: "Custom Data",
                  subtitle: "Personal Logs",
                  icon: Icons.dashboard_customize_rounded,
                  gradientColors: [
                    AppColors.electricPink.withOpacity(0.2),
                    AppColors.electricPink.withOpacity(0.05),
                  ],
                  iconColor: AppColors.electricPink,
                  destination: const CustomEntryDashboard(),
                ),
              ],
            ),
          ),

          // --- Bottom Control Bar ---
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: HomeBottomBar(),
          ),
          // Add extra bottom padding for safety
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }
}
