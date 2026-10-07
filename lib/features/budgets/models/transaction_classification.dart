// lib/features/budgets/models/transaction_classification.dart

enum TransactionClassification {
  /// Fixed/Scheduled: EMI, Rent, Insurance, Subscriptions — happens every month
  fixed,

  /// Variable/Daily: Food, Fuel, Entertainment — fluctuates day to day
  variable,

  /// One-off/Lump Sum: Travel, Medical, Gift — unusual, non-recurring
  oneoff,
}

extension TransactionClassificationX on TransactionClassification {
  String get label {
    switch (this) {
      case TransactionClassification.fixed:
        return 'Fixed / Scheduled';
      case TransactionClassification.variable:
        return 'Variable / Daily';
      case TransactionClassification.oneoff:
        return 'One-off / Lump Sum';
    }
  }

  String get description {
    switch (this) {
      case TransactionClassification.fixed:
        return 'Recurring monthly commitment (EMI, Rent, Insurance)';
      case TransactionClassification.variable:
        return 'Day-to-day spending that may change (Food, Fuel, Shopping)';
      case TransactionClassification.oneoff:
        return 'Unusual, non-recurring expense (Travel, Medical, Gift)';
    }
  }

  String get emoji {
    switch (this) {
      case TransactionClassification.fixed:
        return '🔁';
      case TransactionClassification.variable:
        return '🌊';
      case TransactionClassification.oneoff:
        return '⚡';
    }
  }
}
