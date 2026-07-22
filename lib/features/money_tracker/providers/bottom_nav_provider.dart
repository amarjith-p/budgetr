import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Manages the active tab index for the Money Tracker base screen.
/// 0: Home, 1: Transactions, 2: Accounts, 3: Budgets, 4: Analytics
final moneyTrackerNavProvider = StateProvider.autoDispose<int>((ref) => 0);