import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../net_worth/screens/net_worth_screen.dart';
import '../../custom_entry/screens/custom_entry_dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the color palette
    final bgColor = const Color(0xff0D1B2A);
    final cardColor = const Color(0xFF1B263B).withOpacity(0.6);
    final accentBlue = const Color(0xFF3A86FF);

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: Row(
          children: [
            // --- NEW CUSTOM AVATAR SECTION ---
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                image: const DecorationImage(
                  // 1. Ensure you have a file at: assets/images/avatar.png
                  // 2. Ensure 'assets/images/' is in your pubspec.yaml
                  image: AssetImage('assets/images/avatar.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),

            // ---------------------------------
            const SizedBox(width: 12),
            const Text(
              'BudGetR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                fontSize: 22,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // --- Ambient Background Glows ---
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [accentBlue.withOpacity(0.2), Colors.transparent],
                  center: Alignment.center,
                  radius: 0.6,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00A6FB).withOpacity(0.15),
                    Colors.transparent,
                  ],
                  center: Alignment.center,
                  radius: 0.6,
                ),
              ),
            ),
          ),

          // --- Main Content ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text(
                    "",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Dashboard Grid ---
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85,
                      children: [
                        _buildFeatureCard(
                          context,
                          title: "Budgets",
                          subtitle: "Manage Monthly Budgets",
                          icon: Icons.pie_chart_outline,
                          color: const Color(0xFF4361EE),
                          destination: const DashboardScreen(),
                        ),
                        _buildFeatureCard(
                          context,
                          title: "Net Worth",
                          subtitle: "Track Your Networth",
                          icon: Icons.currency_rupee,
                          color: const Color(0xFF2EC4B6),
                          destination: const NetWorthScreen(),
                        ),
                        _buildFeatureCard(
                          context,
                          title: "Settlements",
                          subtitle: "Month-end Settlements",
                          icon: Icons.handshake_outlined,
                          color: const Color(0xFF7209B7),
                          destination: const SettlementScreen(),
                        ),
                        _buildFeatureCard(
                          context,
                          title: "Custom Datam Entry",
                          subtitle: "Personal Data Trackers",
                          icon: Icons.dashboard_customize_outlined,
                          color: const Color(0xFFF72585),
                          destination: const CustomEntryDashboard(),
                        ),
                      ],
                    ),
                  ),

                  // --- Bottom Settings Bar ---
                  Container(
                    margin: const EdgeInsets.only(bottom: 20, top: 10),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          color: Colors.white,
                        ),
                      ),
                      title: const Text(
                        "Configurations",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Manage Budget Buckets & Preferences",
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white30,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1B263B).withOpacity(0.6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
