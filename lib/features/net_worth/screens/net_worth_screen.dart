import 'package:flutter/material.dart';
import '../widgets/net_worth_dashboard_tab.dart';
import '../widgets/net_worth_splits_tab.dart';

// --- DESIGN SYSTEM IMPORTS ---
import '../../../core/design/budgetr_colors.dart';
import '../../../core/design/budgetr_styles.dart';
import '../../../core/design/budgetr_components.dart';

class NetWorthScreen extends StatefulWidget {
  const NetWorthScreen({super.key});

  @override
  State<NetWorthScreen> createState() => _NetWorthScreenState();
}

class _NetWorthScreenState extends State<NetWorthScreen> {
  // Removed local color constants in favor of BudgetrColors

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: BudgetrScaffold(
        // Unified AppBar using Design Tokens
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text('Net Worth & Analysis', style: BudgetrStyles.h2),
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(
              80,
            ), // Slightly increased for padding
            child: Container(
              height: 56, // Standardized height
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: BudgetrColors.cardSurface,
                borderRadius: BudgetrStyles.radiusM, // Standard radius
                border: BudgetrStyles.glassBorder, // Unified glass border
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
                indicator: BoxDecoration(
                  color: BudgetrColors.accent, // Unified Accent Color
                  borderRadius: BudgetrStyles.radiusM,
                  boxShadow: BudgetrStyles.glowBoxShadow(BudgetrColors.accent),
                ),
                padding: const EdgeInsets.all(6),
                tabs: const [
                  Tab(text: "TOTAL NET WORTH"),
                  Tab(text: "SPLITS ANALYSIS"),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [NetWorthDashboardTab(), NetWorthSplitsTab()],
        ),
      ),
    );
  }
}
