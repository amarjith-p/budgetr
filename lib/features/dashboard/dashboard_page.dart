import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/bento_card.dart';
import '../../core/theme/app_theme.dart';
import '../../core/components/modern_app_bar.dart'; 
import '../category_manager/views/category_manager_page.dart'; 
import '../settings/views/settings_page.dart'; 

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: isDark ? Colors.white60 : Colors.black54,
    );
    final valueStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    );

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'BUDGETR',
        subtitle: 'OVERVIEW',
        leadingIcon: null, 
        trailingIcon: null, // Removed the Settings gear from the App Bar
      ),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // LEFT COLUMN (Wider, Flex 5)
                    // Total Height = 240 + 16 + 140 + 16 + 84 = 496px
                    Expanded(
                      flex: 5,
                      child: Column(
                        children: [
                          // Card 1: Money Tracker (Tall)
                          BentoCard(
                            height: 240,
                            backgroundColor: isDark ? AppTokens.surfaceLight : AppTokens.primary,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.wallet, color: isDark ? Colors.black : Colors.white),
                                    Icon(Icons.arrow_forward, color: isDark ? Colors.black : Colors.white, size: 18),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('NET WORTH', style: labelStyle?.copyWith(color: isDark ? Colors.black54 : Colors.white70)),
                                    const SizedBox(height: 8),
                                    Text('\$12,450.00', style: valueStyle?.copyWith(fontSize: 28, color: isDark ? Colors.black : Colors.white)),
                                    const SizedBox(height: 16),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _buildFlatBar(40, isDark),
                                        _buildFlatBar(60, isDark),
                                        _buildFlatBar(30, isDark),
                                        _buildFlatBar(80, isDark),
                                        _buildFlatBar(50, isDark),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Card 2: Spending (Short)
                          BentoCard(
                            height: 140,
                            onTap: () {},
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('MONTHLY BURN', style: labelStyle),
                                Text('\$3,210', style: valueStyle?.copyWith(fontSize: 24)),
                                Text('+12.4% vs Last', style: theme.textTheme.bodySmall?.copyWith(color: AppTokens.primaryLight, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          
                          // Card 3: Categories Menu (Short)
                          BentoCard(
                            height: 84,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CategoryManagerPage()),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('CATEGORIES', style: labelStyle),
                                const Icon(Icons.category_outlined, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // RIGHT COLUMN (Narrower, Flex 4)
                    // Total Height = 120 + 16 + 160 + 16 + 84 + 16 + 84 = 496px
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          // Card 4: Quick Action (Short)
                          BentoCard(
                            height: 120,
                            onTap: () {},
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(Icons.add_box_outlined, color: theme.colorScheme.onSurface),
                                Text('ADD LOG', style: labelStyle),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Card 5: Budgets (Medium)
                          BentoCard(
                            height: 160,
                            onTap: () {},
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('ACTIVE\nBUDGETS', style: labelStyle),
                                Text('3', style: valueStyle?.copyWith(fontSize: 32)),
                                Container(
                                  height: 4,
                                  width: double.infinity,
                                  color: AppTokens.primaryLight,
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Card 6: Recent (Short)
                          BentoCard(
                            height: 84,
                            onTap: () {},
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('HISTORY', style: labelStyle),
                                const Icon(Icons.receipt_long, size: 20),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Card 7: Settings (Short) -> NEWLY ADDED TO BALANCE GRID
                          BentoCard(
                            height: 84,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsPage()),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('SETTINGS', style: labelStyle),
                                const Icon(Icons.settings_outlined, size: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _buildFlatBar(double height, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      width: 12,
      height: height,
      color: isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.2),
    );
  }
}