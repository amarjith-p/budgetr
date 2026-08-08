// features/insights/providers/insight_view_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

// true = Expense, false = Income
final insightViewIsExpenseProvider = StateProvider<bool>((ref) => true);

// true = By Bucket, false = By Category
final insightViewIsBucketProvider = StateProvider<bool>((ref) => false);

// --- NEW: Drill-Down States ---
final insightSelectedBucketProvider = StateProvider<String?>((ref) => null);
final insightSelectedCategoryProvider = StateProvider<String?>((ref) => null);
