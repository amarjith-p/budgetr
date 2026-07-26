import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/transaction_service.dart';

enum SortOption { newest, oldest, highestAmount, lowestAmount }
enum TimeframeOption { allTime, currentMonth, lastMonth, custom }

class TransactionFilterState {
  final SortOption sortBy;
  final TimeframeOption timeframe;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final Set<String> types; 
  final Set<int> bucketIds; 
  final Set<String> categoryIds;
  final Set<String> subCategories;
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilterState({
    this.sortBy = SortOption.newest,
    this.timeframe = TimeframeOption.allTime,
    this.customStartDate,
    this.customEndDate,
    this.types = const {},
    this.bucketIds = const {},
    this.categoryIds = const {},
    this.subCategories = const {},
    this.minAmount,
    this.maxAmount,
  });

  bool get isActive =>
      sortBy != SortOption.newest ||
      timeframe != TimeframeOption.allTime ||
      types.isNotEmpty ||
      bucketIds.isNotEmpty ||
      categoryIds.isNotEmpty ||
      subCategories.isNotEmpty ||
      minAmount != null ||
      maxAmount != null;

  TransactionFilterState copyWith({
    SortOption? sortBy,
    TimeframeOption? timeframe,
    DateTime? customStartDate,
    DateTime? customEndDate,
    Set<String>? types,
    Set<int>? bucketIds,
    Set<String>? categoryIds,
    Set<String>? subCategories,
    double? minAmount,
    double? maxAmount,
    bool clearMin = false,
    bool clearMax = false,
  }) {
    return TransactionFilterState(
      sortBy: sortBy ?? this.sortBy,
      timeframe: timeframe ?? this.timeframe,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      types: types ?? this.types,
      bucketIds: bucketIds ?? this.bucketIds,
      categoryIds: categoryIds ?? this.categoryIds,
      subCategories: subCategories ?? this.subCategories,
      minAmount: clearMin ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMax ? null : (maxAmount ?? this.maxAmount),
    );
  }
}

final transactionFilterProvider = StateProvider.autoDispose.family<TransactionFilterState, String>((ref, accountId) {
  return const TransactionFilterState();
});

class TransactionFilterHelper {
  static List<TransactionWithDetails> apply(
    List<TransactionWithDetails> transactions,
    TransactionFilterState filter,
    String currentAccountId,
  ) {
    var filtered = transactions.where((data) {
      final tx = data.transaction;

      // 1. Timeframe
      if (filter.timeframe == TimeframeOption.currentMonth) {
        final now = DateTime.now();
        if (tx.date.year != now.year || tx.date.month != now.month) return false;
      } else if (filter.timeframe == TimeframeOption.lastMonth) {
        final now = DateTime.now();
        int targetYear = now.month == 1 ? now.year - 1 : now.year;
        int targetMonth = now.month == 1 ? 12 : now.month - 1;
        if (tx.date.year != targetYear || tx.date.month != targetMonth) return false;
      } else if (filter.timeframe == TimeframeOption.custom && filter.customStartDate != null && filter.customEndDate != null) {
        if (tx.date.isBefore(filter.customStartDate!) || tx.date.isAfter(filter.customEndDate!.add(const Duration(days: 1)))) return false;
      }

      // 2. Type Matcher
      if (filter.types.isNotEmpty) {
        final isExpense = tx.type == 'Expense';
        final isIncome = tx.type == 'Income';
        final isTransfer = tx.type == 'Transfer';
        
        bool isMoneyLeaving = isExpense;
        if (isTransfer) {
          if (tx.toAccountId == 'EXTERNAL_IN') isMoneyLeaving = false;
          else if (tx.toAccountId == 'EXTERNAL_OUT') isMoneyLeaving = true;
          else isMoneyLeaving = tx.accountId == currentAccountId;
        }

        String mappedType = '';
        if (isExpense) mappedType = 'Expense';
        else if (isIncome) mappedType = 'Income';
        else if (isTransfer && isMoneyLeaving) mappedType = 'Transfer Out';
        else if (isTransfer && !isMoneyLeaving) mappedType = 'Transfer In';

        if (!filter.types.contains(mappedType)) return false;
      }

      // 3. Amount Thresholds
      if (filter.minAmount != null && tx.amount < filter.minAmount!) return false;
      if (filter.maxAmount != null && tx.amount > filter.maxAmount!) return false;

      // 4. Categories & Subcategories
      if (filter.categoryIds.isNotEmpty) {
        if (tx.categoryId == null || !filter.categoryIds.contains(tx.categoryId)) return false;
      }
      if (filter.subCategories.isNotEmpty) {
        if (tx.subCategory == null || !filter.subCategories.contains(tx.subCategory)) return false;
      }

      // 5. Buckets
      if (filter.bucketIds.isNotEmpty) {
        int effectiveBucket = tx.bucketId ?? -1;
        if (!filter.bucketIds.contains(effectiveBucket)) return false;
      }

      return true;
    }).toList();

    // 6. Sort Logic
    filtered.sort((a, b) {
      switch (filter.sortBy) {
        case SortOption.newest: return b.transaction.date.compareTo(a.transaction.date);
        case SortOption.oldest: return a.transaction.date.compareTo(b.transaction.date);
        case SortOption.highestAmount: return b.transaction.amount.compareTo(a.transaction.amount);
        case SortOption.lowestAmount: return a.transaction.amount.compareTo(b.transaction.amount);
      }
    });

    return filtered;
  }
}