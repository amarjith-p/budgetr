import 'package:budgetr/features/accounts/views/accounts_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/modern_app_bar.dart';
import '../../../core/components/modern_bottom_nav.dart';
import '../providers/bottom_nav_provider.dart';

class MoneyTrackerBasePage extends ConsumerWidget {
  const MoneyTrackerBasePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current tab index
    final currentIndex = ref.watch(moneyTrackerNavProvider);

    // List of screens corresponding to the bottom nav tabs
    final List<Widget> pages = [
      const _PlaceholderTab(title: 'MONEY TRACKER HOME'),
      const _PlaceholderTab(title: 'TRANSACTION RECORDS'),
      const AccountsTab(),
      const _PlaceholderTab(title: 'BUDGET MANAGEMENT'),
      const _PlaceholderTab(title: 'ANALYTICS & INSIGHTS'),
    ];

    return Scaffold(
      appBar: const ModernAppBar(
        title: 'Tracker',
        subtitle: 'FINANCE',
        leadingIcon: Icons.arrow_back_rounded,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[currentIndex],
      ),
      bottomNavigationBar: ModernBottomNav(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(moneyTrackerNavProvider.notifier).state = index;
        },
      ),
    );
  }
}

/// Temporary placeholder for the tabs until we build them out
class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
    );
  }
}