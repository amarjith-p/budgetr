// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BankAccountsTable extends BankAccounts
    with TableInfo<$BankAccountsTable, BankAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BankAccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNumberMeta = const VerificationMeta(
    'accountNumber',
  );
  @override
  late final GeneratedColumn<String> accountNumber = GeneratedColumn<String>(
    'account_number',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF1E1E1E),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    bankName,
    accountType,
    accountNumber,
    currentBalance,
    color,
    isArchived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bank_accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BankAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeMeta);
    }
    if (data.containsKey('account_number')) {
      context.handle(
        _accountNumberMeta,
        accountNumber.isAcceptableOrUnknown(
          data['account_number']!,
          _accountNumberMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountNumberMeta);
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BankAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BankAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      )!,
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      accountNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_number'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BankAccountsTable createAlias(String alias) {
    return $BankAccountsTable(attachedDatabase, alias);
  }
}

class BankAccount extends DataClass implements Insertable<BankAccount> {
  final String id;
  final String name;
  final String bankName;
  final String accountType;
  final String accountNumber;
  final double currentBalance;
  final int color;
  final bool isArchived;
  final DateTime createdAt;
  const BankAccount({
    required this.id,
    required this.name,
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    required this.currentBalance,
    required this.color,
    required this.isArchived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['bank_name'] = Variable<String>(bankName);
    map['account_type'] = Variable<String>(accountType);
    map['account_number'] = Variable<String>(accountNumber);
    map['current_balance'] = Variable<double>(currentBalance);
    map['color'] = Variable<int>(color);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BankAccountsCompanion toCompanion(bool nullToAbsent) {
    return BankAccountsCompanion(
      id: Value(id),
      name: Value(name),
      bankName: Value(bankName),
      accountType: Value(accountType),
      accountNumber: Value(accountNumber),
      currentBalance: Value(currentBalance),
      color: Value(color),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory BankAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BankAccount(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      bankName: serializer.fromJson<String>(json['bankName']),
      accountType: serializer.fromJson<String>(json['accountType']),
      accountNumber: serializer.fromJson<String>(json['accountNumber']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      color: serializer.fromJson<int>(json['color']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'bankName': serializer.toJson<String>(bankName),
      'accountType': serializer.toJson<String>(accountType),
      'accountNumber': serializer.toJson<String>(accountNumber),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'color': serializer.toJson<int>(color),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BankAccount copyWith({
    String? id,
    String? name,
    String? bankName,
    String? accountType,
    String? accountNumber,
    double? currentBalance,
    int? color,
    bool? isArchived,
    DateTime? createdAt,
  }) => BankAccount(
    id: id ?? this.id,
    name: name ?? this.name,
    bankName: bankName ?? this.bankName,
    accountType: accountType ?? this.accountType,
    accountNumber: accountNumber ?? this.accountNumber,
    currentBalance: currentBalance ?? this.currentBalance,
    color: color ?? this.color,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );
  BankAccount copyWithCompanion(BankAccountsCompanion data) {
    return BankAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      accountNumber: data.accountNumber.present
          ? data.accountNumber.value
          : this.accountNumber,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      color: data.color.present ? data.color.value : this.color,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BankAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('accountType: $accountType, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('color: $color, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    bankName,
    accountType,
    accountNumber,
    currentBalance,
    color,
    isArchived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BankAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.bankName == this.bankName &&
          other.accountType == this.accountType &&
          other.accountNumber == this.accountNumber &&
          other.currentBalance == this.currentBalance &&
          other.color == this.color &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class BankAccountsCompanion extends UpdateCompanion<BankAccount> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> bankName;
  final Value<String> accountType;
  final Value<String> accountNumber;
  final Value<double> currentBalance;
  final Value<int> color;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const BankAccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.bankName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.accountNumber = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.color = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BankAccountsCompanion.insert({
    required String id,
    required String name,
    required String bankName,
    required String accountType,
    required String accountNumber,
    this.currentBalance = const Value.absent(),
    this.color = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       bankName = Value(bankName),
       accountType = Value(accountType),
       accountNumber = Value(accountNumber),
       createdAt = Value(createdAt);
  static Insertable<BankAccount> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? bankName,
    Expression<String>? accountType,
    Expression<String>? accountNumber,
    Expression<double>? currentBalance,
    Expression<int>? color,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (bankName != null) 'bank_name': bankName,
      if (accountType != null) 'account_type': accountType,
      if (accountNumber != null) 'account_number': accountNumber,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (color != null) 'color': color,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BankAccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? bankName,
    Value<String>? accountType,
    Value<String>? accountNumber,
    Value<double>? currentBalance,
    Value<int>? color,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return BankAccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      accountType: accountType ?? this.accountType,
      accountNumber: accountNumber ?? this.accountNumber,
      currentBalance: currentBalance ?? this.currentBalance,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (accountNumber.present) {
      map['account_number'] = Variable<String>(accountNumber.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BankAccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('accountType: $accountType, ')
          ..write('accountNumber: $accountNumber, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('color: $color, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BankTransactionsTable extends BankTransactions
    with TableInfo<$BankTransactionsTable, BankTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BankTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bank_accounts (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bucketMeta = const VerificationMeta('bucket');
  @override
  late final GeneratedColumn<String> bucket = GeneratedColumn<String>(
    'bucket',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subCategoryMeta = const VerificationMeta(
    'subCategory',
  );
  @override
  late final GeneratedColumn<String> subCategory = GeneratedColumn<String>(
    'sub_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkedCreditCardIdMeta =
      const VerificationMeta('linkedCreditCardId');
  @override
  late final GeneratedColumn<String> linkedCreditCardId =
      GeneratedColumn<String>(
        'linked_credit_card_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    amount,
    date,
    bucket,
    type,
    category,
    subCategory,
    notes,
    linkedCreditCardId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bank_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<BankTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bucket')) {
      context.handle(
        _bucketMeta,
        bucket.isAcceptableOrUnknown(data['bucket']!, _bucketMeta),
      );
    } else if (isInserting) {
      context.missing(_bucketMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sub_category')) {
      context.handle(
        _subCategoryMeta,
        subCategory.isAcceptableOrUnknown(
          data['sub_category']!,
          _subCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subCategoryMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('linked_credit_card_id')) {
      context.handle(
        _linkedCreditCardIdMeta,
        linkedCreditCardId.isAcceptableOrUnknown(
          data['linked_credit_card_id']!,
          _linkedCreditCardIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BankTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BankTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      bucket: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      linkedCreditCardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_credit_card_id'],
      ),
    );
  }

  @override
  $BankTransactionsTable createAlias(String alias) {
    return $BankTransactionsTable(attachedDatabase, alias);
  }
}

class BankTransaction extends DataClass implements Insertable<BankTransaction> {
  final String id;
  final String accountId;
  final double amount;
  final DateTime date;
  final String bucket;
  final String type;
  final String category;
  final String subCategory;
  final String notes;
  final String? linkedCreditCardId;
  const BankTransaction({
    required this.id,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.bucket,
    required this.type,
    required this.category,
    required this.subCategory,
    required this.notes,
    this.linkedCreditCardId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['bucket'] = Variable<String>(bucket);
    map['type'] = Variable<String>(type);
    map['category'] = Variable<String>(category);
    map['sub_category'] = Variable<String>(subCategory);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || linkedCreditCardId != null) {
      map['linked_credit_card_id'] = Variable<String>(linkedCreditCardId);
    }
    return map;
  }

  BankTransactionsCompanion toCompanion(bool nullToAbsent) {
    return BankTransactionsCompanion(
      id: Value(id),
      accountId: Value(accountId),
      amount: Value(amount),
      date: Value(date),
      bucket: Value(bucket),
      type: Value(type),
      category: Value(category),
      subCategory: Value(subCategory),
      notes: Value(notes),
      linkedCreditCardId: linkedCreditCardId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedCreditCardId),
    );
  }

  factory BankTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BankTransaction(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      bucket: serializer.fromJson<String>(json['bucket']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String>(json['category']),
      subCategory: serializer.fromJson<String>(json['subCategory']),
      notes: serializer.fromJson<String>(json['notes']),
      linkedCreditCardId: serializer.fromJson<String?>(
        json['linkedCreditCardId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'bucket': serializer.toJson<String>(bucket),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String>(category),
      'subCategory': serializer.toJson<String>(subCategory),
      'notes': serializer.toJson<String>(notes),
      'linkedCreditCardId': serializer.toJson<String?>(linkedCreditCardId),
    };
  }

  BankTransaction copyWith({
    String? id,
    String? accountId,
    double? amount,
    DateTime? date,
    String? bucket,
    String? type,
    String? category,
    String? subCategory,
    String? notes,
    Value<String?> linkedCreditCardId = const Value.absent(),
  }) => BankTransaction(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    bucket: bucket ?? this.bucket,
    type: type ?? this.type,
    category: category ?? this.category,
    subCategory: subCategory ?? this.subCategory,
    notes: notes ?? this.notes,
    linkedCreditCardId: linkedCreditCardId.present
        ? linkedCreditCardId.value
        : this.linkedCreditCardId,
  );
  BankTransaction copyWithCompanion(BankTransactionsCompanion data) {
    return BankTransaction(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      subCategory: data.subCategory.present
          ? data.subCategory.value
          : this.subCategory,
      notes: data.notes.present ? data.notes.value : this.notes,
      linkedCreditCardId: data.linkedCreditCardId.present
          ? data.linkedCreditCardId.value
          : this.linkedCreditCardId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BankTransaction(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('bucket: $bucket, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('subCategory: $subCategory, ')
          ..write('notes: $notes, ')
          ..write('linkedCreditCardId: $linkedCreditCardId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    amount,
    date,
    bucket,
    type,
    category,
    subCategory,
    notes,
    linkedCreditCardId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BankTransaction &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.bucket == this.bucket &&
          other.type == this.type &&
          other.category == this.category &&
          other.subCategory == this.subCategory &&
          other.notes == this.notes &&
          other.linkedCreditCardId == this.linkedCreditCardId);
}

class BankTransactionsCompanion extends UpdateCompanion<BankTransaction> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String> bucket;
  final Value<String> type;
  final Value<String> category;
  final Value<String> subCategory;
  final Value<String> notes;
  final Value<String?> linkedCreditCardId;
  final Value<int> rowid;
  const BankTransactionsCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.bucket = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.notes = const Value.absent(),
    this.linkedCreditCardId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BankTransactionsCompanion.insert({
    required String id,
    required String accountId,
    required double amount,
    required DateTime date,
    required String bucket,
    required String type,
    required String category,
    required String subCategory,
    required String notes,
    this.linkedCreditCardId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       amount = Value(amount),
       date = Value(date),
       bucket = Value(bucket),
       type = Value(type),
       category = Value(category),
       subCategory = Value(subCategory),
       notes = Value(notes);
  static Insertable<BankTransaction> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? bucket,
    Expression<String>? type,
    Expression<String>? category,
    Expression<String>? subCategory,
    Expression<String>? notes,
    Expression<String>? linkedCreditCardId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (bucket != null) 'bucket': bucket,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (subCategory != null) 'sub_category': subCategory,
      if (notes != null) 'notes': notes,
      if (linkedCreditCardId != null)
        'linked_credit_card_id': linkedCreditCardId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BankTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<double>? amount,
    Value<DateTime>? date,
    Value<String>? bucket,
    Value<String>? type,
    Value<String>? category,
    Value<String>? subCategory,
    Value<String>? notes,
    Value<String?>? linkedCreditCardId,
    Value<int>? rowid,
  }) {
    return BankTransactionsCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      bucket: bucket ?? this.bucket,
      type: type ?? this.type,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      notes: notes ?? this.notes,
      linkedCreditCardId: linkedCreditCardId ?? this.linkedCreditCardId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<String>(bucket.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subCategory.present) {
      map['sub_category'] = Variable<String>(subCategory.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (linkedCreditCardId.present) {
      map['linked_credit_card_id'] = Variable<String>(linkedCreditCardId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BankTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('bucket: $bucket, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('subCategory: $subCategory, ')
          ..write('notes: $notes, ')
          ..write('linkedCreditCardId: $linkedCreditCardId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditCardsTable extends CreditCards
    with TableInfo<$CreditCardsTable, CreditCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bankNameMeta = const VerificationMeta(
    'bankName',
  );
  @override
  late final GeneratedColumn<String> bankName = GeneratedColumn<String>(
    'bank_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastFourDigitsMeta = const VerificationMeta(
    'lastFourDigits',
  );
  @override
  late final GeneratedColumn<String> lastFourDigits = GeneratedColumn<String>(
    'last_four_digits',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentBalanceMeta = const VerificationMeta(
    'currentBalance',
  );
  @override
  late final GeneratedColumn<double> currentBalance = GeneratedColumn<double>(
    'current_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _billDateMeta = const VerificationMeta(
    'billDate',
  );
  @override
  late final GeneratedColumn<int> billDate = GeneratedColumn<int>(
    'bill_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF1E1E1E),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    bankName,
    lastFourDigits,
    creditLimit,
    currentBalance,
    billDate,
    dueDate,
    color,
    isArchived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('bank_name')) {
      context.handle(
        _bankNameMeta,
        bankName.isAcceptableOrUnknown(data['bank_name']!, _bankNameMeta),
      );
    } else if (isInserting) {
      context.missing(_bankNameMeta);
    }
    if (data.containsKey('last_four_digits')) {
      context.handle(
        _lastFourDigitsMeta,
        lastFourDigits.isAcceptableOrUnknown(
          data['last_four_digits']!,
          _lastFourDigitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastFourDigitsMeta);
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creditLimitMeta);
    }
    if (data.containsKey('current_balance')) {
      context.handle(
        _currentBalanceMeta,
        currentBalance.isAcceptableOrUnknown(
          data['current_balance']!,
          _currentBalanceMeta,
        ),
      );
    }
    if (data.containsKey('bill_date')) {
      context.handle(
        _billDateMeta,
        billDate.isAcceptableOrUnknown(data['bill_date']!, _billDateMeta),
      );
    } else if (isInserting) {
      context.missing(_billDateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDateMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      bankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bank_name'],
      )!,
      lastFourDigits: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_four_digits'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      )!,
      currentBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_balance'],
      )!,
      billDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bill_date'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CreditCardsTable createAlias(String alias) {
    return $CreditCardsTable(attachedDatabase, alias);
  }
}

class CreditCard extends DataClass implements Insertable<CreditCard> {
  final String id;
  final String name;
  final String bankName;
  final String lastFourDigits;
  final double creditLimit;
  final double currentBalance;
  final int billDate;
  final int dueDate;
  final int color;
  final bool isArchived;
  final DateTime createdAt;
  const CreditCard({
    required this.id,
    required this.name,
    required this.bankName,
    required this.lastFourDigits,
    required this.creditLimit,
    required this.currentBalance,
    required this.billDate,
    required this.dueDate,
    required this.color,
    required this.isArchived,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['bank_name'] = Variable<String>(bankName);
    map['last_four_digits'] = Variable<String>(lastFourDigits);
    map['credit_limit'] = Variable<double>(creditLimit);
    map['current_balance'] = Variable<double>(currentBalance);
    map['bill_date'] = Variable<int>(billDate);
    map['due_date'] = Variable<int>(dueDate);
    map['color'] = Variable<int>(color);
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CreditCardsCompanion toCompanion(bool nullToAbsent) {
    return CreditCardsCompanion(
      id: Value(id),
      name: Value(name),
      bankName: Value(bankName),
      lastFourDigits: Value(lastFourDigits),
      creditLimit: Value(creditLimit),
      currentBalance: Value(currentBalance),
      billDate: Value(billDate),
      dueDate: Value(dueDate),
      color: Value(color),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory CreditCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditCard(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      bankName: serializer.fromJson<String>(json['bankName']),
      lastFourDigits: serializer.fromJson<String>(json['lastFourDigits']),
      creditLimit: serializer.fromJson<double>(json['creditLimit']),
      currentBalance: serializer.fromJson<double>(json['currentBalance']),
      billDate: serializer.fromJson<int>(json['billDate']),
      dueDate: serializer.fromJson<int>(json['dueDate']),
      color: serializer.fromJson<int>(json['color']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'bankName': serializer.toJson<String>(bankName),
      'lastFourDigits': serializer.toJson<String>(lastFourDigits),
      'creditLimit': serializer.toJson<double>(creditLimit),
      'currentBalance': serializer.toJson<double>(currentBalance),
      'billDate': serializer.toJson<int>(billDate),
      'dueDate': serializer.toJson<int>(dueDate),
      'color': serializer.toJson<int>(color),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CreditCard copyWith({
    String? id,
    String? name,
    String? bankName,
    String? lastFourDigits,
    double? creditLimit,
    double? currentBalance,
    int? billDate,
    int? dueDate,
    int? color,
    bool? isArchived,
    DateTime? createdAt,
  }) => CreditCard(
    id: id ?? this.id,
    name: name ?? this.name,
    bankName: bankName ?? this.bankName,
    lastFourDigits: lastFourDigits ?? this.lastFourDigits,
    creditLimit: creditLimit ?? this.creditLimit,
    currentBalance: currentBalance ?? this.currentBalance,
    billDate: billDate ?? this.billDate,
    dueDate: dueDate ?? this.dueDate,
    color: color ?? this.color,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );
  CreditCard copyWithCompanion(CreditCardsCompanion data) {
    return CreditCard(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      bankName: data.bankName.present ? data.bankName.value : this.bankName,
      lastFourDigits: data.lastFourDigits.present
          ? data.lastFourDigits.value
          : this.lastFourDigits,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      currentBalance: data.currentBalance.present
          ? data.currentBalance.value
          : this.currentBalance,
      billDate: data.billDate.present ? data.billDate.value : this.billDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      color: data.color.present ? data.color.value : this.color,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditCard(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('lastFourDigits: $lastFourDigits, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('billDate: $billDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('color: $color, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    bankName,
    lastFourDigits,
    creditLimit,
    currentBalance,
    billDate,
    dueDate,
    color,
    isArchived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditCard &&
          other.id == this.id &&
          other.name == this.name &&
          other.bankName == this.bankName &&
          other.lastFourDigits == this.lastFourDigits &&
          other.creditLimit == this.creditLimit &&
          other.currentBalance == this.currentBalance &&
          other.billDate == this.billDate &&
          other.dueDate == this.dueDate &&
          other.color == this.color &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class CreditCardsCompanion extends UpdateCompanion<CreditCard> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> bankName;
  final Value<String> lastFourDigits;
  final Value<double> creditLimit;
  final Value<double> currentBalance;
  final Value<int> billDate;
  final Value<int> dueDate;
  final Value<int> color;
  final Value<bool> isArchived;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CreditCardsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.bankName = const Value.absent(),
    this.lastFourDigits = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.currentBalance = const Value.absent(),
    this.billDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.color = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditCardsCompanion.insert({
    required String id,
    required String name,
    required String bankName,
    required String lastFourDigits,
    required double creditLimit,
    this.currentBalance = const Value.absent(),
    required int billDate,
    required int dueDate,
    this.color = const Value.absent(),
    this.isArchived = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       bankName = Value(bankName),
       lastFourDigits = Value(lastFourDigits),
       creditLimit = Value(creditLimit),
       billDate = Value(billDate),
       dueDate = Value(dueDate),
       createdAt = Value(createdAt);
  static Insertable<CreditCard> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? bankName,
    Expression<String>? lastFourDigits,
    Expression<double>? creditLimit,
    Expression<double>? currentBalance,
    Expression<int>? billDate,
    Expression<int>? dueDate,
    Expression<int>? color,
    Expression<bool>? isArchived,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (bankName != null) 'bank_name': bankName,
      if (lastFourDigits != null) 'last_four_digits': lastFourDigits,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (currentBalance != null) 'current_balance': currentBalance,
      if (billDate != null) 'bill_date': billDate,
      if (dueDate != null) 'due_date': dueDate,
      if (color != null) 'color': color,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? bankName,
    Value<String>? lastFourDigits,
    Value<double>? creditLimit,
    Value<double>? currentBalance,
    Value<int>? billDate,
    Value<int>? dueDate,
    Value<int>? color,
    Value<bool>? isArchived,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CreditCardsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      bankName: bankName ?? this.bankName,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
      billDate: billDate ?? this.billDate,
      dueDate: dueDate ?? this.dueDate,
      color: color ?? this.color,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (bankName.present) {
      map['bank_name'] = Variable<String>(bankName.value);
    }
    if (lastFourDigits.present) {
      map['last_four_digits'] = Variable<String>(lastFourDigits.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (currentBalance.present) {
      map['current_balance'] = Variable<double>(currentBalance.value);
    }
    if (billDate.present) {
      map['bill_date'] = Variable<int>(billDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditCardsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('bankName: $bankName, ')
          ..write('lastFourDigits: $lastFourDigits, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('currentBalance: $currentBalance, ')
          ..write('billDate: $billDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('color: $color, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CreditTransactionsTable extends CreditTransactions
    with TableInfo<$CreditTransactionsTable, CreditTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CreditTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<String> cardId = GeneratedColumn<String>(
    'card_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES credit_cards (id)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bucketMeta = const VerificationMeta('bucket');
  @override
  late final GeneratedColumn<String> bucket = GeneratedColumn<String>(
    'bucket',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subCategoryMeta = const VerificationMeta(
    'subCategory',
  );
  @override
  late final GeneratedColumn<String> subCategory = GeneratedColumn<String>(
    'sub_category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _linkedBankTransactionIdMeta =
      const VerificationMeta('linkedBankTransactionId');
  @override
  late final GeneratedColumn<String> linkedBankTransactionId =
      GeneratedColumn<String>(
        'linked_bank_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _includeInNextStatementMeta =
      const VerificationMeta('includeInNextStatement');
  @override
  late final GeneratedColumn<bool> includeInNextStatement =
      GeneratedColumn<bool>(
        'include_in_next_statement',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("include_in_next_statement" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _isSettlementVerifiedMeta =
      const VerificationMeta('isSettlementVerified');
  @override
  late final GeneratedColumn<bool> isSettlementVerified = GeneratedColumn<bool>(
    'is_settlement_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settlement_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    cardId,
    amount,
    date,
    bucket,
    type,
    category,
    subCategory,
    notes,
    linkedBankTransactionId,
    includeInNextStatement,
    isSettlementVerified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'credit_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CreditTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('card_id')) {
      context.handle(
        _cardIdMeta,
        cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta),
      );
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('bucket')) {
      context.handle(
        _bucketMeta,
        bucket.isAcceptableOrUnknown(data['bucket']!, _bucketMeta),
      );
    } else if (isInserting) {
      context.missing(_bucketMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('sub_category')) {
      context.handle(
        _subCategoryMeta,
        subCategory.isAcceptableOrUnknown(
          data['sub_category']!,
          _subCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subCategoryMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    } else if (isInserting) {
      context.missing(_notesMeta);
    }
    if (data.containsKey('linked_bank_transaction_id')) {
      context.handle(
        _linkedBankTransactionIdMeta,
        linkedBankTransactionId.isAcceptableOrUnknown(
          data['linked_bank_transaction_id']!,
          _linkedBankTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('include_in_next_statement')) {
      context.handle(
        _includeInNextStatementMeta,
        includeInNextStatement.isAcceptableOrUnknown(
          data['include_in_next_statement']!,
          _includeInNextStatementMeta,
        ),
      );
    }
    if (data.containsKey('is_settlement_verified')) {
      context.handle(
        _isSettlementVerifiedMeta,
        isSettlementVerified.isAcceptableOrUnknown(
          data['is_settlement_verified']!,
          _isSettlementVerifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CreditTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CreditTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      cardId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}card_id'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      bucket: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      subCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      linkedBankTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_bank_transaction_id'],
      ),
      includeInNextStatement: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_next_statement'],
      )!,
      isSettlementVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settlement_verified'],
      )!,
    );
  }

  @override
  $CreditTransactionsTable createAlias(String alias) {
    return $CreditTransactionsTable(attachedDatabase, alias);
  }
}

class CreditTransaction extends DataClass
    implements Insertable<CreditTransaction> {
  final String id;
  final String cardId;
  final double amount;
  final DateTime date;
  final String bucket;
  final String type;
  final String category;
  final String subCategory;
  final String notes;
  final String? linkedBankTransactionId;
  final bool includeInNextStatement;
  final bool isSettlementVerified;
  const CreditTransaction({
    required this.id,
    required this.cardId,
    required this.amount,
    required this.date,
    required this.bucket,
    required this.type,
    required this.category,
    required this.subCategory,
    required this.notes,
    this.linkedBankTransactionId,
    required this.includeInNextStatement,
    required this.isSettlementVerified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['card_id'] = Variable<String>(cardId);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['bucket'] = Variable<String>(bucket);
    map['type'] = Variable<String>(type);
    map['category'] = Variable<String>(category);
    map['sub_category'] = Variable<String>(subCategory);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || linkedBankTransactionId != null) {
      map['linked_bank_transaction_id'] = Variable<String>(
        linkedBankTransactionId,
      );
    }
    map['include_in_next_statement'] = Variable<bool>(includeInNextStatement);
    map['is_settlement_verified'] = Variable<bool>(isSettlementVerified);
    return map;
  }

  CreditTransactionsCompanion toCompanion(bool nullToAbsent) {
    return CreditTransactionsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      amount: Value(amount),
      date: Value(date),
      bucket: Value(bucket),
      type: Value(type),
      category: Value(category),
      subCategory: Value(subCategory),
      notes: Value(notes),
      linkedBankTransactionId: linkedBankTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedBankTransactionId),
      includeInNextStatement: Value(includeInNextStatement),
      isSettlementVerified: Value(isSettlementVerified),
    );
  }

  factory CreditTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CreditTransaction(
      id: serializer.fromJson<String>(json['id']),
      cardId: serializer.fromJson<String>(json['cardId']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      bucket: serializer.fromJson<String>(json['bucket']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String>(json['category']),
      subCategory: serializer.fromJson<String>(json['subCategory']),
      notes: serializer.fromJson<String>(json['notes']),
      linkedBankTransactionId: serializer.fromJson<String?>(
        json['linkedBankTransactionId'],
      ),
      includeInNextStatement: serializer.fromJson<bool>(
        json['includeInNextStatement'],
      ),
      isSettlementVerified: serializer.fromJson<bool>(
        json['isSettlementVerified'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'cardId': serializer.toJson<String>(cardId),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'bucket': serializer.toJson<String>(bucket),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String>(category),
      'subCategory': serializer.toJson<String>(subCategory),
      'notes': serializer.toJson<String>(notes),
      'linkedBankTransactionId': serializer.toJson<String?>(
        linkedBankTransactionId,
      ),
      'includeInNextStatement': serializer.toJson<bool>(includeInNextStatement),
      'isSettlementVerified': serializer.toJson<bool>(isSettlementVerified),
    };
  }

  CreditTransaction copyWith({
    String? id,
    String? cardId,
    double? amount,
    DateTime? date,
    String? bucket,
    String? type,
    String? category,
    String? subCategory,
    String? notes,
    Value<String?> linkedBankTransactionId = const Value.absent(),
    bool? includeInNextStatement,
    bool? isSettlementVerified,
  }) => CreditTransaction(
    id: id ?? this.id,
    cardId: cardId ?? this.cardId,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    bucket: bucket ?? this.bucket,
    type: type ?? this.type,
    category: category ?? this.category,
    subCategory: subCategory ?? this.subCategory,
    notes: notes ?? this.notes,
    linkedBankTransactionId: linkedBankTransactionId.present
        ? linkedBankTransactionId.value
        : this.linkedBankTransactionId,
    includeInNextStatement:
        includeInNextStatement ?? this.includeInNextStatement,
    isSettlementVerified: isSettlementVerified ?? this.isSettlementVerified,
  );
  CreditTransaction copyWithCompanion(CreditTransactionsCompanion data) {
    return CreditTransaction(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      bucket: data.bucket.present ? data.bucket.value : this.bucket,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      subCategory: data.subCategory.present
          ? data.subCategory.value
          : this.subCategory,
      notes: data.notes.present ? data.notes.value : this.notes,
      linkedBankTransactionId: data.linkedBankTransactionId.present
          ? data.linkedBankTransactionId.value
          : this.linkedBankTransactionId,
      includeInNextStatement: data.includeInNextStatement.present
          ? data.includeInNextStatement.value
          : this.includeInNextStatement,
      isSettlementVerified: data.isSettlementVerified.present
          ? data.isSettlementVerified.value
          : this.isSettlementVerified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CreditTransaction(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('bucket: $bucket, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('subCategory: $subCategory, ')
          ..write('notes: $notes, ')
          ..write('linkedBankTransactionId: $linkedBankTransactionId, ')
          ..write('includeInNextStatement: $includeInNextStatement, ')
          ..write('isSettlementVerified: $isSettlementVerified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    cardId,
    amount,
    date,
    bucket,
    type,
    category,
    subCategory,
    notes,
    linkedBankTransactionId,
    includeInNextStatement,
    isSettlementVerified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CreditTransaction &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.bucket == this.bucket &&
          other.type == this.type &&
          other.category == this.category &&
          other.subCategory == this.subCategory &&
          other.notes == this.notes &&
          other.linkedBankTransactionId == this.linkedBankTransactionId &&
          other.includeInNextStatement == this.includeInNextStatement &&
          other.isSettlementVerified == this.isSettlementVerified);
}

class CreditTransactionsCompanion extends UpdateCompanion<CreditTransaction> {
  final Value<String> id;
  final Value<String> cardId;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String> bucket;
  final Value<String> type;
  final Value<String> category;
  final Value<String> subCategory;
  final Value<String> notes;
  final Value<String?> linkedBankTransactionId;
  final Value<bool> includeInNextStatement;
  final Value<bool> isSettlementVerified;
  final Value<int> rowid;
  const CreditTransactionsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.bucket = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.notes = const Value.absent(),
    this.linkedBankTransactionId = const Value.absent(),
    this.includeInNextStatement = const Value.absent(),
    this.isSettlementVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CreditTransactionsCompanion.insert({
    required String id,
    required String cardId,
    required double amount,
    required DateTime date,
    required String bucket,
    required String type,
    required String category,
    required String subCategory,
    required String notes,
    this.linkedBankTransactionId = const Value.absent(),
    this.includeInNextStatement = const Value.absent(),
    this.isSettlementVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       cardId = Value(cardId),
       amount = Value(amount),
       date = Value(date),
       bucket = Value(bucket),
       type = Value(type),
       category = Value(category),
       subCategory = Value(subCategory),
       notes = Value(notes);
  static Insertable<CreditTransaction> custom({
    Expression<String>? id,
    Expression<String>? cardId,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? bucket,
    Expression<String>? type,
    Expression<String>? category,
    Expression<String>? subCategory,
    Expression<String>? notes,
    Expression<String>? linkedBankTransactionId,
    Expression<bool>? includeInNextStatement,
    Expression<bool>? isSettlementVerified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (bucket != null) 'bucket': bucket,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (subCategory != null) 'sub_category': subCategory,
      if (notes != null) 'notes': notes,
      if (linkedBankTransactionId != null)
        'linked_bank_transaction_id': linkedBankTransactionId,
      if (includeInNextStatement != null)
        'include_in_next_statement': includeInNextStatement,
      if (isSettlementVerified != null)
        'is_settlement_verified': isSettlementVerified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CreditTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? cardId,
    Value<double>? amount,
    Value<DateTime>? date,
    Value<String>? bucket,
    Value<String>? type,
    Value<String>? category,
    Value<String>? subCategory,
    Value<String>? notes,
    Value<String?>? linkedBankTransactionId,
    Value<bool>? includeInNextStatement,
    Value<bool>? isSettlementVerified,
    Value<int>? rowid,
  }) {
    return CreditTransactionsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      bucket: bucket ?? this.bucket,
      type: type ?? this.type,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      notes: notes ?? this.notes,
      linkedBankTransactionId:
          linkedBankTransactionId ?? this.linkedBankTransactionId,
      includeInNextStatement:
          includeInNextStatement ?? this.includeInNextStatement,
      isSettlementVerified: isSettlementVerified ?? this.isSettlementVerified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<String>(cardId.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (bucket.present) {
      map['bucket'] = Variable<String>(bucket.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (subCategory.present) {
      map['sub_category'] = Variable<String>(subCategory.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (linkedBankTransactionId.present) {
      map['linked_bank_transaction_id'] = Variable<String>(
        linkedBankTransactionId.value,
      );
    }
    if (includeInNextStatement.present) {
      map['include_in_next_statement'] = Variable<bool>(
        includeInNextStatement.value,
      );
    }
    if (isSettlementVerified.present) {
      map['is_settlement_verified'] = Variable<bool>(
        isSettlementVerified.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CreditTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('bucket: $bucket, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('subCategory: $subCategory, ')
          ..write('notes: $notes, ')
          ..write('linkedBankTransactionId: $linkedBankTransactionId, ')
          ..write('includeInNextStatement: $includeInNextStatement, ')
          ..write('isSettlementVerified: $isSettlementVerified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BankAccountsTable bankAccounts = $BankAccountsTable(this);
  late final $BankTransactionsTable bankTransactions = $BankTransactionsTable(
    this,
  );
  late final $CreditCardsTable creditCards = $CreditCardsTable(this);
  late final $CreditTransactionsTable creditTransactions =
      $CreditTransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    bankAccounts,
    bankTransactions,
    creditCards,
    creditTransactions,
  ];
}

typedef $$BankAccountsTableCreateCompanionBuilder =
    BankAccountsCompanion Function({
      required String id,
      required String name,
      required String bankName,
      required String accountType,
      required String accountNumber,
      Value<double> currentBalance,
      Value<int> color,
      Value<bool> isArchived,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$BankAccountsTableUpdateCompanionBuilder =
    BankAccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> bankName,
      Value<String> accountType,
      Value<String> accountNumber,
      Value<double> currentBalance,
      Value<int> color,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$BankAccountsTableReferences
    extends BaseReferences<_$AppDatabase, $BankAccountsTable, BankAccount> {
  $$BankAccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$BankTransactionsTable, List<BankTransaction>>
  _bankTransactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.bankTransactions,
    aliasName: 'bank_accounts__id__bank_transactions__account_id',
  );

  $$BankTransactionsTableProcessedTableManager get bankTransactionsRefs {
    final manager = $$BankTransactionsTableTableManager(
      $_db,
      $_db.bankTransactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _bankTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BankAccountsTableFilterComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> bankTransactionsRefs(
    Expression<bool> Function($$BankTransactionsTableFilterComposer f) f,
  ) {
    final $$BankTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bankTransactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BankTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.bankTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BankAccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BankAccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BankAccountsTable> {
  $$BankAccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountNumber => $composableBuilder(
    column: $table.accountNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> bankTransactionsRefs<T extends Object>(
    Expression<T> Function($$BankTransactionsTableAnnotationComposer a) f,
  ) {
    final $$BankTransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bankTransactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BankTransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.bankTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BankAccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BankAccountsTable,
          BankAccount,
          $$BankAccountsTableFilterComposer,
          $$BankAccountsTableOrderingComposer,
          $$BankAccountsTableAnnotationComposer,
          $$BankAccountsTableCreateCompanionBuilder,
          $$BankAccountsTableUpdateCompanionBuilder,
          (BankAccount, $$BankAccountsTableReferences),
          BankAccount,
          PrefetchHooks Function({bool bankTransactionsRefs})
        > {
  $$BankAccountsTableTableManager(_$AppDatabase db, $BankAccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BankAccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BankAccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BankAccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> bankName = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<String> accountNumber = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BankAccountsCompanion(
                id: id,
                name: name,
                bankName: bankName,
                accountType: accountType,
                accountNumber: accountNumber,
                currentBalance: currentBalance,
                color: color,
                isArchived: isArchived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String bankName,
                required String accountType,
                required String accountNumber,
                Value<double> currentBalance = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => BankAccountsCompanion.insert(
                id: id,
                name: name,
                bankName: bankName,
                accountType: accountType,
                accountNumber: accountNumber,
                currentBalance: currentBalance,
                color: color,
                isArchived: isArchived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BankAccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({bankTransactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (bankTransactionsRefs) db.bankTransactions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (bankTransactionsRefs)
                    await $_getPrefetchedData<
                      BankAccount,
                      $BankAccountsTable,
                      BankTransaction
                    >(
                      currentTable: table,
                      referencedTable: $$BankAccountsTableReferences
                          ._bankTransactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BankAccountsTableReferences(
                            db,
                            table,
                            p0,
                          ).bankTransactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.accountId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BankAccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BankAccountsTable,
      BankAccount,
      $$BankAccountsTableFilterComposer,
      $$BankAccountsTableOrderingComposer,
      $$BankAccountsTableAnnotationComposer,
      $$BankAccountsTableCreateCompanionBuilder,
      $$BankAccountsTableUpdateCompanionBuilder,
      (BankAccount, $$BankAccountsTableReferences),
      BankAccount,
      PrefetchHooks Function({bool bankTransactionsRefs})
    >;
typedef $$BankTransactionsTableCreateCompanionBuilder =
    BankTransactionsCompanion Function({
      required String id,
      required String accountId,
      required double amount,
      required DateTime date,
      required String bucket,
      required String type,
      required String category,
      required String subCategory,
      required String notes,
      Value<String?> linkedCreditCardId,
      Value<int> rowid,
    });
typedef $$BankTransactionsTableUpdateCompanionBuilder =
    BankTransactionsCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<double> amount,
      Value<DateTime> date,
      Value<String> bucket,
      Value<String> type,
      Value<String> category,
      Value<String> subCategory,
      Value<String> notes,
      Value<String?> linkedCreditCardId,
      Value<int> rowid,
    });

final class $$BankTransactionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $BankTransactionsTable, BankTransaction> {
  $$BankTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BankAccountsTable _accountIdTable(_$AppDatabase db) => db.bankAccounts
      .createAlias('bank_transactions__account_id__bank_accounts__id');

  $$BankAccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$BankAccountsTableTableManager(
      $_db,
      $_db.bankAccounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BankTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $BankTransactionsTable> {
  $$BankTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucket => $composableBuilder(
    column: $table.bucket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedCreditCardId => $composableBuilder(
    column: $table.linkedCreditCardId,
    builder: (column) => ColumnFilters(column),
  );

  $$BankAccountsTableFilterComposer get accountId {
    final $$BankAccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.bankAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BankAccountsTableFilterComposer(
            $db: $db,
            $table: $db.bankAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BankTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $BankTransactionsTable> {
  $$BankTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucket => $composableBuilder(
    column: $table.bucket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedCreditCardId => $composableBuilder(
    column: $table.linkedCreditCardId,
    builder: (column) => ColumnOrderings(column),
  );

  $$BankAccountsTableOrderingComposer get accountId {
    final $$BankAccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.bankAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BankAccountsTableOrderingComposer(
            $db: $db,
            $table: $db.bankAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BankTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BankTransactionsTable> {
  $$BankTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get linkedCreditCardId => $composableBuilder(
    column: $table.linkedCreditCardId,
    builder: (column) => column,
  );

  $$BankAccountsTableAnnotationComposer get accountId {
    final $$BankAccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.bankAccounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BankAccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.bankAccounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BankTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BankTransactionsTable,
          BankTransaction,
          $$BankTransactionsTableFilterComposer,
          $$BankTransactionsTableOrderingComposer,
          $$BankTransactionsTableAnnotationComposer,
          $$BankTransactionsTableCreateCompanionBuilder,
          $$BankTransactionsTableUpdateCompanionBuilder,
          (BankTransaction, $$BankTransactionsTableReferences),
          BankTransaction,
          PrefetchHooks Function({bool accountId})
        > {
  $$BankTransactionsTableTableManager(
    _$AppDatabase db,
    $BankTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BankTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BankTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BankTransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> bucket = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> subCategory = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> linkedCreditCardId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BankTransactionsCompanion(
                id: id,
                accountId: accountId,
                amount: amount,
                date: date,
                bucket: bucket,
                type: type,
                category: category,
                subCategory: subCategory,
                notes: notes,
                linkedCreditCardId: linkedCreditCardId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                required double amount,
                required DateTime date,
                required String bucket,
                required String type,
                required String category,
                required String subCategory,
                required String notes,
                Value<String?> linkedCreditCardId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BankTransactionsCompanion.insert(
                id: id,
                accountId: accountId,
                amount: amount,
                date: date,
                bucket: bucket,
                type: type,
                category: category,
                subCategory: subCategory,
                notes: notes,
                linkedCreditCardId: linkedCreditCardId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BankTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable:
                                    $$BankTransactionsTableReferences
                                        ._accountIdTable(db),
                                referencedColumn:
                                    $$BankTransactionsTableReferences
                                        ._accountIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BankTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BankTransactionsTable,
      BankTransaction,
      $$BankTransactionsTableFilterComposer,
      $$BankTransactionsTableOrderingComposer,
      $$BankTransactionsTableAnnotationComposer,
      $$BankTransactionsTableCreateCompanionBuilder,
      $$BankTransactionsTableUpdateCompanionBuilder,
      (BankTransaction, $$BankTransactionsTableReferences),
      BankTransaction,
      PrefetchHooks Function({bool accountId})
    >;
typedef $$CreditCardsTableCreateCompanionBuilder =
    CreditCardsCompanion Function({
      required String id,
      required String name,
      required String bankName,
      required String lastFourDigits,
      required double creditLimit,
      Value<double> currentBalance,
      required int billDate,
      required int dueDate,
      Value<int> color,
      Value<bool> isArchived,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$CreditCardsTableUpdateCompanionBuilder =
    CreditCardsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> bankName,
      Value<String> lastFourDigits,
      Value<double> creditLimit,
      Value<double> currentBalance,
      Value<int> billDate,
      Value<int> dueDate,
      Value<int> color,
      Value<bool> isArchived,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$CreditCardsTableReferences
    extends BaseReferences<_$AppDatabase, $CreditCardsTable, CreditCard> {
  $$CreditCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CreditTransactionsTable, List<CreditTransaction>>
  _creditTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.creditTransactions,
        aliasName: 'credit_cards__id__credit_transactions__card_id',
      );

  $$CreditTransactionsTableProcessedTableManager get creditTransactionsRefs {
    final manager = $$CreditTransactionsTableTableManager(
      $_db,
      $_db.creditTransactions,
    ).filter((f) => f.cardId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _creditTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CreditCardsTableFilterComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastFourDigits => $composableBuilder(
    column: $table.lastFourDigits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get billDate => $composableBuilder(
    column: $table.billDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> creditTransactionsRefs(
    Expression<bool> Function($$CreditTransactionsTableFilterComposer f) f,
  ) {
    final $$CreditTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.creditTransactions,
      getReferencedColumn: (t) => t.cardId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.creditTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CreditCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bankName => $composableBuilder(
    column: $table.bankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastFourDigits => $composableBuilder(
    column: $table.lastFourDigits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get billDate => $composableBuilder(
    column: $table.billDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CreditCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditCardsTable> {
  $$CreditCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get bankName =>
      $composableBuilder(column: $table.bankName, builder: (column) => column);

  GeneratedColumn<String> get lastFourDigits => $composableBuilder(
    column: $table.lastFourDigits,
    builder: (column) => column,
  );

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentBalance => $composableBuilder(
    column: $table.currentBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billDate =>
      $composableBuilder(column: $table.billDate, builder: (column) => column);

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> creditTransactionsRefs<T extends Object>(
    Expression<T> Function($$CreditTransactionsTableAnnotationComposer a) f,
  ) {
    final $$CreditTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.creditTransactions,
          getReferencedColumn: (t) => t.cardId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CreditTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.creditTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$CreditCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditCardsTable,
          CreditCard,
          $$CreditCardsTableFilterComposer,
          $$CreditCardsTableOrderingComposer,
          $$CreditCardsTableAnnotationComposer,
          $$CreditCardsTableCreateCompanionBuilder,
          $$CreditCardsTableUpdateCompanionBuilder,
          (CreditCard, $$CreditCardsTableReferences),
          CreditCard,
          PrefetchHooks Function({bool creditTransactionsRefs})
        > {
  $$CreditCardsTableTableManager(_$AppDatabase db, $CreditCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> bankName = const Value.absent(),
                Value<String> lastFourDigits = const Value.absent(),
                Value<double> creditLimit = const Value.absent(),
                Value<double> currentBalance = const Value.absent(),
                Value<int> billDate = const Value.absent(),
                Value<int> dueDate = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditCardsCompanion(
                id: id,
                name: name,
                bankName: bankName,
                lastFourDigits: lastFourDigits,
                creditLimit: creditLimit,
                currentBalance: currentBalance,
                billDate: billDate,
                dueDate: dueDate,
                color: color,
                isArchived: isArchived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String bankName,
                required String lastFourDigits,
                required double creditLimit,
                Value<double> currentBalance = const Value.absent(),
                required int billDate,
                required int dueDate,
                Value<int> color = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => CreditCardsCompanion.insert(
                id: id,
                name: name,
                bankName: bankName,
                lastFourDigits: lastFourDigits,
                creditLimit: creditLimit,
                currentBalance: currentBalance,
                billDate: billDate,
                dueDate: dueDate,
                color: color,
                isArchived: isArchived,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CreditCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({creditTransactionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (creditTransactionsRefs) db.creditTransactions,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (creditTransactionsRefs)
                    await $_getPrefetchedData<
                      CreditCard,
                      $CreditCardsTable,
                      CreditTransaction
                    >(
                      currentTable: table,
                      referencedTable: $$CreditCardsTableReferences
                          ._creditTransactionsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CreditCardsTableReferences(
                            db,
                            table,
                            p0,
                          ).creditTransactionsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.cardId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$CreditCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditCardsTable,
      CreditCard,
      $$CreditCardsTableFilterComposer,
      $$CreditCardsTableOrderingComposer,
      $$CreditCardsTableAnnotationComposer,
      $$CreditCardsTableCreateCompanionBuilder,
      $$CreditCardsTableUpdateCompanionBuilder,
      (CreditCard, $$CreditCardsTableReferences),
      CreditCard,
      PrefetchHooks Function({bool creditTransactionsRefs})
    >;
typedef $$CreditTransactionsTableCreateCompanionBuilder =
    CreditTransactionsCompanion Function({
      required String id,
      required String cardId,
      required double amount,
      required DateTime date,
      required String bucket,
      required String type,
      required String category,
      required String subCategory,
      required String notes,
      Value<String?> linkedBankTransactionId,
      Value<bool> includeInNextStatement,
      Value<bool> isSettlementVerified,
      Value<int> rowid,
    });
typedef $$CreditTransactionsTableUpdateCompanionBuilder =
    CreditTransactionsCompanion Function({
      Value<String> id,
      Value<String> cardId,
      Value<double> amount,
      Value<DateTime> date,
      Value<String> bucket,
      Value<String> type,
      Value<String> category,
      Value<String> subCategory,
      Value<String> notes,
      Value<String?> linkedBankTransactionId,
      Value<bool> includeInNextStatement,
      Value<bool> isSettlementVerified,
      Value<int> rowid,
    });

final class $$CreditTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CreditTransactionsTable,
          CreditTransaction
        > {
  $$CreditTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CreditCardsTable _cardIdTable(_$AppDatabase db) => db.creditCards
      .createAlias('credit_transactions__card_id__credit_cards__id');

  $$CreditCardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<String>('card_id')!;

    final manager = $$CreditCardsTableTableManager(
      $_db,
      $_db.creditCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CreditTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $CreditTransactionsTable> {
  $$CreditTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucket => $composableBuilder(
    column: $table.bucket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedBankTransactionId => $composableBuilder(
    column: $table.linkedBankTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get includeInNextStatement => $composableBuilder(
    column: $table.includeInNextStatement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettlementVerified => $composableBuilder(
    column: $table.isSettlementVerified,
    builder: (column) => ColumnFilters(column),
  );

  $$CreditCardsTableFilterComposer get cardId {
    final $$CreditCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.creditCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditCardsTableFilterComposer(
            $db: $db,
            $table: $db.creditCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CreditTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CreditTransactionsTable> {
  $$CreditTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucket => $composableBuilder(
    column: $table.bucket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedBankTransactionId => $composableBuilder(
    column: $table.linkedBankTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get includeInNextStatement => $composableBuilder(
    column: $table.includeInNextStatement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettlementVerified => $composableBuilder(
    column: $table.isSettlementVerified,
    builder: (column) => ColumnOrderings(column),
  );

  $$CreditCardsTableOrderingComposer get cardId {
    final $$CreditCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.creditCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditCardsTableOrderingComposer(
            $db: $db,
            $table: $db.creditCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CreditTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CreditTransactionsTable> {
  $$CreditTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get bucket =>
      $composableBuilder(column: $table.bucket, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get linkedBankTransactionId => $composableBuilder(
    column: $table.linkedBankTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get includeInNextStatement => $composableBuilder(
    column: $table.includeInNextStatement,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSettlementVerified => $composableBuilder(
    column: $table.isSettlementVerified,
    builder: (column) => column,
  );

  $$CreditCardsTableAnnotationComposer get cardId {
    final $$CreditCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cardId,
      referencedTable: $db.creditCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CreditCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.creditCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CreditTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CreditTransactionsTable,
          CreditTransaction,
          $$CreditTransactionsTableFilterComposer,
          $$CreditTransactionsTableOrderingComposer,
          $$CreditTransactionsTableAnnotationComposer,
          $$CreditTransactionsTableCreateCompanionBuilder,
          $$CreditTransactionsTableUpdateCompanionBuilder,
          (CreditTransaction, $$CreditTransactionsTableReferences),
          CreditTransaction,
          PrefetchHooks Function({bool cardId})
        > {
  $$CreditTransactionsTableTableManager(
    _$AppDatabase db,
    $CreditTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CreditTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CreditTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CreditTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> cardId = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> bucket = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> subCategory = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> linkedBankTransactionId = const Value.absent(),
                Value<bool> includeInNextStatement = const Value.absent(),
                Value<bool> isSettlementVerified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditTransactionsCompanion(
                id: id,
                cardId: cardId,
                amount: amount,
                date: date,
                bucket: bucket,
                type: type,
                category: category,
                subCategory: subCategory,
                notes: notes,
                linkedBankTransactionId: linkedBankTransactionId,
                includeInNextStatement: includeInNextStatement,
                isSettlementVerified: isSettlementVerified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String cardId,
                required double amount,
                required DateTime date,
                required String bucket,
                required String type,
                required String category,
                required String subCategory,
                required String notes,
                Value<String?> linkedBankTransactionId = const Value.absent(),
                Value<bool> includeInNextStatement = const Value.absent(),
                Value<bool> isSettlementVerified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CreditTransactionsCompanion.insert(
                id: id,
                cardId: cardId,
                amount: amount,
                date: date,
                bucket: bucket,
                type: type,
                category: category,
                subCategory: subCategory,
                notes: notes,
                linkedBankTransactionId: linkedBankTransactionId,
                includeInNextStatement: includeInNextStatement,
                isSettlementVerified: isSettlementVerified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CreditTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (cardId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cardId,
                                referencedTable:
                                    $$CreditTransactionsTableReferences
                                        ._cardIdTable(db),
                                referencedColumn:
                                    $$CreditTransactionsTableReferences
                                        ._cardIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$CreditTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CreditTransactionsTable,
      CreditTransaction,
      $$CreditTransactionsTableFilterComposer,
      $$CreditTransactionsTableOrderingComposer,
      $$CreditTransactionsTableAnnotationComposer,
      $$CreditTransactionsTableCreateCompanionBuilder,
      $$CreditTransactionsTableUpdateCompanionBuilder,
      (CreditTransaction, $$CreditTransactionsTableReferences),
      CreditTransaction,
      PrefetchHooks Function({bool cardId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BankAccountsTableTableManager get bankAccounts =>
      $$BankAccountsTableTableManager(_db, _db.bankAccounts);
  $$BankTransactionsTableTableManager get bankTransactions =>
      $$BankTransactionsTableTableManager(_db, _db.bankTransactions);
  $$CreditCardsTableTableManager get creditCards =>
      $$CreditCardsTableTableManager(_db, _db.creditCards);
  $$CreditTransactionsTableTableManager get creditTransactions =>
      $$CreditTransactionsTableTableManager(_db, _db.creditTransactions);
}
