// lib/core/database/tables.dart
import 'package:drift/drift.dart';

class TransactionCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get subCategories => text()();
  IntColumn get iconCode => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetBucket')
class BudgetBuckets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get percentage => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get providerName => text()();
  TextColumn get type => text()();
  TextColumn get last4 => text().nullable()();
  RealColumn get balance => real()();

  RealColumn get creditLimit => real().nullable()();
  IntColumn get billDate => integer().nullable()();
  IntColumn get dueDate => integer().nullable()();
  BoolColumn get isCreditPayable =>
      boolean().withDefault(const Constant(false))();

  TextColumn get loanPurpose => text().nullable()();
  RealColumn get loanPrincipal => real().nullable()();
  RealColumn get interestRate => real().nullable()();
  IntColumn get tenureMonths => integer().nullable()();
  DateTimeColumn get emiDate => dateTime().nullable()();
  DateTimeColumn get loanStartDate => dateTime().nullable()();
  DateTimeColumn get loanEndDate => dateTime().nullable()();

  RealColumn get totalInterestPayable => real().nullable()();
  RealColumn get totalTaxPayable => real().nullable()();
  RealColumn get bankCharges => real().nullable()();

  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer().nullable()();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionRecord')
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get accountId => text()();
  TextColumn get toAccountId => text().nullable()();

  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  IntColumn get categoryIcon => integer().nullable()();

  TextColumn get subCategory => text().nullable()();
  IntColumn get bucketId => integer().nullable()();
  TextColumn get bucketName => text().nullable()();
  TextColumn get notes => text().nullable()();

  BoolColumn get isSpillover => boolean().withDefault(const Constant(false))();
  BoolColumn get isSettlementVerified =>
      boolean().withDefault(const Constant(false))();

  TextColumn get locationName => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MonthlyBudget')
class MonthlyBudgets extends Table {
  TextColumn get id => text()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get salaryIncome => real().withDefault(const Constant(0.0))();
  RealColumn get extraIncome => real().withDefault(const Constant(0.0))();
  RealColumn get deductions => real().withDefault(const Constant(0.0))();
  TextColumn get bucketsSnapshot => text().nullable()();
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();
  RealColumn get closedTotalSpent => real().nullable()();
  RealColumn get closedOutOfBucket => real().nullable()();
  RealColumn get closedRemaining => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ClosedBudgetSnapshot')
class ClosedBudgetSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get budgetId => text()();
  RealColumn get salaryIncome => real()();
  RealColumn get extraIncome => real()();
  RealColumn get deductions => real()();
  RealColumn get effectiveIncome => real()();
  RealColumn get totalSpent => real()();
  RealColumn get totalOutOfBucket => real()();
  RealColumn get totalRemaining => real()();
  RealColumn get budgetedRemaining => real()();
  TextColumn get bucketDetailsJson => text()();
  DateTimeColumn get closedAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomBudget')
class CustomBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get amountLimit => real()();
  TextColumn get timeFrame => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get subCategory => text().nullable()();
  IntColumn get bucketId => integer().nullable()();
  TextColumn get accountId => text().nullable()();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  RealColumn get settledAmount => real().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

class Investments extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get provider => text()();
  TextColumn get providerUrl => text().nullable()();
  TextColumn get specialTag => text().nullable()();

  RealColumn get initialAmount => real()();
  RealColumn get currentValue => real().withDefault(const Constant(0.0))();
  RealColumn get targetAmount => real().nullable()();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get expectedEndDate => dateTime().nullable()();
  RealColumn get expectedReturn => real().nullable()();

  TextColumn get folioNo => text().nullable()();
  RealColumn get units => real().nullable()();
  TextColumn get brokerName => text().nullable()();

  TextColumn get linkedAccountNo => text().nullable()();
  TextColumn get linkedAccountIfsc => text().nullable()();
  TextColumn get linkedBankName => text().nullable()();

  TextColumn get purpose => text().nullable()();
  TextColumn get notes => text().nullable()();

