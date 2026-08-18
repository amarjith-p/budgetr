// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionCategoriesTable extends TransactionCategories
    with TableInfo<$TransactionCategoriesTable, TransactionCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionCategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subCategoriesMeta = const VerificationMeta(
    'subCategories',
  );
  @override
  late final GeneratedColumn<String> subCategories = GeneratedColumn<String>(
    'sub_categories',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<int> iconCode = GeneratedColumn<int>(
    'icon_code',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    subCategories,
    iconCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transaction_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionCategory> instance, {
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('sub_categories')) {
      context.handle(
        _subCategoriesMeta,
        subCategories.isAcceptableOrUnknown(
          data['sub_categories']!,
          _subCategoriesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subCategoriesMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    } else if (isInserting) {
      context.missing(_iconCodeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      subCategories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_categories'],
      )!,
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}icon_code'],
      )!,
    );
  }

  @override
  $TransactionCategoriesTable createAlias(String alias) {
    return $TransactionCategoriesTable(attachedDatabase, alias);
  }
}

class TransactionCategory extends DataClass
    implements Insertable<TransactionCategory> {
  final String id;
  final String name;
  final String type;
  final String subCategories;
  final int iconCode;
  const TransactionCategory({
    required this.id,
    required this.name,
    required this.type,
    required this.subCategories,
    required this.iconCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['sub_categories'] = Variable<String>(subCategories);
    map['icon_code'] = Variable<int>(iconCode);
    return map;
  }

  TransactionCategoriesCompanion toCompanion(bool nullToAbsent) {
    return TransactionCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      subCategories: Value(subCategories),
      iconCode: Value(iconCode),
    );
  }

  factory TransactionCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      subCategories: serializer.fromJson<String>(json['subCategories']),
      iconCode: serializer.fromJson<int>(json['iconCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'subCategories': serializer.toJson<String>(subCategories),
      'iconCode': serializer.toJson<int>(iconCode),
    };
  }

  TransactionCategory copyWith({
    String? id,
    String? name,
    String? type,
    String? subCategories,
    int? iconCode,
  }) => TransactionCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    subCategories: subCategories ?? this.subCategories,
    iconCode: iconCode ?? this.iconCode,
  );
  TransactionCategory copyWithCompanion(TransactionCategoriesCompanion data) {
    return TransactionCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      subCategories: data.subCategories.present
          ? data.subCategories.value
          : this.subCategories,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('subCategories: $subCategories, ')
          ..write('iconCode: $iconCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, type, subCategories, iconCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.subCategories == this.subCategories &&
          other.iconCode == this.iconCode);
}

