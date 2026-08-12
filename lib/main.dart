// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/auth/auth_state.dart';
import 'features/dashboard/dashboard_page.dart';
import 'core/providers/theme_provider.dart';

// --- NEW IMPORTS ---
import 'core/services/notification_service.dart';
import 'features/notifications/providers/notification_provider.dart';

void main() async {
  // --- INITIALIZE NATIVE BINDINGS AND NOTIFICATIONS ---
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: BudgetrApp()));
}

class BudgetrApp extends ConsumerStatefulWidget {
  const BudgetrApp({super.key});

  @override
  ConsumerState<BudgetrApp> createState() => _BudgetrAppState();
}

class _BudgetrAppState extends ConsumerState<BudgetrApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // --- REQUEST PERMISSION ON APP LAUNCH ---
    NotificationService.instance.requestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      ref.read(authProvider.notifier).lockApp();
    } else if (state == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).attemptBiometricUnlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    // --- HOOK UP THE SILENT NOTIFICATION SCHEDULER ---
    initializeNotificationScheduler(ref);

    return MaterialApp(
      title: 'FinStack 360',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,

      // The underlying app ALWAYS natively routes to the Dashboard
      home: const DashboardPage(),

      // --- GLOBAL APP LOCK LAYER ---
      // This guarantees 100% security against route-popping.
      // It physically stacks the AuthPage over the ENTIRE running app.
      builder: (context, child) {
        return Stack(
          children: [
            child!, // The real application running normally

            if (authStatus != AuthStatus.authenticated)
              Positioned.fill(
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: currentThemeMode,
                  home: authStatus == AuthStatus.loading
                      ? Scaffold(
                          backgroundColor: Theme.of(
                            context,
                          ).scaffoldBackgroundColor,
                          body: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const AuthPage(),
                ),
              ),
          ],
        );
      },
    );
  }
}
