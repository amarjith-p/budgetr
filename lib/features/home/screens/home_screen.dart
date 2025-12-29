import 'dart:ui';
import 'package:flutter/material.dart';

import '../../custom_entry/screens/custom_entry_dashboard.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../net_worth/screens/net_worth_screen.dart';
import '../../settlement/screens/settlement_screen.dart';
import '../../credit_tracker/screens/credit_tracker_screen.dart';
import '../../investment/screens/investment_screen.dart';

import '../widgets/home_app_bar.dart';
import '../widgets/home_bottom_bar.dart';
import '../widgets/home_feature_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Premium Dark Palette
    const bgColor = Color(0xff050505); // Pure Black / Deep Void
    const accent1 = Color(0xFF4361EE); // Royal Blue
    const accent2 = Color(0xFF7209B7); // Deep Purple

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: const HomeAppBar(),
      body: Stack(
        children: [
          // --- LAYER 1: Aurora Gradients (Subtle & Professional) ---
          Positioned(
            top: -100,
            left: -50,
            child: _buildAuroraOrb(accent1, 350),
          ),
          Positioned(
            top: 200,
            right: -100,
            child: _buildAuroraOrb(accent2.withOpacity(0.5), 300),
          ),
          Positioned(
            bottom: -50,
            left: 50,
            child: _buildAuroraOrb(Colors.teal.withOpacity(0.3), 250),
          ),

          // --- LAYER 2: Noise Texture (Optional for realism, usually implies quality) ---
          // Using a simple opacity layer instead to dim the orbs
          Container(color: bgColor.withOpacity(0.6)),

          // --- LAYER 3: Main Content ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Professional Greeting
                  Text(
                    "Overview",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Financial Suite",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Dashboard Grid ---
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.85, // Taller cards for elegance
                      padding: const EdgeInsets.only(bottom: 20),
                      children: [
                        HomeFeatureCard(
                          title: "Budgets",
                          subtitle: "Allocation & Analysis",
                          icon: Icons.pie_chart_outline_rounded,
                          // Blue Gradient
                          gradientColors: [
                            const Color(0xFF4361EE).withOpacity(0.2),
                            const Color(0xFF4361EE).withOpacity(0.05),
                          ],
                          iconColor: const Color(0xFF4361EE),
                          destination: const DashboardScreen(),
                        ),
                        HomeFeatureCard(
                          title: "Investments",
                          subtitle: "Portfolio Growth",
                          icon: Icons.candlestick_chart_rounded,
                          // Orange/Gold Gradient
                          gradientColors: [
                            const Color(0xFFFF9F1C).withOpacity(0.2),
                            const Color(0xFFFF9F1C).withOpacity(0.05),
                          ],
                          iconColor: const Color(0xFFFF9F1C),
                          destination: const InvestmentScreen(),
                        ),
                        HomeFeatureCard(
                          title: "Net Worth",
                          subtitle: "Total Asset Value",
                          icon: Icons.account_balance_wallet_outlined,
                          // Teal Gradient
                          gradientColors: [
                            const Color(0xFF2EC4B6).withOpacity(0.2),
                            const Color(0xFF2EC4B6).withOpacity(0.05),
                          ],
                          iconColor: const Color(0xFF2EC4B6),
                          destination: const NetWorthScreen(),
                        ),
                        HomeFeatureCard(
                          title: "Settlements",
                          subtitle: "Clearance & Debts",
                          icon: Icons.handshake_outlined,
                          // Purple Gradient
                          gradientColors: [
                            const Color(0xFF7209B7).withOpacity(0.2),
                            const Color(0xFF7209B7).withOpacity(0.05),
                          ],
                          iconColor: const Color(0xFF7209B7),
                          destination: const SettlementScreen(),
                        ),
                        HomeFeatureCard(
                          title: "Credit Cards",
                          subtitle: "Usage & Payments",
                          icon: Icons.credit_card_rounded,
                          // Red/Pink Gradient
                          gradientColors: [
                            const Color(0xFFE63946).withOpacity(0.2),
                            const Color(0xFFE63946).withOpacity(0.05),
                          ],
                          iconColor: const Color(0xFFE63946),
                          destination: const CreditTrackerScreen(),
                        ),
                        HomeFeatureCard(
                          title: "Custom Data",
                          subtitle: "Personal Logs",
                          icon: Icons.dashboard_customize_rounded,
                          // Pink Gradient
                          gradientColors: [
                            const Color(0xFFF72585).withOpacity(0.2),
                            const Color(0xFFF72585).withOpacity(0.05),
                          ],
                          iconColor: const Color(0xFFF72585),
                          destination: const CustomEntryDashboard(),
                        ),
                      ],
                    ),
                  ),

                  // --- Bottom Control Bar ---
                  const HomeBottomBar(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuroraOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
