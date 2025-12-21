import 'package:flutter/material.dart';
import '../../../core/widgets/glass_card.dart'; // Import New Widget
import '../../dashboard/screens/dashboard_screen.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../net_worth/screens/net_worth_screen.dart';
import '../../custom_entry/screens/custom_entry_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0D1B2A),
      body: Stack(
        children: [
          // Background Gradients
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3A86FF).withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00A6FB).withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const SizedBox(height: 40),
                Text(
                  'BudGetR',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF90E0EF).withOpacity(0.8),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'FinTracK',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                _buildMenuCard(
                  context,
                  Icons.account_balance_wallet_outlined,
                  'Budgets',
                  'View & manage monthly Budgets',
                  const DashboardScreen(),
                ),
                _buildMenuCard(
                  context,
                  Icons.analytics_outlined,
                  'Settlement Analysis',
                  'View spending habits',
                  const SettlementScreen(),
                ),
                _buildMenuCard(
                  context,
                  Icons.currency_rupee,
                  'Net Worth',
                  'Track your total wealth',
                  const NetWorthScreen(),
                ),
                _buildMenuCard(
                  context,
                  Icons.dashboard_customize_outlined,
                  'Custom Data Entry',
                  'Your personalized data trackers',
                  const CustomEntryDashboard(),
                ),
                _buildMenuCard(
                  context,
                  Icons.settings_suggest_outlined,
                  'Budget Settings',
                  'Adjust Budget Buckets',
                  const SettingsScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget screen,
  ) {
    // Uses the new reusable GlassCard
    return GlassCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3A86FF), size: 36),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54),
        ],
      ),
    );
  }
}
