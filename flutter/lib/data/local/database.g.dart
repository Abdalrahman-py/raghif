// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class Stores extends Table with TableInfo<Stores, Store> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Stores(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
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
  static const VerificationMeta _ownerPhoneMeta = const VerificationMeta(
    'ownerPhone',
  );
  late final GeneratedColumn<String> ownerPhone = GeneratedColumn<String>(
    'owner_phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _isOpenMeta = const VerificationMeta('isOpen');
  late final GeneratedColumn<bool> isOpen = GeneratedColumn<bool>(
    'is_open',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _dailyBagLimitMeta = const VerificationMeta(
    'dailyBagLimit',
  );
  late final GeneratedColumn<int> dailyBagLimit = GeneratedColumn<int>(
    'daily_bag_limit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bagsRemainingMeta = const VerificationMeta(
    'bagsRemaining',
  );
  late final GeneratedColumn<int> bagsRemaining = GeneratedColumn<int>(
    'bags_remaining',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    ownerPhone,
    isOpen,
    dailyBagLimit,
    bagsRemaining,
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
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('owner_phone')) {
      context.handle(
        _ownerPhoneMeta,
        ownerPhone.isAcceptableOrUnknown(data['owner_phone']!, _ownerPhoneMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerPhoneMeta);
    }
    if (data.containsKey('is_open')) {
      context.handle(
        _isOpenMeta,
        isOpen.isAcceptableOrUnknown(data['is_open']!, _isOpenMeta),
      );
    } else if (isInserting) {
      context.missing(_isOpenMeta);
    }
    if (data.containsKey('daily_bag_limit')) {
      context.handle(
        _dailyBagLimitMeta,
        dailyBagLimit.isAcceptableOrUnknown(
          data['daily_bag_limit']!,
          _dailyBagLimitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyBagLimitMeta);
    }
    if (data.containsKey('bags_remaining')) {
      context.handle(
        _bagsRemainingMeta,
        bagsRemaining.isAcceptableOrUnknown(
          data['bags_remaining']!,
          _bagsRemainingMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_bagsRemainingMeta);
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
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ownerPhone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_phone'],
      )!,
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
  final int id;
  final String name;
  final String ownerPhone;
  final bool isOpen;
  final int dailyBagLimit;
  final int bagsRemaining;
  const Store({
    required this.id,
    required this.name,
    required this.ownerPhone,
    required this.isOpen,
    required this.dailyBagLimit,
    required this.bagsRemaining,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['owner_phone'] = Variable<String>(ownerPhone);
    map['is_open'] = Variable<bool>(isOpen);
    map['daily_bag_limit'] = Variable<int>(dailyBagLimit);
    map['bags_remaining'] = Variable<int>(bagsRemaining);
    return map;
  }

  StoresCompanion toCompanion(bool nullToAbsent) {
    return StoresCompanion(
      id: Value(id),
      name: Value(name),
      ownerPhone: Value(ownerPhone),
      isOpen: Value(isOpen),
      dailyBagLimit: Value(dailyBagLimit),
      bagsRemaining: Value(bagsRemaining),
    );
  }

  factory Store.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Store(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      ownerPhone: serializer.fromJson<String>(json['owner_phone']),
      isOpen: serializer.fromJson<bool>(json['is_open']),
      dailyBagLimit: serializer.fromJson<int>(json['daily_bag_limit']),
      bagsRemaining: serializer.fromJson<int>(json['bags_remaining']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'owner_phone': serializer.toJson<String>(ownerPhone),
      'is_open': serializer.toJson<bool>(isOpen),
      'daily_bag_limit': serializer.toJson<int>(dailyBagLimit),
      'bags_remaining': serializer.toJson<int>(bagsRemaining),
    };
  }

  Store copyWith({
    int? id,
    String? name,
    String? ownerPhone,
    bool? isOpen,
    int? dailyBagLimit,
    int? bagsRemaining,
  }) => Store(
    id: id ?? this.id,
    name: name ?? this.name,
    ownerPhone: ownerPhone ?? this.ownerPhone,
    isOpen: isOpen ?? this.isOpen,
    dailyBagLimit: dailyBagLimit ?? this.dailyBagLimit,
    bagsRemaining: bagsRemaining ?? this.bagsRemaining,
  );
  Store copyWithCompanion(StoresCompanion data) {
    return Store(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      ownerPhone: data.ownerPhone.present
          ? data.ownerPhone.value
          : this.ownerPhone,
      isOpen: data.isOpen.present ? data.isOpen.value : this.isOpen,
      dailyBagLimit: data.dailyBagLimit.present
          ? data.dailyBagLimit.value
          : this.dailyBagLimit,
      bagsRemaining: data.bagsRemaining.present
          ? data.bagsRemaining.value
          : this.bagsRemaining,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Store(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerPhone: $ownerPhone, ')
          ..write('isOpen: $isOpen, ')
          ..write('dailyBagLimit: $dailyBagLimit, ')
          ..write('bagsRemaining: $bagsRemaining')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, ownerPhone, isOpen, dailyBagLimit, bagsRemaining);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Store &&
          other.id == this.id &&
          other.name == this.name &&
          other.ownerPhone == this.ownerPhone &&
          other.isOpen == this.isOpen &&
          other.dailyBagLimit == this.dailyBagLimit &&
          other.bagsRemaining == this.bagsRemaining);
}

class StoresCompanion extends UpdateCompanion<Store> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> ownerPhone;
  final Value<bool> isOpen;
  final Value<int> dailyBagLimit;
  final Value<int> bagsRemaining;
  const StoresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.ownerPhone = const Value.absent(),
    this.isOpen = const Value.absent(),
    this.dailyBagLimit = const Value.absent(),
    this.bagsRemaining = const Value.absent(),
  });
  StoresCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String ownerPhone,
    required bool isOpen,
    required int dailyBagLimit,
    required int bagsRemaining,
  }) : name = Value(name),
       ownerPhone = Value(ownerPhone),
       isOpen = Value(isOpen),
       dailyBagLimit = Value(dailyBagLimit),
       bagsRemaining = Value(bagsRemaining);
  static Insertable<Store> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? ownerPhone,
    Expression<bool>? isOpen,
    Expression<int>? dailyBagLimit,
    Expression<int>? bagsRemaining,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (ownerPhone != null) 'owner_phone': ownerPhone,
      if (isOpen != null) 'is_open': isOpen,
      if (dailyBagLimit != null) 'daily_bag_limit': dailyBagLimit,
      if (bagsRemaining != null) 'bags_remaining': bagsRemaining,
    });
  }

  StoresCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? ownerPhone,
    Value<bool>? isOpen,
    Value<int>? dailyBagLimit,
    Value<int>? bagsRemaining,
  }) {
    return StoresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      isOpen: isOpen ?? this.isOpen,
      dailyBagLimit: dailyBagLimit ?? this.dailyBagLimit,
      bagsRemaining: bagsRemaining ?? this.bagsRemaining,
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
    if (ownerPhone.present) {
      map['owner_phone'] = Variable<String>(ownerPhone.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoresCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('ownerPhone: $ownerPhone, ')
          ..write('isOpen: $isOpen, ')
          ..write('dailyBagLimit: $dailyBagLimit, ')
          ..write('bagsRemaining: $bagsRemaining')
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
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _nationalIdMeta = const VerificationMeta(
    'nationalId',
  );
  late final GeneratedColumn<String> nationalId = GeneratedColumn<String>(
    'national_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _pinHashMeta = const VerificationMeta(
    'pinHash',
  );
  late final GeneratedColumn<String> pinHash = GeneratedColumn<String>(
    'pin_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, phone, nationalId, pinHash];
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
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    } else if (isInserting) {
      context.missing(_phoneMeta);
    }
    if (data.containsKey('national_id')) {
      context.handle(
        _nationalIdMeta,
        nationalId.isAcceptableOrUnknown(data['national_id']!, _nationalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nationalIdMeta);
    }
    if (data.containsKey('pin_hash')) {
      context.handle(
        _pinHashMeta,
        pinHash.isAcceptableOrUnknown(data['pin_hash']!, _pinHashMeta),
      );
    } else if (isInserting) {
      context.missing(_pinHashMeta);
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
        DriftSqlType.int,
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
      pinHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pin_hash'],
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
  final int id;
  final String phone;
  final String nationalId;
  final String pinHash;
  const User({
    required this.id,
    required this.phone,
    required this.nationalId,
    required this.pinHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['phone'] = Variable<String>(phone);
    map['national_id'] = Variable<String>(nationalId);
    map['pin_hash'] = Variable<String>(pinHash);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      phone: Value(phone),
      nationalId: Value(nationalId),
      pinHash: Value(pinHash),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      phone: serializer.fromJson<String>(json['phone']),
      nationalId: serializer.fromJson<String>(json['national_id']),
      pinHash: serializer.fromJson<String>(json['pin_hash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'phone': serializer.toJson<String>(phone),
      'national_id': serializer.toJson<String>(nationalId),
      'pin_hash': serializer.toJson<String>(pinHash),
    };
  }

  User copyWith({
    int? id,
    String? phone,
    String? nationalId,
    String? pinHash,
  }) => User(
    id: id ?? this.id,
    phone: phone ?? this.phone,
    nationalId: nationalId ?? this.nationalId,
    pinHash: pinHash ?? this.pinHash,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      phone: data.phone.present ? data.phone.value : this.phone,
      nationalId: data.nationalId.present
          ? data.nationalId.value
          : this.nationalId,
      pinHash: data.pinHash.present ? data.pinHash.value : this.pinHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('nationalId: $nationalId, ')
          ..write('pinHash: $pinHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, phone, nationalId, pinHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.phone == this.phone &&
          other.nationalId == this.nationalId &&
          other.pinHash == this.pinHash);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> phone;
  final Value<String> nationalId;
  final Value<String> pinHash;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.phone = const Value.absent(),
    this.nationalId = const Value.absent(),
    this.pinHash = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String phone,
    required String nationalId,
    required String pinHash,
  }) : phone = Value(phone),
       nationalId = Value(nationalId),
       pinHash = Value(pinHash);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? phone,
    Expression<String>? nationalId,
    Expression<String>? pinHash,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (phone != null) 'phone': phone,
      if (nationalId != null) 'national_id': nationalId,
      if (pinHash != null) 'pin_hash': pinHash,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? phone,
    Value<String>? nationalId,
    Value<String>? pinHash,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      nationalId: nationalId ?? this.nationalId,
      pinHash: pinHash ?? this.pinHash,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (nationalId.present) {
      map['national_id'] = Variable<String>(nationalId.value);
    }
    if (pinHash.present) {
      map['pin_hash'] = Variable<String>(pinHash.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('phone: $phone, ')
          ..write('nationalId: $nationalId, ')
          ..write('pinHash: $pinHash')
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
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  late final GeneratedColumn<int> storeId = GeneratedColumn<int>(
    'store_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES stores(id)',
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES users(id)',
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (status IN (\'waiting\', \'notified\', \'collected\'))',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
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
    } else if (isInserting) {
      context.missing(_batchNumberMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
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
    {userId, storeId, purchaseDate},
  ];
  @override
  Purchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Purchase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}store_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      )!,
      batchNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}batch_number'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Purchases createAlias(String alias) {
    return Purchases(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(user_id, store_id, purchase_date)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Purchase extends DataClass implements Insertable<Purchase> {
  final int id;
  final int storeId;
  final int userId;
  final DateTime purchaseDate;
  final int batchNumber;
  final String status;
  final DateTime createdAt;
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
    map['id'] = Variable<int>(id);
    map['store_id'] = Variable<int>(storeId);
    map['user_id'] = Variable<int>(userId);
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    map['batch_number'] = Variable<int>(batchNumber);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
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
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<int>(json['store_id']),
      userId: serializer.fromJson<int>(json['user_id']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchase_date']),
      batchNumber: serializer.fromJson<int>(json['batch_number']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'store_id': serializer.toJson<int>(storeId),
      'user_id': serializer.toJson<int>(userId),
      'purchase_date': serializer.toJson<DateTime>(purchaseDate),
      'batch_number': serializer.toJson<int>(batchNumber),
      'status': serializer.toJson<String>(status),
      'created_at': serializer.toJson<DateTime>(createdAt),
    };
  }

  Purchase copyWith({
    int? id,
    int? storeId,
    int? userId,
    DateTime? purchaseDate,
    int? batchNumber,
    String? status,
    DateTime? createdAt,
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
  final Value<int> id;
  final Value<int> storeId;
  final Value<int> userId;
  final Value<DateTime> purchaseDate;
  final Value<int> batchNumber;
  final Value<String> status;
  final Value<DateTime> createdAt;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.userId = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.batchNumber = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PurchasesCompanion.insert({
    this.id = const Value.absent(),
    required int storeId,
    required int userId,
    required DateTime purchaseDate,
    required int batchNumber,
    required String status,
    required DateTime createdAt,
  }) : storeId = Value(storeId),
       userId = Value(userId),
       purchaseDate = Value(purchaseDate),
       batchNumber = Value(batchNumber),
       status = Value(status),
       createdAt = Value(createdAt);
  static Insertable<Purchase> custom({
    Expression<int>? id,
    Expression<int>? storeId,
    Expression<int>? userId,
    Expression<DateTime>? purchaseDate,
    Expression<int>? batchNumber,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (userId != null) 'user_id': userId,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (batchNumber != null) 'batch_number': batchNumber,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PurchasesCompanion copyWith({
    Value<int>? id,
    Value<int>? storeId,
    Value<int>? userId,
    Value<DateTime>? purchaseDate,
    Value<int>? batchNumber,
    Value<String>? status,
    Value<DateTime>? createdAt,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      userId: userId ?? this.userId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      batchNumber: batchNumber ?? this.batchNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<int>(storeId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (batchNumber.present) {
      map['batch_number'] = Variable<int>(batchNumber.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
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
          ..write('createdAt: $createdAt')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    stores,
    users,
    purchases,
  ];
}

typedef $StoresCreateCompanionBuilder =
    StoresCompanion Function({
      Value<int> id,
      required String name,
      required String ownerPhone,
      required bool isOpen,
      required int dailyBagLimit,
      required int bagsRemaining,
    });
typedef $StoresUpdateCompanionBuilder =
    StoresCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String> ownerPhone,
      Value<bool> isOpen,
      Value<int> dailyBagLimit,
      Value<int> bagsRemaining,
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
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerPhone => $composableBuilder(
    column: $table.ownerPhone,
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
}

class $StoresOrderingComposer extends Composer<_$AppDatabase, Stores> {
  $StoresOrderingComposer({
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

  ColumnOrderings<String> get ownerPhone => $composableBuilder(
    column: $table.ownerPhone,
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
}

class $StoresAnnotationComposer extends Composer<_$AppDatabase, Stores> {
  $StoresAnnotationComposer({
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

  GeneratedColumn<String> get ownerPhone => $composableBuilder(
    column: $table.ownerPhone,
    builder: (column) => column,
  );

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
          PrefetchHooks Function({bool purchasesRefs})
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
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> ownerPhone = const Value.absent(),
                Value<bool> isOpen = const Value.absent(),
                Value<int> dailyBagLimit = const Value.absent(),
                Value<int> bagsRemaining = const Value.absent(),
              }) => StoresCompanion(
                id: id,
                name: name,
                ownerPhone: ownerPhone,
                isOpen: isOpen,
                dailyBagLimit: dailyBagLimit,
                bagsRemaining: bagsRemaining,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                required String ownerPhone,
                required bool isOpen,
                required int dailyBagLimit,
                required int bagsRemaining,
              }) => StoresCompanion.insert(
                id: id,
                name: name,
                ownerPhone: ownerPhone,
                isOpen: isOpen,
                dailyBagLimit: dailyBagLimit,
                bagsRemaining: bagsRemaining,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $StoresReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({purchasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (purchasesRefs) db.purchases],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (purchasesRefs)
                    await $_getPrefetchedData<Store, Stores, Purchase>(
                      currentTable: table,
                      referencedTable: $StoresReferences._purchasesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $StoresReferences(db, table, p0).purchasesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.storeId == item.id),
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
      PrefetchHooks Function({bool purchasesRefs})
    >;
typedef $UsersCreateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      required String phone,
      required String nationalId,
      required String pinHash,
    });
typedef $UsersUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<int> id,
      Value<String> phone,
      Value<String> nationalId,
      Value<String> pinHash,
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
    ).filter((f) => f.userId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
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
  ColumnFilters<int> get id => $composableBuilder(
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

  ColumnFilters<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
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
}

class $UsersOrderingComposer extends Composer<_$AppDatabase, Users> {
  $UsersOrderingComposer({
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

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pinHash => $composableBuilder(
    column: $table.pinHash,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get nationalId => $composableBuilder(
    column: $table.nationalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pinHash =>
      $composableBuilder(column: $table.pinHash, builder: (column) => column);

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
          PrefetchHooks Function({bool purchasesRefs})
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
                Value<int> id = const Value.absent(),
                Value<String> phone = const Value.absent(),
                Value<String> nationalId = const Value.absent(),
                Value<String> pinHash = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                phone: phone,
                nationalId: nationalId,
                pinHash: pinHash,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String phone,
                required String nationalId,
                required String pinHash,
              }) => UsersCompanion.insert(
                id: id,
                phone: phone,
                nationalId: nationalId,
                pinHash: pinHash,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $UsersReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({purchasesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (purchasesRefs) db.purchases],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (purchasesRefs)
                    await $_getPrefetchedData<User, Users, Purchase>(
                      currentTable: table,
                      referencedTable: $UsersReferences._purchasesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $UsersReferences(db, table, p0).purchasesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.userId == item.id),
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
      PrefetchHooks Function({bool purchasesRefs})
    >;
typedef $PurchasesCreateCompanionBuilder =
    PurchasesCompanion Function({
      Value<int> id,
      required int storeId,
      required int userId,
      required DateTime purchaseDate,
      required int batchNumber,
      required String status,
      required DateTime createdAt,
    });
typedef $PurchasesUpdateCompanionBuilder =
    PurchasesCompanion Function({
      Value<int> id,
      Value<int> storeId,
      Value<int> userId,
      Value<DateTime> purchaseDate,
      Value<int> batchNumber,
      Value<String> status,
      Value<DateTime> createdAt,
    });

final class $PurchasesReferences
    extends BaseReferences<_$AppDatabase, Purchases, Purchase> {
  $PurchasesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Stores _storeIdTable(_$AppDatabase db) =>
      db.stores.createAlias('purchases__store_id__stores__id');

  $StoresProcessedTableManager get storeId {
    final $_column = $_itemColumn<int>('store_id')!;

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
    final $_column = $_itemColumn<int>('user_id')!;

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
}

class $PurchasesFilterComposer extends Composer<_$AppDatabase, Purchases> {
  $PurchasesFilterComposer({
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

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get batchNumber => $composableBuilder(
    column: $table.batchNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
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
}

class $PurchasesOrderingComposer extends Composer<_$AppDatabase, Purchases> {
  $PurchasesOrderingComposer({
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

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get batchNumber => $composableBuilder(
    column: $table.batchNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
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
          PrefetchHooks Function({bool storeId, bool userId})
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
                Value<int> id = const Value.absent(),
                Value<int> storeId = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<DateTime> purchaseDate = const Value.absent(),
                Value<int> batchNumber = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => PurchasesCompanion(
                id: id,
                storeId: storeId,
                userId: userId,
                purchaseDate: purchaseDate,
                batchNumber: batchNumber,
                status: status,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int storeId,
                required int userId,
                required DateTime purchaseDate,
                required int batchNumber,
                required String status,
                required DateTime createdAt,
              }) => PurchasesCompanion.insert(
                id: id,
                storeId: storeId,
                userId: userId,
                purchaseDate: purchaseDate,
                batchNumber: batchNumber,
                status: status,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $PurchasesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({storeId = false, userId = false}) {
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
                return [];
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
      PrefetchHooks Function({bool storeId, bool userId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $StoresTableManager get stores => $StoresTableManager(_db, _db.stores);
  $UsersTableManager get users => $UsersTableManager(_db, _db.users);
  $PurchasesTableManager get purchases =>
      $PurchasesTableManager(_db, _db.purchases);
}
