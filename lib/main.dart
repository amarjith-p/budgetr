import 'package:budgetr/features/automation/providers/smart_inbox_provider.dart';
import 'package:budgetr/features/budgets/services/home_widget_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/auth_page.dart';
import 'features/auth/auth_state.dart';
import 'features/dashboard/dashboard_page.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/notification_service.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/automation/providers/automation_provider.dart';

import 'core/database/database_provider.dart';
import 'features/transactions/views/transaction_form_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  await HomeWidget.setAppGroupId('group.com.example.budgetr');
  runApp(const ProviderScope(child: BudgetrApp()));
}

class BudgetrApp extends ConsumerStatefulWidget {
  const BudgetrApp({super.key});

  @override
  ConsumerState<BudgetrApp> createState() => _BudgetrAppState();
}

class _BudgetrAppState extends ConsumerState<BudgetrApp>
    with WidgetsBindingObserver {
  bool _hasInitializedSchedulers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.requestPermissions();

    // Listen for deep links from the widget
    HomeWidget.widgetClicked.listen(_handleWidgetDeepLink);
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetDeepLink);

    // --- TRIGGER ENGINE ON FRESH APP LAUNCH ONCE ---
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitializedSchedulers) {
        _hasInitializedSchedulers = true;
        initializeNotificationScheduler(ref);
        ref.read(automationEngineProvider).runCatchUp();
        ref
            .read(smartInboxActionProvider.notifier)
            .requestPermissionsAndListen();

        // Sync widget on fresh launch
        HomeWidgetSyncService.syncBudget(ref.read(databaseProvider));
      }
    });
  }

  void _handleWidgetDeepLink(Uri? uri) {
    if (uri != null && uri.host == 'add_transaction') {
      Future.delayed(const Duration(milliseconds: 300), () {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const TransactionFormPage()),
        );
      });
    }
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
      // Sync widget right as the app goes to background
      HomeWidgetSyncService.syncBudget(ref.read(databaseProvider));
    } else if (state == AppLifecycleState.resumed) {
      ref.read(authProvider.notifier).attemptBiometricUnlock();
      ref.read(automationEngineProvider).runCatchUp();
      ref.read(smartInboxActionProvider.notifier).requestPermissionsAndListen();
      HomeWidgetSyncService.syncBudget(ref.read(databaseProvider));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = ref.watch(authProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'FinStack 360',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: currentThemeMode,
      home: const DashboardPage(),
      builder: (context, child) {
        return Stack(
          children: [
            child!,
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
