// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class Stores extends Table with TableInfo<Stores, Store> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Stores(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL',
  );
  static const VerificationMeta _isOpenMeta = const VerificationMeta('isOpen');
  late final GeneratedColumn<bool> isOpen = GeneratedColumn<bool>(
    'is_open',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT FALSE',
    defaultValue: const CustomExpression('FALSE'),
  );
  static const VerificationMeta _dailyBagLimitMeta = const VerificationMeta(
    'dailyBagLimit',
  );
  late final GeneratedColumn<int> dailyBagLimit = GeneratedColumn<int>(
    'daily_bag_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _bagsRemainingMeta = const VerificationMeta(
    'bagsRemaining',
  );
  late final GeneratedColumn<int> bagsRemaining = GeneratedColumn<int>(
    'bags_remaining',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _openTimeMeta = const VerificationMeta(
    'openTime',
  );
  late final GeneratedColumn<String> openTime = GeneratedColumn<String>(
    'open_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL',
  );
  static const VerificationMeta _closeTimeMeta = const VerificationMeta(
    'closeTime',
  );
  late final GeneratedColumn<String> closeTime = GeneratedColumn<String>(
    'close_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL',
  );
  static const VerificationMeta _batchSizeMeta = const VerificationMeta(
    'batchSize',
  );
  late final GeneratedColumn<int> batchSize = GeneratedColumn<int>(
    'batch_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 20',
    defaultValue: const CustomExpression('20'),
  );
  static const VerificationMeta _areaMeta = const VerificationMeta('area');
  late final GeneratedColumn<String> area = GeneratedColumn<String>(
    'area',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ownerId,
    isOpen,
    dailyBagLimit,
    bagsRemaining,
    openTime,
    closeTime,
    batchSize,
    area,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<Store> instance, {
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
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    }
    if (data.containsKey('is_open')) {
      context.handle(
        _isOpenMeta,
        isOpen.isAcceptableOrUnknown(data['is_open']!, _isOpenMeta),
      );
    }
    if (data.containsKey('daily_bag_limit')) {
      context.handle(
        _dailyBagLimitMeta,
        dailyBagLimit.isAcceptableOrUnknown(
          data['daily_bag_limit']!,
          _dailyBagLimitMeta,
        ),
      );
    }
    if (data.containsKey('bags_remaining')) {
      context.handle(
        _bagsRemainingMeta,
        bagsRemaining.isAcceptableOrUnknown(
          data['bags_remaining']!,
          _bagsRemainingMeta,
        ),
      );
    }
    if (data.containsKey('open_time')) {
      context.handle(
        _openTimeMeta,
        openTime.isAcceptableOrUnknown(data['open_time']!, _openTimeMeta),
      );
    }
    if (data.containsKey('close_time')) {
      context.handle(
        _closeTimeMeta,
        closeTime.isAcceptableOrUnknown(data['close_time']!, _closeTimeMeta),
      );
    }
    if (data.containsKey('batch_size')) {
      context.handle(
        _batchSizeMeta,
        batchSize.isAcceptableOrUnknown(data['batch_size']!, _batchSizeMeta),
      );
    }
    if (data.containsKey('area')) {
      context.handle(
        _areaMeta,
        area.isAcceptableOrUnknown(data['area']!, _areaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Store map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Store(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      isOpen: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_open'],
      )!,
      dailyBagLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}daily_bag_limit'],
      )!,
      bagsRemaining: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bags_remaining'],
      )!,
      openTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}open_time'],
      ),
      closeTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}close_time'],
      ),
      batchSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_size'],
      )!,
      area: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}area'],
      )!,
    );
  }

  @override
  Stores createAlias(String alias) {
    return Stores(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Store extends DataClass implements Insertable<Store> {
  final String id;
  final String name;

  /// Supabase profiles UUID of the owner. NULL for the browse-only demo
  /// bakeries, which nobody signs in to manage.
  final String? ownerId;
  final bool isOpen;
  final int dailyBagLimit;
  final int bagsRemaining;

  /// "HH:mm" 24h, owner-set. Informational for buyers; doesn't gate is_open.
  final String? openTime;
  final String? closeTime;

  /// How many queue positions make up one notify-able batch. The server
  /// assigns each purchase its batch_number from this at reserve time.
  final int batchSize;
  final String area;
  const Store({
    required this.id,
    required this.name,
    this.ownerId,
    required this.isOpen,
    required this.dailyBagLimit,
    required this.bagsRemaining,
    this.openTime,
    this.closeTime,
    required this.batchSize,
    required this.area,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    map['is_open'] = Variable<bool>(isOpen);
    map['daily_bag_limit'] = Variable<int>(dailyBagLimit);
    map['bags_remaining'] = Variable<int>(bagsRemaining);
    if (!nullToAbsent || openTime != null) {
      map['open_time'] = Variable<String>(openTime);
    }
    if (!nullToAbsent || closeTime != null) {
      map['close_time'] = Variable<String>(closeTime);
    }
    map['batch_size'] = Variable<int>(batchSize);
    map['area'] = Variable<String>(area);
    return map;
  }

  StoresCompanion toCompanion(bool nullToAbsent) {
    return StoresCompanion(
      id: Value(id),
      name: Value(name),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      isOpen: Value(isOpen),
      dailyBagLimit: Value(dailyBagLimit),
      bagsRemaining: Value(bagsRemaining),
      openTime: openTime == null && nullToAbsent
          ? const Value.absent()
          : Value(openTime),
      closeTime: closeTime == null && nullToAbsent
          ? const Value.absent()
          : Value(closeTime),
      batchSize: Value(batchSize),
      area: Value(area),
    );
  }

  factory Store.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Store(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerId: serializer.fromJson<String?>(json['owner_id']),
      isOpen: serializer.fromJson<bool>(json['is_open']),
      dailyBagLimit: serializer.fromJson<int>(json['daily_bag_limit']),
      bagsRemaining: serializer.fromJson<int>(json['bags_remaining']),
      openTime: serializer.fromJson<String?>(json['open_time']),
      closeTime: serializer.fromJson<String?>(json['close_time']),
      batchSize: serializer.fromJson<int>(json['batch_size']),
      area: serializer.fromJson<String>(json['area']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'owner_id': serializer.toJson<String?>(ownerId),
      'is_open': serializer.toJson<bool>(isOpen),
      'daily_bag_limit': serializer.toJson<int>(dailyBagLimit),
      'bags_remaining': serializer.toJson<int>(bagsRemaining),
      'open_time': serializer.toJson<String?>(openTime),
      'close_time': serializer.toJson<String?>(closeTime),
      'batch_size': serializer.toJson<int>(batchSize),
      'area': serializer.toJson<String>(area),
    };
  }

  Store copyWith({
    String? id,
    String? name,
    Value<String?> ownerId = const Value.absent(),
    bool? isOpen,
    int? dailyBagLimit,
    int? bagsRemaining,
    Value<String?> openTime = const Value.absent(),
    Value<String?> closeTime = const Value.absent(),
    int? batchSize,
    String? area,
  }) => Store(
    id: id ?? this.id,
    name: name ?? this.name,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    isOpen: isOpen ?? this.isOpen,
    dailyBagLimit: dailyBagLimit ?? this.dailyBagLimit,
    bagsRemaining: bagsRemaining ?? this.bagsRemaining,
    openTime: openTime.present ? openTime.value : this.openTime,
    closeTime: closeTime.present ? closeTime.value : this.closeTime,
    batchSize: batchSize ?? this.batchSize,
    area: area ?? this.area,
  );
  Store copyWithCompanion(StoresCompanion data) {
    return Store(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      isOpen: data.isOpen.present ? data.isOpen.value : this.isOpen,
      dailyBagLimit: data.dailyBagLimit.present
          ? data.dailyBagLimit.value
          : this.dailyBagLimit,
      bagsRemaining: data.bagsRemaining.present
          ? data.bagsRemaining.value
          : this.bagsRemaining,
      openTime: data.openTime.present ? data.openTime.value : this.openTime,
      closeTime: data.closeTime.present ? data.closeTime.value : this.closeTime,
      batchSize: data.batchSize.present ? data.batchSize.value : this.batchSize,
      area: data.area.present ? data.area.value : this.area,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Store(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('isOpen: $isOpen, ')
          ..write('dailyBagLimit: $dailyBagLimit, ')
          ..write('bagsRemaining: $bagsRemaining, ')
          ..write('openTime: $openTime, ')
          ..write('closeTime: $closeTime, ')
          ..write('batchSize: $batchSize, ')
          ..write('area: $area')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    ownerId,
    isOpen,
    dailyBagLimit,
    bagsRemaining,
    openTime,
    closeTime,
    batchSize,
    area,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Store &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerId == this.ownerId &&
          other.isOpen == this.isOpen &&
          other.dailyBagLimit == this.dailyBagLimit &&
          other.bagsRemaining == this.bagsRemaining &&
          other.openTime == this.openTime &&
          other.closeTime == this.closeTime &&
          other.batchSize == this.batchSize &&
          other.area == this.area);
}

class StoresCompanion extends UpdateCompanion<Store> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> ownerId;
  final Value<bool> isOpen;
  final Value<int> dailyBagLimit;
  final Value<int> bagsRemaining;
  final Value<String?> openTime;
  final Value<String?> closeTime;
  final Value<int> batchSize;
  final Value<String> area;
  final Value<int> rowid;
  const StoresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.isOpen = const Value.absent(),
    this.dailyBagLimit = const Value.absent(),
    this.bagsRemaining = const Value.absent(),
    this.openTime = const Value.absent(),
    this.closeTime = const Value.absent(),
    this.batchSize = const Value.absent(),
    this.area = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoresCompanion.insert({
    required String id,
    required String name,
    this.ownerId = const Value.absent(),
    this.isOpen = const Value.absent(),
    this.dailyBagLimit = const Value.absent(),
    this.bagsRemaining = const Value.absent(),
    this.openTime = const Value.absent(),
    this.closeTime = const Value.absent(),
    this.batchSize = const Value.absent(),
    this.area = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Store> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? ownerId,
    Expression<bool>? isOpen,
    Expression<int>? dailyBagLimit,
    Expression<int>? bagsRemaining,
    Expression<String>? openTime,
    Expression<String>? closeTime,
    Expression<int>? batchSize,
    Expression<String>? area,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerId != null) 'owner_id': ownerId,
      if (isOpen != null) 'is_open': isOpen,
      if (dailyBagLimit != null) 'daily_bag_limit': dailyBagLimit,
      if (bagsRemaining != null) 'bags_remaining': bagsRemaining,
      if (openTime != null) 'open_time': openTime,
      if (closeTime != null) 'close_time': closeTime,
      if (batchSize != null) 'batch_size': batchSize,
      if (area != null) 'area': area,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoresCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? ownerId,
    Value<bool>? isOpen,
    Value<int>? dailyBagLimit,
    Value<int>? bagsRemaining,
    Value<String?>? openTime,
    Value<String?>? closeTime,
    Value<int>? batchSize,
    Value<String>? area,
    Value<int>? rowid,
  }) {
    return StoresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      isOpen: isOpen ?? this.isOpen,
      dailyBagLimit: dailyBagLimit ?? this.dailyBagLimit,
      bagsRemaining: bagsRemaining ?? this.bagsRemaining,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      batchSize: batchSize ?? this.batchSize,
      area: area ?? this.area,
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
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (isOpen.present) {
      map['is_open'] = Variable<bool>(isOpen.value);
    }
    if (dailyBagLimit.present) {
      map['daily_bag_limit'] = Variable<int>(dailyBagLimit.value);
    }
    if (bagsRemaining.present) {
      map['bags_remaining'] = Variable<int>(bagsRemaining.value);
    }
    if (openTime.present) {
      map['open_time'] = Variable<String>(openTime.value);
    }
    if (closeTime.present) {
      map['close_time'] = Variable<String>(closeTime.value);
    }
    if (batchSize.present) {
      map['batch_size'] = Variable<int>(batchSize.value);
    }
    if (area.present) {
      map['area'] = Variable<String>(area.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerId: $ownerId, ')
          ..write('isOpen: $isOpen, ')
          ..write('dailyBagLimit: $dailyBagLimit, ')
          ..write('bagsRemaining: $bagsRemaining, ')
          ..write('openTime: $openTime, ')
          ..write('closeTime: $closeTime, ')
          ..write('batchSize: $batchSize, ')
          ..write('area: $area, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Users extends Table with TableInfo<Users, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _nationalIdMeta = const VerificationMeta(
    'nationalId',
  );
  late final GeneratedColumn<String> nationalId = GeneratedColumn<String>(
    'national_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'buyer\'',
    defaultValue: const CustomExpression('\'buyer\''),
  );
  static const VerificationMeta _jawwalPayNumberMeta = const VerificationMeta(
    'jawwalPayNumber',
  );
  late final GeneratedColumn<String> jawwalPayNumber = GeneratedColumn<String>(
    'jawwal_pay_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _verificationStatusMeta =
      const VerificationMeta('verificationStatus');
  late final GeneratedColumn<String> verificationStatus =
      GeneratedColumn<String>(
        'verification_status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'NOT NULL DEFAULT \'pending\'',
        defaultValue: const CustomExpression('\'pending\''),
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    phone,
    nationalId,
    name,
    role,
    jawwalPayNumber,
    verificationStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('national_id')) {
      context.handle(
        _nationalIdMeta,
        nationalId.isAcceptableOrUnknown(data['national_id']!, _nationalIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('jawwal_pay_number')) {
      context.handle(
        _jawwalPayNumberMeta,
        jawwalPayNumber.isAcceptableOrUnknown(
          data['jawwal_pay_number']!,
          _jawwalPayNumberMeta,
        ),
      );
    }
    if (data.containsKey('verification_status')) {
      context.handle(
        _verificationStatusMeta,
        verificationStatus.isAcceptableOrUnknown(
          data['verification_status']!,
          _verificationStatusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      )!,
      nationalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}national_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      )!,
      jawwalPayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jawwal_pay_number'],
      ),
      verificationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}verification_status'],
      )!,
    );
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String phone;
  final String nationalId;
  final String name;
  final String role;
  final String? jawwalPayNumber;
  final String verificationStatus;
  const User({
    required this.id,
    required this.phone,
    required this.nationalId,
    required this.name,
    required this.role,
    this.jawwalPayNumber,
    required this.verificationStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['phone'] = Variable<String>(phone);
    map['national_id'] = Variable<String>(nationalId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || jawwalPayNumber != null) {
      map['jawwal_pay_number'] = Variable<String>(jawwalPayNumber);
    }
    map['verification_status'] = Variable<String>(verificationStatus);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      phone: Value(phone),
      nationalId: Value(nationalId),
      name: Value(name),
      role: Value(role),
      jawwalPayNumber: jawwalPayNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(jawwalPayNumber),
      verificationStatus: Value(verificationStatus),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      phone: serializer.fromJson<String>(json['phone']),
      nationalId: serializer.fromJson<String>(json['national_id']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      jawwalPayNumber: serializer.fromJson<String?>(json['jawwal_pay_number']),
      verificationStatus: serializer.fromJson<String>(
        json['verification_status'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'phone': serializer.toJson<String>(phone),
      'national_id': serializer.toJson<String>(nationalId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'jawwal_pay_number': serializer.toJson<String?>(jawwalPayNumber),
      'verification_status': serializer.toJson<String>(verificationStatus),
    };
  }

  User copyWith({
    String? id,
    String? phone,
    String? nationalId,
    String? name,
    String? role,
    Value<String?> jawwalPayNumber = const Value.absent(),
    String? verificationStatus,
  }) => User(
    id: id ?? this.id,
    phone: phone ?? this.phone,
    nationalId: nationalId ?? this.nationalId,
    name: name ?? this.name,
    role: role ?? this.role,
    jawwalPayNumber: jawwalPayNumber.present
        ? jawwalPayNumber.value
        : this.jawwalPayNumber,
    verificationStatus: verificationStatus ?? this.verificationStatus,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      phone: data.phone.present ? data.phone.value : this.phone,
      nationalId: data.nationalId.present
          ? data.nationalId.value
          : this.nationalId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      jawwalPayNumber: data.jawwalPayNumber.present
          ? data.jawwalPayNumber.value
          : this.jawwalPayNumber,
      verificationStatus: data.verificationStatus.present
          ? data.verificationStatus.value
          : this.verificationStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('nationalId: $nationalId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('jawwalPayNumber: $jawwalPayNumber, ')
          ..write('verificationStatus: $verificationStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    phone,
    nationalId,
    name,
    role,
    jawwalPayNumber,
    verificationStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.phone == this.phone &&
          other.nationalId == this.nationalId &&
          other.name == this.name &&
          other.role == this.role &&
          other.jawwalPayNumber == this.jawwalPayNumber &&
          other.verificationStatus == this.verificationStatus);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> phone;
  final Value<String> nationalId;
  final Value<String> name;
  final Value<String> role;
  final Value<String?> jawwalPayNumber;
  final Value<String> verificationStatus;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.phone = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.jawwalPayNumber = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    this.phone = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.jawwalPayNumber = const Value.absent(),
    this.verificationStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? phone,
    Expression<String>? nationalId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? jawwalPayNumber,
    Expression<String>? verificationStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phone != null) 'phone': phone,
      if (nationalId != null) 'national_id': nationalId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (jawwalPayNumber != null) 'jawwal_pay_number': jawwalPayNumber,
      if (verificationStatus != null) 'verification_status': verificationStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? phone,
    Value<String>? nationalId,
    Value<String>? name,
    Value<String>? role,
    Value<String?>? jawwalPayNumber,
    Value<String>? verificationStatus,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      name: name ?? this.name,
      role: role ?? this.role,
      jawwalPayNumber: jawwalPayNumber ?? this.jawwalPayNumber,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (nationalId.present) {
      map['national_id'] = Variable<String>(nationalId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (jawwalPayNumber.present) {
      map['jawwal_pay_number'] = Variable<String>(jawwalPayNumber.value);
    }
    if (verificationStatus.present) {
      map['verification_status'] = Variable<String>(verificationStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('nationalId: $nationalId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('jawwalPayNumber: $jawwalPayNumber, ')
          ..write('verificationStatus: $verificationStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Purchases extends Table with TableInfo<Purchases, Purchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Purchases(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES stores(id)',
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES users(id)',
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  late final GeneratedColumn<String> purchaseDate = GeneratedColumn<String>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _batchNumberMeta = const VerificationMeta(
    'batchNumber',
  );
  late final GeneratedColumn<int> batchNumber = GeneratedColumn<int>(
    'batch_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  late final GeneratedColumnWithTypeConverter<PurchaseStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<PurchaseStatus>(Purchases.$converterstatus);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    userId,
    purchaseDate,
    batchNumber,
    status,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<Purchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('batch_number')) {
      context.handle(
        _batchNumberMeta,
        batchNumber.isAcceptableOrUnknown(
          data['batch_number']!,
          _batchNumberMeta,
        ),
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {userId, purchaseDate},
  ];
  @override
  Purchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Purchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date'],
      )!,
      batchNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_number'],
      )!,
      status: Purchases.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Purchases createAlias(String alias) {
    return Purchases(attachedDatabase, alias);
  }

  static TypeConverter<PurchaseStatus, String> $converterstatus =
      const PurchaseStatusConverter();
  @override
  List<String> get customConstraints => const [
    'UNIQUE(user_id, purchase_date)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Purchase extends DataClass implements Insertable<Purchase> {
  final String id;
  final String storeId;
  final String userId;

  /// The day the bread is for, "yyyy-MM-dd" -- not a timestamp.
  final String purchaseDate;
  final int batchNumber;
  final PurchaseStatus status;
  final int createdAt;
  const Purchase({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.purchaseDate,
    required this.batchNumber,
    required this.status,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    map['user_id'] = Variable<String>(userId);
    map['purchase_date'] = Variable<String>(purchaseDate);
    map['batch_number'] = Variable<int>(batchNumber);
    {
      map['status'] = Variable<String>(
        Purchases.$converterstatus.toSql(status),
      );
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      storeId: Value(storeId),
      userId: Value(userId),
      purchaseDate: Value(purchaseDate),
      batchNumber: Value(batchNumber),
      status: Value(status),
      createdAt: Value(createdAt),
    );
  }

  factory Purchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Purchase(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['store_id']),
      userId: serializer.fromJson<String>(json['user_id']),
      purchaseDate: serializer.fromJson<String>(json['purchase_date']),
      batchNumber: serializer.fromJson<int>(json['batch_number']),
      status: serializer.fromJson<PurchaseStatus>(json['status']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'store_id': serializer.toJson<String>(storeId),
      'user_id': serializer.toJson<String>(userId),
      'purchase_date': serializer.toJson<String>(purchaseDate),
      'batch_number': serializer.toJson<int>(batchNumber),
      'status': serializer.toJson<PurchaseStatus>(status),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  Purchase copyWith({
    String? id,
    String? storeId,
    String? userId,
    String? purchaseDate,
    int? batchNumber,
    PurchaseStatus? status,
    int? createdAt,
  }) => Purchase(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    userId: userId ?? this.userId,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    batchNumber: batchNumber ?? this.batchNumber,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
  );
  Purchase copyWithCompanion(PurchasesCompanion data) {
    return Purchase(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      userId: data.userId.present ? data.userId.value : this.userId,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      batchNumber: data.batchNumber.present
          ? data.batchNumber.value
          : this.batchNumber,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Purchase(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('userId: $userId, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    userId,
    purchaseDate,
    batchNumber,
    status,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Purchase &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.userId == this.userId &&
          other.purchaseDate == this.purchaseDate &&
          other.batchNumber == this.batchNumber &&
          other.status == this.status &&
          other.createdAt == this.createdAt);
}

class PurchasesCompanion extends UpdateCompanion<Purchase> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String> userId;
  final Value<String> purchaseDate;
  final Value<int> batchNumber;
  final Value<PurchaseStatus> status;
  final Value<int> createdAt;
  final Value<int> rowid;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.userId = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchasesCompanion.insert({
    required String id,
    required String storeId,
    required String userId,
    required String purchaseDate,
    this.batchNumber = const Value.absent(),
    required PurchaseStatus status,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       userId = Value(userId),
       purchaseDate = Value(purchaseDate),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Purchase> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? userId,
    Expression<String>? purchaseDate,
    Expression<int>? batchNumber,
    Expression<String>? status,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (userId != null) 'user_id': userId,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchasesCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String>? userId,
    Value<String>? purchaseDate,
    Value<int>? batchNumber,
    Value<PurchaseStatus>? status,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      userId: userId ?? this.userId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      batchNumber: batchNumber ?? this.batchNumber,
      status: status ?? this.status,
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
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<String>(purchaseDate.value);
    }
    if (batchNumber.present) {
      map['batch_number'] = Variable<int>(batchNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        Purchases.$converterstatus.toSql(status.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('userId: $userId, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('batchNumber: $batchNumber, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ScanEvents extends Table with TableInfo<ScanEvents, ScanEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ScanEvents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY',
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES stores(id)',
  );
  static const VerificationMeta _purchaseIdMeta = const VerificationMeta(
    'purchaseId',
  );
  late final GeneratedColumn<String> purchaseId = GeneratedColumn<String>(
    'purchase_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL REFERENCES purchases(id)',
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _scannedNameMeta = const VerificationMeta(
    'scannedName',
  );
  late final GeneratedColumn<String> scannedName = GeneratedColumn<String>(
    'scanned_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL',
  );
  static const VerificationMeta _scannedNationalIdMeta = const VerificationMeta(
    'scannedNationalId',
  );
  late final GeneratedColumn<String> scannedNationalId =
      GeneratedColumn<String>(
        'scanned_national_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'NULL',
      );
  static const VerificationMeta _scannedAtMeta = const VerificationMeta(
    'scannedAt',
  );
  late final GeneratedColumn<int> scannedAt = GeneratedColumn<int>(
    'scanned_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    purchaseId,
    outcome,
    scannedName,
    scannedNationalId,
    scannedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'scan_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScanEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
        _purchaseIdMeta,
        purchaseId.isAcceptableOrUnknown(data['purchase_id']!, _purchaseIdMeta),
      );
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('scanned_name')) {
      context.handle(
        _scannedNameMeta,
        scannedName.isAcceptableOrUnknown(
          data['scanned_name']!,
          _scannedNameMeta,
        ),
      );
    }
    if (data.containsKey('scanned_national_id')) {
      context.handle(
        _scannedNationalIdMeta,
        scannedNationalId.isAcceptableOrUnknown(
          data['scanned_national_id']!,
          _scannedNationalIdMeta,
        ),
      );
    }
    if (data.containsKey('scanned_at')) {
      context.handle(
        _scannedAtMeta,
        scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_scannedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScanEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScanEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      purchaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_id'],
      ),
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      scannedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scanned_name'],
      ),
      scannedNationalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scanned_national_id'],
      ),
      scannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scanned_at'],
      )!,
    );
  }

  @override
  ScanEvents createAlias(String alias) {
    return ScanEvents(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ScanEvent extends DataClass implements Insertable<ScanEvent> {
  final String id;
  final String storeId;
  final String? purchaseId;
  final String outcome;
  final String? scannedName;
  final String? scannedNationalId;
  final int scannedAt;
  const ScanEvent({
    required this.id,
    required this.storeId,
    this.purchaseId,
    required this.outcome,
    this.scannedName,
    this.scannedNationalId,
    required this.scannedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['store_id'] = Variable<String>(storeId);
    if (!nullToAbsent || purchaseId != null) {
      map['purchase_id'] = Variable<String>(purchaseId);
    }
    map['outcome'] = Variable<String>(outcome);
    if (!nullToAbsent || scannedName != null) {
      map['scanned_name'] = Variable<String>(scannedName);
    }
    if (!nullToAbsent || scannedNationalId != null) {
      map['scanned_national_id'] = Variable<String>(scannedNationalId);
    }
    map['scanned_at'] = Variable<int>(scannedAt);
    return map;
  }

  ScanEventsCompanion toCompanion(bool nullToAbsent) {
    return ScanEventsCompanion(
      id: Value(id),
      storeId: Value(storeId),
      purchaseId: purchaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseId),
      outcome: Value(outcome),
      scannedName: scannedName == null && nullToAbsent
          ? const Value.absent()
          : Value(scannedName),
      scannedNationalId: scannedNationalId == null && nullToAbsent
          ? const Value.absent()
          : Value(scannedNationalId),
      scannedAt: Value(scannedAt),
    );
  }

  factory ScanEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScanEvent(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String>(json['store_id']),
      purchaseId: serializer.fromJson<String?>(json['purchase_id']),
      outcome: serializer.fromJson<String>(json['outcome']),
      scannedName: serializer.fromJson<String?>(json['scanned_name']),
      scannedNationalId: serializer.fromJson<String?>(
        json['scanned_national_id'],
      ),
      scannedAt: serializer.fromJson<int>(json['scanned_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'store_id': serializer.toJson<String>(storeId),
      'purchase_id': serializer.toJson<String?>(purchaseId),
      'outcome': serializer.toJson<String>(outcome),
      'scanned_name': serializer.toJson<String?>(scannedName),
      'scanned_national_id': serializer.toJson<String?>(scannedNationalId),
      'scanned_at': serializer.toJson<int>(scannedAt),
    };
  }

  ScanEvent copyWith({
    String? id,
    String? storeId,
    Value<String?> purchaseId = const Value.absent(),
    String? outcome,
    Value<String?> scannedName = const Value.absent(),
    Value<String?> scannedNationalId = const Value.absent(),
    int? scannedAt,
  }) => ScanEvent(
    id: id ?? this.id,
    storeId: storeId ?? this.storeId,
    purchaseId: purchaseId.present ? purchaseId.value : this.purchaseId,
    outcome: outcome ?? this.outcome,
    scannedName: scannedName.present ? scannedName.value : this.scannedName,
    scannedNationalId: scannedNationalId.present
        ? scannedNationalId.value
        : this.scannedNationalId,
    scannedAt: scannedAt ?? this.scannedAt,
  );
  ScanEvent copyWithCompanion(ScanEventsCompanion data) {
    return ScanEvent(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      purchaseId: data.purchaseId.present
          ? data.purchaseId.value
          : this.purchaseId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      scannedName: data.scannedName.present
          ? data.scannedName.value
          : this.scannedName,
      scannedNationalId: data.scannedNationalId.present
          ? data.scannedNationalId.value
          : this.scannedNationalId,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScanEvent(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('outcome: $outcome, ')
          ..write('scannedName: $scannedName, ')
          ..write('scannedNationalId: $scannedNationalId, ')
          ..write('scannedAt: $scannedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    purchaseId,
    outcome,
    scannedName,
    scannedNationalId,
    scannedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScanEvent &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.purchaseId == this.purchaseId &&
          other.outcome == this.outcome &&
          other.scannedName == this.scannedName &&
          other.scannedNationalId == this.scannedNationalId &&
          other.scannedAt == this.scannedAt);
}

class ScanEventsCompanion extends UpdateCompanion<ScanEvent> {
  final Value<String> id;
  final Value<String> storeId;
  final Value<String?> purchaseId;
  final Value<String> outcome;
  final Value<String?> scannedName;
  final Value<String?> scannedNationalId;
  final Value<int> scannedAt;
  final Value<int> rowid;
  const ScanEventsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.scannedName = const Value.absent(),
    this.scannedNationalId = const Value.absent(),
    this.scannedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ScanEventsCompanion.insert({
    required String id,
    required String storeId,
    this.purchaseId = const Value.absent(),
    required String outcome,
    this.scannedName = const Value.absent(),
    this.scannedNationalId = const Value.absent(),
    required int scannedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       storeId = Value(storeId),
       outcome = Value(outcome),
       scannedAt = Value(scannedAt);
  static Insertable<ScanEvent> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? purchaseId,
    Expression<String>? outcome,
    Expression<String>? scannedName,
    Expression<String>? scannedNationalId,
    Expression<int>? scannedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (outcome != null) 'outcome': outcome,
      if (scannedName != null) 'scanned_name': scannedName,
      if (scannedNationalId != null) 'scanned_national_id': scannedNationalId,
      if (scannedAt != null) 'scanned_at': scannedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ScanEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? storeId,
    Value<String?>? purchaseId,
    Value<String>? outcome,
    Value<String?>? scannedName,
    Value<String?>? scannedNationalId,
    Value<int>? scannedAt,
    Value<int>? rowid,
  }) {
    return ScanEventsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      purchaseId: purchaseId ?? this.purchaseId,
      outcome: outcome ?? this.outcome,
      scannedName: scannedName ?? this.scannedName,
      scannedNationalId: scannedNationalId ?? this.scannedNationalId,
      scannedAt: scannedAt ?? this.scannedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<String>(purchaseId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (scannedName.present) {
      map['scanned_name'] = Variable<String>(scannedName.value);
    }
    if (scannedNationalId.present) {
      map['scanned_national_id'] = Variable<String>(scannedNationalId.value);
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<int>(scannedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ScanEventsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('outcome: $outcome, ')
          ..write('scannedName: $scannedName, ')
          ..write('scannedNationalId: $scannedNationalId, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class StorePins extends Table with TableInfo<StorePins, StorePin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  StorePins(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES users(id)',
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES stores(id)',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [userId, storeId, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'store_pins';
  @override
  VerificationContext validateIntegrity(
    Insertable<StorePin> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_storeIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {userId, storeId};
  @override
  StorePin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StorePin(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  StorePins createAlias(String alias) {
    return StorePins(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(user_id, store_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class StorePin extends DataClass implements Insertable<StorePin> {
  final String userId;
  final String storeId;
  final int createdAt;
  const StorePin({
    required this.userId,
    required this.storeId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['store_id'] = Variable<String>(storeId);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  StorePinsCompanion toCompanion(bool nullToAbsent) {
    return StorePinsCompanion(
      userId: Value(userId),
      storeId: Value(storeId),
      createdAt: Value(createdAt),
    );
  }

  factory StorePin.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StorePin(
      userId: serializer.fromJson<String>(json['user_id']),
      storeId: serializer.fromJson<String>(json['store_id']),
      createdAt: serializer.fromJson<int>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'user_id': serializer.toJson<String>(userId),
      'store_id': serializer.toJson<String>(storeId),
      'created_at': serializer.toJson<int>(createdAt),
    };
  }

  StorePin copyWith({String? userId, String? storeId, int? createdAt}) =>
      StorePin(
        userId: userId ?? this.userId,
        storeId: storeId ?? this.storeId,
        createdAt: createdAt ?? this.createdAt,
      );
  StorePin copyWithCompanion(StorePinsCompanion data) {
    return StorePin(
      userId: data.userId.present ? data.userId.value : this.userId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StorePin(')
          ..write('userId: $userId, ')
          ..write('storeId: $storeId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, storeId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StorePin &&
          other.userId == this.userId &&
          other.storeId == this.storeId &&
          other.createdAt == this.createdAt);
}

class StorePinsCompanion extends UpdateCompanion<StorePin> {
  final Value<String> userId;
  final Value<String> storeId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const StorePinsCompanion({
    this.userId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StorePinsCompanion.insert({
    required String userId,
    required String storeId,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       storeId = Value(storeId),
       createdAt = Value(createdAt);
  static Insertable<StorePin> custom({
    Expression<String>? userId,
    Expression<String>? storeId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (storeId != null) 'store_id': storeId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StorePinsCompanion copyWith({
    Value<String>? userId,
    Value<String>? storeId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return StorePinsCompanion(
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StorePinsCompanion(')
          ..write('userId: $userId, ')
          ..write('storeId: $storeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Stores stores = Stores(this);
  late final Users users = Users(this);
  late final Purchases purchases = Purchases(this);
  late final ScanEvents scanEvents = ScanEvents(this);
  late final StorePins storePins = StorePins(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stores,
    users,
    purchases,
    scanEvents,
    storePins,
  ];
}

typedef $StoresCreateCompanionBuilder =
    StoresCompanion Function({
      required String id,
      required String name,
      Value<String?> ownerId,
      Value<bool> isOpen,
      Value<int> dailyBagLimit,
      Value<int> bagsRemaining,
      Value<String?> openTime,
      Value<String?> closeTime,
      Value<int> batchSize,
      Value<String> area,
      Value<int> rowid,
    });
typedef $StoresUpdateCompanionBuilder =
    StoresCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> ownerId,
      Value<bool> isOpen,
      Value<int> dailyBagLimit,
      Value<int> bagsRemaining,
      Value<String?> openTime,
      Value<String?> closeTime,
      Value<int> batchSize,
      Value<String> area,
      Value<int> rowid,
    });

final class $StoresReferences
    extends BaseReferences<_$AppDatabase, Stores, Store> {
  $StoresReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Purchases, List<Purchase>> _purchasesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.purchases,
    aliasName: 'stores__id__purchases__store_id',
  );

  $PurchasesProcessedTableManager get purchasesRefs {
    final manager = $PurchasesTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<ScanEvents, List<ScanEvent>> _scanEventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scanEvents,
    aliasName: 'stores__id__scan_events__store_id',
  );

  $ScanEventsProcessedTableManager get scanEventsRefs {
    final manager = $ScanEventsTableManager(
      $_db,
      $_db.scanEvents,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<StorePins, List<StorePin>> _storePinsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.storePins,
    aliasName: 'stores__id__store_pins__store_id',
  );

  $StorePinsProcessedTableManager get storePinsRefs {
    final manager = $StorePinsTableManager(
      $_db,
      $_db.storePins,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storePinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $StoresFilterComposer extends Composer<_$AppDatabase, Stores> {
  $StoresFilterComposer({
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

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isOpen => $composableBuilder(
    column: $table.isOpen,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dailyBagLimit => $composableBuilder(
    column: $table.dailyBagLimit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bagsRemaining => $composableBuilder(
    column: $table.bagsRemaining,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get openTime => $composableBuilder(
    column: $table.openTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get closeTime => $composableBuilder(
    column: $table.closeTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batchSize => $composableBuilder(
    column: $table.batchSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> purchasesRefs(
    Expression<bool> Function($PurchasesFilterComposer f) f,
  ) {
    final $PurchasesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchasesFilterComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> scanEventsRefs(
    Expression<bool> Function($ScanEventsFilterComposer f) f,
  ) {
    final $ScanEventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanEvents,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ScanEventsFilterComposer(
            $db: $db,
            $table: $db.scanEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storePinsRefs(
    Expression<bool> Function($StorePinsFilterComposer f) f,
  ) {
    final $StorePinsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storePins,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StorePinsFilterComposer(
            $db: $db,
            $table: $db.storePins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $StoresOrderingComposer extends Composer<_$AppDatabase, Stores> {
  $StoresOrderingComposer({
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

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isOpen => $composableBuilder(
    column: $table.isOpen,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dailyBagLimit => $composableBuilder(
    column: $table.dailyBagLimit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bagsRemaining => $composableBuilder(
    column: $table.bagsRemaining,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get openTime => $composableBuilder(
    column: $table.openTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get closeTime => $composableBuilder(
    column: $table.closeTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batchSize => $composableBuilder(
    column: $table.batchSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get area => $composableBuilder(
    column: $table.area,
    builder: (column) => ColumnOrderings(column),
  );
}

class $StoresAnnotationComposer extends Composer<_$AppDatabase, Stores> {
  $StoresAnnotationComposer({
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

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<bool> get isOpen =>
      $composableBuilder(column: $table.isOpen, builder: (column) => column);

  GeneratedColumn<int> get dailyBagLimit => $composableBuilder(
    column: $table.dailyBagLimit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bagsRemaining => $composableBuilder(
    column: $table.bagsRemaining,
    builder: (column) => column,
  );

  GeneratedColumn<String> get openTime =>
      $composableBuilder(column: $table.openTime, builder: (column) => column);

  GeneratedColumn<String> get closeTime =>
      $composableBuilder(column: $table.closeTime, builder: (column) => column);

  GeneratedColumn<int> get batchSize =>
      $composableBuilder(column: $table.batchSize, builder: (column) => column);

  GeneratedColumn<String> get area =>
      $composableBuilder(column: $table.area, builder: (column) => column);

  Expression<T> purchasesRefs<T extends Object>(
    Expression<T> Function($PurchasesAnnotationComposer a) f,
  ) {
    final $PurchasesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchasesAnnotationComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> scanEventsRefs<T extends Object>(
    Expression<T> Function($ScanEventsAnnotationComposer a) f,
  ) {
    final $ScanEventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanEvents,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ScanEventsAnnotationComposer(
            $db: $db,
            $table: $db.scanEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storePinsRefs<T extends Object>(
    Expression<T> Function($StorePinsAnnotationComposer a) f,
  ) {
    final $StorePinsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storePins,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StorePinsAnnotationComposer(
            $db: $db,
            $table: $db.storePins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $StoresTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Stores,
          Store,
          $StoresFilterComposer,
          $StoresOrderingComposer,
          $StoresAnnotationComposer,
          $StoresCreateCompanionBuilder,
          $StoresUpdateCompanionBuilder,
          (Store, $StoresReferences),
          Store,
          PrefetchHooks Function({
            bool purchasesRefs,
            bool scanEventsRefs,
            bool storePinsRefs,
          })
        > {
  $StoresTableManager(_$AppDatabase db, Stores table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $StoresFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $StoresOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $StoresAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<bool> isOpen = const Value.absent(),
                Value<int> dailyBagLimit = const Value.absent(),
                Value<int> bagsRemaining = const Value.absent(),
                Value<String?> openTime = const Value.absent(),
                Value<String?> closeTime = const Value.absent(),
                Value<int> batchSize = const Value.absent(),
                Value<String> area = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresCompanion(
                id: id,
                name: name,
                ownerId: ownerId,
                isOpen: isOpen,
                dailyBagLimit: dailyBagLimit,
                bagsRemaining: bagsRemaining,
                openTime: openTime,
                closeTime: closeTime,
                batchSize: batchSize,
                area: area,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> ownerId = const Value.absent(),
                Value<bool> isOpen = const Value.absent(),
                Value<int> dailyBagLimit = const Value.absent(),
                Value<int> bagsRemaining = const Value.absent(),
                Value<String?> openTime = const Value.absent(),
                Value<String?> closeTime = const Value.absent(),
                Value<int> batchSize = const Value.absent(),
                Value<String> area = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresCompanion.insert(
                id: id,
                name: name,
                ownerId: ownerId,
                isOpen: isOpen,
                dailyBagLimit: dailyBagLimit,
                bagsRemaining: bagsRemaining,
                openTime: openTime,
                closeTime: closeTime,
                batchSize: batchSize,
                area: area,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $StoresReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({
                purchasesRefs = false,
                scanEventsRefs = false,
                storePinsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (purchasesRefs) db.purchases,
                    if (scanEventsRefs) db.scanEvents,
                    if (storePinsRefs) db.storePins,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (purchasesRefs)
                        await $_getPrefetchedData<Store, Stores, Purchase>(
                          currentTable: table,
                          referencedTable: $StoresReferences
                              ._purchasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $StoresReferences(db, table, p0).purchasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (scanEventsRefs)
                        await $_getPrefetchedData<Store, Stores, ScanEvent>(
                          currentTable: table,
                          referencedTable: $StoresReferences
                              ._scanEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $StoresReferences(db, table, p0).scanEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storePinsRefs)
                        await $_getPrefetchedData<Store, Stores, StorePin>(
                          currentTable: table,
                          referencedTable: $StoresReferences
                              ._storePinsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $StoresReferences(db, table, p0).storePinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $StoresProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Stores,
      Store,
      $StoresFilterComposer,
      $StoresOrderingComposer,
      $StoresAnnotationComposer,
      $StoresCreateCompanionBuilder,
      $StoresUpdateCompanionBuilder,
      (Store, $StoresReferences),
      Store,
      PrefetchHooks Function({
        bool purchasesRefs,
        bool scanEventsRefs,
        bool storePinsRefs,
      })
    >;
typedef $UsersCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      Value<String> phone,
      Value<String> nationalId,
      Value<String> name,
      Value<String> role,
      Value<String?> jawwalPayNumber,
      Value<String> verificationStatus,
      Value<int> rowid,
    });
typedef $UsersUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> phone,
      Value<String> nationalId,
      Value<String> name,
      Value<String> role,
      Value<String?> jawwalPayNumber,
      Value<String> verificationStatus,
      Value<int> rowid,
    });

final class $UsersReferences
    extends BaseReferences<_$AppDatabase, Users, User> {
  $UsersReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Purchases, List<Purchase>> _purchasesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.purchases,
    aliasName: 'users__id__purchases__user_id',
  );

  $PurchasesProcessedTableManager get purchasesRefs {
    final manager = $PurchasesTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<StorePins, List<StorePin>> _storePinsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.storePins,
    aliasName: 'users__id__store_pins__user_id',
  );

  $StorePinsProcessedTableManager get storePinsRefs {
    final manager = $StorePinsTableManager(
      $_db,
      $_db.storePins,
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_storePinsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $UsersFilterComposer extends Composer<_$AppDatabase, Users> {
  $UsersFilterComposer({
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

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jawwalPayNumber => $composableBuilder(
    column: $table.jawwalPayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> purchasesRefs(
    Expression<bool> Function($PurchasesFilterComposer f) f,
  ) {
    final $PurchasesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchasesFilterComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> storePinsRefs(
    Expression<bool> Function($StorePinsFilterComposer f) f,
  ) {
    final $StorePinsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storePins,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StorePinsFilterComposer(
            $db: $db,
            $table: $db.storePins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $UsersOrderingComposer extends Composer<_$AppDatabase, Users> {
  $UsersOrderingComposer({
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

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jawwalPayNumber => $composableBuilder(
    column: $table.jawwalPayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => ColumnOrderings(column),
  );
}

class $UsersAnnotationComposer extends Composer<_$AppDatabase, Users> {
  $UsersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get jawwalPayNumber => $composableBuilder(
    column: $table.jawwalPayNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get verificationStatus => $composableBuilder(
    column: $table.verificationStatus,
    builder: (column) => column,
  );

  Expression<T> purchasesRefs<T extends Object>(
    Expression<T> Function($PurchasesAnnotationComposer a) f,
  ) {
    final $PurchasesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchasesAnnotationComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> storePinsRefs<T extends Object>(
    Expression<T> Function($StorePinsAnnotationComposer a) f,
  ) {
    final $StorePinsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.storePins,
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StorePinsAnnotationComposer(
            $db: $db,
            $table: $db.storePins,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $UsersTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Users,
          User,
          $UsersFilterComposer,
          $UsersOrderingComposer,
          $UsersAnnotationComposer,
          $UsersCreateCompanionBuilder,
          $UsersUpdateCompanionBuilder,
          (User, $UsersReferences),
          User,
          PrefetchHooks Function({bool purchasesRefs, bool storePinsRefs})
        > {
  $UsersTableManager(_$AppDatabase db, Users table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $UsersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $UsersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $UsersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> nationalId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> jawwalPayNumber = const Value.absent(),
                Value<String> verificationStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                phone: phone,
                nationalId: nationalId,
                name: name,
                role: role,
                jawwalPayNumber: jawwalPayNumber,
                verificationStatus: verificationStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String> phone = const Value.absent(),
                Value<String> nationalId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> role = const Value.absent(),
                Value<String?> jawwalPayNumber = const Value.absent(),
                Value<String> verificationStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                phone: phone,
                nationalId: nationalId,
                name: name,
                role: role,
                jawwalPayNumber: jawwalPayNumber,
                verificationStatus: verificationStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $UsersReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({purchasesRefs = false, storePinsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (purchasesRefs) db.purchases,
                    if (storePinsRefs) db.storePins,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (purchasesRefs)
                        await $_getPrefetchedData<User, Users, Purchase>(
                          currentTable: table,
                          referencedTable: $UsersReferences._purchasesRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $UsersReferences(db, table, p0).purchasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (storePinsRefs)
                        await $_getPrefetchedData<User, Users, StorePin>(
                          currentTable: table,
                          referencedTable: $UsersReferences._storePinsRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $UsersReferences(db, table, p0).storePinsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $UsersProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Users,
      User,
      $UsersFilterComposer,
      $UsersOrderingComposer,
      $UsersAnnotationComposer,
      $UsersCreateCompanionBuilder,
      $UsersUpdateCompanionBuilder,
      (User, $UsersReferences),
      User,
      PrefetchHooks Function({bool purchasesRefs, bool storePinsRefs})
    >;
typedef $PurchasesCreateCompanionBuilder =
    PurchasesCompanion Function({
      required String id,
      required String storeId,
      required String userId,
      required String purchaseDate,
      Value<int> batchNumber,
      required PurchaseStatus status,
      required int createdAt,
      Value<int> rowid,
    });
typedef $PurchasesUpdateCompanionBuilder =
    PurchasesCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String> userId,
      Value<String> purchaseDate,
      Value<int> batchNumber,
      Value<PurchaseStatus> status,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $PurchasesReferences
    extends BaseReferences<_$AppDatabase, Purchases, Purchase> {
  $PurchasesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Stores _storeIdTable(_$AppDatabase db) =>
      db.stores.createAlias('purchases__store_id__stores__id');

  $StoresProcessedTableManager get storeId {
    final $_column = $_itemColumn<String>('store_id')!;

    final manager = $StoresTableManager(
      $_db,
      $_db.stores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('purchases__user_id__users__id');

  $UsersProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<ScanEvents, List<ScanEvent>> _scanEventsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.scanEvents,
    aliasName: 'purchases__id__scan_events__purchase_id',
  );

  $ScanEventsProcessedTableManager get scanEventsRefs {
    final manager = $ScanEventsTableManager(
      $_db,
      $_db.scanEvents,
    ).filter((f) => f.purchaseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_scanEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $PurchasesFilterComposer extends Composer<_$AppDatabase, Purchases> {
  $PurchasesFilterComposer({
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

  ColumnFilters<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batchNumber => $composableBuilder(
    column: $table.batchNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<PurchaseStatus, PurchaseStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $StoresFilterComposer get storeId {
    final $StoresFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresFilterComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get userId {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> scanEventsRefs(
    Expression<bool> Function($ScanEventsFilterComposer f) f,
  ) {
    final $ScanEventsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanEvents,
      getReferencedColumn: (t) => t.purchaseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ScanEventsFilterComposer(
            $db: $db,
            $table: $db.scanEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $PurchasesOrderingComposer extends Composer<_$AppDatabase, Purchases> {
  $PurchasesOrderingComposer({
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

  ColumnOrderings<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get batchNumber => $composableBuilder(
    column: $table.batchNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $StoresOrderingComposer get storeId {
    final $StoresOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresOrderingComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get userId {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PurchasesAnnotationComposer extends Composer<_$AppDatabase, Purchases> {
  $PurchasesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get batchNumber => $composableBuilder(
    column: $table.batchNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<PurchaseStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $StoresAnnotationComposer get storeId {
    final $StoresAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresAnnotationComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get userId {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> scanEventsRefs<T extends Object>(
    Expression<T> Function($ScanEventsAnnotationComposer a) f,
  ) {
    final $ScanEventsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.scanEvents,
      getReferencedColumn: (t) => t.purchaseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ScanEventsAnnotationComposer(
            $db: $db,
            $table: $db.scanEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $PurchasesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Purchases,
          Purchase,
          $PurchasesFilterComposer,
          $PurchasesOrderingComposer,
          $PurchasesAnnotationComposer,
          $PurchasesCreateCompanionBuilder,
          $PurchasesUpdateCompanionBuilder,
          (Purchase, $PurchasesReferences),
          Purchase,
          PrefetchHooks Function({
            bool storeId,
            bool userId,
            bool scanEventsRefs,
          })
        > {
  $PurchasesTableManager(_$AppDatabase db, Purchases table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PurchasesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PurchasesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PurchasesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> purchaseDate = const Value.absent(),
                Value<int> batchNumber = const Value.absent(),
                Value<PurchaseStatus> status = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchasesCompanion(
                id: id,
                storeId: storeId,
                userId: userId,
                purchaseDate: purchaseDate,
                batchNumber: batchNumber,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                required String userId,
                required String purchaseDate,
                Value<int> batchNumber = const Value.absent(),
                required PurchaseStatus status,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => PurchasesCompanion.insert(
                id: id,
                storeId: storeId,
                userId: userId,
                purchaseDate: purchaseDate,
                batchNumber: batchNumber,
                status: status,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $PurchasesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({storeId = false, userId = false, scanEventsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (scanEventsRefs) db.scanEvents],
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
                        if (storeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.storeId,
                                    referencedTable: $PurchasesReferences
                                        ._storeIdTable(db),
                                    referencedColumn: $PurchasesReferences
                                        ._storeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable: $PurchasesReferences
                                        ._userIdTable(db),
                                    referencedColumn: $PurchasesReferences
                                        ._userIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (scanEventsRefs)
                        await $_getPrefetchedData<
                          Purchase,
                          Purchases,
                          ScanEvent
                        >(
                          currentTable: table,
                          referencedTable: $PurchasesReferences
                              ._scanEventsRefsTable(db),
                          managerFromTypedResult: (p0) => $PurchasesReferences(
                            db,
                            table,
                            p0,
                          ).scanEventsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.purchaseId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $PurchasesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Purchases,
      Purchase,
      $PurchasesFilterComposer,
      $PurchasesOrderingComposer,
      $PurchasesAnnotationComposer,
      $PurchasesCreateCompanionBuilder,
      $PurchasesUpdateCompanionBuilder,
      (Purchase, $PurchasesReferences),
      Purchase,
      PrefetchHooks Function({bool storeId, bool userId, bool scanEventsRefs})
    >;
typedef $ScanEventsCreateCompanionBuilder =
    ScanEventsCompanion Function({
      required String id,
      required String storeId,
      Value<String?> purchaseId,
      required String outcome,
      Value<String?> scannedName,
      Value<String?> scannedNationalId,
      required int scannedAt,
      Value<int> rowid,
    });
typedef $ScanEventsUpdateCompanionBuilder =
    ScanEventsCompanion Function({
      Value<String> id,
      Value<String> storeId,
      Value<String?> purchaseId,
      Value<String> outcome,
      Value<String?> scannedName,
      Value<String?> scannedNationalId,
      Value<int> scannedAt,
      Value<int> rowid,
    });

final class $ScanEventsReferences
    extends BaseReferences<_$AppDatabase, ScanEvents, ScanEvent> {
  $ScanEventsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Stores _storeIdTable(_$AppDatabase db) =>
      db.stores.createAlias('scan_events__store_id__stores__id');

  $StoresProcessedTableManager get storeId {
    final $_column = $_itemColumn<String>('store_id')!;

    final manager = $StoresTableManager(
      $_db,
      $_db.stores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Purchases _purchaseIdTable(_$AppDatabase db) =>
      db.purchases.createAlias('scan_events__purchase_id__purchases__id');

  $PurchasesProcessedTableManager? get purchaseId {
    final $_column = $_itemColumn<String>('purchase_id');
    if ($_column == null) return null;
    final manager = $PurchasesTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_purchaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ScanEventsFilterComposer extends Composer<_$AppDatabase, ScanEvents> {
  $ScanEventsFilterComposer({
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

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scannedName => $composableBuilder(
    column: $table.scannedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scannedNationalId => $composableBuilder(
    column: $table.scannedNationalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnFilters(column),
  );

  $StoresFilterComposer get storeId {
    final $StoresFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresFilterComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $PurchasesFilterComposer get purchaseId {
    final $PurchasesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchasesFilterComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ScanEventsOrderingComposer extends Composer<_$AppDatabase, ScanEvents> {
  $ScanEventsOrderingComposer({
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

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scannedName => $composableBuilder(
    column: $table.scannedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scannedNationalId => $composableBuilder(
    column: $table.scannedNationalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $StoresOrderingComposer get storeId {
    final $StoresOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresOrderingComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $PurchasesOrderingComposer get purchaseId {
    final $PurchasesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchasesOrderingComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ScanEventsAnnotationComposer
    extends Composer<_$AppDatabase, ScanEvents> {
  $ScanEventsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);

  GeneratedColumn<String> get scannedName => $composableBuilder(
    column: $table.scannedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get scannedNationalId => $composableBuilder(
    column: $table.scannedNationalId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);

  $StoresAnnotationComposer get storeId {
    final $StoresAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresAnnotationComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $PurchasesAnnotationComposer get purchaseId {
    final $PurchasesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchasesAnnotationComposer(
            $db: $db,
            $table: $db.purchases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ScanEventsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ScanEvents,
          ScanEvent,
          $ScanEventsFilterComposer,
          $ScanEventsOrderingComposer,
          $ScanEventsAnnotationComposer,
          $ScanEventsCreateCompanionBuilder,
          $ScanEventsUpdateCompanionBuilder,
          (ScanEvent, $ScanEventsReferences),
          ScanEvent,
          PrefetchHooks Function({bool storeId, bool purchaseId})
        > {
  $ScanEventsTableManager(_$AppDatabase db, ScanEvents table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ScanEventsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ScanEventsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ScanEventsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<String?> purchaseId = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<String?> scannedName = const Value.absent(),
                Value<String?> scannedNationalId = const Value.absent(),
                Value<int> scannedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ScanEventsCompanion(
                id: id,
                storeId: storeId,
                purchaseId: purchaseId,
                outcome: outcome,
                scannedName: scannedName,
                scannedNationalId: scannedNationalId,
                scannedAt: scannedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String storeId,
                Value<String?> purchaseId = const Value.absent(),
                required String outcome,
                Value<String?> scannedName = const Value.absent(),
                Value<String?> scannedNationalId = const Value.absent(),
                required int scannedAt,
                Value<int> rowid = const Value.absent(),
              }) => ScanEventsCompanion.insert(
                id: id,
                storeId: storeId,
                purchaseId: purchaseId,
                outcome: outcome,
                scannedName: scannedName,
                scannedNationalId: scannedNationalId,
                scannedAt: scannedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $ScanEventsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({storeId = false, purchaseId = false}) {
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
                    if (storeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.storeId,
                                referencedTable: $ScanEventsReferences
                                    ._storeIdTable(db),
                                referencedColumn: $ScanEventsReferences
                                    ._storeIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (purchaseId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.purchaseId,
                                referencedTable: $ScanEventsReferences
                                    ._purchaseIdTable(db),
                                referencedColumn: $ScanEventsReferences
                                    ._purchaseIdTable(db)
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

typedef $ScanEventsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ScanEvents,
      ScanEvent,
      $ScanEventsFilterComposer,
      $ScanEventsOrderingComposer,
      $ScanEventsAnnotationComposer,
      $ScanEventsCreateCompanionBuilder,
      $ScanEventsUpdateCompanionBuilder,
      (ScanEvent, $ScanEventsReferences),
      ScanEvent,
      PrefetchHooks Function({bool storeId, bool purchaseId})
    >;
typedef $StorePinsCreateCompanionBuilder =
    StorePinsCompanion Function({
      required String userId,
      required String storeId,
      required int createdAt,
      Value<int> rowid,
    });
typedef $StorePinsUpdateCompanionBuilder =
    StorePinsCompanion Function({
      Value<String> userId,
      Value<String> storeId,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $StorePinsReferences
    extends BaseReferences<_$AppDatabase, StorePins, StorePin> {
  $StorePinsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Users _userIdTable(_$AppDatabase db) =>
      db.users.createAlias('store_pins__user_id__users__id');

  $UsersProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Stores _storeIdTable(_$AppDatabase db) =>
      db.stores.createAlias('store_pins__store_id__stores__id');

  $StoresProcessedTableManager get storeId {
    final $_column = $_itemColumn<String>('store_id')!;

    final manager = $StoresTableManager(
      $_db,
      $_db.stores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $StorePinsFilterComposer extends Composer<_$AppDatabase, StorePins> {
  $StorePinsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $UsersFilterComposer get userId {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $StoresFilterComposer get storeId {
    final $StoresFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresFilterComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StorePinsOrderingComposer extends Composer<_$AppDatabase, StorePins> {
  $StorePinsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $UsersOrderingComposer get userId {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $StoresOrderingComposer get storeId {
    final $StoresOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresOrderingComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StorePinsAnnotationComposer extends Composer<_$AppDatabase, StorePins> {
  $StorePinsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $UsersAnnotationComposer get userId {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $StoresAnnotationComposer get storeId {
    final $StoresAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $StoresAnnotationComposer(
            $db: $db,
            $table: $db.stores,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $StorePinsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          StorePins,
          StorePin,
          $StorePinsFilterComposer,
          $StorePinsOrderingComposer,
          $StorePinsAnnotationComposer,
          $StorePinsCreateCompanionBuilder,
          $StorePinsUpdateCompanionBuilder,
          (StorePin, $StorePinsReferences),
          StorePin,
          PrefetchHooks Function({bool userId, bool storeId})
        > {
  $StorePinsTableManager(_$AppDatabase db, StorePins table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $StorePinsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $StorePinsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $StorePinsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> storeId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StorePinsCompanion(
                userId: userId,
                storeId: storeId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String storeId,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => StorePinsCompanion.insert(
                userId: userId,
                storeId: storeId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $StorePinsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false, storeId = false}) {
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
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: $StorePinsReferences
                                    ._userIdTable(db),
                                referencedColumn: $StorePinsReferences
                                    ._userIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (storeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.storeId,
                                referencedTable: $StorePinsReferences
                                    ._storeIdTable(db),
                                referencedColumn: $StorePinsReferences
                                    ._storeIdTable(db)
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

typedef $StorePinsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      StorePins,
      StorePin,
      $StorePinsFilterComposer,
      $StorePinsOrderingComposer,
      $StorePinsAnnotationComposer,
      $StorePinsCreateCompanionBuilder,
      $StorePinsUpdateCompanionBuilder,
      (StorePin, $StorePinsReferences),
      StorePin,
      PrefetchHooks Function({bool userId, bool storeId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $StoresTableManager get stores => $StoresTableManager(_db, _db.stores);
  $UsersTableManager get users => $UsersTableManager(_db, _db.users);
  $PurchasesTableManager get purchases =>
      $PurchasesTableManager(_db, _db.purchases);
  $ScanEventsTableManager get scanEvents =>
      $ScanEventsTableManager(_db, _db.scanEvents);
  $StorePinsTableManager get storePins =>
      $StorePinsTableManager(_db, _db.storePins);
}