  // --- NEW: Lifecycle Management Fields ---
  BoolColumn get isClosed => boolean().withDefault(const Constant(false))();
  TextColumn get closeReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class InvestmentLogs extends Table {
  TextColumn get id => text()();
  TextColumn get investmentId => text()();
  TextColumn get type => text()(); // 'Deposit', 'Withdrawal', or 'Update'
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SmartTrackerTemplate')
class SmartTrackerTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  // We store the dynamic form fields as a JSON string
  TextColumn get schemaJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SmartTrackerRecord')
class SmartTrackerRecords extends Table {
  TextColumn get id => text()();
  TextColumn get templateId => text()();
  // Stores the user's answers as a JSON map (Field ID -> Value)
  TextColumn get dataJson => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get payload => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class RecurringTransactionRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  TextColumn get serviceWebsite => text().nullable()(); // NEW
  RealColumn get amount => real().nullable()();

  TextColumn get transactionType => text()();
  TextColumn get accountId => text()();
  TextColumn get toAccountId => text().nullable()();

  TextColumn get categoryId => text().nullable()();
  TextColumn get categoryName => text().nullable()();
  IntColumn get categoryIcon => integer().nullable()();
  TextColumn get subCategory => text().nullable()();
  IntColumn get bucketId => integer().nullable()();
  TextColumn get bucketName => text().nullable()();

  TextColumn get repetitionSchedule => text()();
  IntColumn get repetitionInterval => integer()();
  TextColumn get advancedSchedule =>
      text().nullable()(); // NEW (e.g., "1st Monday")
  DateTimeColumn get startDate => dateTime()();
  TextColumn get occurrenceTime => text()();

  BoolColumn get isAutomatic => boolean()();
  DateTimeColumn get lastExecutedDate => dateTime().nullable()();
  DateTimeColumn get nextExecutionDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Trips extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get budget => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text()(); // 'ACTIVE', 'PAUSED', 'COMPLETED'
  TextColumn get periodsJson => text()(); // List of start/end timestamps
  TextColumn get excludedTxIdsJson => text()(); // List of transaction IDs

  @override
  Set<Column> get primaryKey => {id};
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get targetDate => dateTime()();
  BoolColumn get isPushEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get priorDays => integer().nullable()();
  IntColumn get notificationId =>
      integer()(); // Used to cancel OS/In-App notifications

  @override
  Set<Column> get primaryKey => {id};
}

class VaultRecords extends Table {
  TextColumn get id => text()();
  TextColumn get recordType => text()(); // 'Credential' or 'Card'
  TextColumn get recordName => text()(); // Plaintext for list display
  TextColumn get encryptedPayload =>
      text()(); // Encrypted JSON containing all secrets
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class StagedTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get rawText => text()();
  TextColumn get sourceName => text()();
  TextColumn get packageName => text()();
  RealColumn get extractedAmount => real()();
  TextColumn get inferredType => text()();
  TextColumn get accountLast4 => text().nullable()();
  TextColumn get merchantName => text().nullable()();
  TextColumn get referenceNo => text().nullable()();
  DateTimeColumn get date => dateTime()();
  BoolColumn get isApproved => boolean().withDefault(const Constant(false))();

  // --- ADD THESE NEW LOCATION FIELDS ---
  TextColumn get locationName => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ParserRules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get regexPattern => text()();
  TextColumn get targetType => text()(); // 'Expense' or 'Income'
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class Debts extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()(); // 'Borrowed' or 'Lent'
  TextColumn get person => text()();
  TextColumn get purpose => text()();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get dueDate => dateTime()();

  BoolColumn get isPushEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get priorDays => integer().nullable()();
  IntColumn get notificationId => integer()();

  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  // --- NEW FIELDS ---
  RealColumn get settledAmount => real().withDefault(const Constant(0.0))();
  RealColumn get interestAccumulated =>
      real().withDefault(const Constant(0.0))();
  // ------------------
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('NetWorthRecord')
class NetWorthRecords extends Table {
  TextColumn get id => text()();
  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  // --- ASSETS ---
  RealColumn get assetAccountBalance =>
      real().withDefault(const Constant(0.0))();
  RealColumn get assetSavings => real().withDefault(const Constant(0.0))();
  RealColumn get assetMutualFunds => real().withDefault(const Constant(0.0))();
  RealColumn get assetStocks => real().withDefault(const Constant(0.0))();
  RealColumn get assetBonds => real().withDefault(const Constant(0.0))();
  RealColumn get assetFixedDeposits =>
      real().withDefault(const Constant(0.0))();
  RealColumn get assetRecurringDeposits =>
      real().withDefault(const Constant(0.0))();
  RealColumn get assetP2PLending => real().withDefault(const Constant(0.0))();
  RealColumn get assetOtherInvestments =>
      real().withDefault(const Constant(0.0))();
  RealColumn get assetLentDebts => real().withDefault(const Constant(0.0))();
  RealColumn get assetExtraOthers => real().withDefault(const Constant(0.0))();

  // --- LIABILITIES ---
  RealColumn get liabilityCreditCards =>
      real().withDefault(const Constant(0.0))();
  RealColumn get liabilityLoans => real().withDefault(const Constant(0.0))();
  RealColumn get liabilityBorrowedDebts =>
      real().withDefault(const Constant(0.0))();
  RealColumn get liabilityExtraOthers =>
      real().withDefault(const Constant(0.0))();

  // --- MONTHLY CASHFLOW ---
  RealColumn get cashflowTotalIncome =>
      real().withDefault(const Constant(0.0))();
  RealColumn get cashflowTotalExpense =>
      real().withDefault(const Constant(0.0))();
  RealColumn get cashflowBudgetedIncome =>
      real().withDefault(const Constant(0.0))();
  RealColumn get cashflowBudgetedExpense =>
      real().withDefault(const Constant(0.0))();
  RealColumn get cashflowNonCalcIncome =>
      real().withDefault(const Constant(0.0))();
  RealColumn get cashflowNonCalcExpense =>
      real().withDefault(const Constant(0.0))();
  RealColumn get cashflowOutOfBucket =>
      real().withDefault(const Constant(0.0))();
  RealColumn get cashflowNetTotal => real().withDefault(const Constant(0.0))();
  RealColumn get cashflowNetBudgeted =>
      real().withDefault(const Constant(0.0))();

  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
