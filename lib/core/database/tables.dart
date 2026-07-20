import 'package:drift/drift.dart';

/// LIQUIDITY: Bank Accounts & Wallets
class BankAccounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get bankName => text()();
  TextColumn get accountType => text()();
  TextColumn get accountNumber => text()();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  IntColumn get color => integer().withDefault(const Constant(0xFF1E1E1E))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// LIQUIDITY: Bank Transactions (Income, Expense, Transfers)
class BankTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(BankAccounts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get bucket => text()();
  TextColumn get type => text()(); // Income, Expense, Transfer
  TextColumn get category => text()();
  TextColumn get subCategory => text()();
  TextColumn get notes => text()();
  // Foreign key to link a bank transfer to a credit card bill payment
  TextColumn get linkedCreditCardId => text().nullable()(); 

  @override
  Set<Column> get primaryKey => {id};
}

/// LIABILITY: Credit Cards
class CreditCards extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get bankName => text()();
  TextColumn get lastFourDigits => text()();
  RealColumn get creditLimit => real()();
  RealColumn get currentBalance => real().withDefault(const Constant(0.0))();
  IntColumn get billDate => integer()();
  IntColumn get dueDate => integer()();
  IntColumn get color => integer().withDefault(const Constant(0xFF1E1E1E))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// LIABILITY: Credit Card Transactions (Spends & Repayments)
class CreditTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get cardId => text().references(CreditCards, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get date => dateTime()();
  TextColumn get bucket => text()();
  TextColumn get type => text()(); // Expense, Payment
  TextColumn get category => text()();
  TextColumn get subCategory => text()();
  TextColumn get notes => text()();
  // Foreign key to link a credit payment back to the source bank transaction
  TextColumn get linkedBankTransactionId => text().nullable()(); 
  
  // Intelligent Cycle Flags
  BoolColumn get includeInNextStatement => boolean().withDefault(const Constant(false))();
  BoolColumn get isSettlementVerified => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}