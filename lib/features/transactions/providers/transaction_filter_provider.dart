// features/transactions/providers/transaction_filter_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../services/transaction_service.dart';

enum SortOption { newest, oldest, highestAmount, lowestAmount }

enum TimeframeOption { allTime, currentMonth, lastMonth, custom }

class RecordItem {
  final TransactionWithDetails data;
  final String perspectiveAccountId;
  const RecordItem({required this.data, required this.perspectiveAccountId});
}

class TransactionFilterState {
  final SortOption sortBy;
  final TimeframeOption timeframe;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final Set<String> types;

  // --- FIX: USE SNAPSHOT NAMES INSTEAD OF IDS ---
  final Set<String> bucketNames;
  final Set<String> categoryNames;

  final Set<String> subCategories;
  final Set<String> accountIds;
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilterState({
    this.sortBy = SortOption.newest,
    this.timeframe = TimeframeOption.allTime,
    this.customStartDate,
    this.customEndDate,
    this.types = const {},
    this.bucketNames = const {},
    this.categoryNames = const {},
    this.subCategories = const {},
    this.accountIds = const {},
    this.minAmount,
    this.maxAmount,
  });

  bool get isActive =>
      sortBy != SortOption.newest ||
      timeframe != TimeframeOption.allTime ||
      types.isNotEmpty ||
      bucketNames.isNotEmpty ||
      categoryNames.isNotEmpty ||
      subCategories.isNotEmpty ||
      accountIds.isNotEmpty ||
      minAmount != null ||
      maxAmount != null;

  TransactionFilterState copyWith({
    SortOption? sortBy,
    TimeframeOption? timeframe,
    DateTime? customStartDate,
    DateTime? customEndDate,
    Set<String>? types,
    Set<String>? bucketNames,
    Set<String>? categoryNames,
    Set<String>? subCategories,
    Set<String>? accountIds,
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
      bucketNames: bucketNames ?? this.bucketNames,
      categoryNames: categoryNames ?? this.categoryNames,
      subCategories: subCategories ?? this.subCategories,
      accountIds: accountIds ?? this.accountIds,
      minAmount: clearMin ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMax ? null : (maxAmount ?? this.maxAmount),
    );
  }
}

