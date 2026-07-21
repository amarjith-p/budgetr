import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/auth/auth_state.dart';
import 'features/dashboard/dashboard_page.dart';
import 'core/providers/theme_provider.dart'; // 1. Added Import

void main() {
  runApp(const ProviderScope(child: BudgetrApp()));
}

class BudgetrApp extends ConsumerStatefulWidget {
  const BudgetrApp({super.key});

  @override
  ConsumerState<BudgetrApp> createState() => _BudgetrAppState();
}

// Added WidgetsBindingObserver to track App Background/Foreground states
class _BudgetrAppState extends ConsumerState<BudgetrApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App sent to background -> Lock the vault immediately
      ref.read(authProvider.notifier).lockApp();
    } else if (state == AppLifecycleState.resumed) {
      // App brought back to foreground -> Attempt Biometric unlock
      ref.read(authProvider.notifier).attemptBiometricUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authProvider);
    final currentThemeMode = ref.watch(themeModeProvider); // 2. Watch the theme state

    Widget getHomeScreen() {
      switch (authStatus) {
        case AuthStatus.loading:
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        case AuthStatus.authenticated:
          return const DashboardPage();
        case AuthStatus.setupRequired:
        case AuthStatus.unauthenticated:
        default:
          return const AuthPage();
      }
    }

    return MaterialApp(
      title: 'Budgetr Improved',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode, // 3. Reactive theme mode
      home: getHomeScreen(),
    );
  }
}