class TransactionCategoriesCompanion
    extends UpdateCompanion<TransactionCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> subCategories;
  final Value<int> iconCode;
  final Value<int> rowid;
  const TransactionCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.subCategories = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionCategoriesCompanion.insert({
    required String id,
    required String name,
    required String type,
    required String subCategories,
    required int iconCode,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       subCategories = Value(subCategories),
       iconCode = Value(iconCode);
  static Insertable<TransactionCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? subCategories,
    Expression<int>? iconCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (subCategories != null) 'sub_categories': subCategories,
      if (iconCode != null) 'icon_code': iconCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? subCategories,
    Value<int>? iconCode,
    Value<int>? rowid,
  }) {
    return TransactionCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      subCategories: subCategories ?? this.subCategories,
      iconCode: iconCode ?? this.iconCode,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (subCategories.present) {
      map['sub_categories'] = Variable<String>(subCategories.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<int>(iconCode.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('subCategories: $subCategories, ')
          ..write('iconCode: $iconCode, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetBucketsTable extends BudgetBuckets
    with TableInfo<$BudgetBucketsTable, BudgetBucket> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetBucketsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentageMeta = const VerificationMeta(
    'percentage',
  );
  @override
  late final GeneratedColumn<double> percentage = GeneratedColumn<double>(
    'percentage',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, percentage, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_buckets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetBucket> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('percentage')) {
      context.handle(
        _percentageMeta,
        percentage.isAcceptableOrUnknown(data['percentage']!, _percentageMeta),
      );
    } else if (isInserting) {
      context.missing(_percentageMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetBucket map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetBucket(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      percentage: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percentage'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $BudgetBucketsTable createAlias(String alias) {
    return $BudgetBucketsTable(attachedDatabase, alias);
  }
}

class BudgetBucket extends DataClass implements Insertable<BudgetBucket> {
  final int id;
  final String name;
  final double percentage;
  final DateTime createdAt;
  const BudgetBucket({
    required this.id,
    required this.name,
    required this.percentage,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['percentage'] = Variable<double>(percentage);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  BudgetBucketsCompanion toCompanion(bool nullToAbsent) {
    return BudgetBucketsCompanion(
      id: Value(id),
      name: Value(name),
      percentage: Value(percentage),
      createdAt: Value(createdAt),
    );
  }

  factory BudgetBucket.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetBucket(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      percentage: serializer.fromJson<double>(json['percentage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'percentage': serializer.toJson<double>(percentage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  BudgetBucket copyWith({
    int? id,
    String? name,
    double? percentage,
    DateTime? createdAt,
  }) => BudgetBucket(
    id: id ?? this.id,
    name: name ?? this.name,
    percentage: percentage ?? this.percentage,
    createdAt: createdAt ?? this.createdAt,
  );
  BudgetBucket copyWithCompanion(BudgetBucketsCompanion data) {
    return BudgetBucket(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      percentage: data.percentage.present
          ? data.percentage.value
          : this.percentage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetBucket(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('percentage: $percentage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, percentage, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetBucket &&
          other.id == this.id &&
          other.name == this.name &&
          other.percentage == this.percentage &&
          other.createdAt == this.createdAt);
}

class BudgetBucketsCompanion extends UpdateCompanion<BudgetBucket> {
  final Value<int> id;
  final Value<String> name;
  final Value<double> percentage;
  final Value<DateTime> createdAt;
  const BudgetBucketsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.percentage = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  BudgetBucketsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required double percentage,
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       percentage = Value(percentage);
  static Insertable<BudgetBucket> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<double>? percentage,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (percentage != null) 'percentage': percentage,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  BudgetBucketsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<double>? percentage,
    Value<DateTime>? createdAt,
  }) {
    return BudgetBucketsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      percentage: percentage ?? this.percentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (percentage.present) {
      map['percentage'] = Variable<double>(percentage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetBucketsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('percentage: $percentage, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _providerNameMeta = const VerificationMeta(
    'providerName',
  );
  @override
  late final GeneratedColumn<String> providerName = GeneratedColumn<String>(
    'provider_name',
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
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
    'last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _billDateMeta = const VerificationMeta(
    'billDate',
  );
  @override
  late final GeneratedColumn<int> billDate = GeneratedColumn<int>(
    'bill_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<int> dueDate = GeneratedColumn<int>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCreditPayableMeta = const VerificationMeta(
    'isCreditPayable',
  );
  @override
  late final GeneratedColumn<bool> isCreditPayable = GeneratedColumn<bool>(
    'is_credit_payable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_credit_payable" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _loanPurposeMeta = const VerificationMeta(
    'loanPurpose',
  );
  @override
  late final GeneratedColumn<String> loanPurpose = GeneratedColumn<String>(
    'loan_purpose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loanPrincipalMeta = const VerificationMeta(
    'loanPrincipal',
  );
  @override
  late final GeneratedColumn<double> loanPrincipal = GeneratedColumn<double>(
    'loan_principal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _interestRateMeta = const VerificationMeta(
    'interestRate',
  );
  @override
  late final GeneratedColumn<double> interestRate = GeneratedColumn<double>(
    'interest_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tenureMonthsMeta = const VerificationMeta(
    'tenureMonths',
  );
  @override
  late final GeneratedColumn<int> tenureMonths = GeneratedColumn<int>(
    'tenure_months',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emiDateMeta = const VerificationMeta(
    'emiDate',
  );
  @override
  late final GeneratedColumn<DateTime> emiDate = GeneratedColumn<DateTime>(
    'emi_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loanStartDateMeta = const VerificationMeta(
    'loanStartDate',
  );
  @override
  late final GeneratedColumn<DateTime> loanStartDate =
      GeneratedColumn<DateTime>(
        'loan_start_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _loanEndDateMeta = const VerificationMeta(
    'loanEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> loanEndDate = GeneratedColumn<DateTime>(
    'loan_end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalInterestPayableMeta =
      const VerificationMeta('totalInterestPayable');
  @override
  late final GeneratedColumn<double> totalInterestPayable =
      GeneratedColumn<double>(
        'total_interest_payable',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _totalTaxPayableMeta = const VerificationMeta(
    'totalTaxPayable',
  );
  @override
  late final GeneratedColumn<double> totalTaxPayable = GeneratedColumn<double>(
    'total_tax_payable',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bankChargesMeta = const VerificationMeta(
    'bankCharges',
  );
  @override
  late final GeneratedColumn<double> bankCharges = GeneratedColumn<double>(
    'bank_charges',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isHiddenMeta = const VerificationMeta(
    'isHidden',
  );
  @override
  late final GeneratedColumn<bool> isHidden = GeneratedColumn<bool>(
    'is_hidden',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_hidden" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isClosedMeta = const VerificationMeta(
    'isClosed',
  );
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
    'is_closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_closed" IN (0, 1))',
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    providerName,
    type,
    last4,
    balance,
    creditLimit,
    billDate,
    dueDate,
    isCreditPayable,
    loanPurpose,
    loanPrincipal,
    interestRate,
    tenureMonths,
    emiDate,
    loanStartDate,
    loanEndDate,
    totalInterestPayable,
    totalTaxPayable,
    bankCharges,
    isHidden,
    displayOrder,
    isClosed,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
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
    if (data.containsKey('provider_name')) {
      context.handle(
        _providerNameMeta,
        providerName.isAcceptableOrUnknown(
          data['provider_name']!,
          _providerNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerNameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
        _last4Meta,
        last4.isAcceptableOrUnknown(data['last4']!, _last4Meta),
      );
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('bill_date')) {
      context.handle(
        _billDateMeta,
        billDate.isAcceptableOrUnknown(data['bill_date']!, _billDateMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('is_credit_payable')) {
      context.handle(
        _isCreditPayableMeta,
        isCreditPayable.isAcceptableOrUnknown(
          data['is_credit_payable']!,
          _isCreditPayableMeta,
        ),
      );
    }
    if (data.containsKey('loan_purpose')) {
      context.handle(
        _loanPurposeMeta,
        loanPurpose.isAcceptableOrUnknown(
          data['loan_purpose']!,
          _loanPurposeMeta,
        ),
      );
    }
    if (data.containsKey('loan_principal')) {
      context.handle(
        _loanPrincipalMeta,
        loanPrincipal.isAcceptableOrUnknown(
          data['loan_principal']!,
          _loanPrincipalMeta,
        ),
      );
    }
    if (data.containsKey('interest_rate')) {
      context.handle(
        _interestRateMeta,
        interestRate.isAcceptableOrUnknown(
          data['interest_rate']!,
          _interestRateMeta,
        ),
      );
    }
    if (data.containsKey('tenure_months')) {
      context.handle(
        _tenureMonthsMeta,
        tenureMonths.isAcceptableOrUnknown(
          data['tenure_months']!,
          _tenureMonthsMeta,
        ),
      );
    }
    if (data.containsKey('emi_date')) {
      context.handle(
        _emiDateMeta,
        emiDate.isAcceptableOrUnknown(data['emi_date']!, _emiDateMeta),
      );
    }
    if (data.containsKey('loan_start_date')) {
      context.handle(
        _loanStartDateMeta,
        loanStartDate.isAcceptableOrUnknown(
          data['loan_start_date']!,
          _loanStartDateMeta,
        ),
      );
    }
    if (data.containsKey('loan_end_date')) {
      context.handle(
        _loanEndDateMeta,
        loanEndDate.isAcceptableOrUnknown(
          data['loan_end_date']!,
          _loanEndDateMeta,
        ),
      );
    }
    if (data.containsKey('total_interest_payable')) {
      context.handle(
        _totalInterestPayableMeta,
        totalInterestPayable.isAcceptableOrUnknown(
          data['total_interest_payable']!,
          _totalInterestPayableMeta,
        ),
      );
    }
    if (data.containsKey('total_tax_payable')) {
      context.handle(
        _totalTaxPayableMeta,
        totalTaxPayable.isAcceptableOrUnknown(
          data['total_tax_payable']!,
          _totalTaxPayableMeta,
        ),
      );
    }
    if (data.containsKey('bank_charges')) {
      context.handle(
        _bankChargesMeta,
        bankCharges.isAcceptableOrUnknown(
          data['bank_charges']!,
          _bankChargesMeta,
        ),
      );
    }
    if (data.containsKey('is_hidden')) {
      context.handle(
        _isHiddenMeta,
        isHidden.isAcceptableOrUnknown(data['is_hidden']!, _isHiddenMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('is_closed')) {
      context.handle(
        _isClosedMeta,
        isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      providerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      last4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last4'],
      ),
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}credit_limit'],
      ),
      billDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bill_date'],
      ),
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_date'],
      ),
      isCreditPayable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_credit_payable'],
      )!,
      loanPurpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}loan_purpose'],
      ),
      loanPrincipal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}loan_principal'],
      ),
      interestRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}interest_rate'],
      ),
      tenureMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tenure_months'],
      ),
      emiDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}emi_date'],
      ),
      loanStartDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}loan_start_date'],
      ),
      loanEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}loan_end_date'],
      ),
      totalInterestPayable: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_interest_payable'],
      ),
      totalTaxPayable: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_tax_payable'],
      ),
      bankCharges: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}bank_charges'],
      ),
      isHidden: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_hidden'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      ),
      isClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_closed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String name;
  final String providerName;
  final String type;
  final String? last4;
  final double balance;
  final double? creditLimit;
  final int? billDate;
  final int? dueDate;
  final bool isCreditPayable;
  final String? loanPurpose;
  final double? loanPrincipal;
  final double? interestRate;
  final int? tenureMonths;
  final DateTime? emiDate;
  final DateTime? loanStartDate;
  final DateTime? loanEndDate;
  final double? totalInterestPayable;
  final double? totalTaxPayable;
  final double? bankCharges;
  final bool isHidden;
  final int? displayOrder;
  final bool isClosed;
  final DateTime createdAt;
  const Account({
    required this.id,
    required this.name,
    required this.providerName,
    required this.type,
    this.last4,
    required this.balance,
    this.creditLimit,
    this.billDate,
    this.dueDate,
    required this.isCreditPayable,
    this.loanPurpose,
    this.loanPrincipal,
    this.interestRate,
    this.tenureMonths,
    this.emiDate,
    this.loanStartDate,
    this.loanEndDate,
    this.totalInterestPayable,
    this.totalTaxPayable,
    this.bankCharges,
    required this.isHidden,
    this.displayOrder,
    required this.isClosed,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['provider_name'] = Variable<String>(providerName);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || last4 != null) {
      map['last4'] = Variable<String>(last4);
    }
    map['balance'] = Variable<double>(balance);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<double>(creditLimit);
    }
    if (!nullToAbsent || billDate != null) {
      map['bill_date'] = Variable<int>(billDate);
    }
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<int>(dueDate);
    }
    map['is_credit_payable'] = Variable<bool>(isCreditPayable);
    if (!nullToAbsent || loanPurpose != null) {
      map['loan_purpose'] = Variable<String>(loanPurpose);
    }
    if (!nullToAbsent || loanPrincipal != null) {
      map['loan_principal'] = Variable<double>(loanPrincipal);
    }
    if (!nullToAbsent || interestRate != null) {
      map['interest_rate'] = Variable<double>(interestRate);
    }
    if (!nullToAbsent || tenureMonths != null) {
      map['tenure_months'] = Variable<int>(tenureMonths);
    }
    if (!nullToAbsent || emiDate != null) {
      map['emi_date'] = Variable<DateTime>(emiDate);
    }
    if (!nullToAbsent || loanStartDate != null) {
      map['loan_start_date'] = Variable<DateTime>(loanStartDate);
    }
    if (!nullToAbsent || loanEndDate != null) {
      map['loan_end_date'] = Variable<DateTime>(loanEndDate);
    }
    if (!nullToAbsent || totalInterestPayable != null) {
      map['total_interest_payable'] = Variable<double>(totalInterestPayable);
    }
    if (!nullToAbsent || totalTaxPayable != null) {
      map['total_tax_payable'] = Variable<double>(totalTaxPayable);
    }
    if (!nullToAbsent || bankCharges != null) {
      map['bank_charges'] = Variable<double>(bankCharges);
    }
    map['is_hidden'] = Variable<bool>(isHidden);
    if (!nullToAbsent || displayOrder != null) {
      map['display_order'] = Variable<int>(displayOrder);
    }
    map['is_closed'] = Variable<bool>(isClosed);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      providerName: Value(providerName),
      type: Value(type),
      last4: last4 == null && nullToAbsent
          ? const Value.absent()
          : Value(last4),
      balance: Value(balance),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      billDate: billDate == null && nullToAbsent
          ? const Value.absent()
          : Value(billDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isCreditPayable: Value(isCreditPayable),
      loanPurpose: loanPurpose == null && nullToAbsent
          ? const Value.absent()
          : Value(loanPurpose),
      loanPrincipal: loanPrincipal == null && nullToAbsent
          ? const Value.absent()
          : Value(loanPrincipal),
      interestRate: interestRate == null && nullToAbsent
          ? const Value.absent()
          : Value(interestRate),
      tenureMonths: tenureMonths == null && nullToAbsent
          ? const Value.absent()
          : Value(tenureMonths),
      emiDate: emiDate == null && nullToAbsent
          ? const Value.absent()
          : Value(emiDate),
      loanStartDate: loanStartDate == null && nullToAbsent
          ? const Value.absent()
          : Value(loanStartDate),
      loanEndDate: loanEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(loanEndDate),
      totalInterestPayable: totalInterestPayable == null && nullToAbsent
          ? const Value.absent()
          : Value(totalInterestPayable),
      totalTaxPayable: totalTaxPayable == null && nullToAbsent
          ? const Value.absent()
          : Value(totalTaxPayable),
      bankCharges: bankCharges == null && nullToAbsent
          ? const Value.absent()
          : Value(bankCharges),
      isHidden: Value(isHidden),
      displayOrder: displayOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(displayOrder),
      isClosed: Value(isClosed),
      createdAt: Value(createdAt),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      providerName: serializer.fromJson<String>(json['providerName']),
      type: serializer.fromJson<String>(json['type']),
      last4: serializer.fromJson<String?>(json['last4']),
      balance: serializer.fromJson<double>(json['balance']),
      creditLimit: serializer.fromJson<double?>(json['creditLimit']),
      billDate: serializer.fromJson<int?>(json['billDate']),
      dueDate: serializer.fromJson<int?>(json['dueDate']),
      isCreditPayable: serializer.fromJson<bool>(json['isCreditPayable']),
      loanPurpose: serializer.fromJson<String?>(json['loanPurpose']),
      loanPrincipal: serializer.fromJson<double?>(json['loanPrincipal']),
      interestRate: serializer.fromJson<double?>(json['interestRate']),
      tenureMonths: serializer.fromJson<int?>(json['tenureMonths']),
      emiDate: serializer.fromJson<DateTime?>(json['emiDate']),
      loanStartDate: serializer.fromJson<DateTime?>(json['loanStartDate']),
      loanEndDate: serializer.fromJson<DateTime?>(json['loanEndDate']),
      totalInterestPayable: serializer.fromJson<double?>(
        json['totalInterestPayable'],
      ),
      totalTaxPayable: serializer.fromJson<double?>(json['totalTaxPayable']),
      bankCharges: serializer.fromJson<double?>(json['bankCharges']),
      isHidden: serializer.fromJson<bool>(json['isHidden']),
      displayOrder: serializer.fromJson<int?>(json['displayOrder']),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'providerName': serializer.toJson<String>(providerName),
      'type': serializer.toJson<String>(type),
      'last4': serializer.toJson<String?>(last4),
      'balance': serializer.toJson<double>(balance),
      'creditLimit': serializer.toJson<double?>(creditLimit),
      'billDate': serializer.toJson<int?>(billDate),
      'dueDate': serializer.toJson<int?>(dueDate),
      'isCreditPayable': serializer.toJson<bool>(isCreditPayable),
      'loanPurpose': serializer.toJson<String?>(loanPurpose),
      'loanPrincipal': serializer.toJson<double?>(loanPrincipal),
      'interestRate': serializer.toJson<double?>(interestRate),
      'tenureMonths': serializer.toJson<int?>(tenureMonths),
      'emiDate': serializer.toJson<DateTime?>(emiDate),
      'loanStartDate': serializer.toJson<DateTime?>(loanStartDate),
      'loanEndDate': serializer.toJson<DateTime?>(loanEndDate),
      'totalInterestPayable': serializer.toJson<double?>(totalInterestPayable),
      'totalTaxPayable': serializer.toJson<double?>(totalTaxPayable),
      'bankCharges': serializer.toJson<double?>(bankCharges),
      'isHidden': serializer.toJson<bool>(isHidden),
      'displayOrder': serializer.toJson<int?>(displayOrder),
      'isClosed': serializer.toJson<bool>(isClosed),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Account copyWith({
    String? id,
    String? name,
    String? providerName,
    String? type,
    Value<String?> last4 = const Value.absent(),
    double? balance,
    Value<double?> creditLimit = const Value.absent(),
    Value<int?> billDate = const Value.absent(),
    Value<int?> dueDate = const Value.absent(),
    bool? isCreditPayable,
    Value<String?> loanPurpose = const Value.absent(),
    Value<double?> loanPrincipal = const Value.absent(),
    Value<double?> interestRate = const Value.absent(),
    Value<int?> tenureMonths = const Value.absent(),
    Value<DateTime?> emiDate = const Value.absent(),
    Value<DateTime?> loanStartDate = const Value.absent(),
    Value<DateTime?> loanEndDate = const Value.absent(),
    Value<double?> totalInterestPayable = const Value.absent(),
    Value<double?> totalTaxPayable = const Value.absent(),
    Value<double?> bankCharges = const Value.absent(),
    bool? isHidden,
    Value<int?> displayOrder = const Value.absent(),
    bool? isClosed,
    DateTime? createdAt,
  }) => Account(
    id: id ?? this.id,
    name: name ?? this.name,
    providerName: providerName ?? this.providerName,
    type: type ?? this.type,
    last4: last4.present ? last4.value : this.last4,
    balance: balance ?? this.balance,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    billDate: billDate.present ? billDate.value : this.billDate,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isCreditPayable: isCreditPayable ?? this.isCreditPayable,
    loanPurpose: loanPurpose.present ? loanPurpose.value : this.loanPurpose,
    loanPrincipal: loanPrincipal.present
        ? loanPrincipal.value
        : this.loanPrincipal,
    interestRate: interestRate.present ? interestRate.value : this.interestRate,
    tenureMonths: tenureMonths.present ? tenureMonths.value : this.tenureMonths,
    emiDate: emiDate.present ? emiDate.value : this.emiDate,
    loanStartDate: loanStartDate.present
        ? loanStartDate.value
        : this.loanStartDate,
    loanEndDate: loanEndDate.present ? loanEndDate.value : this.loanEndDate,
    totalInterestPayable: totalInterestPayable.present
        ? totalInterestPayable.value
        : this.totalInterestPayable,
    totalTaxPayable: totalTaxPayable.present
        ? totalTaxPayable.value
        : this.totalTaxPayable,
    bankCharges: bankCharges.present ? bankCharges.value : this.bankCharges,
    isHidden: isHidden ?? this.isHidden,
    displayOrder: displayOrder.present ? displayOrder.value : this.displayOrder,
    isClosed: isClosed ?? this.isClosed,
    createdAt: createdAt ?? this.createdAt,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      providerName: data.providerName.present
          ? data.providerName.value
          : this.providerName,
      type: data.type.present ? data.type.value : this.type,
      last4: data.last4.present ? data.last4.value : this.last4,
      balance: data.balance.present ? data.balance.value : this.balance,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      billDate: data.billDate.present ? data.billDate.value : this.billDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isCreditPayable: data.isCreditPayable.present
          ? data.isCreditPayable.value
          : this.isCreditPayable,
      loanPurpose: data.loanPurpose.present
          ? data.loanPurpose.value
          : this.loanPurpose,
      loanPrincipal: data.loanPrincipal.present
          ? data.loanPrincipal.value
          : this.loanPrincipal,
      interestRate: data.interestRate.present
          ? data.interestRate.value
          : this.interestRate,
      tenureMonths: data.tenureMonths.present
          ? data.tenureMonths.value
          : this.tenureMonths,
      emiDate: data.emiDate.present ? data.emiDate.value : this.emiDate,
      loanStartDate: data.loanStartDate.present
          ? data.loanStartDate.value
          : this.loanStartDate,
      loanEndDate: data.loanEndDate.present
          ? data.loanEndDate.value
          : this.loanEndDate,
      totalInterestPayable: data.totalInterestPayable.present
          ? data.totalInterestPayable.value
          : this.totalInterestPayable,
      totalTaxPayable: data.totalTaxPayable.present
          ? data.totalTaxPayable.value
          : this.totalTaxPayable,
      bankCharges: data.bankCharges.present
          ? data.bankCharges.value
          : this.bankCharges,
      isHidden: data.isHidden.present ? data.isHidden.value : this.isHidden,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('providerName: $providerName, ')
          ..write('type: $type, ')
          ..write('last4: $last4, ')
          ..write('balance: $balance, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('billDate: $billDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('isCreditPayable: $isCreditPayable, ')
          ..write('loanPurpose: $loanPurpose, ')
          ..write('loanPrincipal: $loanPrincipal, ')
          ..write('interestRate: $interestRate, ')
          ..write('tenureMonths: $tenureMonths, ')
          ..write('emiDate: $emiDate, ')
          ..write('loanStartDate: $loanStartDate, ')
          ..write('loanEndDate: $loanEndDate, ')
          ..write('totalInterestPayable: $totalInterestPayable, ')
          ..write('totalTaxPayable: $totalTaxPayable, ')
          ..write('bankCharges: $bankCharges, ')
          ..write('isHidden: $isHidden, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('isClosed: $isClosed, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    providerName,
    type,
    last4,
    balance,
    creditLimit,
    billDate,
    dueDate,
    isCreditPayable,
    loanPurpose,
    loanPrincipal,
    interestRate,
    tenureMonths,
    emiDate,
    loanStartDate,
    loanEndDate,
    totalInterestPayable,
    totalTaxPayable,
    bankCharges,
    isHidden,
    displayOrder,
    isClosed,
    createdAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.name == this.name &&
          other.providerName == this.providerName &&
          other.type == this.type &&
          other.last4 == this.last4 &&
          other.balance == this.balance &&
          other.creditLimit == this.creditLimit &&
          other.billDate == this.billDate &&
          other.dueDate == this.dueDate &&
          other.isCreditPayable == this.isCreditPayable &&
          other.loanPurpose == this.loanPurpose &&
          other.loanPrincipal == this.loanPrincipal &&
          other.interestRate == this.interestRate &&
          other.tenureMonths == this.tenureMonths &&
          other.emiDate == this.emiDate &&
          other.loanStartDate == this.loanStartDate &&
          other.loanEndDate == this.loanEndDate &&
          other.totalInterestPayable == this.totalInterestPayable &&
          other.totalTaxPayable == this.totalTaxPayable &&
          other.bankCharges == this.bankCharges &&
          other.isHidden == this.isHidden &&
          other.displayOrder == this.displayOrder &&
          other.isClosed == this.isClosed &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> providerName;
  final Value<String> type;
  final Value<String?> last4;
  final Value<double> balance;
  final Value<double?> creditLimit;
  final Value<int?> billDate;
  final Value<int?> dueDate;
  final Value<bool> isCreditPayable;
  final Value<String?> loanPurpose;
  final Value<double?> loanPrincipal;
  final Value<double?> interestRate;
  final Value<int?> tenureMonths;
  final Value<DateTime?> emiDate;
  final Value<DateTime?> loanStartDate;
  final Value<DateTime?> loanEndDate;
  final Value<double?> totalInterestPayable;
  final Value<double?> totalTaxPayable;
  final Value<double?> bankCharges;
  final Value<bool> isHidden;
  final Value<int?> displayOrder;
  final Value<bool> isClosed;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.providerName = const Value.absent(),
    this.type = const Value.absent(),
    this.last4 = const Value.absent(),
    this.balance = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.billDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isCreditPayable = const Value.absent(),
    this.loanPurpose = const Value.absent(),
    this.loanPrincipal = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.tenureMonths = const Value.absent(),
    this.emiDate = const Value.absent(),
    this.loanStartDate = const Value.absent(),
    this.loanEndDate = const Value.absent(),
    this.totalInterestPayable = const Value.absent(),
    this.totalTaxPayable = const Value.absent(),
    this.bankCharges = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String name,
    required String providerName,
    required String type,
    this.last4 = const Value.absent(),
    required double balance,
    this.creditLimit = const Value.absent(),
    this.billDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isCreditPayable = const Value.absent(),
    this.loanPurpose = const Value.absent(),
    this.loanPrincipal = const Value.absent(),
    this.interestRate = const Value.absent(),
    this.tenureMonths = const Value.absent(),
    this.emiDate = const Value.absent(),
    this.loanStartDate = const Value.absent(),
    this.loanEndDate = const Value.absent(),
    this.totalInterestPayable = const Value.absent(),
    this.totalTaxPayable = const Value.absent(),
    this.bankCharges = const Value.absent(),
    this.isHidden = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       providerName = Value(providerName),
       type = Value(type),
       balance = Value(balance);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? providerName,
    Expression<String>? type,
    Expression<String>? last4,
    Expression<double>? balance,
    Expression<double>? creditLimit,
    Expression<int>? billDate,
    Expression<int>? dueDate,
    Expression<bool>? isCreditPayable,
    Expression<String>? loanPurpose,
    Expression<double>? loanPrincipal,
    Expression<double>? interestRate,
    Expression<int>? tenureMonths,
    Expression<DateTime>? emiDate,
    Expression<DateTime>? loanStartDate,
    Expression<DateTime>? loanEndDate,
    Expression<double>? totalInterestPayable,
    Expression<double>? totalTaxPayable,
    Expression<double>? bankCharges,
    Expression<bool>? isHidden,
    Expression<int>? displayOrder,
    Expression<bool>? isClosed,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (providerName != null) 'provider_name': providerName,
      if (type != null) 'type': type,
      if (last4 != null) 'last4': last4,
      if (balance != null) 'balance': balance,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (billDate != null) 'bill_date': billDate,
      if (dueDate != null) 'due_date': dueDate,
      if (isCreditPayable != null) 'is_credit_payable': isCreditPayable,
      if (loanPurpose != null) 'loan_purpose': loanPurpose,
      if (loanPrincipal != null) 'loan_principal': loanPrincipal,
      if (interestRate != null) 'interest_rate': interestRate,
      if (tenureMonths != null) 'tenure_months': tenureMonths,
      if (emiDate != null) 'emi_date': emiDate,
      if (loanStartDate != null) 'loan_start_date': loanStartDate,
      if (loanEndDate != null) 'loan_end_date': loanEndDate,
      if (totalInterestPayable != null)
        'total_interest_payable': totalInterestPayable,
      if (totalTaxPayable != null) 'total_tax_payable': totalTaxPayable,
      if (bankCharges != null) 'bank_charges': bankCharges,
      if (isHidden != null) 'is_hidden': isHidden,
      if (displayOrder != null) 'display_order': displayOrder,
      if (isClosed != null) 'is_closed': isClosed,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? providerName,
    Value<String>? type,
    Value<String?>? last4,
    Value<double>? balance,
    Value<double?>? creditLimit,
    Value<int?>? billDate,
    Value<int?>? dueDate,
    Value<bool>? isCreditPayable,
    Value<String?>? loanPurpose,
    Value<double?>? loanPrincipal,
    Value<double?>? interestRate,
    Value<int?>? tenureMonths,
    Value<DateTime?>? emiDate,
    Value<DateTime?>? loanStartDate,
    Value<DateTime?>? loanEndDate,
    Value<double?>? totalInterestPayable,
    Value<double?>? totalTaxPayable,
    Value<double?>? bankCharges,
    Value<bool>? isHidden,
    Value<int?>? displayOrder,
    Value<bool>? isClosed,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      providerName: providerName ?? this.providerName,
      type: type ?? this.type,
      last4: last4 ?? this.last4,
      balance: balance ?? this.balance,
      creditLimit: creditLimit ?? this.creditLimit,
      billDate: billDate ?? this.billDate,
      dueDate: dueDate ?? this.dueDate,
      isCreditPayable: isCreditPayable ?? this.isCreditPayable,
      loanPurpose: loanPurpose ?? this.loanPurpose,
      loanPrincipal: loanPrincipal ?? this.loanPrincipal,
      interestRate: interestRate ?? this.interestRate,
      tenureMonths: tenureMonths ?? this.tenureMonths,
      emiDate: emiDate ?? this.emiDate,
      loanStartDate: loanStartDate ?? this.loanStartDate,
      loanEndDate: loanEndDate ?? this.loanEndDate,
      totalInterestPayable: totalInterestPayable ?? this.totalInterestPayable,
      totalTaxPayable: totalTaxPayable ?? this.totalTaxPayable,
      bankCharges: bankCharges ?? this.bankCharges,
      isHidden: isHidden ?? this.isHidden,
      displayOrder: displayOrder ?? this.displayOrder,
      isClosed: isClosed ?? this.isClosed,
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
    if (providerName.present) {
      map['provider_name'] = Variable<String>(providerName.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (billDate.present) {
      map['bill_date'] = Variable<int>(billDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<int>(dueDate.value);
    }
    if (isCreditPayable.present) {
      map['is_credit_payable'] = Variable<bool>(isCreditPayable.value);
    }
    if (loanPurpose.present) {
      map['loan_purpose'] = Variable<String>(loanPurpose.value);
    }
    if (loanPrincipal.present) {
      map['loan_principal'] = Variable<double>(loanPrincipal.value);
    }
    if (interestRate.present) {
      map['interest_rate'] = Variable<double>(interestRate.value);
    }
    if (tenureMonths.present) {
      map['tenure_months'] = Variable<int>(tenureMonths.value);
    }
    if (emiDate.present) {
      map['emi_date'] = Variable<DateTime>(emiDate.value);
    }
    if (loanStartDate.present) {
      map['loan_start_date'] = Variable<DateTime>(loanStartDate.value);
    }
    if (loanEndDate.present) {
      map['loan_end_date'] = Variable<DateTime>(loanEndDate.value);
    }
    if (totalInterestPayable.present) {
      map['total_interest_payable'] = Variable<double>(
        totalInterestPayable.value,
      );
    }
    if (totalTaxPayable.present) {
      map['total_tax_payable'] = Variable<double>(totalTaxPayable.value);
    }
    if (bankCharges.present) {
      map['bank_charges'] = Variable<double>(bankCharges.value);
    }
    if (isHidden.present) {
      map['is_hidden'] = Variable<bool>(isHidden.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
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
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('providerName: $providerName, ')
          ..write('type: $type, ')
          ..write('last4: $last4, ')
          ..write('balance: $balance, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('billDate: $billDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('isCreditPayable: $isCreditPayable, ')
          ..write('loanPurpose: $loanPurpose, ')
          ..write('loanPrincipal: $loanPrincipal, ')
          ..write('interestRate: $interestRate, ')
          ..write('tenureMonths: $tenureMonths, ')
          ..write('emiDate: $emiDate, ')
          ..write('loanStartDate: $loanStartDate, ')
          ..write('loanEndDate: $loanEndDate, ')
          ..write('totalInterestPayable: $totalInterestPayable, ')
          ..write('totalTaxPayable: $totalTaxPayable, ')
          ..write('bankCharges: $bankCharges, ')
          ..write('isHidden: $isHidden, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('isClosed: $isClosed, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIconMeta = const VerificationMeta(
    'categoryIcon',
  );
  @override
  late final GeneratedColumn<int> categoryIcon = GeneratedColumn<int>(
    'category_icon',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subCategoryMeta = const VerificationMeta(
    'subCategory',
  );
  @override
  late final GeneratedColumn<String> subCategory = GeneratedColumn<String>(
    'sub_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bucketIdMeta = const VerificationMeta(
    'bucketId',
  );
  @override
  late final GeneratedColumn<int> bucketId = GeneratedColumn<int>(
    'bucket_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bucketNameMeta = const VerificationMeta(
    'bucketName',
  );
  @override
  late final GeneratedColumn<String> bucketName = GeneratedColumn<String>(
    'bucket_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSpilloverMeta = const VerificationMeta(
    'isSpillover',
  );
  @override
  late final GeneratedColumn<bool> isSpillover = GeneratedColumn<bool>(
    'is_spillover',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_spillover" IN (0, 1))',
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
  static const VerificationMeta _locationNameMeta = const VerificationMeta(
    'locationName',
  );
  @override
  late final GeneratedColumn<String> locationName = GeneratedColumn<String>(
    'location_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    amount,
    date,
    accountId,
    toAccountId,
    categoryId,
    categoryName,
    categoryIcon,
    subCategory,
    bucketId,
    bucketName,
    notes,
    isSpillover,
    isSettlementVerified,
    locationName,
    latitude,
    longitude,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TransactionRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
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
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('category_icon')) {
      context.handle(
        _categoryIconMeta,
        categoryIcon.isAcceptableOrUnknown(
          data['category_icon']!,
          _categoryIconMeta,
        ),
      );
    }
    if (data.containsKey('sub_category')) {
      context.handle(
        _subCategoryMeta,
        subCategory.isAcceptableOrUnknown(
          data['sub_category']!,
          _subCategoryMeta,
        ),
      );
    }
    if (data.containsKey('bucket_id')) {
      context.handle(
        _bucketIdMeta,
        bucketId.isAcceptableOrUnknown(data['bucket_id']!, _bucketIdMeta),
      );
    }
    if (data.containsKey('bucket_name')) {
      context.handle(
        _bucketNameMeta,
        bucketName.isAcceptableOrUnknown(data['bucket_name']!, _bucketNameMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_spillover')) {
      context.handle(
        _isSpilloverMeta,
        isSpillover.isAcceptableOrUnknown(
          data['is_spillover']!,
          _isSpilloverMeta,
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
    if (data.containsKey('location_name')) {
      context.handle(
        _locationNameMeta,
        locationName.isAcceptableOrUnknown(
          data['location_name']!,
          _locationNameMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      categoryIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_icon'],
      ),
      subCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category'],
      ),
      bucketId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bucket_id'],
      ),
      bucketName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket_name'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isSpillover: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_spillover'],
      )!,
      isSettlementVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settlement_verified'],
      )!,
      locationName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location_name'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TransactionRecord extends DataClass
    implements Insertable<TransactionRecord> {
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final String? categoryName;
  final int? categoryIcon;
  final String? subCategory;
  final int? bucketId;
  final String? bucketName;
  final String? notes;
  final bool isSpillover;
  final bool isSettlementVerified;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  const TransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.subCategory,
    this.bucketId,
    this.bucketName,
    this.notes,
    required this.isSpillover,
    required this.isSettlementVerified,
    this.locationName,
    this.latitude,
    this.longitude,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || categoryIcon != null) {
      map['category_icon'] = Variable<int>(categoryIcon);
    }
    if (!nullToAbsent || subCategory != null) {
      map['sub_category'] = Variable<String>(subCategory);
    }
    if (!nullToAbsent || bucketId != null) {
      map['bucket_id'] = Variable<int>(bucketId);
    }
    if (!nullToAbsent || bucketName != null) {
      map['bucket_name'] = Variable<String>(bucketName);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_spillover'] = Variable<bool>(isSpillover);
    map['is_settlement_verified'] = Variable<bool>(isSettlementVerified);
    if (!nullToAbsent || locationName != null) {
      map['location_name'] = Variable<String>(locationName);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      type: Value(type),
      amount: Value(amount),
      date: Value(date),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      categoryIcon: categoryIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryIcon),
      subCategory: subCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subCategory),
      bucketId: bucketId == null && nullToAbsent
          ? const Value.absent()
          : Value(bucketId),
      bucketName: bucketName == null && nullToAbsent
          ? const Value.absent()
          : Value(bucketName),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isSpillover: Value(isSpillover),
      isSettlementVerified: Value(isSettlementVerified),
      locationName: locationName == null && nullToAbsent
          ? const Value.absent()
          : Value(locationName),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
    );
  }

  factory TransactionRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRecord(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      accountId: serializer.fromJson<String>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      categoryIcon: serializer.fromJson<int?>(json['categoryIcon']),
      subCategory: serializer.fromJson<String?>(json['subCategory']),
      bucketId: serializer.fromJson<int?>(json['bucketId']),
      bucketName: serializer.fromJson<String?>(json['bucketName']),
      notes: serializer.fromJson<String?>(json['notes']),
      isSpillover: serializer.fromJson<bool>(json['isSpillover']),
      isSettlementVerified: serializer.fromJson<bool>(
        json['isSettlementVerified'],
      ),
      locationName: serializer.fromJson<String?>(json['locationName']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'accountId': serializer.toJson<String>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'categoryIcon': serializer.toJson<int?>(categoryIcon),
      'subCategory': serializer.toJson<String?>(subCategory),
      'bucketId': serializer.toJson<int?>(bucketId),
      'bucketName': serializer.toJson<String?>(bucketName),
      'notes': serializer.toJson<String?>(notes),
      'isSpillover': serializer.toJson<bool>(isSpillover),
      'isSettlementVerified': serializer.toJson<bool>(isSettlementVerified),
      'locationName': serializer.toJson<String?>(locationName),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
    };
  }

  TransactionRecord copyWith({
    String? id,
    String? type,
    double? amount,
    DateTime? date,
    String? accountId,
    Value<String?> toAccountId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> categoryName = const Value.absent(),
    Value<int?> categoryIcon = const Value.absent(),
    Value<String?> subCategory = const Value.absent(),
    Value<int?> bucketId = const Value.absent(),
    Value<String?> bucketName = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isSpillover,
    bool? isSettlementVerified,
    Value<String?> locationName = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
  }) => TransactionRecord(
    id: id ?? this.id,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    categoryIcon: categoryIcon.present ? categoryIcon.value : this.categoryIcon,
    subCategory: subCategory.present ? subCategory.value : this.subCategory,
    bucketId: bucketId.present ? bucketId.value : this.bucketId,
    bucketName: bucketName.present ? bucketName.value : this.bucketName,
    notes: notes.present ? notes.value : this.notes,
    isSpillover: isSpillover ?? this.isSpillover,
    isSettlementVerified: isSettlementVerified ?? this.isSettlementVerified,
    locationName: locationName.present ? locationName.value : this.locationName,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
  );
  TransactionRecord copyWithCompanion(TransactionsCompanion data) {
    return TransactionRecord(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryIcon: data.categoryIcon.present
          ? data.categoryIcon.value
          : this.categoryIcon,
      subCategory: data.subCategory.present
          ? data.subCategory.value
          : this.subCategory,
      bucketId: data.bucketId.present ? data.bucketId.value : this.bucketId,
      bucketName: data.bucketName.present
          ? data.bucketName.value
          : this.bucketName,
      notes: data.notes.present ? data.notes.value : this.notes,
      isSpillover: data.isSpillover.present
          ? data.isSpillover.value
          : this.isSpillover,
      isSettlementVerified: data.isSettlementVerified.present
          ? data.isSettlementVerified.value
          : this.isSettlementVerified,
      locationName: data.locationName.present
          ? data.locationName.value
          : this.locationName,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRecord(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('subCategory: $subCategory, ')
          ..write('bucketId: $bucketId, ')
          ..write('bucketName: $bucketName, ')
          ..write('notes: $notes, ')
          ..write('isSpillover: $isSpillover, ')
          ..write('isSettlementVerified: $isSettlementVerified, ')
          ..write('locationName: $locationName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    amount,
    date,
    accountId,
    toAccountId,
    categoryId,
    categoryName,
    categoryIcon,
    subCategory,
    bucketId,
    bucketName,
    notes,
    isSpillover,
    isSettlementVerified,
    locationName,
    latitude,
    longitude,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRecord &&
          other.id == this.id &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.categoryIcon == this.categoryIcon &&
          other.subCategory == this.subCategory &&
          other.bucketId == this.bucketId &&
          other.bucketName == this.bucketName &&
          other.notes == this.notes &&
          other.isSpillover == this.isSpillover &&
          other.isSettlementVerified == this.isSettlementVerified &&
          other.locationName == this.locationName &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRecord> {
  final Value<String> id;
  final Value<String> type;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String> accountId;
  final Value<String?> toAccountId;
  final Value<String?> categoryId;
  final Value<String?> categoryName;
  final Value<int?> categoryIcon;
  final Value<String?> subCategory;
  final Value<int?> bucketId;
  final Value<String?> bucketName;
  final Value<String?> notes;
  final Value<bool> isSpillover;
  final Value<bool> isSettlementVerified;
  final Value<String?> locationName;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.bucketId = const Value.absent(),
    this.bucketName = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSpillover = const Value.absent(),
    this.isSettlementVerified = const Value.absent(),
    this.locationName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    required String id,
    required String type,
    required double amount,
    required DateTime date,
    required String accountId,
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.bucketId = const Value.absent(),
    this.bucketName = const Value.absent(),
    this.notes = const Value.absent(),
    this.isSpillover = const Value.absent(),
    this.isSettlementVerified = const Value.absent(),
    this.locationName = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       amount = Value(amount),
       date = Value(date),
       accountId = Value(accountId);
  static Insertable<TransactionRecord> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<int>? categoryIcon,
    Expression<String>? subCategory,
    Expression<int>? bucketId,
    Expression<String>? bucketName,
    Expression<String>? notes,
    Expression<bool>? isSpillover,
    Expression<bool>? isSettlementVerified,
    Expression<String>? locationName,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryIcon != null) 'category_icon': categoryIcon,
      if (subCategory != null) 'sub_category': subCategory,
      if (bucketId != null) 'bucket_id': bucketId,
      if (bucketName != null) 'bucket_name': bucketName,
      if (notes != null) 'notes': notes,
      if (isSpillover != null) 'is_spillover': isSpillover,
      if (isSettlementVerified != null)
        'is_settlement_verified': isSettlementVerified,
      if (locationName != null) 'location_name': locationName,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<double>? amount,
    Value<DateTime>? date,
    Value<String>? accountId,
    Value<String?>? toAccountId,
    Value<String?>? categoryId,
    Value<String?>? categoryName,
    Value<int?>? categoryIcon,
    Value<String?>? subCategory,
    Value<int?>? bucketId,
    Value<String?>? bucketName,
    Value<String?>? notes,
    Value<bool>? isSpillover,
    Value<bool>? isSettlementVerified,
    Value<String?>? locationName,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      subCategory: subCategory ?? this.subCategory,
      bucketId: bucketId ?? this.bucketId,
      bucketName: bucketName ?? this.bucketName,
      notes: notes ?? this.notes,
      isSpillover: isSpillover ?? this.isSpillover,
      isSettlementVerified: isSettlementVerified ?? this.isSettlementVerified,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryIcon.present) {
      map['category_icon'] = Variable<int>(categoryIcon.value);
    }
    if (subCategory.present) {
      map['sub_category'] = Variable<String>(subCategory.value);
    }
    if (bucketId.present) {
      map['bucket_id'] = Variable<int>(bucketId.value);
    }
    if (bucketName.present) {
      map['bucket_name'] = Variable<String>(bucketName.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isSpillover.present) {
      map['is_spillover'] = Variable<bool>(isSpillover.value);
    }
    if (isSettlementVerified.present) {
      map['is_settlement_verified'] = Variable<bool>(
        isSettlementVerified.value,
      );
    }
    if (locationName.present) {
      map['location_name'] = Variable<String>(locationName.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('subCategory: $subCategory, ')
          ..write('bucketId: $bucketId, ')
          ..write('bucketName: $bucketName, ')
          ..write('notes: $notes, ')
          ..write('isSpillover: $isSpillover, ')
          ..write('isSettlementVerified: $isSettlementVerified, ')
          ..write('locationName: $locationName, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthlyBudgetsTable extends MonthlyBudgets
    with TableInfo<$MonthlyBudgetsTable, MonthlyBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthlyBudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salaryIncomeMeta = const VerificationMeta(
    'salaryIncome',
  );
  @override
  late final GeneratedColumn<double> salaryIncome = GeneratedColumn<double>(
    'salary_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _extraIncomeMeta = const VerificationMeta(
    'extraIncome',
  );
  @override
  late final GeneratedColumn<double> extraIncome = GeneratedColumn<double>(
    'extra_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _deductionsMeta = const VerificationMeta(
    'deductions',
  );
  @override
  late final GeneratedColumn<double> deductions = GeneratedColumn<double>(
    'deductions',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _bucketsSnapshotMeta = const VerificationMeta(
    'bucketsSnapshot',
  );
  @override
  late final GeneratedColumn<String> bucketsSnapshot = GeneratedColumn<String>(
    'buckets_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isClosedMeta = const VerificationMeta(
    'isClosed',
  );
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
    'is_closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _closedTotalSpentMeta = const VerificationMeta(
    'closedTotalSpent',
  );
  @override
  late final GeneratedColumn<double> closedTotalSpent = GeneratedColumn<double>(
    'closed_total_spent',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _closedOutOfBucketMeta = const VerificationMeta(
    'closedOutOfBucket',
  );
  @override
  late final GeneratedColumn<double> closedOutOfBucket =
      GeneratedColumn<double>(
        'closed_out_of_bucket',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _closedRemainingMeta = const VerificationMeta(
    'closedRemaining',
  );
  @override
  late final GeneratedColumn<double> closedRemaining = GeneratedColumn<double>(
    'closed_remaining',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    month,
    year,
    salaryIncome,
    extraIncome,
    deductions,
    bucketsSnapshot,
    isClosed,
    closedTotalSpent,
    closedOutOfBucket,
    closedRemaining,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'monthly_budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthlyBudget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('salary_income')) {
      context.handle(
        _salaryIncomeMeta,
        salaryIncome.isAcceptableOrUnknown(
          data['salary_income']!,
          _salaryIncomeMeta,
        ),
      );
    }
    if (data.containsKey('extra_income')) {
      context.handle(
        _extraIncomeMeta,
        extraIncome.isAcceptableOrUnknown(
          data['extra_income']!,
          _extraIncomeMeta,
        ),
      );
    }
    if (data.containsKey('deductions')) {
      context.handle(
        _deductionsMeta,
        deductions.isAcceptableOrUnknown(data['deductions']!, _deductionsMeta),
      );
    }
    if (data.containsKey('buckets_snapshot')) {
      context.handle(
        _bucketsSnapshotMeta,
        bucketsSnapshot.isAcceptableOrUnknown(
          data['buckets_snapshot']!,
          _bucketsSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('is_closed')) {
      context.handle(
        _isClosedMeta,
        isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta),
      );
    }
    if (data.containsKey('closed_total_spent')) {
      context.handle(
        _closedTotalSpentMeta,
        closedTotalSpent.isAcceptableOrUnknown(
          data['closed_total_spent']!,
          _closedTotalSpentMeta,
        ),
      );
    }
    if (data.containsKey('closed_out_of_bucket')) {
      context.handle(
        _closedOutOfBucketMeta,
        closedOutOfBucket.isAcceptableOrUnknown(
          data['closed_out_of_bucket']!,
          _closedOutOfBucketMeta,
        ),
      );
    }
    if (data.containsKey('closed_remaining')) {
      context.handle(
        _closedRemainingMeta,
        closedRemaining.isAcceptableOrUnknown(
          data['closed_remaining']!,
          _closedRemainingMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonthlyBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthlyBudget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      salaryIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salary_income'],
      )!,
      extraIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}extra_income'],
      )!,
      deductions: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deductions'],
      )!,
      bucketsSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}buckets_snapshot'],
      ),
      isClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_closed'],
      )!,
      closedTotalSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}closed_total_spent'],
      ),
      closedOutOfBucket: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}closed_out_of_bucket'],
      ),
      closedRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}closed_remaining'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MonthlyBudgetsTable createAlias(String alias) {
    return $MonthlyBudgetsTable(attachedDatabase, alias);
  }
}

class MonthlyBudget extends DataClass implements Insertable<MonthlyBudget> {
  final String id;
  final int month;
  final int year;
  final double salaryIncome;
  final double extraIncome;
  final double deductions;
  final String? bucketsSnapshot;
  final bool isClosed;
  final double? closedTotalSpent;
  final double? closedOutOfBucket;
  final double? closedRemaining;
  final DateTime createdAt;
  const MonthlyBudget({
    required this.id,
    required this.month,
    required this.year,
    required this.salaryIncome,
    required this.extraIncome,
    required this.deductions,
    this.bucketsSnapshot,
    required this.isClosed,
    this.closedTotalSpent,
    this.closedOutOfBucket,
    this.closedRemaining,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['month'] = Variable<int>(month);
    map['year'] = Variable<int>(year);
    map['salary_income'] = Variable<double>(salaryIncome);
    map['extra_income'] = Variable<double>(extraIncome);
    map['deductions'] = Variable<double>(deductions);
    if (!nullToAbsent || bucketsSnapshot != null) {
      map['buckets_snapshot'] = Variable<String>(bucketsSnapshot);
    }
    map['is_closed'] = Variable<bool>(isClosed);
    if (!nullToAbsent || closedTotalSpent != null) {
      map['closed_total_spent'] = Variable<double>(closedTotalSpent);
    }
    if (!nullToAbsent || closedOutOfBucket != null) {
      map['closed_out_of_bucket'] = Variable<double>(closedOutOfBucket);
    }
    if (!nullToAbsent || closedRemaining != null) {
      map['closed_remaining'] = Variable<double>(closedRemaining);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MonthlyBudgetsCompanion toCompanion(bool nullToAbsent) {
    return MonthlyBudgetsCompanion(
      id: Value(id),
      month: Value(month),
      year: Value(year),
      salaryIncome: Value(salaryIncome),
      extraIncome: Value(extraIncome),
      deductions: Value(deductions),
      bucketsSnapshot: bucketsSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(bucketsSnapshot),
      isClosed: Value(isClosed),
      closedTotalSpent: closedTotalSpent == null && nullToAbsent
          ? const Value.absent()
          : Value(closedTotalSpent),
      closedOutOfBucket: closedOutOfBucket == null && nullToAbsent
          ? const Value.absent()
          : Value(closedOutOfBucket),
      closedRemaining: closedRemaining == null && nullToAbsent
          ? const Value.absent()
          : Value(closedRemaining),
      createdAt: Value(createdAt),
    );
  }

  factory MonthlyBudget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthlyBudget(
      id: serializer.fromJson<String>(json['id']),
      month: serializer.fromJson<int>(json['month']),
      year: serializer.fromJson<int>(json['year']),
      salaryIncome: serializer.fromJson<double>(json['salaryIncome']),
      extraIncome: serializer.fromJson<double>(json['extraIncome']),
      deductions: serializer.fromJson<double>(json['deductions']),
      bucketsSnapshot: serializer.fromJson<String?>(json['bucketsSnapshot']),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
      closedTotalSpent: serializer.fromJson<double?>(json['closedTotalSpent']),
      closedOutOfBucket: serializer.fromJson<double?>(
        json['closedOutOfBucket'],
      ),
      closedRemaining: serializer.fromJson<double?>(json['closedRemaining']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'month': serializer.toJson<int>(month),
      'year': serializer.toJson<int>(year),
      'salaryIncome': serializer.toJson<double>(salaryIncome),
      'extraIncome': serializer.toJson<double>(extraIncome),
      'deductions': serializer.toJson<double>(deductions),
      'bucketsSnapshot': serializer.toJson<String?>(bucketsSnapshot),
      'isClosed': serializer.toJson<bool>(isClosed),
      'closedTotalSpent': serializer.toJson<double?>(closedTotalSpent),
      'closedOutOfBucket': serializer.toJson<double?>(closedOutOfBucket),
      'closedRemaining': serializer.toJson<double?>(closedRemaining),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MonthlyBudget copyWith({
    String? id,
    int? month,
    int? year,
    double? salaryIncome,
    double? extraIncome,
    double? deductions,
    Value<String?> bucketsSnapshot = const Value.absent(),
    bool? isClosed,
    Value<double?> closedTotalSpent = const Value.absent(),
    Value<double?> closedOutOfBucket = const Value.absent(),
    Value<double?> closedRemaining = const Value.absent(),
    DateTime? createdAt,
  }) => MonthlyBudget(
    id: id ?? this.id,
    month: month ?? this.month,
    year: year ?? this.year,
    salaryIncome: salaryIncome ?? this.salaryIncome,
    extraIncome: extraIncome ?? this.extraIncome,
    deductions: deductions ?? this.deductions,
    bucketsSnapshot: bucketsSnapshot.present
        ? bucketsSnapshot.value
        : this.bucketsSnapshot,
    isClosed: isClosed ?? this.isClosed,
    closedTotalSpent: closedTotalSpent.present
        ? closedTotalSpent.value
        : this.closedTotalSpent,
    closedOutOfBucket: closedOutOfBucket.present
        ? closedOutOfBucket.value
        : this.closedOutOfBucket,
    closedRemaining: closedRemaining.present
        ? closedRemaining.value
        : this.closedRemaining,
    createdAt: createdAt ?? this.createdAt,
  );
  MonthlyBudget copyWithCompanion(MonthlyBudgetsCompanion data) {
    return MonthlyBudget(
      id: data.id.present ? data.id.value : this.id,
      month: data.month.present ? data.month.value : this.month,
      year: data.year.present ? data.year.value : this.year,
      salaryIncome: data.salaryIncome.present
          ? data.salaryIncome.value
          : this.salaryIncome,
      extraIncome: data.extraIncome.present
          ? data.extraIncome.value
          : this.extraIncome,
      deductions: data.deductions.present
          ? data.deductions.value
          : this.deductions,
      bucketsSnapshot: data.bucketsSnapshot.present
          ? data.bucketsSnapshot.value
          : this.bucketsSnapshot,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
      closedTotalSpent: data.closedTotalSpent.present
          ? data.closedTotalSpent.value
          : this.closedTotalSpent,
      closedOutOfBucket: data.closedOutOfBucket.present
          ? data.closedOutOfBucket.value
          : this.closedOutOfBucket,
      closedRemaining: data.closedRemaining.present
          ? data.closedRemaining.value
          : this.closedRemaining,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthlyBudget(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('salaryIncome: $salaryIncome, ')
          ..write('extraIncome: $extraIncome, ')
          ..write('deductions: $deductions, ')
          ..write('bucketsSnapshot: $bucketsSnapshot, ')
          ..write('isClosed: $isClosed, ')
          ..write('closedTotalSpent: $closedTotalSpent, ')
          ..write('closedOutOfBucket: $closedOutOfBucket, ')
          ..write('closedRemaining: $closedRemaining, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    month,
    year,
    salaryIncome,
    extraIncome,
    deductions,
    bucketsSnapshot,
    isClosed,
    closedTotalSpent,
    closedOutOfBucket,
    closedRemaining,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthlyBudget &&
          other.id == this.id &&
          other.month == this.month &&
          other.year == this.year &&
          other.salaryIncome == this.salaryIncome &&
          other.extraIncome == this.extraIncome &&
          other.deductions == this.deductions &&
          other.bucketsSnapshot == this.bucketsSnapshot &&
          other.isClosed == this.isClosed &&
          other.closedTotalSpent == this.closedTotalSpent &&
          other.closedOutOfBucket == this.closedOutOfBucket &&
          other.closedRemaining == this.closedRemaining &&
          other.createdAt == this.createdAt);
}

class MonthlyBudgetsCompanion extends UpdateCompanion<MonthlyBudget> {
  final Value<String> id;
  final Value<int> month;
  final Value<int> year;
  final Value<double> salaryIncome;
  final Value<double> extraIncome;
  final Value<double> deductions;
  final Value<String?> bucketsSnapshot;
  final Value<bool> isClosed;
  final Value<double?> closedTotalSpent;
  final Value<double?> closedOutOfBucket;
  final Value<double?> closedRemaining;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MonthlyBudgetsCompanion({
    this.id = const Value.absent(),
    this.month = const Value.absent(),
    this.year = const Value.absent(),
    this.salaryIncome = const Value.absent(),
    this.extraIncome = const Value.absent(),
    this.deductions = const Value.absent(),
    this.bucketsSnapshot = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.closedTotalSpent = const Value.absent(),
    this.closedOutOfBucket = const Value.absent(),
    this.closedRemaining = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthlyBudgetsCompanion.insert({
    required String id,
    required int month,
    required int year,
    this.salaryIncome = const Value.absent(),
    this.extraIncome = const Value.absent(),
    this.deductions = const Value.absent(),
    this.bucketsSnapshot = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.closedTotalSpent = const Value.absent(),
    this.closedOutOfBucket = const Value.absent(),
    this.closedRemaining = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       month = Value(month),
       year = Value(year);
  static Insertable<MonthlyBudget> custom({
    Expression<String>? id,
    Expression<int>? month,
    Expression<int>? year,
    Expression<double>? salaryIncome,
    Expression<double>? extraIncome,
    Expression<double>? deductions,
    Expression<String>? bucketsSnapshot,
    Expression<bool>? isClosed,
    Expression<double>? closedTotalSpent,
    Expression<double>? closedOutOfBucket,
    Expression<double>? closedRemaining,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (month != null) 'month': month,
      if (year != null) 'year': year,
      if (salaryIncome != null) 'salary_income': salaryIncome,
      if (extraIncome != null) 'extra_income': extraIncome,
      if (deductions != null) 'deductions': deductions,
      if (bucketsSnapshot != null) 'buckets_snapshot': bucketsSnapshot,
      if (isClosed != null) 'is_closed': isClosed,
      if (closedTotalSpent != null) 'closed_total_spent': closedTotalSpent,
      if (closedOutOfBucket != null) 'closed_out_of_bucket': closedOutOfBucket,
      if (closedRemaining != null) 'closed_remaining': closedRemaining,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthlyBudgetsCompanion copyWith({
    Value<String>? id,
    Value<int>? month,
    Value<int>? year,
    Value<double>? salaryIncome,
    Value<double>? extraIncome,
    Value<double>? deductions,
    Value<String?>? bucketsSnapshot,
    Value<bool>? isClosed,
    Value<double?>? closedTotalSpent,
    Value<double?>? closedOutOfBucket,
    Value<double?>? closedRemaining,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MonthlyBudgetsCompanion(
      id: id ?? this.id,
      month: month ?? this.month,
      year: year ?? this.year,
      salaryIncome: salaryIncome ?? this.salaryIncome,
      extraIncome: extraIncome ?? this.extraIncome,
      deductions: deductions ?? this.deductions,
      bucketsSnapshot: bucketsSnapshot ?? this.bucketsSnapshot,
      isClosed: isClosed ?? this.isClosed,
      closedTotalSpent: closedTotalSpent ?? this.closedTotalSpent,
      closedOutOfBucket: closedOutOfBucket ?? this.closedOutOfBucket,
      closedRemaining: closedRemaining ?? this.closedRemaining,
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
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (salaryIncome.present) {
      map['salary_income'] = Variable<double>(salaryIncome.value);
    }
    if (extraIncome.present) {
      map['extra_income'] = Variable<double>(extraIncome.value);
    }
    if (deductions.present) {
      map['deductions'] = Variable<double>(deductions.value);
    }
    if (bucketsSnapshot.present) {
      map['buckets_snapshot'] = Variable<String>(bucketsSnapshot.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
    }
    if (closedTotalSpent.present) {
      map['closed_total_spent'] = Variable<double>(closedTotalSpent.value);
    }
    if (closedOutOfBucket.present) {
      map['closed_out_of_bucket'] = Variable<double>(closedOutOfBucket.value);
    }
    if (closedRemaining.present) {
      map['closed_remaining'] = Variable<double>(closedRemaining.value);
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
    return (StringBuffer('MonthlyBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('month: $month, ')
          ..write('year: $year, ')
          ..write('salaryIncome: $salaryIncome, ')
          ..write('extraIncome: $extraIncome, ')
          ..write('deductions: $deductions, ')
          ..write('bucketsSnapshot: $bucketsSnapshot, ')
          ..write('isClosed: $isClosed, ')
          ..write('closedTotalSpent: $closedTotalSpent, ')
          ..write('closedOutOfBucket: $closedOutOfBucket, ')
          ..write('closedRemaining: $closedRemaining, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ClosedBudgetSnapshotsTable extends ClosedBudgetSnapshots
    with TableInfo<$ClosedBudgetSnapshotsTable, ClosedBudgetSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClosedBudgetSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetIdMeta = const VerificationMeta(
    'budgetId',
  );
  @override
  late final GeneratedColumn<String> budgetId = GeneratedColumn<String>(
    'budget_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salaryIncomeMeta = const VerificationMeta(
    'salaryIncome',
  );
  @override
  late final GeneratedColumn<double> salaryIncome = GeneratedColumn<double>(
    'salary_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extraIncomeMeta = const VerificationMeta(
    'extraIncome',
  );
  @override
  late final GeneratedColumn<double> extraIncome = GeneratedColumn<double>(
    'extra_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deductionsMeta = const VerificationMeta(
    'deductions',
  );
  @override
  late final GeneratedColumn<double> deductions = GeneratedColumn<double>(
    'deductions',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectiveIncomeMeta = const VerificationMeta(
    'effectiveIncome',
  );
  @override
  late final GeneratedColumn<double> effectiveIncome = GeneratedColumn<double>(
    'effective_income',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalSpentMeta = const VerificationMeta(
    'totalSpent',
  );
  @override
  late final GeneratedColumn<double> totalSpent = GeneratedColumn<double>(
    'total_spent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalOutOfBucketMeta = const VerificationMeta(
    'totalOutOfBucket',
  );
  @override
  late final GeneratedColumn<double> totalOutOfBucket = GeneratedColumn<double>(
    'total_out_of_bucket',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalRemainingMeta = const VerificationMeta(
    'totalRemaining',
  );
  @override
  late final GeneratedColumn<double> totalRemaining = GeneratedColumn<double>(
    'total_remaining',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _budgetedRemainingMeta = const VerificationMeta(
    'budgetedRemaining',
  );
  @override
  late final GeneratedColumn<double> budgetedRemaining =
      GeneratedColumn<double>(
        'budgeted_remaining',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _bucketDetailsJsonMeta = const VerificationMeta(
    'bucketDetailsJson',
  );
  @override
  late final GeneratedColumn<String> bucketDetailsJson =
      GeneratedColumn<String>(
        'bucket_details_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _closedAtMeta = const VerificationMeta(
    'closedAt',
  );
  @override
  late final GeneratedColumn<DateTime> closedAt = GeneratedColumn<DateTime>(
    'closed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    budgetId,
    salaryIncome,
    extraIncome,
    deductions,
    effectiveIncome,
    totalSpent,
    totalOutOfBucket,
    totalRemaining,
    budgetedRemaining,
    bucketDetailsJson,
    closedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'closed_budget_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<ClosedBudgetSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('budget_id')) {
      context.handle(
        _budgetIdMeta,
        budgetId.isAcceptableOrUnknown(data['budget_id']!, _budgetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_budgetIdMeta);
    }
    if (data.containsKey('salary_income')) {
      context.handle(
        _salaryIncomeMeta,
        salaryIncome.isAcceptableOrUnknown(
          data['salary_income']!,
          _salaryIncomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salaryIncomeMeta);
    }
    if (data.containsKey('extra_income')) {
      context.handle(
        _extraIncomeMeta,
        extraIncome.isAcceptableOrUnknown(
          data['extra_income']!,
          _extraIncomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_extraIncomeMeta);
    }
    if (data.containsKey('deductions')) {
      context.handle(
        _deductionsMeta,
        deductions.isAcceptableOrUnknown(data['deductions']!, _deductionsMeta),
      );
    } else if (isInserting) {
      context.missing(_deductionsMeta);
    }
    if (data.containsKey('effective_income')) {
      context.handle(
        _effectiveIncomeMeta,
        effectiveIncome.isAcceptableOrUnknown(
          data['effective_income']!,
          _effectiveIncomeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_effectiveIncomeMeta);
    }
    if (data.containsKey('total_spent')) {
      context.handle(
        _totalSpentMeta,
        totalSpent.isAcceptableOrUnknown(data['total_spent']!, _totalSpentMeta),
      );
    } else if (isInserting) {
      context.missing(_totalSpentMeta);
    }
    if (data.containsKey('total_out_of_bucket')) {
      context.handle(
        _totalOutOfBucketMeta,
        totalOutOfBucket.isAcceptableOrUnknown(
          data['total_out_of_bucket']!,
          _totalOutOfBucketMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalOutOfBucketMeta);
    }
    if (data.containsKey('total_remaining')) {
      context.handle(
        _totalRemainingMeta,
        totalRemaining.isAcceptableOrUnknown(
          data['total_remaining']!,
          _totalRemainingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalRemainingMeta);
    }
    if (data.containsKey('budgeted_remaining')) {
      context.handle(
        _budgetedRemainingMeta,
        budgetedRemaining.isAcceptableOrUnknown(
          data['budgeted_remaining']!,
          _budgetedRemainingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_budgetedRemainingMeta);
    }
    if (data.containsKey('bucket_details_json')) {
      context.handle(
        _bucketDetailsJsonMeta,
        bucketDetailsJson.isAcceptableOrUnknown(
          data['bucket_details_json']!,
          _bucketDetailsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bucketDetailsJsonMeta);
    }
    if (data.containsKey('closed_at')) {
      context.handle(
        _closedAtMeta,
        closedAt.isAcceptableOrUnknown(data['closed_at']!, _closedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClosedBudgetSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClosedBudgetSnapshot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      budgetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}budget_id'],
      )!,
      salaryIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}salary_income'],
      )!,
      extraIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}extra_income'],
      )!,
      deductions: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}deductions'],
      )!,
      effectiveIncome: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}effective_income'],
      )!,
      totalSpent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_spent'],
      )!,
      totalOutOfBucket: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_out_of_bucket'],
      )!,
      totalRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_remaining'],
      )!,
      budgetedRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}budgeted_remaining'],
      )!,
      bucketDetailsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket_details_json'],
      )!,
      closedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}closed_at'],
      )!,
    );
  }

  @override
  $ClosedBudgetSnapshotsTable createAlias(String alias) {
    return $ClosedBudgetSnapshotsTable(attachedDatabase, alias);
  }
}

class ClosedBudgetSnapshot extends DataClass
    implements Insertable<ClosedBudgetSnapshot> {
  final String id;
  final String budgetId;
  final double salaryIncome;
  final double extraIncome;
  final double deductions;
  final double effectiveIncome;
  final double totalSpent;
  final double totalOutOfBucket;
  final double totalRemaining;
  final double budgetedRemaining;
  final String bucketDetailsJson;
  final DateTime closedAt;
  const ClosedBudgetSnapshot({
    required this.id,
    required this.budgetId,
    required this.salaryIncome,
    required this.extraIncome,
    required this.deductions,
    required this.effectiveIncome,
    required this.totalSpent,
    required this.totalOutOfBucket,
    required this.totalRemaining,
    required this.budgetedRemaining,
    required this.bucketDetailsJson,
    required this.closedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['budget_id'] = Variable<String>(budgetId);
    map['salary_income'] = Variable<double>(salaryIncome);
    map['extra_income'] = Variable<double>(extraIncome);
    map['deductions'] = Variable<double>(deductions);
    map['effective_income'] = Variable<double>(effectiveIncome);
    map['total_spent'] = Variable<double>(totalSpent);
    map['total_out_of_bucket'] = Variable<double>(totalOutOfBucket);
    map['total_remaining'] = Variable<double>(totalRemaining);
    map['budgeted_remaining'] = Variable<double>(budgetedRemaining);
    map['bucket_details_json'] = Variable<String>(bucketDetailsJson);
    map['closed_at'] = Variable<DateTime>(closedAt);
    return map;
  }

  ClosedBudgetSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return ClosedBudgetSnapshotsCompanion(
      id: Value(id),
      budgetId: Value(budgetId),
      salaryIncome: Value(salaryIncome),
      extraIncome: Value(extraIncome),
      deductions: Value(deductions),
      effectiveIncome: Value(effectiveIncome),
      totalSpent: Value(totalSpent),
      totalOutOfBucket: Value(totalOutOfBucket),
      totalRemaining: Value(totalRemaining),
      budgetedRemaining: Value(budgetedRemaining),
      bucketDetailsJson: Value(bucketDetailsJson),
      closedAt: Value(closedAt),
    );
  }

  factory ClosedBudgetSnapshot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClosedBudgetSnapshot(
      id: serializer.fromJson<String>(json['id']),
      budgetId: serializer.fromJson<String>(json['budgetId']),
      salaryIncome: serializer.fromJson<double>(json['salaryIncome']),
      extraIncome: serializer.fromJson<double>(json['extraIncome']),
      deductions: serializer.fromJson<double>(json['deductions']),
      effectiveIncome: serializer.fromJson<double>(json['effectiveIncome']),
      totalSpent: serializer.fromJson<double>(json['totalSpent']),
      totalOutOfBucket: serializer.fromJson<double>(json['totalOutOfBucket']),
      totalRemaining: serializer.fromJson<double>(json['totalRemaining']),
      budgetedRemaining: serializer.fromJson<double>(json['budgetedRemaining']),
      bucketDetailsJson: serializer.fromJson<String>(json['bucketDetailsJson']),
      closedAt: serializer.fromJson<DateTime>(json['closedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'budgetId': serializer.toJson<String>(budgetId),
      'salaryIncome': serializer.toJson<double>(salaryIncome),
      'extraIncome': serializer.toJson<double>(extraIncome),
      'deductions': serializer.toJson<double>(deductions),
      'effectiveIncome': serializer.toJson<double>(effectiveIncome),
      'totalSpent': serializer.toJson<double>(totalSpent),
      'totalOutOfBucket': serializer.toJson<double>(totalOutOfBucket),
      'totalRemaining': serializer.toJson<double>(totalRemaining),
      'budgetedRemaining': serializer.toJson<double>(budgetedRemaining),
      'bucketDetailsJson': serializer.toJson<String>(bucketDetailsJson),
      'closedAt': serializer.toJson<DateTime>(closedAt),
    };
  }

  ClosedBudgetSnapshot copyWith({
    String? id,
    String? budgetId,
    double? salaryIncome,
    double? extraIncome,
    double? deductions,
    double? effectiveIncome,
    double? totalSpent,
    double? totalOutOfBucket,
    double? totalRemaining,
    double? budgetedRemaining,
    String? bucketDetailsJson,
    DateTime? closedAt,
  }) => ClosedBudgetSnapshot(
    id: id ?? this.id,
    budgetId: budgetId ?? this.budgetId,
    salaryIncome: salaryIncome ?? this.salaryIncome,
    extraIncome: extraIncome ?? this.extraIncome,
    deductions: deductions ?? this.deductions,
    effectiveIncome: effectiveIncome ?? this.effectiveIncome,
    totalSpent: totalSpent ?? this.totalSpent,
    totalOutOfBucket: totalOutOfBucket ?? this.totalOutOfBucket,
    totalRemaining: totalRemaining ?? this.totalRemaining,
    budgetedRemaining: budgetedRemaining ?? this.budgetedRemaining,
    bucketDetailsJson: bucketDetailsJson ?? this.bucketDetailsJson,
    closedAt: closedAt ?? this.closedAt,
  );
  ClosedBudgetSnapshot copyWithCompanion(ClosedBudgetSnapshotsCompanion data) {
    return ClosedBudgetSnapshot(
      id: data.id.present ? data.id.value : this.id,
      budgetId: data.budgetId.present ? data.budgetId.value : this.budgetId,
      salaryIncome: data.salaryIncome.present
          ? data.salaryIncome.value
          : this.salaryIncome,
      extraIncome: data.extraIncome.present
          ? data.extraIncome.value
          : this.extraIncome,
      deductions: data.deductions.present
          ? data.deductions.value
          : this.deductions,
      effectiveIncome: data.effectiveIncome.present
          ? data.effectiveIncome.value
          : this.effectiveIncome,
      totalSpent: data.totalSpent.present
          ? data.totalSpent.value
          : this.totalSpent,
      totalOutOfBucket: data.totalOutOfBucket.present
          ? data.totalOutOfBucket.value
          : this.totalOutOfBucket,
      totalRemaining: data.totalRemaining.present
          ? data.totalRemaining.value
          : this.totalRemaining,
      budgetedRemaining: data.budgetedRemaining.present
          ? data.budgetedRemaining.value
          : this.budgetedRemaining,
      bucketDetailsJson: data.bucketDetailsJson.present
          ? data.bucketDetailsJson.value
          : this.bucketDetailsJson,
      closedAt: data.closedAt.present ? data.closedAt.value : this.closedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClosedBudgetSnapshot(')
          ..write('id: $id, ')
          ..write('budgetId: $budgetId, ')
          ..write('salaryIncome: $salaryIncome, ')
          ..write('extraIncome: $extraIncome, ')
          ..write('deductions: $deductions, ')
          ..write('effectiveIncome: $effectiveIncome, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('totalOutOfBucket: $totalOutOfBucket, ')
          ..write('totalRemaining: $totalRemaining, ')
          ..write('budgetedRemaining: $budgetedRemaining, ')
          ..write('bucketDetailsJson: $bucketDetailsJson, ')
          ..write('closedAt: $closedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    budgetId,
    salaryIncome,
    extraIncome,
    deductions,
    effectiveIncome,
    totalSpent,
    totalOutOfBucket,
    totalRemaining,
    budgetedRemaining,
    bucketDetailsJson,
    closedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClosedBudgetSnapshot &&
          other.id == this.id &&
          other.budgetId == this.budgetId &&
          other.salaryIncome == this.salaryIncome &&
          other.extraIncome == this.extraIncome &&
          other.deductions == this.deductions &&
          other.effectiveIncome == this.effectiveIncome &&
          other.totalSpent == this.totalSpent &&
          other.totalOutOfBucket == this.totalOutOfBucket &&
          other.totalRemaining == this.totalRemaining &&
          other.budgetedRemaining == this.budgetedRemaining &&
          other.bucketDetailsJson == this.bucketDetailsJson &&
          other.closedAt == this.closedAt);
}

class ClosedBudgetSnapshotsCompanion
    extends UpdateCompanion<ClosedBudgetSnapshot> {
  final Value<String> id;
  final Value<String> budgetId;
  final Value<double> salaryIncome;
  final Value<double> extraIncome;
  final Value<double> deductions;
  final Value<double> effectiveIncome;
  final Value<double> totalSpent;
  final Value<double> totalOutOfBucket;
  final Value<double> totalRemaining;
  final Value<double> budgetedRemaining;
  final Value<String> bucketDetailsJson;
  final Value<DateTime> closedAt;
  final Value<int> rowid;
  const ClosedBudgetSnapshotsCompanion({
    this.id = const Value.absent(),
    this.budgetId = const Value.absent(),
    this.salaryIncome = const Value.absent(),
    this.extraIncome = const Value.absent(),
    this.deductions = const Value.absent(),
    this.effectiveIncome = const Value.absent(),
    this.totalSpent = const Value.absent(),
    this.totalOutOfBucket = const Value.absent(),
    this.totalRemaining = const Value.absent(),
    this.budgetedRemaining = const Value.absent(),
    this.bucketDetailsJson = const Value.absent(),
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ClosedBudgetSnapshotsCompanion.insert({
    required String id,
    required String budgetId,
    required double salaryIncome,
    required double extraIncome,
    required double deductions,
    required double effectiveIncome,
    required double totalSpent,
    required double totalOutOfBucket,
    required double totalRemaining,
    required double budgetedRemaining,
    required String bucketDetailsJson,
    this.closedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       budgetId = Value(budgetId),
       salaryIncome = Value(salaryIncome),
       extraIncome = Value(extraIncome),
       deductions = Value(deductions),
       effectiveIncome = Value(effectiveIncome),
       totalSpent = Value(totalSpent),
       totalOutOfBucket = Value(totalOutOfBucket),
       totalRemaining = Value(totalRemaining),
       budgetedRemaining = Value(budgetedRemaining),
       bucketDetailsJson = Value(bucketDetailsJson);
  static Insertable<ClosedBudgetSnapshot> custom({
    Expression<String>? id,
    Expression<String>? budgetId,
    Expression<double>? salaryIncome,
    Expression<double>? extraIncome,
    Expression<double>? deductions,
    Expression<double>? effectiveIncome,
    Expression<double>? totalSpent,
    Expression<double>? totalOutOfBucket,
    Expression<double>? totalRemaining,
    Expression<double>? budgetedRemaining,
    Expression<String>? bucketDetailsJson,
    Expression<DateTime>? closedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (budgetId != null) 'budget_id': budgetId,
      if (salaryIncome != null) 'salary_income': salaryIncome,
      if (extraIncome != null) 'extra_income': extraIncome,
      if (deductions != null) 'deductions': deductions,
      if (effectiveIncome != null) 'effective_income': effectiveIncome,
      if (totalSpent != null) 'total_spent': totalSpent,
      if (totalOutOfBucket != null) 'total_out_of_bucket': totalOutOfBucket,
      if (totalRemaining != null) 'total_remaining': totalRemaining,
      if (budgetedRemaining != null) 'budgeted_remaining': budgetedRemaining,
      if (bucketDetailsJson != null) 'bucket_details_json': bucketDetailsJson,
      if (closedAt != null) 'closed_at': closedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ClosedBudgetSnapshotsCompanion copyWith({
    Value<String>? id,
    Value<String>? budgetId,
    Value<double>? salaryIncome,
    Value<double>? extraIncome,
    Value<double>? deductions,
    Value<double>? effectiveIncome,
    Value<double>? totalSpent,
    Value<double>? totalOutOfBucket,
    Value<double>? totalRemaining,
    Value<double>? budgetedRemaining,
    Value<String>? bucketDetailsJson,
    Value<DateTime>? closedAt,
    Value<int>? rowid,
  }) {
    return ClosedBudgetSnapshotsCompanion(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      salaryIncome: salaryIncome ?? this.salaryIncome,
      extraIncome: extraIncome ?? this.extraIncome,
      deductions: deductions ?? this.deductions,
      effectiveIncome: effectiveIncome ?? this.effectiveIncome,
      totalSpent: totalSpent ?? this.totalSpent,
      totalOutOfBucket: totalOutOfBucket ?? this.totalOutOfBucket,
      totalRemaining: totalRemaining ?? this.totalRemaining,
      budgetedRemaining: budgetedRemaining ?? this.budgetedRemaining,
      bucketDetailsJson: bucketDetailsJson ?? this.bucketDetailsJson,
      closedAt: closedAt ?? this.closedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (budgetId.present) {
      map['budget_id'] = Variable<String>(budgetId.value);
    }
    if (salaryIncome.present) {
      map['salary_income'] = Variable<double>(salaryIncome.value);
    }
    if (extraIncome.present) {
      map['extra_income'] = Variable<double>(extraIncome.value);
    }
    if (deductions.present) {
      map['deductions'] = Variable<double>(deductions.value);
    }
    if (effectiveIncome.present) {
      map['effective_income'] = Variable<double>(effectiveIncome.value);
    }
    if (totalSpent.present) {
      map['total_spent'] = Variable<double>(totalSpent.value);
    }
    if (totalOutOfBucket.present) {
      map['total_out_of_bucket'] = Variable<double>(totalOutOfBucket.value);
    }
    if (totalRemaining.present) {
      map['total_remaining'] = Variable<double>(totalRemaining.value);
    }
    if (budgetedRemaining.present) {
      map['budgeted_remaining'] = Variable<double>(budgetedRemaining.value);
    }
    if (bucketDetailsJson.present) {
      map['bucket_details_json'] = Variable<String>(bucketDetailsJson.value);
    }
    if (closedAt.present) {
      map['closed_at'] = Variable<DateTime>(closedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClosedBudgetSnapshotsCompanion(')
          ..write('id: $id, ')
          ..write('budgetId: $budgetId, ')
          ..write('salaryIncome: $salaryIncome, ')
          ..write('extraIncome: $extraIncome, ')
          ..write('deductions: $deductions, ')
          ..write('effectiveIncome: $effectiveIncome, ')
          ..write('totalSpent: $totalSpent, ')
          ..write('totalOutOfBucket: $totalOutOfBucket, ')
          ..write('totalRemaining: $totalRemaining, ')
          ..write('budgetedRemaining: $budgetedRemaining, ')
          ..write('bucketDetailsJson: $bucketDetailsJson, ')
          ..write('closedAt: $closedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomBudgetsTable extends CustomBudgets
    with TableInfo<$CustomBudgetsTable, CustomBudget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomBudgetsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountLimitMeta = const VerificationMeta(
    'amountLimit',
  );
  @override
  late final GeneratedColumn<double> amountLimit = GeneratedColumn<double>(
    'amount_limit',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeFrameMeta = const VerificationMeta(
    'timeFrame',
  );
  @override
  late final GeneratedColumn<String> timeFrame = GeneratedColumn<String>(
    'time_frame',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subCategoryMeta = const VerificationMeta(
    'subCategory',
  );
  @override
  late final GeneratedColumn<String> subCategory = GeneratedColumn<String>(
    'sub_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bucketIdMeta = const VerificationMeta(
    'bucketId',
  );
  @override
  late final GeneratedColumn<int> bucketId = GeneratedColumn<int>(
    'bucket_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSettledMeta = const VerificationMeta(
    'isSettled',
  );
  @override
  late final GeneratedColumn<bool> isSettled = GeneratedColumn<bool>(
    'is_settled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_settled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _settledAmountMeta = const VerificationMeta(
    'settledAmount',
  );
  @override
  late final GeneratedColumn<double> settledAmount = GeneratedColumn<double>(
    'settled_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    amountLimit,
    timeFrame,
    startDate,
    endDate,
    categoryId,
    subCategory,
    bucketId,
    accountId,
    isSettled,
    settledAmount,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomBudget> instance, {
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
    if (data.containsKey('amount_limit')) {
      context.handle(
        _amountLimitMeta,
        amountLimit.isAcceptableOrUnknown(
          data['amount_limit']!,
          _amountLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountLimitMeta);
    }
    if (data.containsKey('time_frame')) {
      context.handle(
        _timeFrameMeta,
        timeFrame.isAcceptableOrUnknown(data['time_frame']!, _timeFrameMeta),
      );
    } else if (isInserting) {
      context.missing(_timeFrameMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('sub_category')) {
      context.handle(
        _subCategoryMeta,
        subCategory.isAcceptableOrUnknown(
          data['sub_category']!,
          _subCategoryMeta,
        ),
      );
    }
    if (data.containsKey('bucket_id')) {
      context.handle(
        _bucketIdMeta,
        bucketId.isAcceptableOrUnknown(data['bucket_id']!, _bucketIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('is_settled')) {
      context.handle(
        _isSettledMeta,
        isSettled.isAcceptableOrUnknown(data['is_settled']!, _isSettledMeta),
      );
    }
    if (data.containsKey('settled_amount')) {
      context.handle(
        _settledAmountMeta,
        settledAmount.isAcceptableOrUnknown(
          data['settled_amount']!,
          _settledAmountMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomBudget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomBudget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount_limit'],
      )!,
      timeFrame: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_frame'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      subCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category'],
      ),
      bucketId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bucket_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      isSettled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_settled'],
      )!,
      settledAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}settled_amount'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $CustomBudgetsTable createAlias(String alias) {
    return $CustomBudgetsTable(attachedDatabase, alias);
  }
}

class CustomBudget extends DataClass implements Insertable<CustomBudget> {
  final String id;
  final String name;
  final double amountLimit;
  final String timeFrame;
  final DateTime startDate;
  final DateTime endDate;
  final String? categoryId;
  final String? subCategory;
  final int? bucketId;
  final String? accountId;
  final bool isSettled;
  final double? settledAmount;
  final DateTime createdAt;
  const CustomBudget({
    required this.id,
    required this.name,
    required this.amountLimit,
    required this.timeFrame,
    required this.startDate,
    required this.endDate,
    this.categoryId,
    this.subCategory,
    this.bucketId,
    this.accountId,
    required this.isSettled,
    this.settledAmount,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['amount_limit'] = Variable<double>(amountLimit);
    map['time_frame'] = Variable<String>(timeFrame);
    map['start_date'] = Variable<DateTime>(startDate);
    map['end_date'] = Variable<DateTime>(endDate);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || subCategory != null) {
      map['sub_category'] = Variable<String>(subCategory);
    }
    if (!nullToAbsent || bucketId != null) {
      map['bucket_id'] = Variable<int>(bucketId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['is_settled'] = Variable<bool>(isSettled);
    if (!nullToAbsent || settledAmount != null) {
      map['settled_amount'] = Variable<double>(settledAmount);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CustomBudgetsCompanion toCompanion(bool nullToAbsent) {
    return CustomBudgetsCompanion(
      id: Value(id),
      name: Value(name),
      amountLimit: Value(amountLimit),
      timeFrame: Value(timeFrame),
      startDate: Value(startDate),
      endDate: Value(endDate),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      subCategory: subCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subCategory),
      bucketId: bucketId == null && nullToAbsent
          ? const Value.absent()
          : Value(bucketId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      isSettled: Value(isSettled),
      settledAmount: settledAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(settledAmount),
      createdAt: Value(createdAt),
    );
  }

  factory CustomBudget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomBudget(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      amountLimit: serializer.fromJson<double>(json['amountLimit']),
      timeFrame: serializer.fromJson<String>(json['timeFrame']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime>(json['endDate']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      subCategory: serializer.fromJson<String?>(json['subCategory']),
      bucketId: serializer.fromJson<int?>(json['bucketId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      isSettled: serializer.fromJson<bool>(json['isSettled']),
      settledAmount: serializer.fromJson<double?>(json['settledAmount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'amountLimit': serializer.toJson<double>(amountLimit),
      'timeFrame': serializer.toJson<String>(timeFrame),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime>(endDate),
      'categoryId': serializer.toJson<String?>(categoryId),
      'subCategory': serializer.toJson<String?>(subCategory),
      'bucketId': serializer.toJson<int?>(bucketId),
      'accountId': serializer.toJson<String?>(accountId),
      'isSettled': serializer.toJson<bool>(isSettled),
      'settledAmount': serializer.toJson<double?>(settledAmount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  CustomBudget copyWith({
    String? id,
    String? name,
    double? amountLimit,
    String? timeFrame,
    DateTime? startDate,
    DateTime? endDate,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> subCategory = const Value.absent(),
    Value<int?> bucketId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    bool? isSettled,
    Value<double?> settledAmount = const Value.absent(),
    DateTime? createdAt,
  }) => CustomBudget(
    id: id ?? this.id,
    name: name ?? this.name,
    amountLimit: amountLimit ?? this.amountLimit,
    timeFrame: timeFrame ?? this.timeFrame,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    subCategory: subCategory.present ? subCategory.value : this.subCategory,
    bucketId: bucketId.present ? bucketId.value : this.bucketId,
    accountId: accountId.present ? accountId.value : this.accountId,
    isSettled: isSettled ?? this.isSettled,
    settledAmount: settledAmount.present
        ? settledAmount.value
        : this.settledAmount,
    createdAt: createdAt ?? this.createdAt,
  );
  CustomBudget copyWithCompanion(CustomBudgetsCompanion data) {
    return CustomBudget(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      amountLimit: data.amountLimit.present
          ? data.amountLimit.value
          : this.amountLimit,
      timeFrame: data.timeFrame.present ? data.timeFrame.value : this.timeFrame,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      subCategory: data.subCategory.present
          ? data.subCategory.value
          : this.subCategory,
      bucketId: data.bucketId.present ? data.bucketId.value : this.bucketId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      isSettled: data.isSettled.present ? data.isSettled.value : this.isSettled,
      settledAmount: data.settledAmount.present
          ? data.settledAmount.value
          : this.settledAmount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomBudget(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountLimit: $amountLimit, ')
          ..write('timeFrame: $timeFrame, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('subCategory: $subCategory, ')
          ..write('bucketId: $bucketId, ')
          ..write('accountId: $accountId, ')
          ..write('isSettled: $isSettled, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    amountLimit,
    timeFrame,
    startDate,
    endDate,
    categoryId,
    subCategory,
    bucketId,
    accountId,
    isSettled,
    settledAmount,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomBudget &&
          other.id == this.id &&
          other.name == this.name &&
          other.amountLimit == this.amountLimit &&
          other.timeFrame == this.timeFrame &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.categoryId == this.categoryId &&
          other.subCategory == this.subCategory &&
          other.bucketId == this.bucketId &&
          other.accountId == this.accountId &&
          other.isSettled == this.isSettled &&
          other.settledAmount == this.settledAmount &&
          other.createdAt == this.createdAt);
}

class CustomBudgetsCompanion extends UpdateCompanion<CustomBudget> {
  final Value<String> id;
  final Value<String> name;
  final Value<double> amountLimit;
  final Value<String> timeFrame;
  final Value<DateTime> startDate;
  final Value<DateTime> endDate;
  final Value<String?> categoryId;
  final Value<String?> subCategory;
  final Value<int?> bucketId;
  final Value<String?> accountId;
  final Value<bool> isSettled;
  final Value<double?> settledAmount;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const CustomBudgetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.amountLimit = const Value.absent(),
    this.timeFrame = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.bucketId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.settledAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomBudgetsCompanion.insert({
    required String id,
    required String name,
    required double amountLimit,
    required String timeFrame,
    required DateTime startDate,
    required DateTime endDate,
    this.categoryId = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.bucketId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.isSettled = const Value.absent(),
    this.settledAmount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       amountLimit = Value(amountLimit),
       timeFrame = Value(timeFrame),
       startDate = Value(startDate),
       endDate = Value(endDate);
  static Insertable<CustomBudget> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? amountLimit,
    Expression<String>? timeFrame,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? categoryId,
    Expression<String>? subCategory,
    Expression<int>? bucketId,
    Expression<String>? accountId,
    Expression<bool>? isSettled,
    Expression<double>? settledAmount,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (amountLimit != null) 'amount_limit': amountLimit,
      if (timeFrame != null) 'time_frame': timeFrame,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (categoryId != null) 'category_id': categoryId,
      if (subCategory != null) 'sub_category': subCategory,
      if (bucketId != null) 'bucket_id': bucketId,
      if (accountId != null) 'account_id': accountId,
      if (isSettled != null) 'is_settled': isSettled,
      if (settledAmount != null) 'settled_amount': settledAmount,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomBudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double>? amountLimit,
    Value<String>? timeFrame,
    Value<DateTime>? startDate,
    Value<DateTime>? endDate,
    Value<String?>? categoryId,
    Value<String?>? subCategory,
    Value<int?>? bucketId,
    Value<String?>? accountId,
    Value<bool>? isSettled,
    Value<double?>? settledAmount,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return CustomBudgetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      amountLimit: amountLimit ?? this.amountLimit,
      timeFrame: timeFrame ?? this.timeFrame,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categoryId: categoryId ?? this.categoryId,
      subCategory: subCategory ?? this.subCategory,
      bucketId: bucketId ?? this.bucketId,
      accountId: accountId ?? this.accountId,
      isSettled: isSettled ?? this.isSettled,
      settledAmount: settledAmount ?? this.settledAmount,
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
    if (amountLimit.present) {
      map['amount_limit'] = Variable<double>(amountLimit.value);
    }
    if (timeFrame.present) {
      map['time_frame'] = Variable<String>(timeFrame.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (subCategory.present) {
      map['sub_category'] = Variable<String>(subCategory.value);
    }
    if (bucketId.present) {
      map['bucket_id'] = Variable<int>(bucketId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (isSettled.present) {
      map['is_settled'] = Variable<bool>(isSettled.value);
    }
    if (settledAmount.present) {
      map['settled_amount'] = Variable<double>(settledAmount.value);
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
    return (StringBuffer('CustomBudgetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('amountLimit: $amountLimit, ')
          ..write('timeFrame: $timeFrame, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('categoryId: $categoryId, ')
          ..write('subCategory: $subCategory, ')
          ..write('bucketId: $bucketId, ')
          ..write('accountId: $accountId, ')
          ..write('isSettled: $isSettled, ')
          ..write('settledAmount: $settledAmount, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentsTable extends Investments
    with TableInfo<$InvestmentsTable, Investment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerUrlMeta = const VerificationMeta(
    'providerUrl',
  );
  @override
  late final GeneratedColumn<String> providerUrl = GeneratedColumn<String>(
    'provider_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _specialTagMeta = const VerificationMeta(
    'specialTag',
  );
  @override
  late final GeneratedColumn<String> specialTag = GeneratedColumn<String>(
    'special_tag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _initialAmountMeta = const VerificationMeta(
    'initialAmount',
  );
  @override
  late final GeneratedColumn<double> initialAmount = GeneratedColumn<double>(
    'initial_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentValueMeta = const VerificationMeta(
    'currentValue',
  );
  @override
  late final GeneratedColumn<double> currentValue = GeneratedColumn<double>(
    'current_value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _targetAmountMeta = const VerificationMeta(
    'targetAmount',
  );
  @override
  late final GeneratedColumn<double> targetAmount = GeneratedColumn<double>(
    'target_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expectedEndDateMeta = const VerificationMeta(
    'expectedEndDate',
  );
  @override
  late final GeneratedColumn<DateTime> expectedEndDate =
      GeneratedColumn<DateTime>(
        'expected_end_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _expectedReturnMeta = const VerificationMeta(
    'expectedReturn',
  );
  @override
  late final GeneratedColumn<double> expectedReturn = GeneratedColumn<double>(
    'expected_return',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folioNoMeta = const VerificationMeta(
    'folioNo',
  );
  @override
  late final GeneratedColumn<String> folioNo = GeneratedColumn<String>(
    'folio_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitsMeta = const VerificationMeta('units');
  @override
  late final GeneratedColumn<double> units = GeneratedColumn<double>(
    'units',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brokerNameMeta = const VerificationMeta(
    'brokerName',
  );
  @override
  late final GeneratedColumn<String> brokerName = GeneratedColumn<String>(
    'broker_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedAccountNoMeta = const VerificationMeta(
    'linkedAccountNo',
  );
  @override
  late final GeneratedColumn<String> linkedAccountNo = GeneratedColumn<String>(
    'linked_account_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedAccountIfscMeta = const VerificationMeta(
    'linkedAccountIfsc',
  );
  @override
  late final GeneratedColumn<String> linkedAccountIfsc =
      GeneratedColumn<String>(
        'linked_account_ifsc',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _linkedBankNameMeta = const VerificationMeta(
    'linkedBankName',
  );
  @override
  late final GeneratedColumn<String> linkedBankName = GeneratedColumn<String>(
    'linked_bank_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _purposeMeta = const VerificationMeta(
    'purpose',
  );
  @override
  late final GeneratedColumn<String> purpose = GeneratedColumn<String>(
    'purpose',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isClosedMeta = const VerificationMeta(
    'isClosed',
  );
  @override
  late final GeneratedColumn<bool> isClosed = GeneratedColumn<bool>(
    'is_closed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_closed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _closeReasonMeta = const VerificationMeta(
    'closeReason',
  );
  @override
  late final GeneratedColumn<String> closeReason = GeneratedColumn<String>(
    'close_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    provider,
    providerUrl,
    specialTag,
    initialAmount,
    currentValue,
    targetAmount,
    startDate,
    expectedEndDate,
    expectedReturn,
    folioNo,
    units,
    brokerName,
    linkedAccountNo,
    linkedAccountIfsc,
    linkedBankName,
    purpose,
    notes,
    isClosed,
    closeReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Investment> instance, {
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
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('provider_url')) {
      context.handle(
        _providerUrlMeta,
        providerUrl.isAcceptableOrUnknown(
          data['provider_url']!,
          _providerUrlMeta,
        ),
      );
    }
    if (data.containsKey('special_tag')) {
      context.handle(
        _specialTagMeta,
        specialTag.isAcceptableOrUnknown(data['special_tag']!, _specialTagMeta),
      );
    }
    if (data.containsKey('initial_amount')) {
      context.handle(
        _initialAmountMeta,
        initialAmount.isAcceptableOrUnknown(
          data['initial_amount']!,
          _initialAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_initialAmountMeta);
    }
    if (data.containsKey('current_value')) {
      context.handle(
        _currentValueMeta,
        currentValue.isAcceptableOrUnknown(
          data['current_value']!,
          _currentValueMeta,
        ),
      );
    }
    if (data.containsKey('target_amount')) {
      context.handle(
        _targetAmountMeta,
        targetAmount.isAcceptableOrUnknown(
          data['target_amount']!,
          _targetAmountMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('expected_end_date')) {
      context.handle(
        _expectedEndDateMeta,
        expectedEndDate.isAcceptableOrUnknown(
          data['expected_end_date']!,
          _expectedEndDateMeta,
        ),
      );
    }
    if (data.containsKey('expected_return')) {
      context.handle(
        _expectedReturnMeta,
        expectedReturn.isAcceptableOrUnknown(
          data['expected_return']!,
          _expectedReturnMeta,
        ),
      );
    }
    if (data.containsKey('folio_no')) {
      context.handle(
        _folioNoMeta,
        folioNo.isAcceptableOrUnknown(data['folio_no']!, _folioNoMeta),
      );
    }
    if (data.containsKey('units')) {
      context.handle(
        _unitsMeta,
        units.isAcceptableOrUnknown(data['units']!, _unitsMeta),
      );
    }
    if (data.containsKey('broker_name')) {
      context.handle(
        _brokerNameMeta,
        brokerName.isAcceptableOrUnknown(data['broker_name']!, _brokerNameMeta),
      );
    }
    if (data.containsKey('linked_account_no')) {
      context.handle(
        _linkedAccountNoMeta,
        linkedAccountNo.isAcceptableOrUnknown(
          data['linked_account_no']!,
          _linkedAccountNoMeta,
        ),
      );
    }
    if (data.containsKey('linked_account_ifsc')) {
      context.handle(
        _linkedAccountIfscMeta,
        linkedAccountIfsc.isAcceptableOrUnknown(
          data['linked_account_ifsc']!,
          _linkedAccountIfscMeta,
        ),
      );
    }
    if (data.containsKey('linked_bank_name')) {
      context.handle(
        _linkedBankNameMeta,
        linkedBankName.isAcceptableOrUnknown(
          data['linked_bank_name']!,
          _linkedBankNameMeta,
        ),
      );
    }
    if (data.containsKey('purpose')) {
      context.handle(
        _purposeMeta,
        purpose.isAcceptableOrUnknown(data['purpose']!, _purposeMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_closed')) {
      context.handle(
        _isClosedMeta,
        isClosed.isAcceptableOrUnknown(data['is_closed']!, _isClosedMeta),
      );
    }
    if (data.containsKey('close_reason')) {
      context.handle(
        _closeReasonMeta,
        closeReason.isAcceptableOrUnknown(
          data['close_reason']!,
          _closeReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Investment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Investment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      providerUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_url'],
      ),
      specialTag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}special_tag'],
      ),
      initialAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}initial_amount'],
      )!,
      currentValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_value'],
      )!,
      targetAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_amount'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      expectedEndDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expected_end_date'],
      ),
      expectedReturn: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}expected_return'],
      ),
      folioNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folio_no'],
      ),
      units: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}units'],
      ),
      brokerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}broker_name'],
      ),
      linkedAccountNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_account_no'],
      ),
      linkedAccountIfsc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_account_ifsc'],
      ),
      linkedBankName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_bank_name'],
      ),
      purpose: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purpose'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isClosed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_closed'],
      )!,
      closeReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}close_reason'],
      ),
    );
  }

  @override
  $InvestmentsTable createAlias(String alias) {
    return $InvestmentsTable(attachedDatabase, alias);
  }
}

class Investment extends DataClass implements Insertable<Investment> {
  final String id;
  final String name;
  final String type;
  final String provider;
  final String? providerUrl;
  final String? specialTag;
  final double initialAmount;
  final double currentValue;
  final double? targetAmount;
  final DateTime startDate;
  final DateTime? expectedEndDate;
  final double? expectedReturn;
  final String? folioNo;
  final double? units;
  final String? brokerName;
  final String? linkedAccountNo;
  final String? linkedAccountIfsc;
  final String? linkedBankName;
  final String? purpose;
  final String? notes;
  final bool isClosed;
  final String? closeReason;
  const Investment({
    required this.id,
    required this.name,
    required this.type,
    required this.provider,
    this.providerUrl,
    this.specialTag,
    required this.initialAmount,
    required this.currentValue,
    this.targetAmount,
    required this.startDate,
    this.expectedEndDate,
    this.expectedReturn,
    this.folioNo,
    this.units,
    this.brokerName,
    this.linkedAccountNo,
    this.linkedAccountIfsc,
    this.linkedBankName,
    this.purpose,
    this.notes,
    required this.isClosed,
    this.closeReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || providerUrl != null) {
      map['provider_url'] = Variable<String>(providerUrl);
    }
    if (!nullToAbsent || specialTag != null) {
      map['special_tag'] = Variable<String>(specialTag);
    }
    map['initial_amount'] = Variable<double>(initialAmount);
    map['current_value'] = Variable<double>(currentValue);
    if (!nullToAbsent || targetAmount != null) {
      map['target_amount'] = Variable<double>(targetAmount);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || expectedEndDate != null) {
      map['expected_end_date'] = Variable<DateTime>(expectedEndDate);
    }
    if (!nullToAbsent || expectedReturn != null) {
      map['expected_return'] = Variable<double>(expectedReturn);
    }
    if (!nullToAbsent || folioNo != null) {
      map['folio_no'] = Variable<String>(folioNo);
    }
    if (!nullToAbsent || units != null) {
      map['units'] = Variable<double>(units);
    }
    if (!nullToAbsent || brokerName != null) {
      map['broker_name'] = Variable<String>(brokerName);
    }
    if (!nullToAbsent || linkedAccountNo != null) {
      map['linked_account_no'] = Variable<String>(linkedAccountNo);
    }
    if (!nullToAbsent || linkedAccountIfsc != null) {
      map['linked_account_ifsc'] = Variable<String>(linkedAccountIfsc);
    }
    if (!nullToAbsent || linkedBankName != null) {
      map['linked_bank_name'] = Variable<String>(linkedBankName);
    }
    if (!nullToAbsent || purpose != null) {
      map['purpose'] = Variable<String>(purpose);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_closed'] = Variable<bool>(isClosed);
    if (!nullToAbsent || closeReason != null) {
      map['close_reason'] = Variable<String>(closeReason);
    }
    return map;
  }

  InvestmentsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      provider: Value(provider),
      providerUrl: providerUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(providerUrl),
      specialTag: specialTag == null && nullToAbsent
          ? const Value.absent()
          : Value(specialTag),
      initialAmount: Value(initialAmount),
      currentValue: Value(currentValue),
      targetAmount: targetAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(targetAmount),
      startDate: Value(startDate),
      expectedEndDate: expectedEndDate == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedEndDate),
      expectedReturn: expectedReturn == null && nullToAbsent
          ? const Value.absent()
          : Value(expectedReturn),
      folioNo: folioNo == null && nullToAbsent
          ? const Value.absent()
          : Value(folioNo),
      units: units == null && nullToAbsent
          ? const Value.absent()
          : Value(units),
      brokerName: brokerName == null && nullToAbsent
          ? const Value.absent()
          : Value(brokerName),
      linkedAccountNo: linkedAccountNo == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedAccountNo),
      linkedAccountIfsc: linkedAccountIfsc == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedAccountIfsc),
      linkedBankName: linkedBankName == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedBankName),
      purpose: purpose == null && nullToAbsent
          ? const Value.absent()
          : Value(purpose),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isClosed: Value(isClosed),
      closeReason: closeReason == null && nullToAbsent
          ? const Value.absent()
          : Value(closeReason),
    );
  }

  factory Investment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Investment(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      provider: serializer.fromJson<String>(json['provider']),
      providerUrl: serializer.fromJson<String?>(json['providerUrl']),
      specialTag: serializer.fromJson<String?>(json['specialTag']),
      initialAmount: serializer.fromJson<double>(json['initialAmount']),
      currentValue: serializer.fromJson<double>(json['currentValue']),
      targetAmount: serializer.fromJson<double?>(json['targetAmount']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      expectedEndDate: serializer.fromJson<DateTime?>(json['expectedEndDate']),
      expectedReturn: serializer.fromJson<double?>(json['expectedReturn']),
      folioNo: serializer.fromJson<String?>(json['folioNo']),
      units: serializer.fromJson<double?>(json['units']),
      brokerName: serializer.fromJson<String?>(json['brokerName']),
      linkedAccountNo: serializer.fromJson<String?>(json['linkedAccountNo']),
      linkedAccountIfsc: serializer.fromJson<String?>(
        json['linkedAccountIfsc'],
      ),
      linkedBankName: serializer.fromJson<String?>(json['linkedBankName']),
      purpose: serializer.fromJson<String?>(json['purpose']),
      notes: serializer.fromJson<String?>(json['notes']),
      isClosed: serializer.fromJson<bool>(json['isClosed']),
      closeReason: serializer.fromJson<String?>(json['closeReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'provider': serializer.toJson<String>(provider),
      'providerUrl': serializer.toJson<String?>(providerUrl),
      'specialTag': serializer.toJson<String?>(specialTag),
      'initialAmount': serializer.toJson<double>(initialAmount),
      'currentValue': serializer.toJson<double>(currentValue),
      'targetAmount': serializer.toJson<double?>(targetAmount),
      'startDate': serializer.toJson<DateTime>(startDate),
      'expectedEndDate': serializer.toJson<DateTime?>(expectedEndDate),
      'expectedReturn': serializer.toJson<double?>(expectedReturn),
      'folioNo': serializer.toJson<String?>(folioNo),
      'units': serializer.toJson<double?>(units),
      'brokerName': serializer.toJson<String?>(brokerName),
      'linkedAccountNo': serializer.toJson<String?>(linkedAccountNo),
      'linkedAccountIfsc': serializer.toJson<String?>(linkedAccountIfsc),
      'linkedBankName': serializer.toJson<String?>(linkedBankName),
      'purpose': serializer.toJson<String?>(purpose),
      'notes': serializer.toJson<String?>(notes),
      'isClosed': serializer.toJson<bool>(isClosed),
      'closeReason': serializer.toJson<String?>(closeReason),
    };
  }

  Investment copyWith({
    String? id,
    String? name,
    String? type,
    String? provider,
    Value<String?> providerUrl = const Value.absent(),
    Value<String?> specialTag = const Value.absent(),
    double? initialAmount,
    double? currentValue,
    Value<double?> targetAmount = const Value.absent(),
    DateTime? startDate,
    Value<DateTime?> expectedEndDate = const Value.absent(),
    Value<double?> expectedReturn = const Value.absent(),
    Value<String?> folioNo = const Value.absent(),
    Value<double?> units = const Value.absent(),
    Value<String?> brokerName = const Value.absent(),
    Value<String?> linkedAccountNo = const Value.absent(),
    Value<String?> linkedAccountIfsc = const Value.absent(),
    Value<String?> linkedBankName = const Value.absent(),
    Value<String?> purpose = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isClosed,
    Value<String?> closeReason = const Value.absent(),
  }) => Investment(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    provider: provider ?? this.provider,
    providerUrl: providerUrl.present ? providerUrl.value : this.providerUrl,
    specialTag: specialTag.present ? specialTag.value : this.specialTag,
    initialAmount: initialAmount ?? this.initialAmount,
    currentValue: currentValue ?? this.currentValue,
    targetAmount: targetAmount.present ? targetAmount.value : this.targetAmount,
    startDate: startDate ?? this.startDate,
    expectedEndDate: expectedEndDate.present
        ? expectedEndDate.value
        : this.expectedEndDate,
    expectedReturn: expectedReturn.present
        ? expectedReturn.value
        : this.expectedReturn,
    folioNo: folioNo.present ? folioNo.value : this.folioNo,
    units: units.present ? units.value : this.units,
    brokerName: brokerName.present ? brokerName.value : this.brokerName,
    linkedAccountNo: linkedAccountNo.present
        ? linkedAccountNo.value
        : this.linkedAccountNo,
    linkedAccountIfsc: linkedAccountIfsc.present
        ? linkedAccountIfsc.value
        : this.linkedAccountIfsc,
    linkedBankName: linkedBankName.present
        ? linkedBankName.value
        : this.linkedBankName,
    purpose: purpose.present ? purpose.value : this.purpose,
    notes: notes.present ? notes.value : this.notes,
    isClosed: isClosed ?? this.isClosed,
    closeReason: closeReason.present ? closeReason.value : this.closeReason,
  );
  Investment copyWithCompanion(InvestmentsCompanion data) {
    return Investment(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      provider: data.provider.present ? data.provider.value : this.provider,
      providerUrl: data.providerUrl.present
          ? data.providerUrl.value
          : this.providerUrl,
      specialTag: data.specialTag.present
          ? data.specialTag.value
          : this.specialTag,
      initialAmount: data.initialAmount.present
          ? data.initialAmount.value
          : this.initialAmount,
      currentValue: data.currentValue.present
          ? data.currentValue.value
          : this.currentValue,
      targetAmount: data.targetAmount.present
          ? data.targetAmount.value
          : this.targetAmount,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      expectedEndDate: data.expectedEndDate.present
          ? data.expectedEndDate.value
          : this.expectedEndDate,
      expectedReturn: data.expectedReturn.present
          ? data.expectedReturn.value
          : this.expectedReturn,
      folioNo: data.folioNo.present ? data.folioNo.value : this.folioNo,
      units: data.units.present ? data.units.value : this.units,
      brokerName: data.brokerName.present
          ? data.brokerName.value
          : this.brokerName,
      linkedAccountNo: data.linkedAccountNo.present
          ? data.linkedAccountNo.value
          : this.linkedAccountNo,
      linkedAccountIfsc: data.linkedAccountIfsc.present
          ? data.linkedAccountIfsc.value
          : this.linkedAccountIfsc,
      linkedBankName: data.linkedBankName.present
          ? data.linkedBankName.value
          : this.linkedBankName,
      purpose: data.purpose.present ? data.purpose.value : this.purpose,
      notes: data.notes.present ? data.notes.value : this.notes,
      isClosed: data.isClosed.present ? data.isClosed.value : this.isClosed,
      closeReason: data.closeReason.present
          ? data.closeReason.value
          : this.closeReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Investment(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('provider: $provider, ')
          ..write('providerUrl: $providerUrl, ')
          ..write('specialTag: $specialTag, ')
          ..write('initialAmount: $initialAmount, ')
          ..write('currentValue: $currentValue, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('startDate: $startDate, ')
          ..write('expectedEndDate: $expectedEndDate, ')
          ..write('expectedReturn: $expectedReturn, ')
          ..write('folioNo: $folioNo, ')
          ..write('units: $units, ')
          ..write('brokerName: $brokerName, ')
          ..write('linkedAccountNo: $linkedAccountNo, ')
          ..write('linkedAccountIfsc: $linkedAccountIfsc, ')
          ..write('linkedBankName: $linkedBankName, ')
          ..write('purpose: $purpose, ')
          ..write('notes: $notes, ')
          ..write('isClosed: $isClosed, ')
          ..write('closeReason: $closeReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    type,
    provider,
    providerUrl,
    specialTag,
    initialAmount,
    currentValue,
    targetAmount,
    startDate,
    expectedEndDate,
    expectedReturn,
    folioNo,
    units,
    brokerName,
    linkedAccountNo,
    linkedAccountIfsc,
    linkedBankName,
    purpose,
    notes,
    isClosed,
    closeReason,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Investment &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.provider == this.provider &&
          other.providerUrl == this.providerUrl &&
          other.specialTag == this.specialTag &&
          other.initialAmount == this.initialAmount &&
          other.currentValue == this.currentValue &&
          other.targetAmount == this.targetAmount &&
          other.startDate == this.startDate &&
          other.expectedEndDate == this.expectedEndDate &&
          other.expectedReturn == this.expectedReturn &&
          other.folioNo == this.folioNo &&
          other.units == this.units &&
          other.brokerName == this.brokerName &&
          other.linkedAccountNo == this.linkedAccountNo &&
          other.linkedAccountIfsc == this.linkedAccountIfsc &&
          other.linkedBankName == this.linkedBankName &&
          other.purpose == this.purpose &&
          other.notes == this.notes &&
          other.isClosed == this.isClosed &&
          other.closeReason == this.closeReason);
}

class InvestmentsCompanion extends UpdateCompanion<Investment> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String> provider;
  final Value<String?> providerUrl;
  final Value<String?> specialTag;
  final Value<double> initialAmount;
  final Value<double> currentValue;
  final Value<double?> targetAmount;
  final Value<DateTime> startDate;
  final Value<DateTime?> expectedEndDate;
  final Value<double?> expectedReturn;
  final Value<String?> folioNo;
  final Value<double?> units;
  final Value<String?> brokerName;
  final Value<String?> linkedAccountNo;
  final Value<String?> linkedAccountIfsc;
  final Value<String?> linkedBankName;
  final Value<String?> purpose;
  final Value<String?> notes;
  final Value<bool> isClosed;
  final Value<String?> closeReason;
  final Value<int> rowid;
  const InvestmentsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.provider = const Value.absent(),
    this.providerUrl = const Value.absent(),
    this.specialTag = const Value.absent(),
    this.initialAmount = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.targetAmount = const Value.absent(),
    this.startDate = const Value.absent(),
    this.expectedEndDate = const Value.absent(),
    this.expectedReturn = const Value.absent(),
    this.folioNo = const Value.absent(),
    this.units = const Value.absent(),
    this.brokerName = const Value.absent(),
    this.linkedAccountNo = const Value.absent(),
    this.linkedAccountIfsc = const Value.absent(),
    this.linkedBankName = const Value.absent(),
    this.purpose = const Value.absent(),
    this.notes = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.closeReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestmentsCompanion.insert({
    required String id,
    required String name,
    required String type,
    required String provider,
    this.providerUrl = const Value.absent(),
    this.specialTag = const Value.absent(),
    required double initialAmount,
    this.currentValue = const Value.absent(),
    this.targetAmount = const Value.absent(),
    required DateTime startDate,
    this.expectedEndDate = const Value.absent(),
    this.expectedReturn = const Value.absent(),
    this.folioNo = const Value.absent(),
    this.units = const Value.absent(),
    this.brokerName = const Value.absent(),
    this.linkedAccountNo = const Value.absent(),
    this.linkedAccountIfsc = const Value.absent(),
    this.linkedBankName = const Value.absent(),
    this.purpose = const Value.absent(),
    this.notes = const Value.absent(),
    this.isClosed = const Value.absent(),
    this.closeReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       type = Value(type),
       provider = Value(provider),
       initialAmount = Value(initialAmount),
       startDate = Value(startDate);
  static Insertable<Investment> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? provider,
    Expression<String>? providerUrl,
    Expression<String>? specialTag,
    Expression<double>? initialAmount,
    Expression<double>? currentValue,
    Expression<double>? targetAmount,
    Expression<DateTime>? startDate,
    Expression<DateTime>? expectedEndDate,
    Expression<double>? expectedReturn,
    Expression<String>? folioNo,
    Expression<double>? units,
    Expression<String>? brokerName,
    Expression<String>? linkedAccountNo,
    Expression<String>? linkedAccountIfsc,
    Expression<String>? linkedBankName,
    Expression<String>? purpose,
    Expression<String>? notes,
    Expression<bool>? isClosed,
    Expression<String>? closeReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (provider != null) 'provider': provider,
      if (providerUrl != null) 'provider_url': providerUrl,
      if (specialTag != null) 'special_tag': specialTag,
      if (initialAmount != null) 'initial_amount': initialAmount,
      if (currentValue != null) 'current_value': currentValue,
      if (targetAmount != null) 'target_amount': targetAmount,
      if (startDate != null) 'start_date': startDate,
      if (expectedEndDate != null) 'expected_end_date': expectedEndDate,
      if (expectedReturn != null) 'expected_return': expectedReturn,
      if (folioNo != null) 'folio_no': folioNo,
      if (units != null) 'units': units,
      if (brokerName != null) 'broker_name': brokerName,
      if (linkedAccountNo != null) 'linked_account_no': linkedAccountNo,
      if (linkedAccountIfsc != null) 'linked_account_ifsc': linkedAccountIfsc,
      if (linkedBankName != null) 'linked_bank_name': linkedBankName,
      if (purpose != null) 'purpose': purpose,
      if (notes != null) 'notes': notes,
      if (isClosed != null) 'is_closed': isClosed,
      if (closeReason != null) 'close_reason': closeReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String>? provider,
    Value<String?>? providerUrl,
    Value<String?>? specialTag,
    Value<double>? initialAmount,
    Value<double>? currentValue,
    Value<double?>? targetAmount,
    Value<DateTime>? startDate,
    Value<DateTime?>? expectedEndDate,
    Value<double?>? expectedReturn,
    Value<String?>? folioNo,
    Value<double?>? units,
    Value<String?>? brokerName,
    Value<String?>? linkedAccountNo,
    Value<String?>? linkedAccountIfsc,
    Value<String?>? linkedBankName,
    Value<String?>? purpose,
    Value<String?>? notes,
    Value<bool>? isClosed,
    Value<String?>? closeReason,
    Value<int>? rowid,
  }) {
    return InvestmentsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      providerUrl: providerUrl ?? this.providerUrl,
      specialTag: specialTag ?? this.specialTag,
      initialAmount: initialAmount ?? this.initialAmount,
      currentValue: currentValue ?? this.currentValue,
      targetAmount: targetAmount ?? this.targetAmount,
      startDate: startDate ?? this.startDate,
      expectedEndDate: expectedEndDate ?? this.expectedEndDate,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      folioNo: folioNo ?? this.folioNo,
      units: units ?? this.units,
      brokerName: brokerName ?? this.brokerName,
      linkedAccountNo: linkedAccountNo ?? this.linkedAccountNo,
      linkedAccountIfsc: linkedAccountIfsc ?? this.linkedAccountIfsc,
      linkedBankName: linkedBankName ?? this.linkedBankName,
      purpose: purpose ?? this.purpose,
      notes: notes ?? this.notes,
      isClosed: isClosed ?? this.isClosed,
      closeReason: closeReason ?? this.closeReason,
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
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (providerUrl.present) {
      map['provider_url'] = Variable<String>(providerUrl.value);
    }
    if (specialTag.present) {
      map['special_tag'] = Variable<String>(specialTag.value);
    }
    if (initialAmount.present) {
      map['initial_amount'] = Variable<double>(initialAmount.value);
    }
    if (currentValue.present) {
      map['current_value'] = Variable<double>(currentValue.value);
    }
    if (targetAmount.present) {
      map['target_amount'] = Variable<double>(targetAmount.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (expectedEndDate.present) {
      map['expected_end_date'] = Variable<DateTime>(expectedEndDate.value);
    }
    if (expectedReturn.present) {
      map['expected_return'] = Variable<double>(expectedReturn.value);
    }
    if (folioNo.present) {
      map['folio_no'] = Variable<String>(folioNo.value);
    }
    if (units.present) {
      map['units'] = Variable<double>(units.value);
    }
    if (brokerName.present) {
      map['broker_name'] = Variable<String>(brokerName.value);
    }
    if (linkedAccountNo.present) {
      map['linked_account_no'] = Variable<String>(linkedAccountNo.value);
    }
    if (linkedAccountIfsc.present) {
      map['linked_account_ifsc'] = Variable<String>(linkedAccountIfsc.value);
    }
    if (linkedBankName.present) {
      map['linked_bank_name'] = Variable<String>(linkedBankName.value);
    }
    if (purpose.present) {
      map['purpose'] = Variable<String>(purpose.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isClosed.present) {
      map['is_closed'] = Variable<bool>(isClosed.value);
    }
    if (closeReason.present) {
      map['close_reason'] = Variable<String>(closeReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('provider: $provider, ')
          ..write('providerUrl: $providerUrl, ')
          ..write('specialTag: $specialTag, ')
          ..write('initialAmount: $initialAmount, ')
          ..write('currentValue: $currentValue, ')
          ..write('targetAmount: $targetAmount, ')
          ..write('startDate: $startDate, ')
          ..write('expectedEndDate: $expectedEndDate, ')
          ..write('expectedReturn: $expectedReturn, ')
          ..write('folioNo: $folioNo, ')
          ..write('units: $units, ')
          ..write('brokerName: $brokerName, ')
          ..write('linkedAccountNo: $linkedAccountNo, ')
          ..write('linkedAccountIfsc: $linkedAccountIfsc, ')
          ..write('linkedBankName: $linkedBankName, ')
          ..write('purpose: $purpose, ')
          ..write('notes: $notes, ')
          ..write('isClosed: $isClosed, ')
          ..write('closeReason: $closeReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InvestmentLogsTable extends InvestmentLogs
    with TableInfo<$InvestmentLogsTable, InvestmentLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InvestmentLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _investmentIdMeta = const VerificationMeta(
    'investmentId',
  );
  @override
  late final GeneratedColumn<String> investmentId = GeneratedColumn<String>(
    'investment_id',
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
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    investmentId,
    type,
    amount,
    date,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'investment_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<InvestmentLog> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('investment_id')) {
      context.handle(
        _investmentIdMeta,
        investmentId.isAcceptableOrUnknown(
          data['investment_id']!,
          _investmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_investmentIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
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
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InvestmentLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InvestmentLog(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      investmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}investment_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $InvestmentLogsTable createAlias(String alias) {
    return $InvestmentLogsTable(attachedDatabase, alias);
  }
}

class InvestmentLog extends DataClass implements Insertable<InvestmentLog> {
  final String id;
  final String investmentId;
  final String type;
  final double amount;
  final DateTime date;
  final String? notes;
  const InvestmentLog({
    required this.id,
    required this.investmentId,
    required this.type,
    required this.amount,
    required this.date,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['investment_id'] = Variable<String>(investmentId);
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  InvestmentLogsCompanion toCompanion(bool nullToAbsent) {
    return InvestmentLogsCompanion(
      id: Value(id),
      investmentId: Value(investmentId),
      type: Value(type),
      amount: Value(amount),
      date: Value(date),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory InvestmentLog.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InvestmentLog(
      id: serializer.fromJson<String>(json['id']),
      investmentId: serializer.fromJson<String>(json['investmentId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'investmentId': serializer.toJson<String>(investmentId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  InvestmentLog copyWith({
    String? id,
    String? investmentId,
    String? type,
    double? amount,
    DateTime? date,
    Value<String?> notes = const Value.absent(),
  }) => InvestmentLog(
    id: id ?? this.id,
    investmentId: investmentId ?? this.investmentId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    notes: notes.present ? notes.value : this.notes,
  );
  InvestmentLog copyWithCompanion(InvestmentLogsCompanion data) {
    return InvestmentLog(
      id: data.id.present ? data.id.value : this.id,
      investmentId: data.investmentId.present
          ? data.investmentId.value
          : this.investmentId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentLog(')
          ..write('id: $id, ')
          ..write('investmentId: $investmentId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, investmentId, type, amount, date, notes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InvestmentLog &&
          other.id == this.id &&
          other.investmentId == this.investmentId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.notes == this.notes);
}

class InvestmentLogsCompanion extends UpdateCompanion<InvestmentLog> {
  final Value<String> id;
  final Value<String> investmentId;
  final Value<String> type;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String?> notes;
  final Value<int> rowid;
  const InvestmentLogsCompanion({
    this.id = const Value.absent(),
    this.investmentId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InvestmentLogsCompanion.insert({
    required String id,
    required String investmentId,
    required String type,
    required double amount,
    required DateTime date,
    this.notes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       investmentId = Value(investmentId),
       type = Value(type),
       amount = Value(amount),
       date = Value(date);
  static Insertable<InvestmentLog> custom({
    Expression<String>? id,
    Expression<String>? investmentId,
    Expression<String>? type,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? notes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (investmentId != null) 'investment_id': investmentId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InvestmentLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? investmentId,
    Value<String>? type,
    Value<double>? amount,
    Value<DateTime>? date,
    Value<String?>? notes,
    Value<int>? rowid,
  }) {
    return InvestmentLogsCompanion(
      id: id ?? this.id,
      investmentId: investmentId ?? this.investmentId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (investmentId.present) {
      map['investment_id'] = Variable<String>(investmentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InvestmentLogsCompanion(')
          ..write('id: $id, ')
          ..write('investmentId: $investmentId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmartTrackerTemplatesTable extends SmartTrackerTemplates
    with TableInfo<$SmartTrackerTemplatesTable, SmartTrackerTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartTrackerTemplatesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _schemaJsonMeta = const VerificationMeta(
    'schemaJson',
  );
  @override
  late final GeneratedColumn<String> schemaJson = GeneratedColumn<String>(
    'schema_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [id, name, schemaJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_tracker_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartTrackerTemplate> instance, {
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
    if (data.containsKey('schema_json')) {
      context.handle(
        _schemaJsonMeta,
        schemaJson.isAcceptableOrUnknown(data['schema_json']!, _schemaJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_schemaJsonMeta);
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
  SmartTrackerTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartTrackerTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      schemaJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schema_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SmartTrackerTemplatesTable createAlias(String alias) {
    return $SmartTrackerTemplatesTable(attachedDatabase, alias);
  }
}

class SmartTrackerTemplate extends DataClass
    implements Insertable<SmartTrackerTemplate> {
  final String id;
  final String name;
  final String schemaJson;
  final DateTime createdAt;
  const SmartTrackerTemplate({
    required this.id,
    required this.name,
    required this.schemaJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['schema_json'] = Variable<String>(schemaJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SmartTrackerTemplatesCompanion toCompanion(bool nullToAbsent) {
    return SmartTrackerTemplatesCompanion(
      id: Value(id),
      name: Value(name),
      schemaJson: Value(schemaJson),
      createdAt: Value(createdAt),
    );
  }

  factory SmartTrackerTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartTrackerTemplate(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      schemaJson: serializer.fromJson<String>(json['schemaJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'schemaJson': serializer.toJson<String>(schemaJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SmartTrackerTemplate copyWith({
    String? id,
    String? name,
    String? schemaJson,
    DateTime? createdAt,
  }) => SmartTrackerTemplate(
    id: id ?? this.id,
    name: name ?? this.name,
    schemaJson: schemaJson ?? this.schemaJson,
    createdAt: createdAt ?? this.createdAt,
  );
  SmartTrackerTemplate copyWithCompanion(SmartTrackerTemplatesCompanion data) {
    return SmartTrackerTemplate(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      schemaJson: data.schemaJson.present
          ? data.schemaJson.value
          : this.schemaJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartTrackerTemplate(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('schemaJson: $schemaJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, schemaJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartTrackerTemplate &&
          other.id == this.id &&
          other.name == this.name &&
          other.schemaJson == this.schemaJson &&
          other.createdAt == this.createdAt);
}

class SmartTrackerTemplatesCompanion
    extends UpdateCompanion<SmartTrackerTemplate> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> schemaJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SmartTrackerTemplatesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.schemaJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmartTrackerTemplatesCompanion.insert({
    required String id,
    required String name,
    required String schemaJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       schemaJson = Value(schemaJson),
       createdAt = Value(createdAt);
  static Insertable<SmartTrackerTemplate> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? schemaJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (schemaJson != null) 'schema_json': schemaJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmartTrackerTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? schemaJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SmartTrackerTemplatesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      schemaJson: schemaJson ?? this.schemaJson,
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
    if (schemaJson.present) {
      map['schema_json'] = Variable<String>(schemaJson.value);
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
    return (StringBuffer('SmartTrackerTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('schemaJson: $schemaJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmartTrackerRecordsTable extends SmartTrackerRecords
    with TableInfo<$SmartTrackerRecordsTable, SmartTrackerRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmartTrackerRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataJsonMeta = const VerificationMeta(
    'dataJson',
  );
  @override
  late final GeneratedColumn<String> dataJson = GeneratedColumn<String>(
    'data_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  List<GeneratedColumn> get $columns => [id, templateId, dataJson, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'smart_tracker_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmartTrackerRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('data_json')) {
      context.handle(
        _dataJsonMeta,
        dataJson.isAcceptableOrUnknown(data['data_json']!, _dataJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_dataJsonMeta);
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
  SmartTrackerRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmartTrackerRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      dataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SmartTrackerRecordsTable createAlias(String alias) {
    return $SmartTrackerRecordsTable(attachedDatabase, alias);
  }
}

class SmartTrackerRecord extends DataClass
    implements Insertable<SmartTrackerRecord> {
  final String id;
  final String templateId;
  final String dataJson;
  final DateTime createdAt;
  const SmartTrackerRecord({
    required this.id,
    required this.templateId,
    required this.dataJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['template_id'] = Variable<String>(templateId);
    map['data_json'] = Variable<String>(dataJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SmartTrackerRecordsCompanion toCompanion(bool nullToAbsent) {
    return SmartTrackerRecordsCompanion(
      id: Value(id),
      templateId: Value(templateId),
      dataJson: Value(dataJson),
      createdAt: Value(createdAt),
    );
  }

  factory SmartTrackerRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmartTrackerRecord(
      id: serializer.fromJson<String>(json['id']),
      templateId: serializer.fromJson<String>(json['templateId']),
      dataJson: serializer.fromJson<String>(json['dataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'templateId': serializer.toJson<String>(templateId),
      'dataJson': serializer.toJson<String>(dataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SmartTrackerRecord copyWith({
    String? id,
    String? templateId,
    String? dataJson,
    DateTime? createdAt,
  }) => SmartTrackerRecord(
    id: id ?? this.id,
    templateId: templateId ?? this.templateId,
    dataJson: dataJson ?? this.dataJson,
    createdAt: createdAt ?? this.createdAt,
  );
  SmartTrackerRecord copyWithCompanion(SmartTrackerRecordsCompanion data) {
    return SmartTrackerRecord(
      id: data.id.present ? data.id.value : this.id,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      dataJson: data.dataJson.present ? data.dataJson.value : this.dataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmartTrackerRecord(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, templateId, dataJson, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmartTrackerRecord &&
          other.id == this.id &&
          other.templateId == this.templateId &&
          other.dataJson == this.dataJson &&
          other.createdAt == this.createdAt);
}

class SmartTrackerRecordsCompanion extends UpdateCompanion<SmartTrackerRecord> {
  final Value<String> id;
  final Value<String> templateId;
  final Value<String> dataJson;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SmartTrackerRecordsCompanion({
    this.id = const Value.absent(),
    this.templateId = const Value.absent(),
    this.dataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmartTrackerRecordsCompanion.insert({
    required String id,
    required String templateId,
    required String dataJson,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       templateId = Value(templateId),
       dataJson = Value(dataJson),
       createdAt = Value(createdAt);
  static Insertable<SmartTrackerRecord> custom({
    Expression<String>? id,
    Expression<String>? templateId,
    Expression<String>? dataJson,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (templateId != null) 'template_id': templateId,
      if (dataJson != null) 'data_json': dataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmartTrackerRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? templateId,
    Value<String>? dataJson,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SmartTrackerRecordsCompanion(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      dataJson: dataJson ?? this.dataJson,
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
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (dataJson.present) {
      map['data_json'] = Variable<String>(dataJson.value);
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
    return (StringBuffer('SmartTrackerRecordsCompanion(')
          ..write('id: $id, ')
          ..write('templateId: $templateId, ')
          ..write('dataJson: $dataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppNotificationsTable extends AppNotifications
    with TableInfo<$AppNotificationsTable, AppNotification> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppNotificationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _isReadMeta = const VerificationMeta('isRead');
  @override
  late final GeneratedColumn<bool> isRead = GeneratedColumn<bool>(
    'is_read',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_read" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    body,
    payload,
    createdAt,
    isRead,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_notifications';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppNotification> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
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
    if (data.containsKey('is_read')) {
      context.handle(
        _isReadMeta,
        isRead.isAcceptableOrUnknown(data['is_read']!, _isReadMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppNotification map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppNotification(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      isRead: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_read'],
      )!,
    );
  }

  @override
  $AppNotificationsTable createAlias(String alias) {
    return $AppNotificationsTable(attachedDatabase, alias);
  }
}

class AppNotification extends DataClass implements Insertable<AppNotification> {
  final String id;
  final String title;
  final String body;
  final String? payload;
  final DateTime createdAt;
  final bool isRead;
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.payload,
    required this.createdAt,
    required this.isRead,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['body'] = Variable<String>(body);
    if (!nullToAbsent || payload != null) {
      map['payload'] = Variable<String>(payload);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['is_read'] = Variable<bool>(isRead);
    return map;
  }

  AppNotificationsCompanion toCompanion(bool nullToAbsent) {
    return AppNotificationsCompanion(
      id: Value(id),
      title: Value(title),
      body: Value(body),
      payload: payload == null && nullToAbsent
          ? const Value.absent()
          : Value(payload),
      createdAt: Value(createdAt),
      isRead: Value(isRead),
    );
  }

  factory AppNotification.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppNotification(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      body: serializer.fromJson<String>(json['body']),
      payload: serializer.fromJson<String?>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      isRead: serializer.fromJson<bool>(json['isRead']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'body': serializer.toJson<String>(body),
      'payload': serializer.toJson<String?>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'isRead': serializer.toJson<bool>(isRead),
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    Value<String?> payload = const Value.absent(),
    DateTime? createdAt,
    bool? isRead,
  }) => AppNotification(
    id: id ?? this.id,
    title: title ?? this.title,
    body: body ?? this.body,
    payload: payload.present ? payload.value : this.payload,
    createdAt: createdAt ?? this.createdAt,
    isRead: isRead ?? this.isRead,
  );
  AppNotification copyWithCompanion(AppNotificationsCompanion data) {
    return AppNotification(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      body: data.body.present ? data.body.value : this.body,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      isRead: data.isRead.present ? data.isRead.value : this.isRead,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppNotification(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('isRead: $isRead')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, body, payload, createdAt, isRead);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppNotification &&
          other.id == this.id &&
          other.title == this.title &&
          other.body == this.body &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.isRead == this.isRead);
}

class AppNotificationsCompanion extends UpdateCompanion<AppNotification> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> body;
  final Value<String?> payload;
  final Value<DateTime> createdAt;
  final Value<bool> isRead;
  final Value<int> rowid;
  const AppNotificationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.body = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppNotificationsCompanion.insert({
    required String id,
    required String title,
    required String body,
    this.payload = const Value.absent(),
    required DateTime createdAt,
    this.isRead = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       body = Value(body),
       createdAt = Value(createdAt);
  static Insertable<AppNotification> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? body,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<bool>? isRead,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (isRead != null) 'is_read': isRead,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppNotificationsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? body,
    Value<String?>? payload,
    Value<DateTime>? createdAt,
    Value<bool>? isRead,
    Value<int>? rowid,
  }) {
    return AppNotificationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (isRead.present) {
      map['is_read'] = Variable<bool>(isRead.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppNotificationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('isRead: $isRead, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringTransactionRulesTable extends RecurringTransactionRules
    with TableInfo<$RecurringTransactionRulesTable, RecurringTransactionRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringTransactionRulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _serviceWebsiteMeta = const VerificationMeta(
    'serviceWebsite',
  );
  @override
  late final GeneratedColumn<String> serviceWebsite = GeneratedColumn<String>(
    'service_website',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
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
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryNameMeta = const VerificationMeta(
    'categoryName',
  );
  @override
  late final GeneratedColumn<String> categoryName = GeneratedColumn<String>(
    'category_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIconMeta = const VerificationMeta(
    'categoryIcon',
  );
  @override
  late final GeneratedColumn<int> categoryIcon = GeneratedColumn<int>(
    'category_icon',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subCategoryMeta = const VerificationMeta(
    'subCategory',
  );
  @override
  late final GeneratedColumn<String> subCategory = GeneratedColumn<String>(
    'sub_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bucketIdMeta = const VerificationMeta(
    'bucketId',
  );
  @override
  late final GeneratedColumn<int> bucketId = GeneratedColumn<int>(
    'bucket_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bucketNameMeta = const VerificationMeta(
    'bucketName',
  );
  @override
  late final GeneratedColumn<String> bucketName = GeneratedColumn<String>(
    'bucket_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repetitionScheduleMeta =
      const VerificationMeta('repetitionSchedule');
  @override
  late final GeneratedColumn<String> repetitionSchedule =
      GeneratedColumn<String>(
        'repetition_schedule',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _repetitionIntervalMeta =
      const VerificationMeta('repetitionInterval');
  @override
  late final GeneratedColumn<int> repetitionInterval = GeneratedColumn<int>(
    'repetition_interval',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _advancedScheduleMeta = const VerificationMeta(
    'advancedSchedule',
  );
  @override
  late final GeneratedColumn<String> advancedSchedule = GeneratedColumn<String>(
    'advanced_schedule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceTimeMeta = const VerificationMeta(
    'occurrenceTime',
  );
  @override
  late final GeneratedColumn<String> occurrenceTime = GeneratedColumn<String>(
    'occurrence_time',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAutomaticMeta = const VerificationMeta(
    'isAutomatic',
  );
  @override
  late final GeneratedColumn<bool> isAutomatic = GeneratedColumn<bool>(
    'is_automatic',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_automatic" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastExecutedDateMeta = const VerificationMeta(
    'lastExecutedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastExecutedDate =
      GeneratedColumn<DateTime>(
        'last_executed_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _nextExecutionDateMeta = const VerificationMeta(
    'nextExecutionDate',
  );
  @override
  late final GeneratedColumn<DateTime> nextExecutionDate =
      GeneratedColumn<DateTime>(
        'next_execution_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    serviceWebsite,
    amount,
    transactionType,
    accountId,
    toAccountId,
    categoryId,
    categoryName,
    categoryIcon,
    subCategory,
    bucketId,
    bucketName,
    repetitionSchedule,
    repetitionInterval,
    advancedSchedule,
    startDate,
    occurrenceTime,
    isAutomatic,
    lastExecutedDate,
    nextExecutionDate,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_transaction_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringTransactionRule> instance, {
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
    if (data.containsKey('service_website')) {
      context.handle(
        _serviceWebsiteMeta,
        serviceWebsite.isAcceptableOrUnknown(
          data['service_website']!,
          _serviceWebsiteMeta,
        ),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('category_name')) {
      context.handle(
        _categoryNameMeta,
        categoryName.isAcceptableOrUnknown(
          data['category_name']!,
          _categoryNameMeta,
        ),
      );
    }
    if (data.containsKey('category_icon')) {
      context.handle(
        _categoryIconMeta,
        categoryIcon.isAcceptableOrUnknown(
          data['category_icon']!,
          _categoryIconMeta,
        ),
      );
    }
    if (data.containsKey('sub_category')) {
      context.handle(
        _subCategoryMeta,
        subCategory.isAcceptableOrUnknown(
          data['sub_category']!,
          _subCategoryMeta,
        ),
      );
    }
    if (data.containsKey('bucket_id')) {
      context.handle(
        _bucketIdMeta,
        bucketId.isAcceptableOrUnknown(data['bucket_id']!, _bucketIdMeta),
      );
    }
    if (data.containsKey('bucket_name')) {
      context.handle(
        _bucketNameMeta,
        bucketName.isAcceptableOrUnknown(data['bucket_name']!, _bucketNameMeta),
      );
    }
    if (data.containsKey('repetition_schedule')) {
      context.handle(
        _repetitionScheduleMeta,
        repetitionSchedule.isAcceptableOrUnknown(
          data['repetition_schedule']!,
          _repetitionScheduleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repetitionScheduleMeta);
    }
    if (data.containsKey('repetition_interval')) {
      context.handle(
        _repetitionIntervalMeta,
        repetitionInterval.isAcceptableOrUnknown(
          data['repetition_interval']!,
          _repetitionIntervalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_repetitionIntervalMeta);
    }
    if (data.containsKey('advanced_schedule')) {
      context.handle(
        _advancedScheduleMeta,
        advancedSchedule.isAcceptableOrUnknown(
          data['advanced_schedule']!,
          _advancedScheduleMeta,
        ),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('occurrence_time')) {
      context.handle(
        _occurrenceTimeMeta,
        occurrenceTime.isAcceptableOrUnknown(
          data['occurrence_time']!,
          _occurrenceTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceTimeMeta);
    }
    if (data.containsKey('is_automatic')) {
      context.handle(
        _isAutomaticMeta,
        isAutomatic.isAcceptableOrUnknown(
          data['is_automatic']!,
          _isAutomaticMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isAutomaticMeta);
    }
    if (data.containsKey('last_executed_date')) {
      context.handle(
        _lastExecutedDateMeta,
        lastExecutedDate.isAcceptableOrUnknown(
          data['last_executed_date']!,
          _lastExecutedDateMeta,
        ),
      );
    }
    if (data.containsKey('next_execution_date')) {
      context.handle(
        _nextExecutionDateMeta,
        nextExecutionDate.isAcceptableOrUnknown(
          data['next_execution_date']!,
          _nextExecutionDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextExecutionDateMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringTransactionRule map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringTransactionRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      serviceWebsite: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_website'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      categoryName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_name'],
      ),
      categoryIcon: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_icon'],
      ),
      subCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category'],
      ),
      bucketId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bucket_id'],
      ),
      bucketName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bucket_name'],
      ),
      repetitionSchedule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repetition_schedule'],
      )!,
      repetitionInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repetition_interval'],
      )!,
      advancedSchedule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}advanced_schedule'],
      ),
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      occurrenceTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_time'],
      )!,
      isAutomatic: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_automatic'],
      )!,
      lastExecutedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_executed_date'],
      ),
      nextExecutionDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_execution_date'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $RecurringTransactionRulesTable createAlias(String alias) {
    return $RecurringTransactionRulesTable(attachedDatabase, alias);
  }
}

class RecurringTransactionRule extends DataClass
    implements Insertable<RecurringTransactionRule> {
  final String id;
  final String name;
  final String? serviceWebsite;
  final double? amount;
  final String transactionType;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final String? categoryName;
  final int? categoryIcon;
  final String? subCategory;
  final int? bucketId;
  final String? bucketName;
  final String repetitionSchedule;
  final int repetitionInterval;
  final String? advancedSchedule;
  final DateTime startDate;
  final String occurrenceTime;
  final bool isAutomatic;
  final DateTime? lastExecutedDate;
  final DateTime nextExecutionDate;
  final bool isActive;
  const RecurringTransactionRule({
    required this.id,
    required this.name,
    this.serviceWebsite,
    this.amount,
    required this.transactionType,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.subCategory,
    this.bucketId,
    this.bucketName,
    required this.repetitionSchedule,
    required this.repetitionInterval,
    this.advancedSchedule,
    required this.startDate,
    required this.occurrenceTime,
    required this.isAutomatic,
    this.lastExecutedDate,
    required this.nextExecutionDate,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || serviceWebsite != null) {
      map['service_website'] = Variable<String>(serviceWebsite);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    map['transaction_type'] = Variable<String>(transactionType);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || categoryName != null) {
      map['category_name'] = Variable<String>(categoryName);
    }
    if (!nullToAbsent || categoryIcon != null) {
      map['category_icon'] = Variable<int>(categoryIcon);
    }
    if (!nullToAbsent || subCategory != null) {
      map['sub_category'] = Variable<String>(subCategory);
    }
    if (!nullToAbsent || bucketId != null) {
      map['bucket_id'] = Variable<int>(bucketId);
    }
    if (!nullToAbsent || bucketName != null) {
      map['bucket_name'] = Variable<String>(bucketName);
    }
    map['repetition_schedule'] = Variable<String>(repetitionSchedule);
    map['repetition_interval'] = Variable<int>(repetitionInterval);
    if (!nullToAbsent || advancedSchedule != null) {
      map['advanced_schedule'] = Variable<String>(advancedSchedule);
    }
    map['start_date'] = Variable<DateTime>(startDate);
    map['occurrence_time'] = Variable<String>(occurrenceTime);
    map['is_automatic'] = Variable<bool>(isAutomatic);
    if (!nullToAbsent || lastExecutedDate != null) {
      map['last_executed_date'] = Variable<DateTime>(lastExecutedDate);
    }
    map['next_execution_date'] = Variable<DateTime>(nextExecutionDate);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  RecurringTransactionRulesCompanion toCompanion(bool nullToAbsent) {
    return RecurringTransactionRulesCompanion(
      id: Value(id),
      name: Value(name),
      serviceWebsite: serviceWebsite == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceWebsite),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      transactionType: Value(transactionType),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      categoryName: categoryName == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryName),
      categoryIcon: categoryIcon == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryIcon),
      subCategory: subCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(subCategory),
      bucketId: bucketId == null && nullToAbsent
          ? const Value.absent()
          : Value(bucketId),
      bucketName: bucketName == null && nullToAbsent
          ? const Value.absent()
          : Value(bucketName),
      repetitionSchedule: Value(repetitionSchedule),
      repetitionInterval: Value(repetitionInterval),
      advancedSchedule: advancedSchedule == null && nullToAbsent
          ? const Value.absent()
          : Value(advancedSchedule),
      startDate: Value(startDate),
      occurrenceTime: Value(occurrenceTime),
      isAutomatic: Value(isAutomatic),
      lastExecutedDate: lastExecutedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastExecutedDate),
      nextExecutionDate: Value(nextExecutionDate),
      isActive: Value(isActive),
    );
  }

  factory RecurringTransactionRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringTransactionRule(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      serviceWebsite: serializer.fromJson<String?>(json['serviceWebsite']),
      amount: serializer.fromJson<double?>(json['amount']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      accountId: serializer.fromJson<String>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      categoryName: serializer.fromJson<String?>(json['categoryName']),
      categoryIcon: serializer.fromJson<int?>(json['categoryIcon']),
      subCategory: serializer.fromJson<String?>(json['subCategory']),
      bucketId: serializer.fromJson<int?>(json['bucketId']),
      bucketName: serializer.fromJson<String?>(json['bucketName']),
      repetitionSchedule: serializer.fromJson<String>(
        json['repetitionSchedule'],
      ),
      repetitionInterval: serializer.fromJson<int>(json['repetitionInterval']),
      advancedSchedule: serializer.fromJson<String?>(json['advancedSchedule']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      occurrenceTime: serializer.fromJson<String>(json['occurrenceTime']),
      isAutomatic: serializer.fromJson<bool>(json['isAutomatic']),
      lastExecutedDate: serializer.fromJson<DateTime?>(
        json['lastExecutedDate'],
      ),
      nextExecutionDate: serializer.fromJson<DateTime>(
        json['nextExecutionDate'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'serviceWebsite': serializer.toJson<String?>(serviceWebsite),
      'amount': serializer.toJson<double?>(amount),
      'transactionType': serializer.toJson<String>(transactionType),
      'accountId': serializer.toJson<String>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'categoryName': serializer.toJson<String?>(categoryName),
      'categoryIcon': serializer.toJson<int?>(categoryIcon),
      'subCategory': serializer.toJson<String?>(subCategory),
      'bucketId': serializer.toJson<int?>(bucketId),
      'bucketName': serializer.toJson<String?>(bucketName),
      'repetitionSchedule': serializer.toJson<String>(repetitionSchedule),
      'repetitionInterval': serializer.toJson<int>(repetitionInterval),
      'advancedSchedule': serializer.toJson<String?>(advancedSchedule),
      'startDate': serializer.toJson<DateTime>(startDate),
      'occurrenceTime': serializer.toJson<String>(occurrenceTime),
      'isAutomatic': serializer.toJson<bool>(isAutomatic),
      'lastExecutedDate': serializer.toJson<DateTime?>(lastExecutedDate),
      'nextExecutionDate': serializer.toJson<DateTime>(nextExecutionDate),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  RecurringTransactionRule copyWith({
    String? id,
    String? name,
    Value<String?> serviceWebsite = const Value.absent(),
    Value<double?> amount = const Value.absent(),
    String? transactionType,
    String? accountId,
    Value<String?> toAccountId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> categoryName = const Value.absent(),
    Value<int?> categoryIcon = const Value.absent(),
    Value<String?> subCategory = const Value.absent(),
    Value<int?> bucketId = const Value.absent(),
    Value<String?> bucketName = const Value.absent(),
    String? repetitionSchedule,
    int? repetitionInterval,
    Value<String?> advancedSchedule = const Value.absent(),
    DateTime? startDate,
    String? occurrenceTime,
    bool? isAutomatic,
    Value<DateTime?> lastExecutedDate = const Value.absent(),
    DateTime? nextExecutionDate,
    bool? isActive,
  }) => RecurringTransactionRule(
    id: id ?? this.id,
    name: name ?? this.name,
    serviceWebsite: serviceWebsite.present
        ? serviceWebsite.value
        : this.serviceWebsite,
    amount: amount.present ? amount.value : this.amount,
    transactionType: transactionType ?? this.transactionType,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    categoryName: categoryName.present ? categoryName.value : this.categoryName,
    categoryIcon: categoryIcon.present ? categoryIcon.value : this.categoryIcon,
    subCategory: subCategory.present ? subCategory.value : this.subCategory,
    bucketId: bucketId.present ? bucketId.value : this.bucketId,
    bucketName: bucketName.present ? bucketName.value : this.bucketName,
    repetitionSchedule: repetitionSchedule ?? this.repetitionSchedule,
    repetitionInterval: repetitionInterval ?? this.repetitionInterval,
    advancedSchedule: advancedSchedule.present
        ? advancedSchedule.value
        : this.advancedSchedule,
    startDate: startDate ?? this.startDate,
    occurrenceTime: occurrenceTime ?? this.occurrenceTime,
    isAutomatic: isAutomatic ?? this.isAutomatic,
    lastExecutedDate: lastExecutedDate.present
        ? lastExecutedDate.value
        : this.lastExecutedDate,
    nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
    isActive: isActive ?? this.isActive,
  );
  RecurringTransactionRule copyWithCompanion(
    RecurringTransactionRulesCompanion data,
  ) {
    return RecurringTransactionRule(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      serviceWebsite: data.serviceWebsite.present
          ? data.serviceWebsite.value
          : this.serviceWebsite,
      amount: data.amount.present ? data.amount.value : this.amount,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      categoryName: data.categoryName.present
          ? data.categoryName.value
          : this.categoryName,
      categoryIcon: data.categoryIcon.present
          ? data.categoryIcon.value
          : this.categoryIcon,
      subCategory: data.subCategory.present
          ? data.subCategory.value
          : this.subCategory,
      bucketId: data.bucketId.present ? data.bucketId.value : this.bucketId,
      bucketName: data.bucketName.present
          ? data.bucketName.value
          : this.bucketName,
      repetitionSchedule: data.repetitionSchedule.present
          ? data.repetitionSchedule.value
          : this.repetitionSchedule,
      repetitionInterval: data.repetitionInterval.present
          ? data.repetitionInterval.value
          : this.repetitionInterval,
      advancedSchedule: data.advancedSchedule.present
          ? data.advancedSchedule.value
          : this.advancedSchedule,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      occurrenceTime: data.occurrenceTime.present
          ? data.occurrenceTime.value
          : this.occurrenceTime,
      isAutomatic: data.isAutomatic.present
          ? data.isAutomatic.value
          : this.isAutomatic,
      lastExecutedDate: data.lastExecutedDate.present
          ? data.lastExecutedDate.value
          : this.lastExecutedDate,
      nextExecutionDate: data.nextExecutionDate.present
          ? data.nextExecutionDate.value
          : this.nextExecutionDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTransactionRule(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('serviceWebsite: $serviceWebsite, ')
          ..write('amount: $amount, ')
          ..write('transactionType: $transactionType, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('subCategory: $subCategory, ')
          ..write('bucketId: $bucketId, ')
          ..write('bucketName: $bucketName, ')
          ..write('repetitionSchedule: $repetitionSchedule, ')
          ..write('repetitionInterval: $repetitionInterval, ')
          ..write('advancedSchedule: $advancedSchedule, ')
          ..write('startDate: $startDate, ')
          ..write('occurrenceTime: $occurrenceTime, ')
          ..write('isAutomatic: $isAutomatic, ')
          ..write('lastExecutedDate: $lastExecutedDate, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    serviceWebsite,
    amount,
    transactionType,
    accountId,
    toAccountId,
    categoryId,
    categoryName,
    categoryIcon,
    subCategory,
    bucketId,
    bucketName,
    repetitionSchedule,
    repetitionInterval,
    advancedSchedule,
    startDate,
    occurrenceTime,
    isAutomatic,
    lastExecutedDate,
    nextExecutionDate,
    isActive,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringTransactionRule &&
          other.id == this.id &&
          other.name == this.name &&
          other.serviceWebsite == this.serviceWebsite &&
          other.amount == this.amount &&
          other.transactionType == this.transactionType &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId &&
          other.categoryName == this.categoryName &&
          other.categoryIcon == this.categoryIcon &&
          other.subCategory == this.subCategory &&
          other.bucketId == this.bucketId &&
          other.bucketName == this.bucketName &&
          other.repetitionSchedule == this.repetitionSchedule &&
          other.repetitionInterval == this.repetitionInterval &&
          other.advancedSchedule == this.advancedSchedule &&
          other.startDate == this.startDate &&
          other.occurrenceTime == this.occurrenceTime &&
          other.isAutomatic == this.isAutomatic &&
          other.lastExecutedDate == this.lastExecutedDate &&
          other.nextExecutionDate == this.nextExecutionDate &&
          other.isActive == this.isActive);
}

class RecurringTransactionRulesCompanion
    extends UpdateCompanion<RecurringTransactionRule> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> serviceWebsite;
  final Value<double?> amount;
  final Value<String> transactionType;
  final Value<String> accountId;
  final Value<String?> toAccountId;
  final Value<String?> categoryId;
  final Value<String?> categoryName;
  final Value<int?> categoryIcon;
  final Value<String?> subCategory;
  final Value<int?> bucketId;
  final Value<String?> bucketName;
  final Value<String> repetitionSchedule;
  final Value<int> repetitionInterval;
  final Value<String?> advancedSchedule;
  final Value<DateTime> startDate;
  final Value<String> occurrenceTime;
  final Value<bool> isAutomatic;
  final Value<DateTime?> lastExecutedDate;
  final Value<DateTime> nextExecutionDate;
  final Value<bool> isActive;
  final Value<int> rowid;
  const RecurringTransactionRulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.serviceWebsite = const Value.absent(),
    this.amount = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.bucketId = const Value.absent(),
    this.bucketName = const Value.absent(),
    this.repetitionSchedule = const Value.absent(),
    this.repetitionInterval = const Value.absent(),
    this.advancedSchedule = const Value.absent(),
    this.startDate = const Value.absent(),
    this.occurrenceTime = const Value.absent(),
    this.isAutomatic = const Value.absent(),
    this.lastExecutedDate = const Value.absent(),
    this.nextExecutionDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringTransactionRulesCompanion.insert({
    required String id,
    required String name,
    this.serviceWebsite = const Value.absent(),
    this.amount = const Value.absent(),
    required String transactionType,
    required String accountId,
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.categoryName = const Value.absent(),
    this.categoryIcon = const Value.absent(),
    this.subCategory = const Value.absent(),
    this.bucketId = const Value.absent(),
    this.bucketName = const Value.absent(),
    required String repetitionSchedule,
    required int repetitionInterval,
    this.advancedSchedule = const Value.absent(),
    required DateTime startDate,
    required String occurrenceTime,
    required bool isAutomatic,
    this.lastExecutedDate = const Value.absent(),
    required DateTime nextExecutionDate,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       transactionType = Value(transactionType),
       accountId = Value(accountId),
       repetitionSchedule = Value(repetitionSchedule),
       repetitionInterval = Value(repetitionInterval),
       startDate = Value(startDate),
       occurrenceTime = Value(occurrenceTime),
       isAutomatic = Value(isAutomatic),
       nextExecutionDate = Value(nextExecutionDate);
  static Insertable<RecurringTransactionRule> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? serviceWebsite,
    Expression<double>? amount,
    Expression<String>? transactionType,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? categoryId,
    Expression<String>? categoryName,
    Expression<int>? categoryIcon,
    Expression<String>? subCategory,
    Expression<int>? bucketId,
    Expression<String>? bucketName,
    Expression<String>? repetitionSchedule,
    Expression<int>? repetitionInterval,
    Expression<String>? advancedSchedule,
    Expression<DateTime>? startDate,
    Expression<String>? occurrenceTime,
    Expression<bool>? isAutomatic,
    Expression<DateTime>? lastExecutedDate,
    Expression<DateTime>? nextExecutionDate,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (serviceWebsite != null) 'service_website': serviceWebsite,
      if (amount != null) 'amount': amount,
      if (transactionType != null) 'transaction_type': transactionType,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (categoryName != null) 'category_name': categoryName,
      if (categoryIcon != null) 'category_icon': categoryIcon,
      if (subCategory != null) 'sub_category': subCategory,
      if (bucketId != null) 'bucket_id': bucketId,
      if (bucketName != null) 'bucket_name': bucketName,
      if (repetitionSchedule != null) 'repetition_schedule': repetitionSchedule,
      if (repetitionInterval != null) 'repetition_interval': repetitionInterval,
      if (advancedSchedule != null) 'advanced_schedule': advancedSchedule,
      if (startDate != null) 'start_date': startDate,
      if (occurrenceTime != null) 'occurrence_time': occurrenceTime,
      if (isAutomatic != null) 'is_automatic': isAutomatic,
      if (lastExecutedDate != null) 'last_executed_date': lastExecutedDate,
      if (nextExecutionDate != null) 'next_execution_date': nextExecutionDate,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringTransactionRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? serviceWebsite,
    Value<double?>? amount,
    Value<String>? transactionType,
    Value<String>? accountId,
    Value<String?>? toAccountId,
    Value<String?>? categoryId,
    Value<String?>? categoryName,
    Value<int?>? categoryIcon,
    Value<String?>? subCategory,
    Value<int?>? bucketId,
    Value<String?>? bucketName,
    Value<String>? repetitionSchedule,
    Value<int>? repetitionInterval,
    Value<String?>? advancedSchedule,
    Value<DateTime>? startDate,
    Value<String>? occurrenceTime,
    Value<bool>? isAutomatic,
    Value<DateTime?>? lastExecutedDate,
    Value<DateTime>? nextExecutionDate,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return RecurringTransactionRulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceWebsite: serviceWebsite ?? this.serviceWebsite,
      amount: amount ?? this.amount,
      transactionType: transactionType ?? this.transactionType,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      subCategory: subCategory ?? this.subCategory,
      bucketId: bucketId ?? this.bucketId,
      bucketName: bucketName ?? this.bucketName,
      repetitionSchedule: repetitionSchedule ?? this.repetitionSchedule,
      repetitionInterval: repetitionInterval ?? this.repetitionInterval,
      advancedSchedule: advancedSchedule ?? this.advancedSchedule,
      startDate: startDate ?? this.startDate,
      occurrenceTime: occurrenceTime ?? this.occurrenceTime,
      isAutomatic: isAutomatic ?? this.isAutomatic,
      lastExecutedDate: lastExecutedDate ?? this.lastExecutedDate,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      isActive: isActive ?? this.isActive,
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
    if (serviceWebsite.present) {
      map['service_website'] = Variable<String>(serviceWebsite.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (categoryName.present) {
      map['category_name'] = Variable<String>(categoryName.value);
    }
    if (categoryIcon.present) {
      map['category_icon'] = Variable<int>(categoryIcon.value);
    }
    if (subCategory.present) {
      map['sub_category'] = Variable<String>(subCategory.value);
    }
    if (bucketId.present) {
      map['bucket_id'] = Variable<int>(bucketId.value);
    }
    if (bucketName.present) {
      map['bucket_name'] = Variable<String>(bucketName.value);
    }
    if (repetitionSchedule.present) {
      map['repetition_schedule'] = Variable<String>(repetitionSchedule.value);
    }
    if (repetitionInterval.present) {
      map['repetition_interval'] = Variable<int>(repetitionInterval.value);
    }
    if (advancedSchedule.present) {
      map['advanced_schedule'] = Variable<String>(advancedSchedule.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (occurrenceTime.present) {
      map['occurrence_time'] = Variable<String>(occurrenceTime.value);
    }
    if (isAutomatic.present) {
      map['is_automatic'] = Variable<bool>(isAutomatic.value);
    }
    if (lastExecutedDate.present) {
      map['last_executed_date'] = Variable<DateTime>(lastExecutedDate.value);
    }
    if (nextExecutionDate.present) {
      map['next_execution_date'] = Variable<DateTime>(nextExecutionDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringTransactionRulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('serviceWebsite: $serviceWebsite, ')
          ..write('amount: $amount, ')
          ..write('transactionType: $transactionType, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('categoryName: $categoryName, ')
          ..write('categoryIcon: $categoryIcon, ')
          ..write('subCategory: $subCategory, ')
          ..write('bucketId: $bucketId, ')
          ..write('bucketName: $bucketName, ')
          ..write('repetitionSchedule: $repetitionSchedule, ')
          ..write('repetitionInterval: $repetitionInterval, ')
          ..write('advancedSchedule: $advancedSchedule, ')
          ..write('startDate: $startDate, ')
          ..write('occurrenceTime: $occurrenceTime, ')
          ..write('isAutomatic: $isAutomatic, ')
          ..write('lastExecutedDate: $lastExecutedDate, ')
          ..write('nextExecutionDate: $nextExecutionDate, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripsTable extends Trips with TableInfo<$TripsTable, Trip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _budgetMeta = const VerificationMeta('budget');
  @override
  late final GeneratedColumn<double> budget = GeneratedColumn<double>(
    'budget',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodsJsonMeta = const VerificationMeta(
    'periodsJson',
  );
  @override
  late final GeneratedColumn<String> periodsJson = GeneratedColumn<String>(
    'periods_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _excludedTxIdsJsonMeta = const VerificationMeta(
    'excludedTxIdsJson',
  );
  @override
  late final GeneratedColumn<String> excludedTxIdsJson =
      GeneratedColumn<String>(
        'excluded_tx_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    budget,
    notes,
    status,
    periodsJson,
    excludedTxIdsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Trip> instance, {
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
    if (data.containsKey('budget')) {
      context.handle(
        _budgetMeta,
        budget.isAcceptableOrUnknown(data['budget']!, _budgetMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('periods_json')) {
      context.handle(
        _periodsJsonMeta,
        periodsJson.isAcceptableOrUnknown(
          data['periods_json']!,
          _periodsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_periodsJsonMeta);
    }
    if (data.containsKey('excluded_tx_ids_json')) {
      context.handle(
        _excludedTxIdsJsonMeta,
        excludedTxIdsJson.isAcceptableOrUnknown(
          data['excluded_tx_ids_json']!,
          _excludedTxIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_excludedTxIdsJsonMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Trip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Trip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      budget: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}budget'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      periodsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}periods_json'],
      )!,
      excludedTxIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}excluded_tx_ids_json'],
      )!,
    );
  }

  @override
  $TripsTable createAlias(String alias) {
    return $TripsTable(attachedDatabase, alias);
  }
}

class Trip extends DataClass implements Insertable<Trip> {
  final String id;
  final String name;
  final double? budget;
  final String? notes;
  final String status;
  final String periodsJson;
  final String excludedTxIdsJson;
  const Trip({
    required this.id,
    required this.name,
    this.budget,
    this.notes,
    required this.status,
    required this.periodsJson,
    required this.excludedTxIdsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || budget != null) {
      map['budget'] = Variable<double>(budget);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['status'] = Variable<String>(status);
    map['periods_json'] = Variable<String>(periodsJson);
    map['excluded_tx_ids_json'] = Variable<String>(excludedTxIdsJson);
    return map;
  }

  TripsCompanion toCompanion(bool nullToAbsent) {
    return TripsCompanion(
      id: Value(id),
      name: Value(name),
      budget: budget == null && nullToAbsent
          ? const Value.absent()
          : Value(budget),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      status: Value(status),
      periodsJson: Value(periodsJson),
      excludedTxIdsJson: Value(excludedTxIdsJson),
    );
  }

  factory Trip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Trip(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      budget: serializer.fromJson<double?>(json['budget']),
      notes: serializer.fromJson<String?>(json['notes']),
      status: serializer.fromJson<String>(json['status']),
      periodsJson: serializer.fromJson<String>(json['periodsJson']),
      excludedTxIdsJson: serializer.fromJson<String>(json['excludedTxIdsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'budget': serializer.toJson<double?>(budget),
      'notes': serializer.toJson<String?>(notes),
      'status': serializer.toJson<String>(status),
      'periodsJson': serializer.toJson<String>(periodsJson),
      'excludedTxIdsJson': serializer.toJson<String>(excludedTxIdsJson),
    };
  }

  Trip copyWith({
    String? id,
    String? name,
    Value<double?> budget = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    String? status,
    String? periodsJson,
    String? excludedTxIdsJson,
  }) => Trip(
    id: id ?? this.id,
    name: name ?? this.name,
    budget: budget.present ? budget.value : this.budget,
    notes: notes.present ? notes.value : this.notes,
    status: status ?? this.status,
    periodsJson: periodsJson ?? this.periodsJson,
    excludedTxIdsJson: excludedTxIdsJson ?? this.excludedTxIdsJson,
  );
  Trip copyWithCompanion(TripsCompanion data) {
    return Trip(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      budget: data.budget.present ? data.budget.value : this.budget,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      periodsJson: data.periodsJson.present
          ? data.periodsJson.value
          : this.periodsJson,
      excludedTxIdsJson: data.excludedTxIdsJson.present
          ? data.excludedTxIdsJson.value
          : this.excludedTxIdsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Trip(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('budget: $budget, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('periodsJson: $periodsJson, ')
          ..write('excludedTxIdsJson: $excludedTxIdsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    budget,
    notes,
    status,
    periodsJson,
    excludedTxIdsJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Trip &&
          other.id == this.id &&
          other.name == this.name &&
          other.budget == this.budget &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.periodsJson == this.periodsJson &&
          other.excludedTxIdsJson == this.excludedTxIdsJson);
}

class TripsCompanion extends UpdateCompanion<Trip> {
  final Value<String> id;
  final Value<String> name;
  final Value<double?> budget;
  final Value<String?> notes;
  final Value<String> status;
  final Value<String> periodsJson;
  final Value<String> excludedTxIdsJson;
  final Value<int> rowid;
  const TripsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.budget = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.periodsJson = const Value.absent(),
    this.excludedTxIdsJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripsCompanion.insert({
    required String id,
    required String name,
    this.budget = const Value.absent(),
    this.notes = const Value.absent(),
    required String status,
    required String periodsJson,
    required String excludedTxIdsJson,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       status = Value(status),
       periodsJson = Value(periodsJson),
       excludedTxIdsJson = Value(excludedTxIdsJson);
  static Insertable<Trip> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<double>? budget,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<String>? periodsJson,
    Expression<String>? excludedTxIdsJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (budget != null) 'budget': budget,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (periodsJson != null) 'periods_json': periodsJson,
      if (excludedTxIdsJson != null) 'excluded_tx_ids_json': excludedTxIdsJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<double?>? budget,
    Value<String?>? notes,
    Value<String>? status,
    Value<String>? periodsJson,
    Value<String>? excludedTxIdsJson,
    Value<int>? rowid,
  }) {
    return TripsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      budget: budget ?? this.budget,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      periodsJson: periodsJson ?? this.periodsJson,
      excludedTxIdsJson: excludedTxIdsJson ?? this.excludedTxIdsJson,
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
    if (budget.present) {
      map['budget'] = Variable<double>(budget.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (periodsJson.present) {
      map['periods_json'] = Variable<String>(periodsJson.value);
    }
    if (excludedTxIdsJson.present) {
      map['excluded_tx_ids_json'] = Variable<String>(excludedTxIdsJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('budget: $budget, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('periodsJson: $periodsJson, ')
          ..write('excludedTxIdsJson: $excludedTxIdsJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RemindersTable extends Reminders
    with TableInfo<$RemindersTable, Reminder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
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
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPushEnabledMeta = const VerificationMeta(
    'isPushEnabled',
  );
  @override
  late final GeneratedColumn<bool> isPushEnabled = GeneratedColumn<bool>(
    'is_push_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_push_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _priorDaysMeta = const VerificationMeta(
    'priorDays',
  );
  @override
  late final GeneratedColumn<int> priorDays = GeneratedColumn<int>(
    'prior_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationIdMeta = const VerificationMeta(
    'notificationId',
  );
  @override
  late final GeneratedColumn<int> notificationId = GeneratedColumn<int>(
    'notification_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    notes,
    targetDate,
    isPushEnabled,
    priorDays,
    notificationId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(
    Insertable<Reminder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    } else if (isInserting) {
      context.missing(_targetDateMeta);
    }
    if (data.containsKey('is_push_enabled')) {
      context.handle(
        _isPushEnabledMeta,
        isPushEnabled.isAcceptableOrUnknown(
          data['is_push_enabled']!,
          _isPushEnabledMeta,
        ),
      );
    }
    if (data.containsKey('prior_days')) {
      context.handle(
        _priorDaysMeta,
        priorDays.isAcceptableOrUnknown(data['prior_days']!, _priorDaysMeta),
      );
    }
    if (data.containsKey('notification_id')) {
      context.handle(
        _notificationIdMeta,
        notificationId.isAcceptableOrUnknown(
          data['notification_id']!,
          _notificationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_notificationIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Reminder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Reminder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      )!,
      isPushEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_push_enabled'],
      )!,
      priorDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prior_days'],
      ),
      notificationId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_id'],
      )!,
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }
}

class Reminder extends DataClass implements Insertable<Reminder> {
  final String id;
  final String title;
  final String? notes;
  final DateTime targetDate;
  final bool isPushEnabled;
  final int? priorDays;
  final int notificationId;
  const Reminder({
    required this.id,
    required this.title,
    this.notes,
    required this.targetDate,
    required this.isPushEnabled,
    this.priorDays,
    required this.notificationId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['target_date'] = Variable<DateTime>(targetDate);
    map['is_push_enabled'] = Variable<bool>(isPushEnabled);
    if (!nullToAbsent || priorDays != null) {
      map['prior_days'] = Variable<int>(priorDays);
    }
    map['notification_id'] = Variable<int>(notificationId);
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      targetDate: Value(targetDate),
      isPushEnabled: Value(isPushEnabled),
      priorDays: priorDays == null && nullToAbsent
          ? const Value.absent()
          : Value(priorDays),
      notificationId: Value(notificationId),
    );
  }

  factory Reminder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Reminder(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      targetDate: serializer.fromJson<DateTime>(json['targetDate']),
      isPushEnabled: serializer.fromJson<bool>(json['isPushEnabled']),
      priorDays: serializer.fromJson<int?>(json['priorDays']),
      notificationId: serializer.fromJson<int>(json['notificationId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'targetDate': serializer.toJson<DateTime>(targetDate),
      'isPushEnabled': serializer.toJson<bool>(isPushEnabled),
      'priorDays': serializer.toJson<int?>(priorDays),
      'notificationId': serializer.toJson<int>(notificationId),
    };
  }

  Reminder copyWith({
    String? id,
    String? title,
    Value<String?> notes = const Value.absent(),
    DateTime? targetDate,
    bool? isPushEnabled,
    Value<int?> priorDays = const Value.absent(),
    int? notificationId,
  }) => Reminder(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    targetDate: targetDate ?? this.targetDate,
    isPushEnabled: isPushEnabled ?? this.isPushEnabled,
    priorDays: priorDays.present ? priorDays.value : this.priorDays,
    notificationId: notificationId ?? this.notificationId,
  );
  Reminder copyWithCompanion(RemindersCompanion data) {
    return Reminder(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      isPushEnabled: data.isPushEnabled.present
          ? data.isPushEnabled.value
          : this.isPushEnabled,
      priorDays: data.priorDays.present ? data.priorDays.value : this.priorDays,
      notificationId: data.notificationId.present
          ? data.notificationId.value
          : this.notificationId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Reminder(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('targetDate: $targetDate, ')
          ..write('isPushEnabled: $isPushEnabled, ')
          ..write('priorDays: $priorDays, ')
          ..write('notificationId: $notificationId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    notes,
    targetDate,
    isPushEnabled,
    priorDays,
    notificationId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Reminder &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.targetDate == this.targetDate &&
          other.isPushEnabled == this.isPushEnabled &&
          other.priorDays == this.priorDays &&
          other.notificationId == this.notificationId);
}

class RemindersCompanion extends UpdateCompanion<Reminder> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> notes;
  final Value<DateTime> targetDate;
  final Value<bool> isPushEnabled;
  final Value<int?> priorDays;
  final Value<int> notificationId;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.isPushEnabled = const Value.absent(),
    this.priorDays = const Value.absent(),
    this.notificationId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required String title,
    this.notes = const Value.absent(),
    required DateTime targetDate,
    this.isPushEnabled = const Value.absent(),
    this.priorDays = const Value.absent(),
    required int notificationId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       targetDate = Value(targetDate),
       notificationId = Value(notificationId);
  static Insertable<Reminder> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<DateTime>? targetDate,
    Expression<bool>? isPushEnabled,
    Expression<int>? priorDays,
    Expression<int>? notificationId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (targetDate != null) 'target_date': targetDate,
      if (isPushEnabled != null) 'is_push_enabled': isPushEnabled,
      if (priorDays != null) 'prior_days': priorDays,
      if (notificationId != null) 'notification_id': notificationId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? notes,
    Value<DateTime>? targetDate,
    Value<bool>? isPushEnabled,
    Value<int?>? priorDays,
    Value<int>? notificationId,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      targetDate: targetDate ?? this.targetDate,
      isPushEnabled: isPushEnabled ?? this.isPushEnabled,
      priorDays: priorDays ?? this.priorDays,
      notificationId: notificationId ?? this.notificationId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (isPushEnabled.present) {
      map['is_push_enabled'] = Variable<bool>(isPushEnabled.value);
    }
    if (priorDays.present) {
      map['prior_days'] = Variable<int>(priorDays.value);
    }
    if (notificationId.present) {
      map['notification_id'] = Variable<int>(notificationId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('targetDate: $targetDate, ')
          ..write('isPushEnabled: $isPushEnabled, ')
          ..write('priorDays: $priorDays, ')
          ..write('notificationId: $notificationId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VaultRecordsTable extends VaultRecords
    with TableInfo<$VaultRecordsTable, VaultRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VaultRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordTypeMeta = const VerificationMeta(
    'recordType',
  );
  @override
  late final GeneratedColumn<String> recordType = GeneratedColumn<String>(
    'record_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordNameMeta = const VerificationMeta(
    'recordName',
  );
  @override
  late final GeneratedColumn<String> recordName = GeneratedColumn<String>(
    'record_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _encryptedPayloadMeta = const VerificationMeta(
    'encryptedPayload',
  );
  @override
  late final GeneratedColumn<String> encryptedPayload = GeneratedColumn<String>(
    'encrypted_payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    recordType,
    recordName,
    encryptedPayload,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('record_type')) {
      context.handle(
        _recordTypeMeta,
        recordType.isAcceptableOrUnknown(data['record_type']!, _recordTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_recordTypeMeta);
    }
    if (data.containsKey('record_name')) {
      context.handle(
        _recordNameMeta,
        recordName.isAcceptableOrUnknown(data['record_name']!, _recordNameMeta),
      );
    } else if (isInserting) {
      context.missing(_recordNameMeta);
    }
    if (data.containsKey('encrypted_payload')) {
      context.handle(
        _encryptedPayloadMeta,
        encryptedPayload.isAcceptableOrUnknown(
          data['encrypted_payload']!,
          _encryptedPayloadMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_encryptedPayloadMeta);
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
  VaultRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recordType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_type'],
      )!,
      recordName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_name'],
      )!,
      encryptedPayload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}encrypted_payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $VaultRecordsTable createAlias(String alias) {
    return $VaultRecordsTable(attachedDatabase, alias);
  }
}

class VaultRecord extends DataClass implements Insertable<VaultRecord> {
  final String id;
  final String recordType;
  final String recordName;
  final String encryptedPayload;
  final DateTime createdAt;
  const VaultRecord({
    required this.id,
    required this.recordType,
    required this.recordName,
    required this.encryptedPayload,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['record_type'] = Variable<String>(recordType);
    map['record_name'] = Variable<String>(recordName);
    map['encrypted_payload'] = Variable<String>(encryptedPayload);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  VaultRecordsCompanion toCompanion(bool nullToAbsent) {
    return VaultRecordsCompanion(
      id: Value(id),
      recordType: Value(recordType),
      recordName: Value(recordName),
      encryptedPayload: Value(encryptedPayload),
      createdAt: Value(createdAt),
    );
  }

  factory VaultRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultRecord(
      id: serializer.fromJson<String>(json['id']),
      recordType: serializer.fromJson<String>(json['recordType']),
      recordName: serializer.fromJson<String>(json['recordName']),
      encryptedPayload: serializer.fromJson<String>(json['encryptedPayload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recordType': serializer.toJson<String>(recordType),
      'recordName': serializer.toJson<String>(recordName),
      'encryptedPayload': serializer.toJson<String>(encryptedPayload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  VaultRecord copyWith({
    String? id,
    String? recordType,
    String? recordName,
    String? encryptedPayload,
    DateTime? createdAt,
  }) => VaultRecord(
    id: id ?? this.id,
    recordType: recordType ?? this.recordType,
    recordName: recordName ?? this.recordName,
    encryptedPayload: encryptedPayload ?? this.encryptedPayload,
    createdAt: createdAt ?? this.createdAt,
  );
  VaultRecord copyWithCompanion(VaultRecordsCompanion data) {
    return VaultRecord(
      id: data.id.present ? data.id.value : this.id,
      recordType: data.recordType.present
          ? data.recordType.value
          : this.recordType,
      recordName: data.recordName.present
          ? data.recordName.value
          : this.recordName,
      encryptedPayload: data.encryptedPayload.present
          ? data.encryptedPayload.value
          : this.encryptedPayload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultRecord(')
          ..write('id: $id, ')
          ..write('recordType: $recordType, ')
          ..write('recordName: $recordName, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, recordType, recordName, encryptedPayload, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultRecord &&
          other.id == this.id &&
          other.recordType == this.recordType &&
          other.recordName == this.recordName &&
          other.encryptedPayload == this.encryptedPayload &&
          other.createdAt == this.createdAt);
}

class VaultRecordsCompanion extends UpdateCompanion<VaultRecord> {
  final Value<String> id;
  final Value<String> recordType;
  final Value<String> recordName;
  final Value<String> encryptedPayload;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const VaultRecordsCompanion({
    this.id = const Value.absent(),
    this.recordType = const Value.absent(),
    this.recordName = const Value.absent(),
    this.encryptedPayload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VaultRecordsCompanion.insert({
    required String id,
    required String recordType,
    required String recordName,
    required String encryptedPayload,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       recordType = Value(recordType),
       recordName = Value(recordName),
       encryptedPayload = Value(encryptedPayload),
       createdAt = Value(createdAt);
  static Insertable<VaultRecord> custom({
    Expression<String>? id,
    Expression<String>? recordType,
    Expression<String>? recordName,
    Expression<String>? encryptedPayload,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recordType != null) 'record_type': recordType,
      if (recordName != null) 'record_name': recordName,
      if (encryptedPayload != null) 'encrypted_payload': encryptedPayload,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VaultRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? recordType,
    Value<String>? recordName,
    Value<String>? encryptedPayload,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return VaultRecordsCompanion(
      id: id ?? this.id,
      recordType: recordType ?? this.recordType,
      recordName: recordName ?? this.recordName,
      encryptedPayload: encryptedPayload ?? this.encryptedPayload,
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
    if (recordType.present) {
      map['record_type'] = Variable<String>(recordType.value);
    }
    if (recordName.present) {
      map['record_name'] = Variable<String>(recordName.value);
    }
    if (encryptedPayload.present) {
      map['encrypted_payload'] = Variable<String>(encryptedPayload.value);
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
    return (StringBuffer('VaultRecordsCompanion(')
          ..write('id: $id, ')
          ..write('recordType: $recordType, ')
          ..write('recordName: $recordName, ')
          ..write('encryptedPayload: $encryptedPayload, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StagedTransactionsTable extends StagedTransactions
    with TableInfo<$StagedTransactionsTable, StagedTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StagedTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rawTextMeta = const VerificationMeta(
    'rawText',
  );
  @override
  late final GeneratedColumn<String> rawText = GeneratedColumn<String>(
    'raw_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _extractedAmountMeta = const VerificationMeta(
    'extractedAmount',
  );
  @override
  late final GeneratedColumn<double> extractedAmount = GeneratedColumn<double>(
    'extracted_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _inferredTypeMeta = const VerificationMeta(
    'inferredType',
  );
  @override
  late final GeneratedColumn<String> inferredType = GeneratedColumn<String>(
    'inferred_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountLast4Meta = const VerificationMeta(
    'accountLast4',
  );
  @override
  late final GeneratedColumn<String> accountLast4 = GeneratedColumn<String>(
    'account_last4',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _referenceNoMeta = const VerificationMeta(
    'referenceNo',
  );
  @override
  late final GeneratedColumn<String> referenceNo = GeneratedColumn<String>(
    'reference_no',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantNameMeta = const VerificationMeta(
    'merchantName',
  );
  @override
  late final GeneratedColumn<String> merchantName = GeneratedColumn<String>(
    'merchant_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
  static const VerificationMeta _isApprovedMeta = const VerificationMeta(
    'isApproved',
  );
  @override
  late final GeneratedColumn<bool> isApproved = GeneratedColumn<bool>(
    'is_approved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_approved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rawText,
    sourceName,
    packageName,
    extractedAmount,
    inferredType,
    accountLast4,
    referenceNo,
    merchantName,
    date,
    isApproved,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'staged_transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<StagedTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceNameMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('extracted_amount')) {
      context.handle(
        _extractedAmountMeta,
        extractedAmount.isAcceptableOrUnknown(
          data['extracted_amount']!,
          _extractedAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_extractedAmountMeta);
    }
    if (data.containsKey('inferred_type')) {
      context.handle(
        _inferredTypeMeta,
        inferredType.isAcceptableOrUnknown(
          data['inferred_type']!,
          _inferredTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inferredTypeMeta);
    }
    if (data.containsKey('account_last4')) {
      context.handle(
        _accountLast4Meta,
        accountLast4.isAcceptableOrUnknown(
          data['account_last4']!,
          _accountLast4Meta,
        ),
      );
    }
    if (data.containsKey('reference_no')) {
      context.handle(
        _referenceNoMeta,
        referenceNo.isAcceptableOrUnknown(
          data['reference_no']!,
          _referenceNoMeta,
        ),
      );
    }
    if (data.containsKey('merchant_name')) {
      context.handle(
        _merchantNameMeta,
        merchantName.isAcceptableOrUnknown(
          data['merchant_name']!,
          _merchantNameMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('is_approved')) {
      context.handle(
        _isApprovedMeta,
        isApproved.isAcceptableOrUnknown(data['is_approved']!, _isApprovedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StagedTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StagedTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      extractedAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}extracted_amount'],
      )!,
      inferredType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}inferred_type'],
      )!,
      accountLast4: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_last4'],
      ),
      referenceNo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reference_no'],
      ),
      merchantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant_name'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      isApproved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_approved'],
      )!,
    );
  }

  @override
  $StagedTransactionsTable createAlias(String alias) {
    return $StagedTransactionsTable(attachedDatabase, alias);
  }
}

class StagedTransaction extends DataClass
    implements Insertable<StagedTransaction> {
  final String id;
  final String rawText;
  final String sourceName;
  final String packageName;
  final double extractedAmount;
  final String inferredType;
  final String? accountLast4;
  final String? referenceNo;
  final String? merchantName;
  final DateTime date;
  final bool isApproved;
  const StagedTransaction({
    required this.id,
    required this.rawText,
    required this.sourceName,
    required this.packageName,
    required this.extractedAmount,
    required this.inferredType,
    this.accountLast4,
    this.referenceNo,
    this.merchantName,
    required this.date,
    required this.isApproved,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['raw_text'] = Variable<String>(rawText);
    map['source_name'] = Variable<String>(sourceName);
    map['package_name'] = Variable<String>(packageName);
    map['extracted_amount'] = Variable<double>(extractedAmount);
    map['inferred_type'] = Variable<String>(inferredType);
    if (!nullToAbsent || accountLast4 != null) {
      map['account_last4'] = Variable<String>(accountLast4);
    }
    if (!nullToAbsent || referenceNo != null) {
      map['reference_no'] = Variable<String>(referenceNo);
    }
    if (!nullToAbsent || merchantName != null) {
      map['merchant_name'] = Variable<String>(merchantName);
    }
    map['date'] = Variable<DateTime>(date);
    map['is_approved'] = Variable<bool>(isApproved);
    return map;
  }

  StagedTransactionsCompanion toCompanion(bool nullToAbsent) {
    return StagedTransactionsCompanion(
      id: Value(id),
      rawText: Value(rawText),
      sourceName: Value(sourceName),
      packageName: Value(packageName),
      extractedAmount: Value(extractedAmount),
      inferredType: Value(inferredType),
      accountLast4: accountLast4 == null && nullToAbsent
          ? const Value.absent()
          : Value(accountLast4),
      referenceNo: referenceNo == null && nullToAbsent
          ? const Value.absent()
          : Value(referenceNo),
      merchantName: merchantName == null && nullToAbsent
          ? const Value.absent()
          : Value(merchantName),
      date: Value(date),
      isApproved: Value(isApproved),
    );
  }

  factory StagedTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StagedTransaction(
      id: serializer.fromJson<String>(json['id']),
      rawText: serializer.fromJson<String>(json['rawText']),
      sourceName: serializer.fromJson<String>(json['sourceName']),
      packageName: serializer.fromJson<String>(json['packageName']),
      extractedAmount: serializer.fromJson<double>(json['extractedAmount']),
      inferredType: serializer.fromJson<String>(json['inferredType']),
      accountLast4: serializer.fromJson<String?>(json['accountLast4']),
      referenceNo: serializer.fromJson<String?>(json['referenceNo']),
      merchantName: serializer.fromJson<String?>(json['merchantName']),
      date: serializer.fromJson<DateTime>(json['date']),
      isApproved: serializer.fromJson<bool>(json['isApproved']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rawText': serializer.toJson<String>(rawText),
      'sourceName': serializer.toJson<String>(sourceName),
      'packageName': serializer.toJson<String>(packageName),
      'extractedAmount': serializer.toJson<double>(extractedAmount),
      'inferredType': serializer.toJson<String>(inferredType),
      'accountLast4': serializer.toJson<String?>(accountLast4),
      'referenceNo': serializer.toJson<String?>(referenceNo),
      'merchantName': serializer.toJson<String?>(merchantName),
      'date': serializer.toJson<DateTime>(date),
      'isApproved': serializer.toJson<bool>(isApproved),
    };
  }

  StagedTransaction copyWith({
    String? id,
    String? rawText,
    String? sourceName,
    String? packageName,
    double? extractedAmount,
    String? inferredType,
    Value<String?> accountLast4 = const Value.absent(),
    Value<String?> referenceNo = const Value.absent(),
    Value<String?> merchantName = const Value.absent(),
    DateTime? date,
    bool? isApproved,
  }) => StagedTransaction(
    id: id ?? this.id,
    rawText: rawText ?? this.rawText,
    sourceName: sourceName ?? this.sourceName,
    packageName: packageName ?? this.packageName,
    extractedAmount: extractedAmount ?? this.extractedAmount,
    inferredType: inferredType ?? this.inferredType,
    accountLast4: accountLast4.present ? accountLast4.value : this.accountLast4,
    referenceNo: referenceNo.present ? referenceNo.value : this.referenceNo,
    merchantName: merchantName.present ? merchantName.value : this.merchantName,
    date: date ?? this.date,
    isApproved: isApproved ?? this.isApproved,
  );
  StagedTransaction copyWithCompanion(StagedTransactionsCompanion data) {
    return StagedTransaction(
      id: data.id.present ? data.id.value : this.id,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      extractedAmount: data.extractedAmount.present
          ? data.extractedAmount.value
          : this.extractedAmount,
      inferredType: data.inferredType.present
          ? data.inferredType.value
          : this.inferredType,
      accountLast4: data.accountLast4.present
          ? data.accountLast4.value
          : this.accountLast4,
      referenceNo: data.referenceNo.present
          ? data.referenceNo.value
          : this.referenceNo,
      merchantName: data.merchantName.present
          ? data.merchantName.value
          : this.merchantName,
      date: data.date.present ? data.date.value : this.date,
      isApproved: data.isApproved.present
          ? data.isApproved.value
          : this.isApproved,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StagedTransaction(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('sourceName: $sourceName, ')
          ..write('packageName: $packageName, ')
          ..write('extractedAmount: $extractedAmount, ')
          ..write('inferredType: $inferredType, ')
          ..write('accountLast4: $accountLast4, ')
          ..write('referenceNo: $referenceNo, ')
          ..write('merchantName: $merchantName, ')
          ..write('date: $date, ')
          ..write('isApproved: $isApproved')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rawText,
    sourceName,
    packageName,
    extractedAmount,
    inferredType,
    accountLast4,
    referenceNo,
    merchantName,
    date,
    isApproved,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StagedTransaction &&
          other.id == this.id &&
          other.rawText == this.rawText &&
          other.sourceName == this.sourceName &&
          other.packageName == this.packageName &&
          other.extractedAmount == this.extractedAmount &&
          other.inferredType == this.inferredType &&
          other.accountLast4 == this.accountLast4 &&
          other.referenceNo == this.referenceNo &&
          other.merchantName == this.merchantName &&
          other.date == this.date &&
          other.isApproved == this.isApproved);
}

class StagedTransactionsCompanion extends UpdateCompanion<StagedTransaction> {
  final Value<String> id;
  final Value<String> rawText;
  final Value<String> sourceName;
  final Value<String> packageName;
  final Value<double> extractedAmount;
  final Value<String> inferredType;
  final Value<String?> accountLast4;
  final Value<String?> referenceNo;
  final Value<String?> merchantName;
  final Value<DateTime> date;
  final Value<bool> isApproved;
  final Value<int> rowid;
  const StagedTransactionsCompanion({
    this.id = const Value.absent(),
    this.rawText = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.packageName = const Value.absent(),
    this.extractedAmount = const Value.absent(),
    this.inferredType = const Value.absent(),
    this.accountLast4 = const Value.absent(),
    this.referenceNo = const Value.absent(),
    this.merchantName = const Value.absent(),
    this.date = const Value.absent(),
    this.isApproved = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StagedTransactionsCompanion.insert({
    required String id,
    required String rawText,
    required String sourceName,
    required String packageName,
    required double extractedAmount,
    required String inferredType,
    this.accountLast4 = const Value.absent(),
    this.referenceNo = const Value.absent(),
    this.merchantName = const Value.absent(),
    required DateTime date,
    this.isApproved = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawText = Value(rawText),
       sourceName = Value(sourceName),
       packageName = Value(packageName),
       extractedAmount = Value(extractedAmount),
       inferredType = Value(inferredType),
       date = Value(date);
  static Insertable<StagedTransaction> custom({
    Expression<String>? id,
    Expression<String>? rawText,
    Expression<String>? sourceName,
    Expression<String>? packageName,
    Expression<double>? extractedAmount,
    Expression<String>? inferredType,
    Expression<String>? accountLast4,
    Expression<String>? referenceNo,
    Expression<String>? merchantName,
    Expression<DateTime>? date,
    Expression<bool>? isApproved,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rawText != null) 'raw_text': rawText,
      if (sourceName != null) 'source_name': sourceName,
      if (packageName != null) 'package_name': packageName,
      if (extractedAmount != null) 'extracted_amount': extractedAmount,
      if (inferredType != null) 'inferred_type': inferredType,
      if (accountLast4 != null) 'account_last4': accountLast4,
      if (referenceNo != null) 'reference_no': referenceNo,
      if (merchantName != null) 'merchant_name': merchantName,
      if (date != null) 'date': date,
      if (isApproved != null) 'is_approved': isApproved,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StagedTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? rawText,
    Value<String>? sourceName,
    Value<String>? packageName,
    Value<double>? extractedAmount,
    Value<String>? inferredType,
    Value<String?>? accountLast4,
    Value<String?>? referenceNo,
    Value<String?>? merchantName,
    Value<DateTime>? date,
    Value<bool>? isApproved,
    Value<int>? rowid,
  }) {
    return StagedTransactionsCompanion(
      id: id ?? this.id,
      rawText: rawText ?? this.rawText,
      sourceName: sourceName ?? this.sourceName,
      packageName: packageName ?? this.packageName,
      extractedAmount: extractedAmount ?? this.extractedAmount,
      inferredType: inferredType ?? this.inferredType,
      accountLast4: accountLast4 ?? this.accountLast4,
      referenceNo: referenceNo ?? this.referenceNo,
      merchantName: merchantName ?? this.merchantName,
      date: date ?? this.date,
      isApproved: isApproved ?? this.isApproved,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (extractedAmount.present) {
      map['extracted_amount'] = Variable<double>(extractedAmount.value);
    }
    if (inferredType.present) {
      map['inferred_type'] = Variable<String>(inferredType.value);
    }
    if (accountLast4.present) {
      map['account_last4'] = Variable<String>(accountLast4.value);
    }
    if (referenceNo.present) {
      map['reference_no'] = Variable<String>(referenceNo.value);
    }
    if (merchantName.present) {
      map['merchant_name'] = Variable<String>(merchantName.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (isApproved.present) {
      map['is_approved'] = Variable<bool>(isApproved.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StagedTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('rawText: $rawText, ')
          ..write('sourceName: $sourceName, ')
          ..write('packageName: $packageName, ')
          ..write('extractedAmount: $extractedAmount, ')
          ..write('inferredType: $inferredType, ')
          ..write('accountLast4: $accountLast4, ')
          ..write('referenceNo: $referenceNo, ')
          ..write('merchantName: $merchantName, ')
          ..write('date: $date, ')
          ..write('isApproved: $isApproved, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParserRulesTable extends ParserRules
    with TableInfo<$ParserRulesTable, ParserRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParserRulesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _regexPatternMeta = const VerificationMeta(
    'regexPattern',
  );
  @override
  late final GeneratedColumn<String> regexPattern = GeneratedColumn<String>(
    'regex_pattern',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetTypeMeta = const VerificationMeta(
    'targetType',
  );
  @override
  late final GeneratedColumn<String> targetType = GeneratedColumn<String>(
    'target_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isCustomMeta = const VerificationMeta(
    'isCustom',
  );
  @override
  late final GeneratedColumn<bool> isCustom = GeneratedColumn<bool>(
    'is_custom',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_custom" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    regexPattern,
    targetType,
    isActive,
    isCustom,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parser_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ParserRule> instance, {
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
    if (data.containsKey('regex_pattern')) {
      context.handle(
        _regexPatternMeta,
        regexPattern.isAcceptableOrUnknown(
          data['regex_pattern']!,
          _regexPatternMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_regexPatternMeta);
    }
    if (data.containsKey('target_type')) {
      context.handle(
        _targetTypeMeta,
        targetType.isAcceptableOrUnknown(data['target_type']!, _targetTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_targetTypeMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_custom')) {
      context.handle(
        _isCustomMeta,
        isCustom.isAcceptableOrUnknown(data['is_custom']!, _isCustomMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ParserRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParserRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      regexPattern: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}regex_pattern'],
      )!,
      targetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_type'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isCustom: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_custom'],
      )!,
    );
  }

  @override
  $ParserRulesTable createAlias(String alias) {
    return $ParserRulesTable(attachedDatabase, alias);
  }
}

class ParserRule extends DataClass implements Insertable<ParserRule> {
  final String id;
  final String name;
  final String regexPattern;
  final String targetType;
  final bool isActive;
  final bool isCustom;
  const ParserRule({
    required this.id,
    required this.name,
    required this.regexPattern,
    required this.targetType,
    required this.isActive,
    required this.isCustom,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['regex_pattern'] = Variable<String>(regexPattern);
    map['target_type'] = Variable<String>(targetType);
    map['is_active'] = Variable<bool>(isActive);
    map['is_custom'] = Variable<bool>(isCustom);
    return map;
  }

  ParserRulesCompanion toCompanion(bool nullToAbsent) {
    return ParserRulesCompanion(
      id: Value(id),
      name: Value(name),
      regexPattern: Value(regexPattern),
      targetType: Value(targetType),
      isActive: Value(isActive),
      isCustom: Value(isCustom),
    );
  }

  factory ParserRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParserRule(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      regexPattern: serializer.fromJson<String>(json['regexPattern']),
      targetType: serializer.fromJson<String>(json['targetType']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isCustom: serializer.fromJson<bool>(json['isCustom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'regexPattern': serializer.toJson<String>(regexPattern),
      'targetType': serializer.toJson<String>(targetType),
      'isActive': serializer.toJson<bool>(isActive),
      'isCustom': serializer.toJson<bool>(isCustom),
    };
  }

  ParserRule copyWith({
    String? id,
    String? name,
    String? regexPattern,
    String? targetType,
    bool? isActive,
    bool? isCustom,
  }) => ParserRule(
    id: id ?? this.id,
    name: name ?? this.name,
    regexPattern: regexPattern ?? this.regexPattern,
    targetType: targetType ?? this.targetType,
    isActive: isActive ?? this.isActive,
    isCustom: isCustom ?? this.isCustom,
  );
  ParserRule copyWithCompanion(ParserRulesCompanion data) {
    return ParserRule(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      regexPattern: data.regexPattern.present
          ? data.regexPattern.value
          : this.regexPattern,
      targetType: data.targetType.present
          ? data.targetType.value
          : this.targetType,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isCustom: data.isCustom.present ? data.isCustom.value : this.isCustom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParserRule(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('regexPattern: $regexPattern, ')
          ..write('targetType: $targetType, ')
          ..write('isActive: $isActive, ')
          ..write('isCustom: $isCustom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, regexPattern, targetType, isActive, isCustom);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParserRule &&
          other.id == this.id &&
          other.name == this.name &&
          other.regexPattern == this.regexPattern &&
          other.targetType == this.targetType &&
          other.isActive == this.isActive &&
          other.isCustom == this.isCustom);
}

class ParserRulesCompanion extends UpdateCompanion<ParserRule> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> regexPattern;
  final Value<String> targetType;
  final Value<bool> isActive;
  final Value<bool> isCustom;
  final Value<int> rowid;
  const ParserRulesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.regexPattern = const Value.absent(),
    this.targetType = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParserRulesCompanion.insert({
    required String id,
    required String name,
    required String regexPattern,
    required String targetType,
    this.isActive = const Value.absent(),
    this.isCustom = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       regexPattern = Value(regexPattern),
       targetType = Value(targetType);
  static Insertable<ParserRule> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? regexPattern,
    Expression<String>? targetType,
    Expression<bool>? isActive,
    Expression<bool>? isCustom,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (regexPattern != null) 'regex_pattern': regexPattern,
      if (targetType != null) 'target_type': targetType,
      if (isActive != null) 'is_active': isActive,
      if (isCustom != null) 'is_custom': isCustom,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParserRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? regexPattern,
    Value<String>? targetType,
    Value<bool>? isActive,
    Value<bool>? isCustom,
    Value<int>? rowid,
  }) {
    return ParserRulesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      regexPattern: regexPattern ?? this.regexPattern,
      targetType: targetType ?? this.targetType,
      isActive: isActive ?? this.isActive,
      isCustom: isCustom ?? this.isCustom,
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
    if (regexPattern.present) {
      map['regex_pattern'] = Variable<String>(regexPattern.value);
    }
    if (targetType.present) {
      map['target_type'] = Variable<String>(targetType.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isCustom.present) {
      map['is_custom'] = Variable<bool>(isCustom.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParserRulesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('regexPattern: $regexPattern, ')
          ..write('targetType: $targetType, ')
          ..write('isActive: $isActive, ')
          ..write('isCustom: $isCustom, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionCategoriesTable transactionCategories =
      $TransactionCategoriesTable(this);
  late final $BudgetBucketsTable budgetBuckets = $BudgetBucketsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $MonthlyBudgetsTable monthlyBudgets = $MonthlyBudgetsTable(this);
  late final $ClosedBudgetSnapshotsTable closedBudgetSnapshots =
      $ClosedBudgetSnapshotsTable(this);
  late final $CustomBudgetsTable customBudgets = $CustomBudgetsTable(this);
  late final $InvestmentsTable investments = $InvestmentsTable(this);
  late final $InvestmentLogsTable investmentLogs = $InvestmentLogsTable(this);
  late final $SmartTrackerTemplatesTable smartTrackerTemplates =
      $SmartTrackerTemplatesTable(this);
  late final $SmartTrackerRecordsTable smartTrackerRecords =
      $SmartTrackerRecordsTable(this);
  late final $AppNotificationsTable appNotifications = $AppNotificationsTable(
    this,
  );
  late final $RecurringTransactionRulesTable recurringTransactionRules =
      $RecurringTransactionRulesTable(this);
  late final $TripsTable trips = $TripsTable(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $VaultRecordsTable vaultRecords = $VaultRecordsTable(this);
  late final $StagedTransactionsTable stagedTransactions =
      $StagedTransactionsTable(this);
  late final $ParserRulesTable parserRules = $ParserRulesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    transactionCategories,
    budgetBuckets,
    accounts,
    transactions,
    monthlyBudgets,
    closedBudgetSnapshots,
    customBudgets,
    investments,
    investmentLogs,
    smartTrackerTemplates,
    smartTrackerRecords,
    appNotifications,
    recurringTransactionRules,
    trips,
    reminders,
    vaultRecords,
    stagedTransactions,
    parserRules,
  ];
}

typedef $$TransactionCategoriesTableCreateCompanionBuilder =
    TransactionCategoriesCompanion Function({
      required String id,
      required String name,
      required String type,
      required String subCategories,
      required int iconCode,
      Value<int> rowid,
    });
typedef $$TransactionCategoriesTableUpdateCompanionBuilder =
    TransactionCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String> subCategories,
      Value<int> iconCode,
      Value<int> rowid,
    });

class $$TransactionCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategories => $composableBuilder(
    column: $table.subCategories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategories => $composableBuilder(
    column: $table.subCategories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionCategoriesTable> {
  $$TransactionCategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get subCategories => $composableBuilder(
    column: $table.subCategories,
    builder: (column) => column,
  );

  GeneratedColumn<int> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);
}

class $$TransactionCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionCategoriesTable,
          TransactionCategory,
          $$TransactionCategoriesTableFilterComposer,
          $$TransactionCategoriesTableOrderingComposer,
          $$TransactionCategoriesTableAnnotationComposer,
          $$TransactionCategoriesTableCreateCompanionBuilder,
          $$TransactionCategoriesTableUpdateCompanionBuilder,
          (
            TransactionCategory,
            BaseReferences<
              _$AppDatabase,
              $TransactionCategoriesTable,
              TransactionCategory
            >,
          ),
          TransactionCategory,
          PrefetchHooks Function()
        > {
  $$TransactionCategoriesTableTableManager(
    _$AppDatabase db,
    $TransactionCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionCategoriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$TransactionCategoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$TransactionCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> subCategories = const Value.absent(),
                Value<int> iconCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionCategoriesCompanion(
                id: id,
                name: name,
                type: type,
                subCategories: subCategories,
                iconCode: iconCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required String subCategories,
                required int iconCode,
                Value<int> rowid = const Value.absent(),
              }) => TransactionCategoriesCompanion.insert(
                id: id,
                name: name,
                type: type,
                subCategories: subCategories,
                iconCode: iconCode,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionCategoriesTable,
      TransactionCategory,
      $$TransactionCategoriesTableFilterComposer,
      $$TransactionCategoriesTableOrderingComposer,
      $$TransactionCategoriesTableAnnotationComposer,
      $$TransactionCategoriesTableCreateCompanionBuilder,
      $$TransactionCategoriesTableUpdateCompanionBuilder,
      (
        TransactionCategory,
        BaseReferences<
          _$AppDatabase,
          $TransactionCategoriesTable,
          TransactionCategory
        >,
      ),
      TransactionCategory,
      PrefetchHooks Function()
    >;
typedef $$BudgetBucketsTableCreateCompanionBuilder =
    BudgetBucketsCompanion Function({
      Value<int> id,
      required String name,
      required double percentage,
      Value<DateTime> createdAt,
    });
typedef $$BudgetBucketsTableUpdateCompanionBuilder =
    BudgetBucketsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<double> percentage,
      Value<DateTime> createdAt,
    });

class $$BudgetBucketsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetBucketsTable> {
  $$BudgetBucketsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetBucketsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetBucketsTable> {
  $$BudgetBucketsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetBucketsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetBucketsTable> {
  $$BudgetBucketsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<double> get percentage => $composableBuilder(
    column: $table.percentage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$BudgetBucketsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetBucketsTable,
          BudgetBucket,
          $$BudgetBucketsTableFilterComposer,
          $$BudgetBucketsTableOrderingComposer,
          $$BudgetBucketsTableAnnotationComposer,
          $$BudgetBucketsTableCreateCompanionBuilder,
          $$BudgetBucketsTableUpdateCompanionBuilder,
          (
            BudgetBucket,
            BaseReferences<_$AppDatabase, $BudgetBucketsTable, BudgetBucket>,
          ),
          BudgetBucket,
          PrefetchHooks Function()
        > {
  $$BudgetBucketsTableTableManager(_$AppDatabase db, $BudgetBucketsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetBucketsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetBucketsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetBucketsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> percentage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => BudgetBucketsCompanion(
                id: id,
                name: name,
                percentage: percentage,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required double percentage,
                Value<DateTime> createdAt = const Value.absent(),
              }) => BudgetBucketsCompanion.insert(
                id: id,
                name: name,
                percentage: percentage,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetBucketsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetBucketsTable,
      BudgetBucket,
      $$BudgetBucketsTableFilterComposer,
      $$BudgetBucketsTableOrderingComposer,
      $$BudgetBucketsTableAnnotationComposer,
      $$BudgetBucketsTableCreateCompanionBuilder,
      $$BudgetBucketsTableUpdateCompanionBuilder,
      (
        BudgetBucket,
        BaseReferences<_$AppDatabase, $BudgetBucketsTable, BudgetBucket>,
      ),
      BudgetBucket,
      PrefetchHooks Function()
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String name,
      required String providerName,
      required String type,
      Value<String?> last4,
      required double balance,
      Value<double?> creditLimit,
      Value<int?> billDate,
      Value<int?> dueDate,
      Value<bool> isCreditPayable,
      Value<String?> loanPurpose,
      Value<double?> loanPrincipal,
      Value<double?> interestRate,
      Value<int?> tenureMonths,
      Value<DateTime?> emiDate,
      Value<DateTime?> loanStartDate,
      Value<DateTime?> loanEndDate,
      Value<double?> totalInterestPayable,
      Value<double?> totalTaxPayable,
      Value<double?> bankCharges,
      Value<bool> isHidden,
      Value<int?> displayOrder,
      Value<bool> isClosed,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> providerName,
      Value<String> type,
      Value<String?> last4,
      Value<double> balance,
      Value<double?> creditLimit,
      Value<int?> billDate,
      Value<int?> dueDate,
      Value<bool> isCreditPayable,
      Value<String?> loanPurpose,
      Value<double?> loanPrincipal,
      Value<double?> interestRate,
      Value<int?> tenureMonths,
      Value<DateTime?> emiDate,
      Value<DateTime?> loanStartDate,
      Value<DateTime?> loanEndDate,
      Value<double?> totalInterestPayable,
      Value<double?> totalTaxPayable,
      Value<double?> bankCharges,
      Value<bool> isHidden,
      Value<int?> displayOrder,
      Value<bool> isClosed,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
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

  ColumnFilters<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
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

  ColumnFilters<bool> get isCreditPayable => $composableBuilder(
    column: $table.isCreditPayable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loanPurpose => $composableBuilder(
    column: $table.loanPurpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get loanPrincipal => $composableBuilder(
    column: $table.loanPrincipal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tenureMonths => $composableBuilder(
    column: $table.tenureMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get emiDate => $composableBuilder(
    column: $table.emiDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loanStartDate => $composableBuilder(
    column: $table.loanStartDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get loanEndDate => $composableBuilder(
    column: $table.loanEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalInterestPayable => $composableBuilder(
    column: $table.totalInterestPayable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalTaxPayable => $composableBuilder(
    column: $table.totalTaxPayable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get bankCharges => $composableBuilder(
    column: $table.bankCharges,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
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

  ColumnOrderings<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get last4 => $composableBuilder(
    column: $table.last4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
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

  ColumnOrderings<bool> get isCreditPayable => $composableBuilder(
    column: $table.isCreditPayable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loanPurpose => $composableBuilder(
    column: $table.loanPurpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get loanPrincipal => $composableBuilder(
    column: $table.loanPrincipal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tenureMonths => $composableBuilder(
    column: $table.tenureMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get emiDate => $composableBuilder(
    column: $table.emiDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loanStartDate => $composableBuilder(
    column: $table.loanStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get loanEndDate => $composableBuilder(
    column: $table.loanEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalInterestPayable => $composableBuilder(
    column: $table.totalInterestPayable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalTaxPayable => $composableBuilder(
    column: $table.totalTaxPayable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get bankCharges => $composableBuilder(
    column: $table.bankCharges,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isHidden => $composableBuilder(
    column: $table.isHidden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
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

  GeneratedColumn<String> get providerName => $composableBuilder(
    column: $table.providerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<double> get creditLimit => $composableBuilder(
    column: $table.creditLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get billDate =>
      $composableBuilder(column: $table.billDate, builder: (column) => column);

  GeneratedColumn<int> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isCreditPayable => $composableBuilder(
    column: $table.isCreditPayable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get loanPurpose => $composableBuilder(
    column: $table.loanPurpose,
    builder: (column) => column,
  );

  GeneratedColumn<double> get loanPrincipal => $composableBuilder(
    column: $table.loanPrincipal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get interestRate => $composableBuilder(
    column: $table.interestRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tenureMonths => $composableBuilder(
    column: $table.tenureMonths,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get emiDate =>
      $composableBuilder(column: $table.emiDate, builder: (column) => column);

  GeneratedColumn<DateTime> get loanStartDate => $composableBuilder(
    column: $table.loanStartDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get loanEndDate => $composableBuilder(
    column: $table.loanEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalInterestPayable => $composableBuilder(
    column: $table.totalInterestPayable,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalTaxPayable => $composableBuilder(
    column: $table.totalTaxPayable,
    builder: (column) => column,
  );

  GeneratedColumn<double> get bankCharges => $composableBuilder(
    column: $table.bankCharges,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isHidden =>
      $composableBuilder(column: $table.isHidden, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
          Account,
          PrefetchHooks Function()
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> providerName = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> last4 = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<double?> creditLimit = const Value.absent(),
                Value<int?> billDate = const Value.absent(),
                Value<int?> dueDate = const Value.absent(),
                Value<bool> isCreditPayable = const Value.absent(),
                Value<String?> loanPurpose = const Value.absent(),
                Value<double?> loanPrincipal = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<int?> tenureMonths = const Value.absent(),
                Value<DateTime?> emiDate = const Value.absent(),
                Value<DateTime?> loanStartDate = const Value.absent(),
                Value<DateTime?> loanEndDate = const Value.absent(),
                Value<double?> totalInterestPayable = const Value.absent(),
                Value<double?> totalTaxPayable = const Value.absent(),
                Value<double?> bankCharges = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<int?> displayOrder = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                providerName: providerName,
                type: type,
                last4: last4,
                balance: balance,
                creditLimit: creditLimit,
                billDate: billDate,
                dueDate: dueDate,
                isCreditPayable: isCreditPayable,
                loanPurpose: loanPurpose,
                loanPrincipal: loanPrincipal,
                interestRate: interestRate,
                tenureMonths: tenureMonths,
                emiDate: emiDate,
                loanStartDate: loanStartDate,
                loanEndDate: loanEndDate,
                totalInterestPayable: totalInterestPayable,
                totalTaxPayable: totalTaxPayable,
                bankCharges: bankCharges,
                isHidden: isHidden,
                displayOrder: displayOrder,
                isClosed: isClosed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String providerName,
                required String type,
                Value<String?> last4 = const Value.absent(),
                required double balance,
                Value<double?> creditLimit = const Value.absent(),
                Value<int?> billDate = const Value.absent(),
                Value<int?> dueDate = const Value.absent(),
                Value<bool> isCreditPayable = const Value.absent(),
                Value<String?> loanPurpose = const Value.absent(),
                Value<double?> loanPrincipal = const Value.absent(),
                Value<double?> interestRate = const Value.absent(),
                Value<int?> tenureMonths = const Value.absent(),
                Value<DateTime?> emiDate = const Value.absent(),
                Value<DateTime?> loanStartDate = const Value.absent(),
                Value<DateTime?> loanEndDate = const Value.absent(),
                Value<double?> totalInterestPayable = const Value.absent(),
                Value<double?> totalTaxPayable = const Value.absent(),
                Value<double?> bankCharges = const Value.absent(),
                Value<bool> isHidden = const Value.absent(),
                Value<int?> displayOrder = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                providerName: providerName,
                type: type,
                last4: last4,
                balance: balance,
                creditLimit: creditLimit,
                billDate: billDate,
                dueDate: dueDate,
                isCreditPayable: isCreditPayable,
                loanPurpose: loanPurpose,
                loanPrincipal: loanPrincipal,
                interestRate: interestRate,
                tenureMonths: tenureMonths,
                emiDate: emiDate,
                loanStartDate: loanStartDate,
                loanEndDate: loanEndDate,
                totalInterestPayable: totalInterestPayable,
                totalTaxPayable: totalTaxPayable,
                bankCharges: bankCharges,
                isHidden: isHidden,
                displayOrder: displayOrder,
                isClosed: isClosed,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, BaseReferences<_$AppDatabase, $AccountsTable, Account>),
      Account,
      PrefetchHooks Function()
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      required String id,
      required String type,
      required double amount,
      required DateTime date,
      required String accountId,
      Value<String?> toAccountId,
      Value<String?> categoryId,
      Value<String?> categoryName,
      Value<int?> categoryIcon,
      Value<String?> subCategory,
      Value<int?> bucketId,
      Value<String?> bucketName,
      Value<String?> notes,
      Value<bool> isSpillover,
      Value<bool> isSettlementVerified,
      Value<String?> locationName,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<double> amount,
      Value<DateTime> date,
      Value<String> accountId,
      Value<String?> toAccountId,
      Value<String?> categoryId,
      Value<String?> categoryName,
      Value<int?> categoryIcon,
      Value<String?> subCategory,
      Value<int?> bucketId,
      Value<String?> bucketName,
      Value<String?> notes,
      Value<bool> isSpillover,
      Value<bool> isSettlementVerified,
      Value<String?> locationName,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int> rowid,
    });

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bucketId => $composableBuilder(
    column: $table.bucketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSpillover => $composableBuilder(
    column: $table.isSpillover,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettlementVerified => $composableBuilder(
    column: $table.isSettlementVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bucketId => $composableBuilder(
    column: $table.bucketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSpillover => $composableBuilder(
    column: $table.isSpillover,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettlementVerified => $composableBuilder(
    column: $table.isSettlementVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bucketId =>
      $composableBuilder(column: $table.bucketId, builder: (column) => column);

  GeneratedColumn<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isSpillover => $composableBuilder(
    column: $table.isSpillover,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSettlementVerified => $composableBuilder(
    column: $table.isSettlementVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get locationName => $composableBuilder(
    column: $table.locationName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          TransactionRecord,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (
            TransactionRecord,
            BaseReferences<
              _$AppDatabase,
              $TransactionsTable,
              TransactionRecord
            >,
          ),
          TransactionRecord,
          PrefetchHooks Function()
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<int?> categoryIcon = const Value.absent(),
                Value<String?> subCategory = const Value.absent(),
                Value<int?> bucketId = const Value.absent(),
                Value<String?> bucketName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isSpillover = const Value.absent(),
                Value<bool> isSettlementVerified = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                type: type,
                amount: amount,
                date: date,
                accountId: accountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                subCategory: subCategory,
                bucketId: bucketId,
                bucketName: bucketName,
                notes: notes,
                isSpillover: isSpillover,
                isSettlementVerified: isSettlementVerified,
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required double amount,
                required DateTime date,
                required String accountId,
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<int?> categoryIcon = const Value.absent(),
                Value<String?> subCategory = const Value.absent(),
                Value<int?> bucketId = const Value.absent(),
                Value<String?> bucketName = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isSpillover = const Value.absent(),
                Value<bool> isSettlementVerified = const Value.absent(),
                Value<String?> locationName = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                type: type,
                amount: amount,
                date: date,
                accountId: accountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                subCategory: subCategory,
                bucketId: bucketId,
                bucketName: bucketName,
                notes: notes,
                isSpillover: isSpillover,
                isSettlementVerified: isSettlementVerified,
                locationName: locationName,
                latitude: latitude,
                longitude: longitude,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      TransactionRecord,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (
        TransactionRecord,
        BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRecord>,
      ),
      TransactionRecord,
      PrefetchHooks Function()
    >;
typedef $$MonthlyBudgetsTableCreateCompanionBuilder =
    MonthlyBudgetsCompanion Function({
      required String id,
      required int month,
      required int year,
      Value<double> salaryIncome,
      Value<double> extraIncome,
      Value<double> deductions,
      Value<String?> bucketsSnapshot,
      Value<bool> isClosed,
      Value<double?> closedTotalSpent,
      Value<double?> closedOutOfBucket,
      Value<double?> closedRemaining,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MonthlyBudgetsTableUpdateCompanionBuilder =
    MonthlyBudgetsCompanion Function({
      Value<String> id,
      Value<int> month,
      Value<int> year,
      Value<double> salaryIncome,
      Value<double> extraIncome,
      Value<double> deductions,
      Value<String?> bucketsSnapshot,
      Value<bool> isClosed,
      Value<double?> closedTotalSpent,
      Value<double?> closedOutOfBucket,
      Value<double?> closedRemaining,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$MonthlyBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableFilterComposer({
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

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salaryIncome => $composableBuilder(
    column: $table.salaryIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get extraIncome => $composableBuilder(
    column: $table.extraIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucketsSnapshot => $composableBuilder(
    column: $table.bucketsSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get closedTotalSpent => $composableBuilder(
    column: $table.closedTotalSpent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get closedOutOfBucket => $composableBuilder(
    column: $table.closedOutOfBucket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get closedRemaining => $composableBuilder(
    column: $table.closedRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MonthlyBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableOrderingComposer({
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

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salaryIncome => $composableBuilder(
    column: $table.salaryIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get extraIncome => $composableBuilder(
    column: $table.extraIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucketsSnapshot => $composableBuilder(
    column: $table.bucketsSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get closedTotalSpent => $composableBuilder(
    column: $table.closedTotalSpent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get closedOutOfBucket => $composableBuilder(
    column: $table.closedOutOfBucket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get closedRemaining => $composableBuilder(
    column: $table.closedRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthlyBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthlyBudgetsTable> {
  $$MonthlyBudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<double> get salaryIncome => $composableBuilder(
    column: $table.salaryIncome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get extraIncome => $composableBuilder(
    column: $table.extraIncome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bucketsSnapshot => $composableBuilder(
    column: $table.bucketsSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  GeneratedColumn<double> get closedTotalSpent => $composableBuilder(
    column: $table.closedTotalSpent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get closedOutOfBucket => $composableBuilder(
    column: $table.closedOutOfBucket,
    builder: (column) => column,
  );

  GeneratedColumn<double> get closedRemaining => $composableBuilder(
    column: $table.closedRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$MonthlyBudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthlyBudgetsTable,
          MonthlyBudget,
          $$MonthlyBudgetsTableFilterComposer,
          $$MonthlyBudgetsTableOrderingComposer,
          $$MonthlyBudgetsTableAnnotationComposer,
          $$MonthlyBudgetsTableCreateCompanionBuilder,
          $$MonthlyBudgetsTableUpdateCompanionBuilder,
          (
            MonthlyBudget,
            BaseReferences<_$AppDatabase, $MonthlyBudgetsTable, MonthlyBudget>,
          ),
          MonthlyBudget,
          PrefetchHooks Function()
        > {
  $$MonthlyBudgetsTableTableManager(
    _$AppDatabase db,
    $MonthlyBudgetsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthlyBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthlyBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthlyBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<double> salaryIncome = const Value.absent(),
                Value<double> extraIncome = const Value.absent(),
                Value<double> deductions = const Value.absent(),
                Value<String?> bucketsSnapshot = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<double?> closedTotalSpent = const Value.absent(),
                Value<double?> closedOutOfBucket = const Value.absent(),
                Value<double?> closedRemaining = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlyBudgetsCompanion(
                id: id,
                month: month,
                year: year,
                salaryIncome: salaryIncome,
                extraIncome: extraIncome,
                deductions: deductions,
                bucketsSnapshot: bucketsSnapshot,
                isClosed: isClosed,
                closedTotalSpent: closedTotalSpent,
                closedOutOfBucket: closedOutOfBucket,
                closedRemaining: closedRemaining,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int month,
                required int year,
                Value<double> salaryIncome = const Value.absent(),
                Value<double> extraIncome = const Value.absent(),
                Value<double> deductions = const Value.absent(),
                Value<String?> bucketsSnapshot = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<double?> closedTotalSpent = const Value.absent(),
                Value<double?> closedOutOfBucket = const Value.absent(),
                Value<double?> closedRemaining = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthlyBudgetsCompanion.insert(
                id: id,
                month: month,
                year: year,
                salaryIncome: salaryIncome,
                extraIncome: extraIncome,
                deductions: deductions,
                bucketsSnapshot: bucketsSnapshot,
                isClosed: isClosed,
                closedTotalSpent: closedTotalSpent,
                closedOutOfBucket: closedOutOfBucket,
                closedRemaining: closedRemaining,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MonthlyBudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthlyBudgetsTable,
      MonthlyBudget,
      $$MonthlyBudgetsTableFilterComposer,
      $$MonthlyBudgetsTableOrderingComposer,
      $$MonthlyBudgetsTableAnnotationComposer,
      $$MonthlyBudgetsTableCreateCompanionBuilder,
      $$MonthlyBudgetsTableUpdateCompanionBuilder,
      (
        MonthlyBudget,
        BaseReferences<_$AppDatabase, $MonthlyBudgetsTable, MonthlyBudget>,
      ),
      MonthlyBudget,
      PrefetchHooks Function()
    >;
typedef $$ClosedBudgetSnapshotsTableCreateCompanionBuilder =
    ClosedBudgetSnapshotsCompanion Function({
      required String id,
      required String budgetId,
      required double salaryIncome,
      required double extraIncome,
      required double deductions,
      required double effectiveIncome,
      required double totalSpent,
      required double totalOutOfBucket,
      required double totalRemaining,
      required double budgetedRemaining,
      required String bucketDetailsJson,
      Value<DateTime> closedAt,
      Value<int> rowid,
    });
typedef $$ClosedBudgetSnapshotsTableUpdateCompanionBuilder =
    ClosedBudgetSnapshotsCompanion Function({
      Value<String> id,
      Value<String> budgetId,
      Value<double> salaryIncome,
      Value<double> extraIncome,
      Value<double> deductions,
      Value<double> effectiveIncome,
      Value<double> totalSpent,
      Value<double> totalOutOfBucket,
      Value<double> totalRemaining,
      Value<double> budgetedRemaining,
      Value<String> bucketDetailsJson,
      Value<DateTime> closedAt,
      Value<int> rowid,
    });

class $$ClosedBudgetSnapshotsTableFilterComposer
    extends Composer<_$AppDatabase, $ClosedBudgetSnapshotsTable> {
  $$ClosedBudgetSnapshotsTableFilterComposer({
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

  ColumnFilters<String> get budgetId => $composableBuilder(
    column: $table.budgetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get salaryIncome => $composableBuilder(
    column: $table.salaryIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get extraIncome => $composableBuilder(
    column: $table.extraIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get effectiveIncome => $composableBuilder(
    column: $table.effectiveIncome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalOutOfBucket => $composableBuilder(
    column: $table.totalOutOfBucket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalRemaining => $composableBuilder(
    column: $table.totalRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get budgetedRemaining => $composableBuilder(
    column: $table.budgetedRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucketDetailsJson => $composableBuilder(
    column: $table.bucketDetailsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClosedBudgetSnapshotsTableOrderingComposer
    extends Composer<_$AppDatabase, $ClosedBudgetSnapshotsTable> {
  $$ClosedBudgetSnapshotsTableOrderingComposer({
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

  ColumnOrderings<String> get budgetId => $composableBuilder(
    column: $table.budgetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get salaryIncome => $composableBuilder(
    column: $table.salaryIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get extraIncome => $composableBuilder(
    column: $table.extraIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get effectiveIncome => $composableBuilder(
    column: $table.effectiveIncome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalOutOfBucket => $composableBuilder(
    column: $table.totalOutOfBucket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalRemaining => $composableBuilder(
    column: $table.totalRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get budgetedRemaining => $composableBuilder(
    column: $table.budgetedRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucketDetailsJson => $composableBuilder(
    column: $table.bucketDetailsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get closedAt => $composableBuilder(
    column: $table.closedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClosedBudgetSnapshotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClosedBudgetSnapshotsTable> {
  $$ClosedBudgetSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get budgetId =>
      $composableBuilder(column: $table.budgetId, builder: (column) => column);

  GeneratedColumn<double> get salaryIncome => $composableBuilder(
    column: $table.salaryIncome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get extraIncome => $composableBuilder(
    column: $table.extraIncome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get deductions => $composableBuilder(
    column: $table.deductions,
    builder: (column) => column,
  );

  GeneratedColumn<double> get effectiveIncome => $composableBuilder(
    column: $table.effectiveIncome,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalSpent => $composableBuilder(
    column: $table.totalSpent,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalOutOfBucket => $composableBuilder(
    column: $table.totalOutOfBucket,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalRemaining => $composableBuilder(
    column: $table.totalRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<double> get budgetedRemaining => $composableBuilder(
    column: $table.budgetedRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bucketDetailsJson => $composableBuilder(
    column: $table.bucketDetailsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get closedAt =>
      $composableBuilder(column: $table.closedAt, builder: (column) => column);
}

class $$ClosedBudgetSnapshotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ClosedBudgetSnapshotsTable,
          ClosedBudgetSnapshot,
          $$ClosedBudgetSnapshotsTableFilterComposer,
          $$ClosedBudgetSnapshotsTableOrderingComposer,
          $$ClosedBudgetSnapshotsTableAnnotationComposer,
          $$ClosedBudgetSnapshotsTableCreateCompanionBuilder,
          $$ClosedBudgetSnapshotsTableUpdateCompanionBuilder,
          (
            ClosedBudgetSnapshot,
            BaseReferences<
              _$AppDatabase,
              $ClosedBudgetSnapshotsTable,
              ClosedBudgetSnapshot
            >,
          ),
          ClosedBudgetSnapshot,
          PrefetchHooks Function()
        > {
  $$ClosedBudgetSnapshotsTableTableManager(
    _$AppDatabase db,
    $ClosedBudgetSnapshotsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClosedBudgetSnapshotsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ClosedBudgetSnapshotsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ClosedBudgetSnapshotsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> budgetId = const Value.absent(),
                Value<double> salaryIncome = const Value.absent(),
                Value<double> extraIncome = const Value.absent(),
                Value<double> deductions = const Value.absent(),
                Value<double> effectiveIncome = const Value.absent(),
                Value<double> totalSpent = const Value.absent(),
                Value<double> totalOutOfBucket = const Value.absent(),
                Value<double> totalRemaining = const Value.absent(),
                Value<double> budgetedRemaining = const Value.absent(),
                Value<String> bucketDetailsJson = const Value.absent(),
                Value<DateTime> closedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClosedBudgetSnapshotsCompanion(
                id: id,
                budgetId: budgetId,
                salaryIncome: salaryIncome,
                extraIncome: extraIncome,
                deductions: deductions,
                effectiveIncome: effectiveIncome,
                totalSpent: totalSpent,
                totalOutOfBucket: totalOutOfBucket,
                totalRemaining: totalRemaining,
                budgetedRemaining: budgetedRemaining,
                bucketDetailsJson: bucketDetailsJson,
                closedAt: closedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String budgetId,
                required double salaryIncome,
                required double extraIncome,
                required double deductions,
                required double effectiveIncome,
                required double totalSpent,
                required double totalOutOfBucket,
                required double totalRemaining,
                required double budgetedRemaining,
                required String bucketDetailsJson,
                Value<DateTime> closedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ClosedBudgetSnapshotsCompanion.insert(
                id: id,
                budgetId: budgetId,
                salaryIncome: salaryIncome,
                extraIncome: extraIncome,
                deductions: deductions,
                effectiveIncome: effectiveIncome,
                totalSpent: totalSpent,
                totalOutOfBucket: totalOutOfBucket,
                totalRemaining: totalRemaining,
                budgetedRemaining: budgetedRemaining,
                bucketDetailsJson: bucketDetailsJson,
                closedAt: closedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ClosedBudgetSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ClosedBudgetSnapshotsTable,
      ClosedBudgetSnapshot,
      $$ClosedBudgetSnapshotsTableFilterComposer,
      $$ClosedBudgetSnapshotsTableOrderingComposer,
      $$ClosedBudgetSnapshotsTableAnnotationComposer,
      $$ClosedBudgetSnapshotsTableCreateCompanionBuilder,
      $$ClosedBudgetSnapshotsTableUpdateCompanionBuilder,
      (
        ClosedBudgetSnapshot,
        BaseReferences<
          _$AppDatabase,
          $ClosedBudgetSnapshotsTable,
          ClosedBudgetSnapshot
        >,
      ),
      ClosedBudgetSnapshot,
      PrefetchHooks Function()
    >;
typedef $$CustomBudgetsTableCreateCompanionBuilder =
    CustomBudgetsCompanion Function({
      required String id,
      required String name,
      required double amountLimit,
      required String timeFrame,
      required DateTime startDate,
      required DateTime endDate,
      Value<String?> categoryId,
      Value<String?> subCategory,
      Value<int?> bucketId,
      Value<String?> accountId,
      Value<bool> isSettled,
      Value<double?> settledAmount,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$CustomBudgetsTableUpdateCompanionBuilder =
    CustomBudgetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double> amountLimit,
      Value<String> timeFrame,
      Value<DateTime> startDate,
      Value<DateTime> endDate,
      Value<String?> categoryId,
      Value<String?> subCategory,
      Value<int?> bucketId,
      Value<String?> accountId,
      Value<bool> isSettled,
      Value<double?> settledAmount,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$CustomBudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $CustomBudgetsTable> {
  $$CustomBudgetsTableFilterComposer({
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

  ColumnFilters<double> get amountLimit => $composableBuilder(
    column: $table.amountLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeFrame => $composableBuilder(
    column: $table.timeFrame,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bucketId => $composableBuilder(
    column: $table.bucketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomBudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomBudgetsTable> {
  $$CustomBudgetsTableOrderingComposer({
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

  ColumnOrderings<double> get amountLimit => $composableBuilder(
    column: $table.amountLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeFrame => $composableBuilder(
    column: $table.timeFrame,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bucketId => $composableBuilder(
    column: $table.bucketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSettled => $composableBuilder(
    column: $table.isSettled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomBudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomBudgetsTable> {
  $$CustomBudgetsTableAnnotationComposer({
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

  GeneratedColumn<double> get amountLimit => $composableBuilder(
    column: $table.amountLimit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeFrame =>
      $composableBuilder(column: $table.timeFrame, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bucketId =>
      $composableBuilder(column: $table.bucketId, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<bool> get isSettled =>
      $composableBuilder(column: $table.isSettled, builder: (column) => column);

  GeneratedColumn<double> get settledAmount => $composableBuilder(
    column: $table.settledAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CustomBudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomBudgetsTable,
          CustomBudget,
          $$CustomBudgetsTableFilterComposer,
          $$CustomBudgetsTableOrderingComposer,
          $$CustomBudgetsTableAnnotationComposer,
          $$CustomBudgetsTableCreateCompanionBuilder,
          $$CustomBudgetsTableUpdateCompanionBuilder,
          (
            CustomBudget,
            BaseReferences<_$AppDatabase, $CustomBudgetsTable, CustomBudget>,
          ),
          CustomBudget,
          PrefetchHooks Function()
        > {
  $$CustomBudgetsTableTableManager(_$AppDatabase db, $CustomBudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomBudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomBudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomBudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double> amountLimit = const Value.absent(),
                Value<String> timeFrame = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime> endDate = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> subCategory = const Value.absent(),
                Value<int?> bucketId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<double?> settledAmount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomBudgetsCompanion(
                id: id,
                name: name,
                amountLimit: amountLimit,
                timeFrame: timeFrame,
                startDate: startDate,
                endDate: endDate,
                categoryId: categoryId,
                subCategory: subCategory,
                bucketId: bucketId,
                accountId: accountId,
                isSettled: isSettled,
                settledAmount: settledAmount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required double amountLimit,
                required String timeFrame,
                required DateTime startDate,
                required DateTime endDate,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> subCategory = const Value.absent(),
                Value<int?> bucketId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<bool> isSettled = const Value.absent(),
                Value<double?> settledAmount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomBudgetsCompanion.insert(
                id: id,
                name: name,
                amountLimit: amountLimit,
                timeFrame: timeFrame,
                startDate: startDate,
                endDate: endDate,
                categoryId: categoryId,
                subCategory: subCategory,
                bucketId: bucketId,
                accountId: accountId,
                isSettled: isSettled,
                settledAmount: settledAmount,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomBudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomBudgetsTable,
      CustomBudget,
      $$CustomBudgetsTableFilterComposer,
      $$CustomBudgetsTableOrderingComposer,
      $$CustomBudgetsTableAnnotationComposer,
      $$CustomBudgetsTableCreateCompanionBuilder,
      $$CustomBudgetsTableUpdateCompanionBuilder,
      (
        CustomBudget,
        BaseReferences<_$AppDatabase, $CustomBudgetsTable, CustomBudget>,
      ),
      CustomBudget,
      PrefetchHooks Function()
    >;
typedef $$InvestmentsTableCreateCompanionBuilder =
    InvestmentsCompanion Function({
      required String id,
      required String name,
      required String type,
      required String provider,
      Value<String?> providerUrl,
      Value<String?> specialTag,
      required double initialAmount,
      Value<double> currentValue,
      Value<double?> targetAmount,
      required DateTime startDate,
      Value<DateTime?> expectedEndDate,
      Value<double?> expectedReturn,
      Value<String?> folioNo,
      Value<double?> units,
      Value<String?> brokerName,
      Value<String?> linkedAccountNo,
      Value<String?> linkedAccountIfsc,
      Value<String?> linkedBankName,
      Value<String?> purpose,
      Value<String?> notes,
      Value<bool> isClosed,
      Value<String?> closeReason,
      Value<int> rowid,
    });
typedef $$InvestmentsTableUpdateCompanionBuilder =
    InvestmentsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> type,
      Value<String> provider,
      Value<String?> providerUrl,
      Value<String?> specialTag,
      Value<double> initialAmount,
      Value<double> currentValue,
      Value<double?> targetAmount,
      Value<DateTime> startDate,
      Value<DateTime?> expectedEndDate,
      Value<double?> expectedReturn,
      Value<String?> folioNo,
      Value<double?> units,
      Value<String?> brokerName,
      Value<String?> linkedAccountNo,
      Value<String?> linkedAccountIfsc,
      Value<String?> linkedBankName,
      Value<String?> purpose,
      Value<String?> notes,
      Value<bool> isClosed,
      Value<String?> closeReason,
      Value<int> rowid,
    });

class $$InvestmentsTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableFilterComposer({
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

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerUrl => $composableBuilder(
    column: $table.providerUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get specialTag => $composableBuilder(
    column: $table.specialTag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get initialAmount => $composableBuilder(
    column: $table.initialAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expectedEndDate => $composableBuilder(
    column: $table.expectedEndDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folioNo => $composableBuilder(
    column: $table.folioNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brokerName => $composableBuilder(
    column: $table.brokerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedAccountNo => $composableBuilder(
    column: $table.linkedAccountNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedAccountIfsc => $composableBuilder(
    column: $table.linkedAccountIfsc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedBankName => $composableBuilder(
    column: $table.linkedBankName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closeReason => $composableBuilder(
    column: $table.closeReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvestmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableOrderingComposer({
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

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerUrl => $composableBuilder(
    column: $table.providerUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get specialTag => $composableBuilder(
    column: $table.specialTag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get initialAmount => $composableBuilder(
    column: $table.initialAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expectedEndDate => $composableBuilder(
    column: $table.expectedEndDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folioNo => $composableBuilder(
    column: $table.folioNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get units => $composableBuilder(
    column: $table.units,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brokerName => $composableBuilder(
    column: $table.brokerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedAccountNo => $composableBuilder(
    column: $table.linkedAccountNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedAccountIfsc => $composableBuilder(
    column: $table.linkedAccountIfsc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedBankName => $composableBuilder(
    column: $table.linkedBankName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purpose => $composableBuilder(
    column: $table.purpose,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isClosed => $composableBuilder(
    column: $table.isClosed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closeReason => $composableBuilder(
    column: $table.closeReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvestmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentsTable> {
  $$InvestmentsTableAnnotationComposer({
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

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get providerUrl => $composableBuilder(
    column: $table.providerUrl,
    builder: (column) => column,
  );

  GeneratedColumn<String> get specialTag => $composableBuilder(
    column: $table.specialTag,
    builder: (column) => column,
  );

  GeneratedColumn<double> get initialAmount => $composableBuilder(
    column: $table.initialAmount,
    builder: (column) => column,
  );

  GeneratedColumn<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetAmount => $composableBuilder(
    column: $table.targetAmount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get expectedEndDate => $composableBuilder(
    column: $table.expectedEndDate,
    builder: (column) => column,
  );

  GeneratedColumn<double> get expectedReturn => $composableBuilder(
    column: $table.expectedReturn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get folioNo =>
      $composableBuilder(column: $table.folioNo, builder: (column) => column);

  GeneratedColumn<double> get units =>
      $composableBuilder(column: $table.units, builder: (column) => column);

  GeneratedColumn<String> get brokerName => $composableBuilder(
    column: $table.brokerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedAccountNo => $composableBuilder(
    column: $table.linkedAccountNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedAccountIfsc => $composableBuilder(
    column: $table.linkedAccountIfsc,
    builder: (column) => column,
  );

  GeneratedColumn<String> get linkedBankName => $composableBuilder(
    column: $table.linkedBankName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purpose =>
      $composableBuilder(column: $table.purpose, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isClosed =>
      $composableBuilder(column: $table.isClosed, builder: (column) => column);

  GeneratedColumn<String> get closeReason => $composableBuilder(
    column: $table.closeReason,
    builder: (column) => column,
  );
}

class $$InvestmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestmentsTable,
          Investment,
          $$InvestmentsTableFilterComposer,
          $$InvestmentsTableOrderingComposer,
          $$InvestmentsTableAnnotationComposer,
          $$InvestmentsTableCreateCompanionBuilder,
          $$InvestmentsTableUpdateCompanionBuilder,
          (
            Investment,
            BaseReferences<_$AppDatabase, $InvestmentsTable, Investment>,
          ),
          Investment,
          PrefetchHooks Function()
        > {
  $$InvestmentsTableTableManager(_$AppDatabase db, $InvestmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvestmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvestmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String?> providerUrl = const Value.absent(),
                Value<String?> specialTag = const Value.absent(),
                Value<double> initialAmount = const Value.absent(),
                Value<double> currentValue = const Value.absent(),
                Value<double?> targetAmount = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> expectedEndDate = const Value.absent(),
                Value<double?> expectedReturn = const Value.absent(),
                Value<String?> folioNo = const Value.absent(),
                Value<double?> units = const Value.absent(),
                Value<String?> brokerName = const Value.absent(),
                Value<String?> linkedAccountNo = const Value.absent(),
                Value<String?> linkedAccountIfsc = const Value.absent(),
                Value<String?> linkedBankName = const Value.absent(),
                Value<String?> purpose = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<String?> closeReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentsCompanion(
                id: id,
                name: name,
                type: type,
                provider: provider,
                providerUrl: providerUrl,
                specialTag: specialTag,
                initialAmount: initialAmount,
                currentValue: currentValue,
                targetAmount: targetAmount,
                startDate: startDate,
                expectedEndDate: expectedEndDate,
                expectedReturn: expectedReturn,
                folioNo: folioNo,
                units: units,
                brokerName: brokerName,
                linkedAccountNo: linkedAccountNo,
                linkedAccountIfsc: linkedAccountIfsc,
                linkedBankName: linkedBankName,
                purpose: purpose,
                notes: notes,
                isClosed: isClosed,
                closeReason: closeReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String type,
                required String provider,
                Value<String?> providerUrl = const Value.absent(),
                Value<String?> specialTag = const Value.absent(),
                required double initialAmount,
                Value<double> currentValue = const Value.absent(),
                Value<double?> targetAmount = const Value.absent(),
                required DateTime startDate,
                Value<DateTime?> expectedEndDate = const Value.absent(),
                Value<double?> expectedReturn = const Value.absent(),
                Value<String?> folioNo = const Value.absent(),
                Value<double?> units = const Value.absent(),
                Value<String?> brokerName = const Value.absent(),
                Value<String?> linkedAccountNo = const Value.absent(),
                Value<String?> linkedAccountIfsc = const Value.absent(),
                Value<String?> linkedBankName = const Value.absent(),
                Value<String?> purpose = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isClosed = const Value.absent(),
                Value<String?> closeReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentsCompanion.insert(
                id: id,
                name: name,
                type: type,
                provider: provider,
                providerUrl: providerUrl,
                specialTag: specialTag,
                initialAmount: initialAmount,
                currentValue: currentValue,
                targetAmount: targetAmount,
                startDate: startDate,
                expectedEndDate: expectedEndDate,
                expectedReturn: expectedReturn,
                folioNo: folioNo,
                units: units,
                brokerName: brokerName,
                linkedAccountNo: linkedAccountNo,
                linkedAccountIfsc: linkedAccountIfsc,
                linkedBankName: linkedBankName,
                purpose: purpose,
                notes: notes,
                isClosed: isClosed,
                closeReason: closeReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvestmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestmentsTable,
      Investment,
      $$InvestmentsTableFilterComposer,
      $$InvestmentsTableOrderingComposer,
      $$InvestmentsTableAnnotationComposer,
      $$InvestmentsTableCreateCompanionBuilder,
      $$InvestmentsTableUpdateCompanionBuilder,
      (
        Investment,
        BaseReferences<_$AppDatabase, $InvestmentsTable, Investment>,
      ),
      Investment,
      PrefetchHooks Function()
    >;
typedef $$InvestmentLogsTableCreateCompanionBuilder =
    InvestmentLogsCompanion Function({
      required String id,
      required String investmentId,
      required String type,
      required double amount,
      required DateTime date,
      Value<String?> notes,
      Value<int> rowid,
    });
typedef $$InvestmentLogsTableUpdateCompanionBuilder =
    InvestmentLogsCompanion Function({
      Value<String> id,
      Value<String> investmentId,
      Value<String> type,
      Value<double> amount,
      Value<DateTime> date,
      Value<String?> notes,
      Value<int> rowid,
    });

class $$InvestmentLogsTableFilterComposer
    extends Composer<_$AppDatabase, $InvestmentLogsTable> {
  $$InvestmentLogsTableFilterComposer({
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

  ColumnFilters<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InvestmentLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $InvestmentLogsTable> {
  $$InvestmentLogsTableOrderingComposer({
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

  ColumnOrderings<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
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

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InvestmentLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InvestmentLogsTable> {
  $$InvestmentLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get investmentId => $composableBuilder(
    column: $table.investmentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);
}

class $$InvestmentLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InvestmentLogsTable,
          InvestmentLog,
          $$InvestmentLogsTableFilterComposer,
          $$InvestmentLogsTableOrderingComposer,
          $$InvestmentLogsTableAnnotationComposer,
          $$InvestmentLogsTableCreateCompanionBuilder,
          $$InvestmentLogsTableUpdateCompanionBuilder,
          (
            InvestmentLog,
            BaseReferences<_$AppDatabase, $InvestmentLogsTable, InvestmentLog>,
          ),
          InvestmentLog,
          PrefetchHooks Function()
        > {
  $$InvestmentLogsTableTableManager(
    _$AppDatabase db,
    $InvestmentLogsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InvestmentLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InvestmentLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InvestmentLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> investmentId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentLogsCompanion(
                id: id,
                investmentId: investmentId,
                type: type,
                amount: amount,
                date: date,
                notes: notes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String investmentId,
                required String type,
                required double amount,
                required DateTime date,
                Value<String?> notes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InvestmentLogsCompanion.insert(
                id: id,
                investmentId: investmentId,
                type: type,
                amount: amount,
                date: date,
                notes: notes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InvestmentLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InvestmentLogsTable,
      InvestmentLog,
      $$InvestmentLogsTableFilterComposer,
      $$InvestmentLogsTableOrderingComposer,
      $$InvestmentLogsTableAnnotationComposer,
      $$InvestmentLogsTableCreateCompanionBuilder,
      $$InvestmentLogsTableUpdateCompanionBuilder,
      (
        InvestmentLog,
        BaseReferences<_$AppDatabase, $InvestmentLogsTable, InvestmentLog>,
      ),
      InvestmentLog,
      PrefetchHooks Function()
    >;
typedef $$SmartTrackerTemplatesTableCreateCompanionBuilder =
    SmartTrackerTemplatesCompanion Function({
      required String id,
      required String name,
      required String schemaJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SmartTrackerTemplatesTableUpdateCompanionBuilder =
    SmartTrackerTemplatesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> schemaJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SmartTrackerTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $SmartTrackerTemplatesTable> {
  $$SmartTrackerTemplatesTableFilterComposer({
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

  ColumnFilters<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmartTrackerTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartTrackerTemplatesTable> {
  $$SmartTrackerTemplatesTableOrderingComposer({
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

  ColumnOrderings<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmartTrackerTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartTrackerTemplatesTable> {
  $$SmartTrackerTemplatesTableAnnotationComposer({
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

  GeneratedColumn<String> get schemaJson => $composableBuilder(
    column: $table.schemaJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SmartTrackerTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartTrackerTemplatesTable,
          SmartTrackerTemplate,
          $$SmartTrackerTemplatesTableFilterComposer,
          $$SmartTrackerTemplatesTableOrderingComposer,
          $$SmartTrackerTemplatesTableAnnotationComposer,
          $$SmartTrackerTemplatesTableCreateCompanionBuilder,
          $$SmartTrackerTemplatesTableUpdateCompanionBuilder,
          (
            SmartTrackerTemplate,
            BaseReferences<
              _$AppDatabase,
              $SmartTrackerTemplatesTable,
              SmartTrackerTemplate
            >,
          ),
          SmartTrackerTemplate,
          PrefetchHooks Function()
        > {
  $$SmartTrackerTemplatesTableTableManager(
    _$AppDatabase db,
    $SmartTrackerTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartTrackerTemplatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SmartTrackerTemplatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SmartTrackerTemplatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> schemaJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmartTrackerTemplatesCompanion(
                id: id,
                name: name,
                schemaJson: schemaJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String schemaJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SmartTrackerTemplatesCompanion.insert(
                id: id,
                name: name,
                schemaJson: schemaJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmartTrackerTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartTrackerTemplatesTable,
      SmartTrackerTemplate,
      $$SmartTrackerTemplatesTableFilterComposer,
      $$SmartTrackerTemplatesTableOrderingComposer,
      $$SmartTrackerTemplatesTableAnnotationComposer,
      $$SmartTrackerTemplatesTableCreateCompanionBuilder,
      $$SmartTrackerTemplatesTableUpdateCompanionBuilder,
      (
        SmartTrackerTemplate,
        BaseReferences<
          _$AppDatabase,
          $SmartTrackerTemplatesTable,
          SmartTrackerTemplate
        >,
      ),
      SmartTrackerTemplate,
      PrefetchHooks Function()
    >;
typedef $$SmartTrackerRecordsTableCreateCompanionBuilder =
    SmartTrackerRecordsCompanion Function({
      required String id,
      required String templateId,
      required String dataJson,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SmartTrackerRecordsTableUpdateCompanionBuilder =
    SmartTrackerRecordsCompanion Function({
      Value<String> id,
      Value<String> templateId,
      Value<String> dataJson,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SmartTrackerRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $SmartTrackerRecordsTable> {
  $$SmartTrackerRecordsTableFilterComposer({
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

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmartTrackerRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmartTrackerRecordsTable> {
  $$SmartTrackerRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dataJson => $composableBuilder(
    column: $table.dataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmartTrackerRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmartTrackerRecordsTable> {
  $$SmartTrackerRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dataJson =>
      $composableBuilder(column: $table.dataJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SmartTrackerRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmartTrackerRecordsTable,
          SmartTrackerRecord,
          $$SmartTrackerRecordsTableFilterComposer,
          $$SmartTrackerRecordsTableOrderingComposer,
          $$SmartTrackerRecordsTableAnnotationComposer,
          $$SmartTrackerRecordsTableCreateCompanionBuilder,
          $$SmartTrackerRecordsTableUpdateCompanionBuilder,
          (
            SmartTrackerRecord,
            BaseReferences<
              _$AppDatabase,
              $SmartTrackerRecordsTable,
              SmartTrackerRecord
            >,
          ),
          SmartTrackerRecord,
          PrefetchHooks Function()
        > {
  $$SmartTrackerRecordsTableTableManager(
    _$AppDatabase db,
    $SmartTrackerRecordsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmartTrackerRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmartTrackerRecordsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SmartTrackerRecordsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> dataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmartTrackerRecordsCompanion(
                id: id,
                templateId: templateId,
                dataJson: dataJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String templateId,
                required String dataJson,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SmartTrackerRecordsCompanion.insert(
                id: id,
                templateId: templateId,
                dataJson: dataJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmartTrackerRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmartTrackerRecordsTable,
      SmartTrackerRecord,
      $$SmartTrackerRecordsTableFilterComposer,
      $$SmartTrackerRecordsTableOrderingComposer,
      $$SmartTrackerRecordsTableAnnotationComposer,
      $$SmartTrackerRecordsTableCreateCompanionBuilder,
      $$SmartTrackerRecordsTableUpdateCompanionBuilder,
      (
        SmartTrackerRecord,
        BaseReferences<
          _$AppDatabase,
          $SmartTrackerRecordsTable,
          SmartTrackerRecord
        >,
      ),
      SmartTrackerRecord,
      PrefetchHooks Function()
    >;
typedef $$AppNotificationsTableCreateCompanionBuilder =
    AppNotificationsCompanion Function({
      required String id,
      required String title,
      required String body,
      Value<String?> payload,
      required DateTime createdAt,
      Value<bool> isRead,
      Value<int> rowid,
    });
typedef $$AppNotificationsTableUpdateCompanionBuilder =
    AppNotificationsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> body,
      Value<String?> payload,
      Value<DateTime> createdAt,
      Value<bool> isRead,
      Value<int> rowid,
    });

class $$AppNotificationsTableFilterComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppNotificationsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isRead => $composableBuilder(
    column: $table.isRead,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppNotificationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppNotificationsTable> {
  $$AppNotificationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get isRead =>
      $composableBuilder(column: $table.isRead, builder: (column) => column);
}

class $$AppNotificationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppNotificationsTable,
          AppNotification,
          $$AppNotificationsTableFilterComposer,
          $$AppNotificationsTableOrderingComposer,
          $$AppNotificationsTableAnnotationComposer,
          $$AppNotificationsTableCreateCompanionBuilder,
          $$AppNotificationsTableUpdateCompanionBuilder,
          (
            AppNotification,
            BaseReferences<
              _$AppDatabase,
              $AppNotificationsTable,
              AppNotification
            >,
          ),
          AppNotification,
          PrefetchHooks Function()
        > {
  $$AppNotificationsTableTableManager(
    _$AppDatabase db,
    $AppNotificationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppNotificationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppNotificationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppNotificationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<String?> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<bool> isRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppNotificationsCompanion(
                id: id,
                title: title,
                body: body,
                payload: payload,
                createdAt: createdAt,
                isRead: isRead,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String body,
                Value<String?> payload = const Value.absent(),
                required DateTime createdAt,
                Value<bool> isRead = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppNotificationsCompanion.insert(
                id: id,
                title: title,
                body: body,
                payload: payload,
                createdAt: createdAt,
                isRead: isRead,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppNotificationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppNotificationsTable,
      AppNotification,
      $$AppNotificationsTableFilterComposer,
      $$AppNotificationsTableOrderingComposer,
      $$AppNotificationsTableAnnotationComposer,
      $$AppNotificationsTableCreateCompanionBuilder,
      $$AppNotificationsTableUpdateCompanionBuilder,
      (
        AppNotification,
        BaseReferences<_$AppDatabase, $AppNotificationsTable, AppNotification>,
      ),
      AppNotification,
      PrefetchHooks Function()
    >;
typedef $$RecurringTransactionRulesTableCreateCompanionBuilder =
    RecurringTransactionRulesCompanion Function({
      required String id,
      required String name,
      Value<String?> serviceWebsite,
      Value<double?> amount,
      required String transactionType,
      required String accountId,
      Value<String?> toAccountId,
      Value<String?> categoryId,
      Value<String?> categoryName,
      Value<int?> categoryIcon,
      Value<String?> subCategory,
      Value<int?> bucketId,
      Value<String?> bucketName,
      required String repetitionSchedule,
      required int repetitionInterval,
      Value<String?> advancedSchedule,
      required DateTime startDate,
      required String occurrenceTime,
      required bool isAutomatic,
      Value<DateTime?> lastExecutedDate,
      required DateTime nextExecutionDate,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$RecurringTransactionRulesTableUpdateCompanionBuilder =
    RecurringTransactionRulesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> serviceWebsite,
      Value<double?> amount,
      Value<String> transactionType,
      Value<String> accountId,
      Value<String?> toAccountId,
      Value<String?> categoryId,
      Value<String?> categoryName,
      Value<int?> categoryIcon,
      Value<String?> subCategory,
      Value<int?> bucketId,
      Value<String?> bucketName,
      Value<String> repetitionSchedule,
      Value<int> repetitionInterval,
      Value<String?> advancedSchedule,
      Value<DateTime> startDate,
      Value<String> occurrenceTime,
      Value<bool> isAutomatic,
      Value<DateTime?> lastExecutedDate,
      Value<DateTime> nextExecutionDate,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$RecurringTransactionRulesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringTransactionRulesTable> {
  $$RecurringTransactionRulesTableFilterComposer({
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

  ColumnFilters<String> get serviceWebsite => $composableBuilder(
    column: $table.serviceWebsite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bucketId => $composableBuilder(
    column: $table.bucketId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repetitionSchedule => $composableBuilder(
    column: $table.repetitionSchedule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repetitionInterval => $composableBuilder(
    column: $table.repetitionInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get advancedSchedule => $composableBuilder(
    column: $table.advancedSchedule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurrenceTime => $composableBuilder(
    column: $table.occurrenceTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAutomatic => $composableBuilder(
    column: $table.isAutomatic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastExecutedDate => $composableBuilder(
    column: $table.lastExecutedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextExecutionDate => $composableBuilder(
    column: $table.nextExecutionDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecurringTransactionRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringTransactionRulesTable> {
  $$RecurringTransactionRulesTableOrderingComposer({
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

  ColumnOrderings<String> get serviceWebsite => $composableBuilder(
    column: $table.serviceWebsite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bucketId => $composableBuilder(
    column: $table.bucketId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repetitionSchedule => $composableBuilder(
    column: $table.repetitionSchedule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repetitionInterval => $composableBuilder(
    column: $table.repetitionInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get advancedSchedule => $composableBuilder(
    column: $table.advancedSchedule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurrenceTime => $composableBuilder(
    column: $table.occurrenceTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAutomatic => $composableBuilder(
    column: $table.isAutomatic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastExecutedDate => $composableBuilder(
    column: $table.lastExecutedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextExecutionDate => $composableBuilder(
    column: $table.nextExecutionDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringTransactionRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringTransactionRulesTable> {
  $$RecurringTransactionRulesTableAnnotationComposer({
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

  GeneratedColumn<String> get serviceWebsite => $composableBuilder(
    column: $table.serviceWebsite,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get toAccountId => $composableBuilder(
    column: $table.toAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryName => $composableBuilder(
    column: $table.categoryName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get categoryIcon => $composableBuilder(
    column: $table.categoryIcon,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subCategory => $composableBuilder(
    column: $table.subCategory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bucketId =>
      $composableBuilder(column: $table.bucketId, builder: (column) => column);

  GeneratedColumn<String> get bucketName => $composableBuilder(
    column: $table.bucketName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repetitionSchedule => $composableBuilder(
    column: $table.repetitionSchedule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repetitionInterval => $composableBuilder(
    column: $table.repetitionInterval,
    builder: (column) => column,
  );

  GeneratedColumn<String> get advancedSchedule => $composableBuilder(
    column: $table.advancedSchedule,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get occurrenceTime => $composableBuilder(
    column: $table.occurrenceTime,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAutomatic => $composableBuilder(
    column: $table.isAutomatic,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastExecutedDate => $composableBuilder(
    column: $table.lastExecutedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextExecutionDate => $composableBuilder(
    column: $table.nextExecutionDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$RecurringTransactionRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringTransactionRulesTable,
          RecurringTransactionRule,
          $$RecurringTransactionRulesTableFilterComposer,
          $$RecurringTransactionRulesTableOrderingComposer,
          $$RecurringTransactionRulesTableAnnotationComposer,
          $$RecurringTransactionRulesTableCreateCompanionBuilder,
          $$RecurringTransactionRulesTableUpdateCompanionBuilder,
          (
            RecurringTransactionRule,
            BaseReferences<
              _$AppDatabase,
              $RecurringTransactionRulesTable,
              RecurringTransactionRule
            >,
          ),
          RecurringTransactionRule,
          PrefetchHooks Function()
        > {
  $$RecurringTransactionRulesTableTableManager(
    _$AppDatabase db,
    $RecurringTransactionRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringTransactionRulesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RecurringTransactionRulesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RecurringTransactionRulesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> serviceWebsite = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<int?> categoryIcon = const Value.absent(),
                Value<String?> subCategory = const Value.absent(),
                Value<int?> bucketId = const Value.absent(),
                Value<String?> bucketName = const Value.absent(),
                Value<String> repetitionSchedule = const Value.absent(),
                Value<int> repetitionInterval = const Value.absent(),
                Value<String?> advancedSchedule = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<String> occurrenceTime = const Value.absent(),
                Value<bool> isAutomatic = const Value.absent(),
                Value<DateTime?> lastExecutedDate = const Value.absent(),
                Value<DateTime> nextExecutionDate = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringTransactionRulesCompanion(
                id: id,
                name: name,
                serviceWebsite: serviceWebsite,
                amount: amount,
                transactionType: transactionType,
                accountId: accountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                subCategory: subCategory,
                bucketId: bucketId,
                bucketName: bucketName,
                repetitionSchedule: repetitionSchedule,
                repetitionInterval: repetitionInterval,
                advancedSchedule: advancedSchedule,
                startDate: startDate,
                occurrenceTime: occurrenceTime,
                isAutomatic: isAutomatic,
                lastExecutedDate: lastExecutedDate,
                nextExecutionDate: nextExecutionDate,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> serviceWebsite = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                required String transactionType,
                required String accountId,
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> categoryName = const Value.absent(),
                Value<int?> categoryIcon = const Value.absent(),
                Value<String?> subCategory = const Value.absent(),
                Value<int?> bucketId = const Value.absent(),
                Value<String?> bucketName = const Value.absent(),
                required String repetitionSchedule,
                required int repetitionInterval,
                Value<String?> advancedSchedule = const Value.absent(),
                required DateTime startDate,
                required String occurrenceTime,
                required bool isAutomatic,
                Value<DateTime?> lastExecutedDate = const Value.absent(),
                required DateTime nextExecutionDate,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringTransactionRulesCompanion.insert(
                id: id,
                name: name,
                serviceWebsite: serviceWebsite,
                amount: amount,
                transactionType: transactionType,
                accountId: accountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                categoryName: categoryName,
                categoryIcon: categoryIcon,
                subCategory: subCategory,
                bucketId: bucketId,
                bucketName: bucketName,
                repetitionSchedule: repetitionSchedule,
                repetitionInterval: repetitionInterval,
                advancedSchedule: advancedSchedule,
                startDate: startDate,
                occurrenceTime: occurrenceTime,
                isAutomatic: isAutomatic,
                lastExecutedDate: lastExecutedDate,
                nextExecutionDate: nextExecutionDate,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecurringTransactionRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringTransactionRulesTable,
      RecurringTransactionRule,
      $$RecurringTransactionRulesTableFilterComposer,
      $$RecurringTransactionRulesTableOrderingComposer,
      $$RecurringTransactionRulesTableAnnotationComposer,
      $$RecurringTransactionRulesTableCreateCompanionBuilder,
      $$RecurringTransactionRulesTableUpdateCompanionBuilder,
      (
        RecurringTransactionRule,
        BaseReferences<
          _$AppDatabase,
          $RecurringTransactionRulesTable,
          RecurringTransactionRule
        >,
      ),
      RecurringTransactionRule,
      PrefetchHooks Function()
    >;
typedef $$TripsTableCreateCompanionBuilder =
    TripsCompanion Function({
      required String id,
      required String name,
      Value<double?> budget,
      Value<String?> notes,
      required String status,
      required String periodsJson,
      required String excludedTxIdsJson,
      Value<int> rowid,
    });
typedef $$TripsTableUpdateCompanionBuilder =
    TripsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<double?> budget,
      Value<String?> notes,
      Value<String> status,
      Value<String> periodsJson,
      Value<String> excludedTxIdsJson,
      Value<int> rowid,
    });

class $$TripsTableFilterComposer extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableFilterComposer({
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

  ColumnFilters<double> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodsJson => $composableBuilder(
    column: $table.periodsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get excludedTxIdsJson => $composableBuilder(
    column: $table.excludedTxIdsJson,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TripsTableOrderingComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableOrderingComposer({
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

  ColumnOrderings<double> get budget => $composableBuilder(
    column: $table.budget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodsJson => $composableBuilder(
    column: $table.periodsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get excludedTxIdsJson => $composableBuilder(
    column: $table.excludedTxIdsJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TripsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TripsTable> {
  $$TripsTableAnnotationComposer({
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

  GeneratedColumn<double> get budget =>
      $composableBuilder(column: $table.budget, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get periodsJson => $composableBuilder(
    column: $table.periodsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get excludedTxIdsJson => $composableBuilder(
    column: $table.excludedTxIdsJson,
    builder: (column) => column,
  );
}

class $$TripsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TripsTable,
          Trip,
          $$TripsTableFilterComposer,
          $$TripsTableOrderingComposer,
          $$TripsTableAnnotationComposer,
          $$TripsTableCreateCompanionBuilder,
          $$TripsTableUpdateCompanionBuilder,
          (Trip, BaseReferences<_$AppDatabase, $TripsTable, Trip>),
          Trip,
          PrefetchHooks Function()
        > {
  $$TripsTableTableManager(_$AppDatabase db, $TripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<double?> budget = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> periodsJson = const Value.absent(),
                Value<String> excludedTxIdsJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion(
                id: id,
                name: name,
                budget: budget,
                notes: notes,
                status: status,
                periodsJson: periodsJson,
                excludedTxIdsJson: excludedTxIdsJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<double?> budget = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                required String status,
                required String periodsJson,
                required String excludedTxIdsJson,
                Value<int> rowid = const Value.absent(),
              }) => TripsCompanion.insert(
                id: id,
                name: name,
                budget: budget,
                notes: notes,
                status: status,
                periodsJson: periodsJson,
                excludedTxIdsJson: excludedTxIdsJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TripsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TripsTable,
      Trip,
      $$TripsTableFilterComposer,
      $$TripsTableOrderingComposer,
      $$TripsTableAnnotationComposer,
      $$TripsTableCreateCompanionBuilder,
      $$TripsTableUpdateCompanionBuilder,
      (Trip, BaseReferences<_$AppDatabase, $TripsTable, Trip>),
      Trip,
      PrefetchHooks Function()
    >;
typedef $$RemindersTableCreateCompanionBuilder =
    RemindersCompanion Function({
      required String id,
      required String title,
      Value<String?> notes,
      required DateTime targetDate,
      Value<bool> isPushEnabled,
      Value<int?> priorDays,
      required int notificationId,
      Value<int> rowid,
    });
typedef $$RemindersTableUpdateCompanionBuilder =
    RemindersCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> notes,
      Value<DateTime> targetDate,
      Value<bool> isPushEnabled,
      Value<int?> priorDays,
      Value<int> notificationId,
      Value<int> rowid,
    });

class $$RemindersTableFilterComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPushEnabled => $composableBuilder(
    column: $table.isPushEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priorDays => $composableBuilder(
    column: $table.priorDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RemindersTableOrderingComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPushEnabled => $composableBuilder(
    column: $table.isPushEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priorDays => $composableBuilder(
    column: $table.priorDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RemindersTableAnnotationComposer
    extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPushEnabled => $composableBuilder(
    column: $table.isPushEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priorDays =>
      $composableBuilder(column: $table.priorDays, builder: (column) => column);

  GeneratedColumn<int> get notificationId => $composableBuilder(
    column: $table.notificationId,
    builder: (column) => column,
  );
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          Reminder,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
          Reminder,
          PrefetchHooks Function()
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> targetDate = const Value.absent(),
                Value<bool> isPushEnabled = const Value.absent(),
                Value<int?> priorDays = const Value.absent(),
                Value<int> notificationId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                title: title,
                notes: notes,
                targetDate: targetDate,
                isPushEnabled: isPushEnabled,
                priorDays: priorDays,
                notificationId: notificationId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> notes = const Value.absent(),
                required DateTime targetDate,
                Value<bool> isPushEnabled = const Value.absent(),
                Value<int?> priorDays = const Value.absent(),
                required int notificationId,
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                targetDate: targetDate,
                isPushEnabled: isPushEnabled,
                priorDays: priorDays,
                notificationId: notificationId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      Reminder,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (Reminder, BaseReferences<_$AppDatabase, $RemindersTable, Reminder>),
      Reminder,
      PrefetchHooks Function()
    >;
typedef $$VaultRecordsTableCreateCompanionBuilder =
    VaultRecordsCompanion Function({
      required String id,
      required String recordType,
      required String recordName,
      required String encryptedPayload,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$VaultRecordsTableUpdateCompanionBuilder =
    VaultRecordsCompanion Function({
      Value<String> id,
      Value<String> recordType,
      Value<String> recordName,
      Value<String> encryptedPayload,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$VaultRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $VaultRecordsTable> {
  $$VaultRecordsTableFilterComposer({
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

  ColumnFilters<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordName => $composableBuilder(
    column: $table.recordName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VaultRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $VaultRecordsTable> {
  $$VaultRecordsTableOrderingComposer({
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

  ColumnOrderings<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordName => $composableBuilder(
    column: $table.recordName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VaultRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $VaultRecordsTable> {
  $$VaultRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get recordType => $composableBuilder(
    column: $table.recordType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordName => $composableBuilder(
    column: $table.recordName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get encryptedPayload => $composableBuilder(
    column: $table.encryptedPayload,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$VaultRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VaultRecordsTable,
          VaultRecord,
          $$VaultRecordsTableFilterComposer,
          $$VaultRecordsTableOrderingComposer,
          $$VaultRecordsTableAnnotationComposer,
          $$VaultRecordsTableCreateCompanionBuilder,
          $$VaultRecordsTableUpdateCompanionBuilder,
          (
            VaultRecord,
            BaseReferences<_$AppDatabase, $VaultRecordsTable, VaultRecord>,
          ),
          VaultRecord,
          PrefetchHooks Function()
        > {
  $$VaultRecordsTableTableManager(_$AppDatabase db, $VaultRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VaultRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VaultRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VaultRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> recordType = const Value.absent(),
                Value<String> recordName = const Value.absent(),
                Value<String> encryptedPayload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VaultRecordsCompanion(
                id: id,
                recordType: recordType,
                recordName: recordName,
                encryptedPayload: encryptedPayload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String recordType,
                required String recordName,
                required String encryptedPayload,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => VaultRecordsCompanion.insert(
                id: id,
                recordType: recordType,
                recordName: recordName,
                encryptedPayload: encryptedPayload,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VaultRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VaultRecordsTable,
      VaultRecord,
      $$VaultRecordsTableFilterComposer,
      $$VaultRecordsTableOrderingComposer,
      $$VaultRecordsTableAnnotationComposer,
      $$VaultRecordsTableCreateCompanionBuilder,
      $$VaultRecordsTableUpdateCompanionBuilder,
      (
        VaultRecord,
        BaseReferences<_$AppDatabase, $VaultRecordsTable, VaultRecord>,
      ),
      VaultRecord,
      PrefetchHooks Function()
    >;
typedef $$StagedTransactionsTableCreateCompanionBuilder =
    StagedTransactionsCompanion Function({
      required String id,
      required String rawText,
      required String sourceName,
      required String packageName,
      required double extractedAmount,
      required String inferredType,
      Value<String?> accountLast4,
      Value<String?> referenceNo,
      Value<String?> merchantName,
      required DateTime date,
      Value<bool> isApproved,
      Value<int> rowid,
    });
typedef $$StagedTransactionsTableUpdateCompanionBuilder =
    StagedTransactionsCompanion Function({
      Value<String> id,
      Value<String> rawText,
      Value<String> sourceName,
      Value<String> packageName,
      Value<double> extractedAmount,
      Value<String> inferredType,
      Value<String?> accountLast4,
      Value<String?> referenceNo,
      Value<String?> merchantName,
      Value<DateTime> date,
      Value<bool> isApproved,
      Value<int> rowid,
    });

class $$StagedTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $StagedTransactionsTable> {
  $$StagedTransactionsTableFilterComposer({
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

  ColumnFilters<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get extractedAmount => $composableBuilder(
    column: $table.extractedAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inferredType => $composableBuilder(
    column: $table.inferredType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountLast4 => $composableBuilder(
    column: $table.accountLast4,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referenceNo => $composableBuilder(
    column: $table.referenceNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isApproved => $composableBuilder(
    column: $table.isApproved,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StagedTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $StagedTransactionsTable> {
  $$StagedTransactionsTableOrderingComposer({
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

  ColumnOrderings<String> get rawText => $composableBuilder(
    column: $table.rawText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get extractedAmount => $composableBuilder(
    column: $table.extractedAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inferredType => $composableBuilder(
    column: $table.inferredType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountLast4 => $composableBuilder(
    column: $table.accountLast4,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referenceNo => $composableBuilder(
    column: $table.referenceNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isApproved => $composableBuilder(
    column: $table.isApproved,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StagedTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StagedTransactionsTable> {
  $$StagedTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawText =>
      $composableBuilder(column: $table.rawText, builder: (column) => column);

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<double> get extractedAmount => $composableBuilder(
    column: $table.extractedAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inferredType => $composableBuilder(
    column: $table.inferredType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountLast4 => $composableBuilder(
    column: $table.accountLast4,
    builder: (column) => column,
  );

  GeneratedColumn<String> get referenceNo => $composableBuilder(
    column: $table.referenceNo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get merchantName => $composableBuilder(
    column: $table.merchantName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<bool> get isApproved => $composableBuilder(
    column: $table.isApproved,
    builder: (column) => column,
  );
}

class $$StagedTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StagedTransactionsTable,
          StagedTransaction,
          $$StagedTransactionsTableFilterComposer,
          $$StagedTransactionsTableOrderingComposer,
          $$StagedTransactionsTableAnnotationComposer,
          $$StagedTransactionsTableCreateCompanionBuilder,
          $$StagedTransactionsTableUpdateCompanionBuilder,
          (
            StagedTransaction,
            BaseReferences<
              _$AppDatabase,
              $StagedTransactionsTable,
              StagedTransaction
            >,
          ),
          StagedTransaction,
          PrefetchHooks Function()
        > {
  $$StagedTransactionsTableTableManager(
    _$AppDatabase db,
    $StagedTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StagedTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StagedTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StagedTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String> sourceName = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<double> extractedAmount = const Value.absent(),
                Value<String> inferredType = const Value.absent(),
                Value<String?> accountLast4 = const Value.absent(),
                Value<String?> referenceNo = const Value.absent(),
                Value<String?> merchantName = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<bool> isApproved = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StagedTransactionsCompanion(
                id: id,
                rawText: rawText,
                sourceName: sourceName,
                packageName: packageName,
                extractedAmount: extractedAmount,
                inferredType: inferredType,
                accountLast4: accountLast4,
                referenceNo: referenceNo,
                merchantName: merchantName,
                date: date,
                isApproved: isApproved,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rawText,
                required String sourceName,
                required String packageName,
                required double extractedAmount,
                required String inferredType,
                Value<String?> accountLast4 = const Value.absent(),
                Value<String?> referenceNo = const Value.absent(),
                Value<String?> merchantName = const Value.absent(),
                required DateTime date,
                Value<bool> isApproved = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StagedTransactionsCompanion.insert(
                id: id,
                rawText: rawText,
                sourceName: sourceName,
                packageName: packageName,
                extractedAmount: extractedAmount,
                inferredType: inferredType,
                accountLast4: accountLast4,
                referenceNo: referenceNo,
                merchantName: merchantName,
                date: date,
                isApproved: isApproved,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StagedTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StagedTransactionsTable,
      StagedTransaction,
      $$StagedTransactionsTableFilterComposer,
      $$StagedTransactionsTableOrderingComposer,
      $$StagedTransactionsTableAnnotationComposer,
      $$StagedTransactionsTableCreateCompanionBuilder,
      $$StagedTransactionsTableUpdateCompanionBuilder,
      (
        StagedTransaction,
        BaseReferences<
          _$AppDatabase,
          $StagedTransactionsTable,
          StagedTransaction
        >,
      ),
      StagedTransaction,
      PrefetchHooks Function()
    >;
typedef $$ParserRulesTableCreateCompanionBuilder =
    ParserRulesCompanion Function({
      required String id,
      required String name,
      required String regexPattern,
      required String targetType,
      Value<bool> isActive,
      Value<bool> isCustom,
      Value<int> rowid,
    });
typedef $$ParserRulesTableUpdateCompanionBuilder =
    ParserRulesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> regexPattern,
      Value<String> targetType,
      Value<bool> isActive,
      Value<bool> isCustom,
      Value<int> rowid,
    });

class $$ParserRulesTableFilterComposer
    extends Composer<_$AppDatabase, $ParserRulesTable> {
  $$ParserRulesTableFilterComposer({
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

  ColumnFilters<String> get regexPattern => $composableBuilder(
    column: $table.regexPattern,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ParserRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $ParserRulesTable> {
  $$ParserRulesTableOrderingComposer({
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

  ColumnOrderings<String> get regexPattern => $composableBuilder(
    column: $table.regexPattern,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCustom => $composableBuilder(
    column: $table.isCustom,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParserRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParserRulesTable> {
  $$ParserRulesTableAnnotationComposer({
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

  GeneratedColumn<String> get regexPattern => $composableBuilder(
    column: $table.regexPattern,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetType => $composableBuilder(
    column: $table.targetType,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isCustom =>
      $composableBuilder(column: $table.isCustom, builder: (column) => column);
}

class $$ParserRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParserRulesTable,
          ParserRule,
          $$ParserRulesTableFilterComposer,
          $$ParserRulesTableOrderingComposer,
          $$ParserRulesTableAnnotationComposer,
          $$ParserRulesTableCreateCompanionBuilder,
          $$ParserRulesTableUpdateCompanionBuilder,
          (
            ParserRule,
            BaseReferences<_$AppDatabase, $ParserRulesTable, ParserRule>,
          ),
          ParserRule,
          PrefetchHooks Function()
        > {
  $$ParserRulesTableTableManager(_$AppDatabase db, $ParserRulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParserRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParserRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParserRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> regexPattern = const Value.absent(),
                Value<String> targetType = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParserRulesCompanion(
                id: id,
                name: name,
                regexPattern: regexPattern,
                targetType: targetType,
                isActive: isActive,
                isCustom: isCustom,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String regexPattern,
                required String targetType,
                Value<bool> isActive = const Value.absent(),
                Value<bool> isCustom = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParserRulesCompanion.insert(
                id: id,
                name: name,
                regexPattern: regexPattern,
                targetType: targetType,
                isActive: isActive,
                isCustom: isCustom,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ParserRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParserRulesTable,
      ParserRule,
      $$ParserRulesTableFilterComposer,
      $$ParserRulesTableOrderingComposer,
      $$ParserRulesTableAnnotationComposer,
      $$ParserRulesTableCreateCompanionBuilder,
      $$ParserRulesTableUpdateCompanionBuilder,
      (
        ParserRule,
        BaseReferences<_$AppDatabase, $ParserRulesTable, ParserRule>,
      ),
      ParserRule,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionCategoriesTableTableManager get transactionCategories =>
      $$TransactionCategoriesTableTableManager(_db, _db.transactionCategories);
  $$BudgetBucketsTableTableManager get budgetBuckets =>
      $$BudgetBucketsTableTableManager(_db, _db.budgetBuckets);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$MonthlyBudgetsTableTableManager get monthlyBudgets =>
      $$MonthlyBudgetsTableTableManager(_db, _db.monthlyBudgets);
  $$ClosedBudgetSnapshotsTableTableManager get closedBudgetSnapshots =>
      $$ClosedBudgetSnapshotsTableTableManager(_db, _db.closedBudgetSnapshots);
  $$CustomBudgetsTableTableManager get customBudgets =>
      $$CustomBudgetsTableTableManager(_db, _db.customBudgets);
  $$InvestmentsTableTableManager get investments =>
      $$InvestmentsTableTableManager(_db, _db.investments);
  $$InvestmentLogsTableTableManager get investmentLogs =>
      $$InvestmentLogsTableTableManager(_db, _db.investmentLogs);
  $$SmartTrackerTemplatesTableTableManager get smartTrackerTemplates =>
      $$SmartTrackerTemplatesTableTableManager(_db, _db.smartTrackerTemplates);
  $$SmartTrackerRecordsTableTableManager get smartTrackerRecords =>
      $$SmartTrackerRecordsTableTableManager(_db, _db.smartTrackerRecords);
  $$AppNotificationsTableTableManager get appNotifications =>
      $$AppNotificationsTableTableManager(_db, _db.appNotifications);
  $$RecurringTransactionRulesTableTableManager get recurringTransactionRules =>
      $$RecurringTransactionRulesTableTableManager(
        _db,
        _db.recurringTransactionRules,
      );
  $$TripsTableTableManager get trips =>
      $$TripsTableTableManager(_db, _db.trips);
  $$RemindersTableTableManager get reminders =>
      $$RemindersTableTableManager(_db, _db.reminders);
  $$VaultRecordsTableTableManager get vaultRecords =>
      $$VaultRecordsTableTableManager(_db, _db.vaultRecords);
  $$StagedTransactionsTableTableManager get stagedTransactions =>
      $$StagedTransactionsTableTableManager(_db, _db.stagedTransactions);
  $$ParserRulesTableTableManager get parserRules =>
      $$ParserRulesTableTableManager(_db, _db.parserRules);
}