final transactionFilterProvider = StateProvider.autoDispose
    .family<TransactionFilterState, String>((ref, accountId) {
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

      if (filter.accountIds.isNotEmpty) {
        if (!filter.accountIds.contains(tx.accountId)) return false;
      }

      if (filter.timeframe == TimeframeOption.currentMonth) {
        final now = DateTime.now();
        if (tx.date.year != now.year || tx.date.month != now.month)
          return false;
      } else if (filter.timeframe == TimeframeOption.lastMonth) {
        final now = DateTime.now();
        int targetYear = now.month == 1 ? now.year - 1 : now.year;
        int targetMonth = now.month == 1 ? 12 : now.month - 1;
        if (tx.date.year != targetYear || tx.date.month != targetMonth)
          return false;
      } else if (filter.timeframe == TimeframeOption.custom &&
          filter.customStartDate != null &&
          filter.customEndDate != null) {
        if (tx.date.isBefore(filter.customStartDate!) ||
            tx.date.isAfter(filter.customEndDate!.add(const Duration(days: 1))))
          return false;
      }

      if (filter.types.isNotEmpty) {
        final isExpense = tx.type == 'Expense';
        final isIncome = tx.type == 'Income';
        final isTransfer = tx.type == 'Transfer';

        bool isMoneyLeaving = isExpense;

        if (isTransfer) {
          if (tx.toAccountId == 'EXTERNAL_IN')
            isMoneyLeaving = false;
          else if (tx.toAccountId == 'EXTERNAL_OUT')
            isMoneyLeaving = true;
          else
            isMoneyLeaving = tx.accountId == currentAccountId;
        }

        String mappedType = '';
        if (isExpense)
          mappedType = 'Expense';
        else if (isIncome)
          mappedType = 'Income';
        else if (isTransfer && isMoneyLeaving)
          mappedType = 'Transfer Out';
        else if (isTransfer && !isMoneyLeaving)
          mappedType = 'Transfer In';

        if (mappedType.isNotEmpty && !filter.types.contains(mappedType))
          return false;
      }

      if (filter.minAmount != null && tx.amount < filter.minAmount!)
        return false;
      if (filter.maxAmount != null && tx.amount > filter.maxAmount!)
        return false;

      // --- FIX: USE SNAPSHOT NAME ---
      if (filter.categoryNames.isNotEmpty) {
        final catName =
            tx.categoryName ?? data.category?.name ?? 'Uncategorized';
        if (!filter.categoryNames.contains(catName)) return false;
      }

      if (filter.subCategories.isNotEmpty) {
        if (tx.subCategory == null ||
            !filter.subCategories.contains(tx.subCategory))
          return false;
      }

      // --- FIX: USE SNAPSHOT NAME ---
      if (filter.bucketNames.isNotEmpty) {
        final bucketName =
            tx.bucketName ?? data.bucket?.name ?? 'Out of Bucket';
        if (!filter.bucketNames.contains(bucketName)) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (filter.sortBy) {
        case SortOption.newest:
          return b.transaction.date.compareTo(a.transaction.date);
        case SortOption.oldest:
          return a.transaction.date.compareTo(b.transaction.date);
        case SortOption.highestAmount:
          return b.transaction.amount.compareTo(a.transaction.amount);
        case SortOption.lowestAmount:
          return a.transaction.amount.compareTo(b.transaction.amount);
      }
    });

    return filtered;
  }

  static List<RecordItem> applyForRecords(
    List<TransactionWithDetails> transactions,
    TransactionFilterState filter,
  ) {
    List<RecordItem> expanded = [];

    for (var data in transactions) {
      final tx = data.transaction;
      expanded.add(RecordItem(data: data, perspectiveAccountId: tx.accountId));

      if (tx.type == 'Transfer' &&
          tx.toAccountId != null &&
          !tx.toAccountId!.startsWith('EXTERNAL')) {
        expanded.add(
          RecordItem(data: data, perspectiveAccountId: tx.toAccountId!),
        );
      }
    }

    var filtered = expanded.where((item) {
      final tx = item.data.transaction;
      final perspective = item.perspectiveAccountId;

      if (filter.accountIds.isNotEmpty) {
        if (!filter.accountIds.contains(perspective)) return false;
      }

      if (filter.timeframe == TimeframeOption.currentMonth) {
        final now = DateTime.now();
        if (tx.date.year != now.year || tx.date.month != now.month)
          return false;
      } else if (filter.timeframe == TimeframeOption.lastMonth) {
        final now = DateTime.now();
        int targetYear = now.month == 1 ? now.year - 1 : now.year;
        int targetMonth = now.month == 1 ? 12 : now.month - 1;
        if (tx.date.year != targetYear || tx.date.month != targetMonth)
          return false;
      } else if (filter.timeframe == TimeframeOption.custom &&
          filter.customStartDate != null &&
          filter.customEndDate != null) {
        if (tx.date.isBefore(filter.customStartDate!) ||
            tx.date.isAfter(filter.customEndDate!.add(const Duration(days: 1))))
          return false;
      }

      if (filter.types.isNotEmpty) {
        final isExpense = tx.type == 'Expense';
        final isIncome = tx.type == 'Income';
        final isTransfer = tx.type == 'Transfer';

        bool isMoneyLeaving = isExpense;

        if (isTransfer) {
          if (tx.toAccountId == 'EXTERNAL_IN')
            isMoneyLeaving = false;
          else if (tx.toAccountId == 'EXTERNAL_OUT')
            isMoneyLeaving = true;
          else
            isMoneyLeaving = tx.accountId == perspective;
        }

        String mappedType = '';
        if (isExpense)
          mappedType = 'Expense';
        else if (isIncome)
          mappedType = 'Income';
        else if (isTransfer && isMoneyLeaving)
          mappedType = 'Transfer Out';
        else if (isTransfer && !isMoneyLeaving)
          mappedType = 'Transfer In';

        if (mappedType.isNotEmpty && !filter.types.contains(mappedType))
          return false;
      }

      if (filter.minAmount != null && tx.amount < filter.minAmount!)
        return false;
      if (filter.maxAmount != null && tx.amount > filter.maxAmount!)
        return false;

      // --- FIX: USE SNAPSHOT NAME ---
      if (filter.categoryNames.isNotEmpty) {
        final catName =
            tx.categoryName ?? item.data.category?.name ?? 'Uncategorized';
        if (!filter.categoryNames.contains(catName)) return false;
      }

      if (filter.subCategories.isNotEmpty) {
        if (tx.subCategory == null ||
            !filter.subCategories.contains(tx.subCategory))
          return false;
      }

      // --- FIX: USE SNAPSHOT NAME ---
      if (filter.bucketNames.isNotEmpty) {
        final bucketName =
            tx.bucketName ?? item.data.bucket?.name ?? 'Out of Bucket';
        if (!filter.bucketNames.contains(bucketName)) return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (filter.sortBy) {
        case SortOption.newest:
          return b.data.transaction.date.compareTo(a.data.transaction.date);
        case SortOption.oldest:
          return a.data.transaction.date.compareTo(b.data.transaction.date);
        case SortOption.highestAmount:
          return b.data.transaction.amount.compareTo(a.data.transaction.amount);
        case SortOption.lowestAmount:
          return a.data.transaction.amount.compareTo(b.data.transaction.amount);
      }
    });

    return filtered;
  }
}
