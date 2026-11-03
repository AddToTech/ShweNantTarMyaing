// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BranchesCacheTable extends BranchesCache
    with TableInfo<$BranchesCacheTable, BranchesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, address, isActive, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branches_cache';
  @override
  VerificationContext validateIntegrity(Insertable<BranchesCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BranchesCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BranchesCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BranchesCacheTable createAlias(String alias) {
    return $BranchesCacheTable(attachedDatabase, alias);
  }
}

class BranchesCacheData extends DataClass
    implements Insertable<BranchesCacheData> {
  final String id;
  final String name;
  final String? address;
  final bool isActive;
  final DateTime updatedAt;
  const BranchesCacheData(
      {required this.id,
      required this.name,
      this.address,
      required this.isActive,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BranchesCacheCompanion toCompanion(bool nullToAbsent) {
    return BranchesCacheCompanion(
      id: Value(id),
      name: Value(name),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory BranchesCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BranchesCacheData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String?>(json['address']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String?>(address),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BranchesCacheData copyWith(
          {String? id,
          String? name,
          Value<String?> address = const Value.absent(),
          bool? isActive,
          DateTime? updatedAt}) =>
      BranchesCacheData(
        id: id ?? this.id,
        name: name ?? this.name,
        address: address.present ? address.value : this.address,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BranchesCacheData copyWithCompanion(BranchesCacheCompanion data) {
    return BranchesCacheData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BranchesCacheData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, address, isActive, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BranchesCacheData &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class BranchesCacheCompanion extends UpdateCompanion<BranchesCacheData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> address;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BranchesCacheCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BranchesCacheCompanion.insert({
    required String id,
    required String name,
    this.address = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<BranchesCacheData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BranchesCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? address,
      Value<bool>? isActive,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BranchesCacheCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchesCacheCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesCacheTable extends CategoriesCache
    with TableInfo<$CategoriesCacheTable, CategoriesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [id, name, sortOrder, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<CategoriesCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoriesCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoriesCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $CategoriesCacheTable createAlias(String alias) {
    return $CategoriesCacheTable(attachedDatabase, alias);
  }
}

class CategoriesCacheData extends DataClass
    implements Insertable<CategoriesCacheData> {
  final String id;
  final String name;
  final int sortOrder;
  final DateTime updatedAt;
  const CategoriesCacheData(
      {required this.id,
      required this.name,
      required this.sortOrder,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  CategoriesCacheCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCacheCompanion(
      id: Value(id),
      name: Value(name),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory CategoriesCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoriesCacheData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  CategoriesCacheData copyWith(
          {String? id, String? name, int? sortOrder, DateTime? updatedAt}) =>
      CategoriesCacheData(
        id: id ?? this.id,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  CategoriesCacheData copyWithCompanion(CategoriesCacheCompanion data) {
    return CategoriesCacheData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCacheData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoriesCacheData &&
          other.id == this.id &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class CategoriesCacheCompanion extends UpdateCompanion<CategoriesCacheData> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const CategoriesCacheCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCacheCompanion.insert({
    required String id,
    required String name,
    this.sortOrder = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<CategoriesCacheData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return CategoriesCacheCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCacheCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SubcategoriesCacheTable extends SubcategoriesCache
    with TableInfo<$SubcategoriesCacheTable, SubcategoriesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubcategoriesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryId, name, sortOrder, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subcategories_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<SubcategoriesCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubcategoriesCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubcategoriesCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $SubcategoriesCacheTable createAlias(String alias) {
    return $SubcategoriesCacheTable(attachedDatabase, alias);
  }
}

class SubcategoriesCacheData extends DataClass
    implements Insertable<SubcategoriesCacheData> {
  final String id;
  final String categoryId;
  final String name;
  final int sortOrder;
  final DateTime updatedAt;
  const SubcategoriesCacheData(
      {required this.id,
      required this.categoryId,
      required this.name,
      required this.sortOrder,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SubcategoriesCacheCompanion toCompanion(bool nullToAbsent) {
    return SubcategoriesCacheCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      sortOrder: Value(sortOrder),
      updatedAt: Value(updatedAt),
    );
  }

  factory SubcategoriesCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubcategoriesCacheData(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SubcategoriesCacheData copyWith(
          {String? id,
          String? categoryId,
          String? name,
          int? sortOrder,
          DateTime? updatedAt}) =>
      SubcategoriesCacheData(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        name: name ?? this.name,
        sortOrder: sortOrder ?? this.sortOrder,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SubcategoriesCacheData copyWithCompanion(SubcategoriesCacheCompanion data) {
    return SubcategoriesCacheData(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubcategoriesCacheData(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, name, sortOrder, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubcategoriesCacheData &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder &&
          other.updatedAt == this.updatedAt);
}

class SubcategoriesCacheCompanion
    extends UpdateCompanion<SubcategoriesCacheData> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SubcategoriesCacheCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SubcategoriesCacheCompanion.insert({
    required String id,
    required String categoryId,
    required String name,
    this.sortOrder = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        categoryId = Value(categoryId),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<SubcategoriesCacheData> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SubcategoriesCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? categoryId,
      Value<String>? name,
      Value<int>? sortOrder,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return SubcategoriesCacheCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubcategoriesCacheCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsCacheTable extends ProductsCache
    with TableInfo<$ProductsCacheTable, ProductsCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
      'category_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _subcategoryIdMeta =
      const VerificationMeta('subcategoryId');
  @override
  late final GeneratedColumn<String> subcategoryId = GeneratedColumn<String>(
      'subcategory_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
      'sku', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _barcodeMeta =
      const VerificationMeta('barcode');
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
      'barcode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _costPriceMeta =
      const VerificationMeta('costPrice');
  @override
  late final GeneratedColumn<double> costPrice = GeneratedColumn<double>(
      'cost_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _salePriceMeta =
      const VerificationMeta('salePrice');
  @override
  late final GeneratedColumn<double> salePrice = GeneratedColumn<double>(
      'sale_price', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _originTypeMeta =
      const VerificationMeta('originType');
  @override
  late final GeneratedColumn<String> originType = GeneratedColumn<String>(
      'origin_type', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _sizeLabelMeta =
      const VerificationMeta('sizeLabel');
  @override
  late final GeneratedColumn<String> sizeLabel = GeneratedColumn<String>(
      'size_label', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _unitOfMeasureMeta =
      const VerificationMeta('unitOfMeasure');
  @override
  late final GeneratedColumn<String> unitOfMeasure = GeneratedColumn<String>(
      'unit_of_measure', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('piece'));
  static const VerificationMeta _attributesJsonMeta =
      const VerificationMeta('attributesJson');
  @override
  late final GeneratedColumn<String> attributesJson = GeneratedColumn<String>(
      'attributes_json', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('{}'));
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        categoryId,
        subcategoryId,
        name,
        sku,
        barcode,
        costPrice,
        salePrice,
        originType,
        sizeLabel,
        unitOfMeasure,
        attributesJson,
        isActive,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products_cache';
  @override
  VerificationContext validateIntegrity(Insertable<ProductsCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('subcategory_id')) {
      context.handle(
          _subcategoryIdMeta,
          subcategoryId.isAcceptableOrUnknown(
              data['subcategory_id']!, _subcategoryIdMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
          _skuMeta, sku.isAcceptableOrUnknown(data['sku']!, _skuMeta));
    }
    if (data.containsKey('barcode')) {
      context.handle(_barcodeMeta,
          barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta));
    }
    if (data.containsKey('cost_price')) {
      context.handle(_costPriceMeta,
          costPrice.isAcceptableOrUnknown(data['cost_price']!, _costPriceMeta));
    }
    if (data.containsKey('sale_price')) {
      context.handle(_salePriceMeta,
          salePrice.isAcceptableOrUnknown(data['sale_price']!, _salePriceMeta));
    }
    if (data.containsKey('origin_type')) {
      context.handle(
          _originTypeMeta,
          originType.isAcceptableOrUnknown(
              data['origin_type']!, _originTypeMeta));
    }
    if (data.containsKey('size_label')) {
      context.handle(_sizeLabelMeta,
          sizeLabel.isAcceptableOrUnknown(data['size_label']!, _sizeLabelMeta));
    }
    if (data.containsKey('unit_of_measure')) {
      context.handle(
          _unitOfMeasureMeta,
          unitOfMeasure.isAcceptableOrUnknown(
              data['unit_of_measure']!, _unitOfMeasureMeta));
    }
    if (data.containsKey('attributes_json')) {
      context.handle(
          _attributesJsonMeta,
          attributesJson.isAcceptableOrUnknown(
              data['attributes_json']!, _attributesJsonMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductsCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category_id'])!,
      subcategoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}subcategory_id']),
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      sku: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sku']),
      barcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}barcode']),
      costPrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}cost_price'])!,
      salePrice: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}sale_price'])!,
      originType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}origin_type']),
      sizeLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}size_label']),
      unitOfMeasure: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}unit_of_measure'])!,
      attributesJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}attributes_json'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ProductsCacheTable createAlias(String alias) {
    return $ProductsCacheTable(attachedDatabase, alias);
  }
}

class ProductsCacheData extends DataClass
    implements Insertable<ProductsCacheData> {
  final String id;
  final String categoryId;
  final String? subcategoryId;
  final String name;
  final String? sku;
  final String? barcode;
  final double costPrice;
  final double salePrice;
  final String? originType;
  final String? sizeLabel;
  final String unitOfMeasure;
  final String attributesJson;
  final bool isActive;
  final DateTime updatedAt;
  const ProductsCacheData(
      {required this.id,
      required this.categoryId,
      this.subcategoryId,
      required this.name,
      this.sku,
      this.barcode,
      required this.costPrice,
      required this.salePrice,
      this.originType,
      this.sizeLabel,
      required this.unitOfMeasure,
      required this.attributesJson,
      required this.isActive,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || subcategoryId != null) {
      map['subcategory_id'] = Variable<String>(subcategoryId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sku != null) {
      map['sku'] = Variable<String>(sku);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['cost_price'] = Variable<double>(costPrice);
    map['sale_price'] = Variable<double>(salePrice);
    if (!nullToAbsent || originType != null) {
      map['origin_type'] = Variable<String>(originType);
    }
    if (!nullToAbsent || sizeLabel != null) {
      map['size_label'] = Variable<String>(sizeLabel);
    }
    map['unit_of_measure'] = Variable<String>(unitOfMeasure);
    map['attributes_json'] = Variable<String>(attributesJson);
    map['is_active'] = Variable<bool>(isActive);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCacheCompanion toCompanion(bool nullToAbsent) {
    return ProductsCacheCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      subcategoryId: subcategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subcategoryId),
      name: Value(name),
      sku: sku == null && nullToAbsent ? const Value.absent() : Value(sku),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      costPrice: Value(costPrice),
      salePrice: Value(salePrice),
      originType: originType == null && nullToAbsent
          ? const Value.absent()
          : Value(originType),
      sizeLabel: sizeLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeLabel),
      unitOfMeasure: Value(unitOfMeasure),
      attributesJson: Value(attributesJson),
      isActive: Value(isActive),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProductsCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsCacheData(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      subcategoryId: serializer.fromJson<String?>(json['subcategoryId']),
      name: serializer.fromJson<String>(json['name']),
      sku: serializer.fromJson<String?>(json['sku']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      costPrice: serializer.fromJson<double>(json['costPrice']),
      salePrice: serializer.fromJson<double>(json['salePrice']),
      originType: serializer.fromJson<String?>(json['originType']),
      sizeLabel: serializer.fromJson<String?>(json['sizeLabel']),
      unitOfMeasure: serializer.fromJson<String>(json['unitOfMeasure']),
      attributesJson: serializer.fromJson<String>(json['attributesJson']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'subcategoryId': serializer.toJson<String?>(subcategoryId),
      'name': serializer.toJson<String>(name),
      'sku': serializer.toJson<String?>(sku),
      'barcode': serializer.toJson<String?>(barcode),
      'costPrice': serializer.toJson<double>(costPrice),
      'salePrice': serializer.toJson<double>(salePrice),
      'originType': serializer.toJson<String?>(originType),
      'sizeLabel': serializer.toJson<String?>(sizeLabel),
      'unitOfMeasure': serializer.toJson<String>(unitOfMeasure),
      'attributesJson': serializer.toJson<String>(attributesJson),
      'isActive': serializer.toJson<bool>(isActive),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProductsCacheData copyWith(
          {String? id,
          String? categoryId,
          Value<String?> subcategoryId = const Value.absent(),
          String? name,
          Value<String?> sku = const Value.absent(),
          Value<String?> barcode = const Value.absent(),
          double? costPrice,
          double? salePrice,
          Value<String?> originType = const Value.absent(),
          Value<String?> sizeLabel = const Value.absent(),
          String? unitOfMeasure,
          String? attributesJson,
          bool? isActive,
          DateTime? updatedAt}) =>
      ProductsCacheData(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        subcategoryId:
            subcategoryId.present ? subcategoryId.value : this.subcategoryId,
        name: name ?? this.name,
        sku: sku.present ? sku.value : this.sku,
        barcode: barcode.present ? barcode.value : this.barcode,
        costPrice: costPrice ?? this.costPrice,
        salePrice: salePrice ?? this.salePrice,
        originType: originType.present ? originType.value : this.originType,
        sizeLabel: sizeLabel.present ? sizeLabel.value : this.sizeLabel,
        unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
        attributesJson: attributesJson ?? this.attributesJson,
        isActive: isActive ?? this.isActive,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ProductsCacheData copyWithCompanion(ProductsCacheCompanion data) {
    return ProductsCacheData(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      subcategoryId: data.subcategoryId.present
          ? data.subcategoryId.value
          : this.subcategoryId,
      name: data.name.present ? data.name.value : this.name,
      sku: data.sku.present ? data.sku.value : this.sku,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      costPrice: data.costPrice.present ? data.costPrice.value : this.costPrice,
      salePrice: data.salePrice.present ? data.salePrice.value : this.salePrice,
      originType:
          data.originType.present ? data.originType.value : this.originType,
      sizeLabel: data.sizeLabel.present ? data.sizeLabel.value : this.sizeLabel,
      unitOfMeasure: data.unitOfMeasure.present
          ? data.unitOfMeasure.value
          : this.unitOfMeasure,
      attributesJson: data.attributesJson.present
          ? data.attributesJson.value
          : this.attributesJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCacheData(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('costPrice: $costPrice, ')
          ..write('salePrice: $salePrice, ')
          ..write('originType: $originType, ')
          ..write('sizeLabel: $sizeLabel, ')
          ..write('unitOfMeasure: $unitOfMeasure, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      categoryId,
      subcategoryId,
      name,
      sku,
      barcode,
      costPrice,
      salePrice,
      originType,
      sizeLabel,
      unitOfMeasure,
      attributesJson,
      isActive,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsCacheData &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.subcategoryId == this.subcategoryId &&
          other.name == this.name &&
          other.sku == this.sku &&
          other.barcode == this.barcode &&
          other.costPrice == this.costPrice &&
          other.salePrice == this.salePrice &&
          other.originType == this.originType &&
          other.sizeLabel == this.sizeLabel &&
          other.unitOfMeasure == this.unitOfMeasure &&
          other.attributesJson == this.attributesJson &&
          other.isActive == this.isActive &&
          other.updatedAt == this.updatedAt);
}

class ProductsCacheCompanion extends UpdateCompanion<ProductsCacheData> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String?> subcategoryId;
  final Value<String> name;
  final Value<String?> sku;
  final Value<String?> barcode;
  final Value<double> costPrice;
  final Value<double> salePrice;
  final Value<String?> originType;
  final Value<String?> sizeLabel;
  final Value<String> unitOfMeasure;
  final Value<String> attributesJson;
  final Value<bool> isActive;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductsCacheCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subcategoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.originType = const Value.absent(),
    this.sizeLabel = const Value.absent(),
    this.unitOfMeasure = const Value.absent(),
    this.attributesJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCacheCompanion.insert({
    required String id,
    required String categoryId,
    this.subcategoryId = const Value.absent(),
    required String name,
    this.sku = const Value.absent(),
    this.barcode = const Value.absent(),
    this.costPrice = const Value.absent(),
    this.salePrice = const Value.absent(),
    this.originType = const Value.absent(),
    this.sizeLabel = const Value.absent(),
    this.unitOfMeasure = const Value.absent(),
    this.attributesJson = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        categoryId = Value(categoryId),
        name = Value(name),
        updatedAt = Value(updatedAt);
  static Insertable<ProductsCacheData> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? subcategoryId,
    Expression<String>? name,
    Expression<String>? sku,
    Expression<String>? barcode,
    Expression<double>? costPrice,
    Expression<double>? salePrice,
    Expression<String>? originType,
    Expression<String>? sizeLabel,
    Expression<String>? unitOfMeasure,
    Expression<String>? attributesJson,
    Expression<bool>? isActive,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      if (name != null) 'name': name,
      if (sku != null) 'sku': sku,
      if (barcode != null) 'barcode': barcode,
      if (costPrice != null) 'cost_price': costPrice,
      if (salePrice != null) 'sale_price': salePrice,
      if (originType != null) 'origin_type': originType,
      if (sizeLabel != null) 'size_label': sizeLabel,
      if (unitOfMeasure != null) 'unit_of_measure': unitOfMeasure,
      if (attributesJson != null) 'attributes_json': attributesJson,
      if (isActive != null) 'is_active': isActive,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? categoryId,
      Value<String?>? subcategoryId,
      Value<String>? name,
      Value<String?>? sku,
      Value<String?>? barcode,
      Value<double>? costPrice,
      Value<double>? salePrice,
      Value<String?>? originType,
      Value<String?>? sizeLabel,
      Value<String>? unitOfMeasure,
      Value<String>? attributesJson,
      Value<bool>? isActive,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return ProductsCacheCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      originType: originType ?? this.originType,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      attributesJson: attributesJson ?? this.attributesJson,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (subcategoryId.present) {
      map['subcategory_id'] = Variable<String>(subcategoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (costPrice.present) {
      map['cost_price'] = Variable<double>(costPrice.value);
    }
    if (salePrice.present) {
      map['sale_price'] = Variable<double>(salePrice.value);
    }
    if (originType.present) {
      map['origin_type'] = Variable<String>(originType.value);
    }
    if (sizeLabel.present) {
      map['size_label'] = Variable<String>(sizeLabel.value);
    }
    if (unitOfMeasure.present) {
      map['unit_of_measure'] = Variable<String>(unitOfMeasure.value);
    }
    if (attributesJson.present) {
      map['attributes_json'] = Variable<String>(attributesJson.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCacheCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('subcategoryId: $subcategoryId, ')
          ..write('name: $name, ')
          ..write('sku: $sku, ')
          ..write('barcode: $barcode, ')
          ..write('costPrice: $costPrice, ')
          ..write('salePrice: $salePrice, ')
          ..write('originType: $originType, ')
          ..write('sizeLabel: $sizeLabel, ')
          ..write('unitOfMeasure: $unitOfMeasure, ')
          ..write('attributesJson: $attributesJson, ')
          ..write('isActive: $isActive, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BranchInventoriesCacheTable extends BranchInventoriesCache
    with TableInfo<$BranchInventoriesCacheTable, BranchInventoriesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BranchInventoriesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _stockQuantityMeta =
      const VerificationMeta('stockQuantity');
  @override
  late final GeneratedColumn<double> stockQuantity = GeneratedColumn<double>(
      'stock_quantity', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _minAlertThresholdMeta =
      const VerificationMeta('minAlertThreshold');
  @override
  late final GeneratedColumn<double> minAlertThreshold =
      GeneratedColumn<double>('min_alert_threshold', aliasedName, false,
          type: DriftSqlType.double,
          requiredDuringInsert: false,
          defaultValue: const Constant(0.0));
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, branchId, productId, stockQuantity, minAlertThreshold, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'branch_inventories_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<BranchInventoriesCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('stock_quantity')) {
      context.handle(
          _stockQuantityMeta,
          stockQuantity.isAcceptableOrUnknown(
              data['stock_quantity']!, _stockQuantityMeta));
    }
    if (data.containsKey('min_alert_threshold')) {
      context.handle(
          _minAlertThresholdMeta,
          minAlertThreshold.isAcceptableOrUnknown(
              data['min_alert_threshold']!, _minAlertThresholdMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BranchInventoriesCacheData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BranchInventoriesCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      stockQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}stock_quantity'])!,
      minAlertThreshold: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}min_alert_threshold'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $BranchInventoriesCacheTable createAlias(String alias) {
    return $BranchInventoriesCacheTable(attachedDatabase, alias);
  }
}

class BranchInventoriesCacheData extends DataClass
    implements Insertable<BranchInventoriesCacheData> {
  final String id;
  final String branchId;
  final String productId;
  final double stockQuantity;
  final double minAlertThreshold;
  final DateTime updatedAt;
  const BranchInventoriesCacheData(
      {required this.id,
      required this.branchId,
      required this.productId,
      required this.stockQuantity,
      required this.minAlertThreshold,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    map['product_id'] = Variable<String>(productId);
    map['stock_quantity'] = Variable<double>(stockQuantity);
    map['min_alert_threshold'] = Variable<double>(minAlertThreshold);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  BranchInventoriesCacheCompanion toCompanion(bool nullToAbsent) {
    return BranchInventoriesCacheCompanion(
      id: Value(id),
      branchId: Value(branchId),
      productId: Value(productId),
      stockQuantity: Value(stockQuantity),
      minAlertThreshold: Value(minAlertThreshold),
      updatedAt: Value(updatedAt),
    );
  }

  factory BranchInventoriesCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BranchInventoriesCacheData(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      productId: serializer.fromJson<String>(json['productId']),
      stockQuantity: serializer.fromJson<double>(json['stockQuantity']),
      minAlertThreshold: serializer.fromJson<double>(json['minAlertThreshold']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'productId': serializer.toJson<String>(productId),
      'stockQuantity': serializer.toJson<double>(stockQuantity),
      'minAlertThreshold': serializer.toJson<double>(minAlertThreshold),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BranchInventoriesCacheData copyWith(
          {String? id,
          String? branchId,
          String? productId,
          double? stockQuantity,
          double? minAlertThreshold,
          DateTime? updatedAt}) =>
      BranchInventoriesCacheData(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        productId: productId ?? this.productId,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        minAlertThreshold: minAlertThreshold ?? this.minAlertThreshold,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  BranchInventoriesCacheData copyWithCompanion(
      BranchInventoriesCacheCompanion data) {
    return BranchInventoriesCacheData(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      productId: data.productId.present ? data.productId.value : this.productId,
      stockQuantity: data.stockQuantity.present
          ? data.stockQuantity.value
          : this.stockQuantity,
      minAlertThreshold: data.minAlertThreshold.present
          ? data.minAlertThreshold.value
          : this.minAlertThreshold,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BranchInventoriesCacheData(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('productId: $productId, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minAlertThreshold: $minAlertThreshold, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, branchId, productId, stockQuantity, minAlertThreshold, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BranchInventoriesCacheData &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.productId == this.productId &&
          other.stockQuantity == this.stockQuantity &&
          other.minAlertThreshold == this.minAlertThreshold &&
          other.updatedAt == this.updatedAt);
}

class BranchInventoriesCacheCompanion
    extends UpdateCompanion<BranchInventoriesCacheData> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String> productId;
  final Value<double> stockQuantity;
  final Value<double> minAlertThreshold;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const BranchInventoriesCacheCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.productId = const Value.absent(),
    this.stockQuantity = const Value.absent(),
    this.minAlertThreshold = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BranchInventoriesCacheCompanion.insert({
    required String id,
    required String branchId,
    required String productId,
    this.stockQuantity = const Value.absent(),
    this.minAlertThreshold = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        branchId = Value(branchId),
        productId = Value(productId),
        updatedAt = Value(updatedAt);
  static Insertable<BranchInventoriesCacheData> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? productId,
    Expression<double>? stockQuantity,
    Expression<double>? minAlertThreshold,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (productId != null) 'product_id': productId,
      if (stockQuantity != null) 'stock_quantity': stockQuantity,
      if (minAlertThreshold != null) 'min_alert_threshold': minAlertThreshold,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BranchInventoriesCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? branchId,
      Value<String>? productId,
      Value<double>? stockQuantity,
      Value<double>? minAlertThreshold,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return BranchInventoriesCacheCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      productId: productId ?? this.productId,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      minAlertThreshold: minAlertThreshold ?? this.minAlertThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (stockQuantity.present) {
      map['stock_quantity'] = Variable<double>(stockQuantity.value);
    }
    if (minAlertThreshold.present) {
      map['min_alert_threshold'] = Variable<double>(minAlertThreshold.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BranchInventoriesCacheCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('productId: $productId, ')
          ..write('stockQuantity: $stockQuantity, ')
          ..write('minAlertThreshold: $minAlertThreshold, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSalesTable extends PendingSales
    with TableInfo<$PendingSalesTable, PendingSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _saleUuidMeta =
      const VerificationMeta('saleUuid');
  @override
  late final GeneratedColumn<String> saleUuid = GeneratedColumn<String>(
      'sale_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cashierIdMeta =
      const VerificationMeta('cashierId');
  @override
  late final GeneratedColumn<String> cashierId = GeneratedColumn<String>(
      'cashier_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        localId,
        saleUuid,
        branchId,
        cashierId,
        payloadJson,
        isSynced,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sales';
  @override
  VerificationContext validateIntegrity(Insertable<PendingSale> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('sale_uuid')) {
      context.handle(_saleUuidMeta,
          saleUuid.isAcceptableOrUnknown(data['sale_uuid']!, _saleUuidMeta));
    } else if (isInserting) {
      context.missing(_saleUuidMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('cashier_id')) {
      context.handle(_cashierIdMeta,
          cashierId.isAcceptableOrUnknown(data['cashier_id']!, _cashierIdMeta));
    } else if (isInserting) {
      context.missing(_cashierIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSale(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      saleUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sale_uuid'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      cashierId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cashier_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PendingSalesTable createAlias(String alias) {
    return $PendingSalesTable(attachedDatabase, alias);
  }
}

class PendingSale extends DataClass implements Insertable<PendingSale> {
  final int localId;
  final String saleUuid;
  final String branchId;
  final String cashierId;
  final String payloadJson;
  final bool isSynced;
  final DateTime createdAt;
  const PendingSale(
      {required this.localId,
      required this.saleUuid,
      required this.branchId,
      required this.cashierId,
      required this.payloadJson,
      required this.isSynced,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['sale_uuid'] = Variable<String>(saleUuid);
    map['branch_id'] = Variable<String>(branchId);
    map['cashier_id'] = Variable<String>(cashierId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingSalesCompanion toCompanion(bool nullToAbsent) {
    return PendingSalesCompanion(
      localId: Value(localId),
      saleUuid: Value(saleUuid),
      branchId: Value(branchId),
      cashierId: Value(cashierId),
      payloadJson: Value(payloadJson),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory PendingSale.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSale(
      localId: serializer.fromJson<int>(json['localId']),
      saleUuid: serializer.fromJson<String>(json['saleUuid']),
      branchId: serializer.fromJson<String>(json['branchId']),
      cashierId: serializer.fromJson<String>(json['cashierId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'saleUuid': serializer.toJson<String>(saleUuid),
      'branchId': serializer.toJson<String>(branchId),
      'cashierId': serializer.toJson<String>(cashierId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingSale copyWith(
          {int? localId,
          String? saleUuid,
          String? branchId,
          String? cashierId,
          String? payloadJson,
          bool? isSynced,
          DateTime? createdAt}) =>
      PendingSale(
        localId: localId ?? this.localId,
        saleUuid: saleUuid ?? this.saleUuid,
        branchId: branchId ?? this.branchId,
        cashierId: cashierId ?? this.cashierId,
        payloadJson: payloadJson ?? this.payloadJson,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
      );
  PendingSale copyWithCompanion(PendingSalesCompanion data) {
    return PendingSale(
      localId: data.localId.present ? data.localId.value : this.localId,
      saleUuid: data.saleUuid.present ? data.saleUuid.value : this.saleUuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      cashierId: data.cashierId.present ? data.cashierId.value : this.cashierId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSale(')
          ..write('localId: $localId, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('branchId: $branchId, ')
          ..write('cashierId: $cashierId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      localId, saleUuid, branchId, cashierId, payloadJson, isSynced, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSale &&
          other.localId == this.localId &&
          other.saleUuid == this.saleUuid &&
          other.branchId == this.branchId &&
          other.cashierId == this.cashierId &&
          other.payloadJson == this.payloadJson &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class PendingSalesCompanion extends UpdateCompanion<PendingSale> {
  final Value<int> localId;
  final Value<String> saleUuid;
  final Value<String> branchId;
  final Value<String> cashierId;
  final Value<String> payloadJson;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  const PendingSalesCompanion({
    this.localId = const Value.absent(),
    this.saleUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.cashierId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingSalesCompanion.insert({
    this.localId = const Value.absent(),
    required String saleUuid,
    required String branchId,
    required String cashierId,
    required String payloadJson,
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
  })  : saleUuid = Value(saleUuid),
        branchId = Value(branchId),
        cashierId = Value(cashierId),
        payloadJson = Value(payloadJson),
        createdAt = Value(createdAt);
  static Insertable<PendingSale> custom({
    Expression<int>? localId,
    Expression<String>? saleUuid,
    Expression<String>? branchId,
    Expression<String>? cashierId,
    Expression<String>? payloadJson,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (saleUuid != null) 'sale_uuid': saleUuid,
      if (branchId != null) 'branch_id': branchId,
      if (cashierId != null) 'cashier_id': cashierId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingSalesCompanion copyWith(
      {Value<int>? localId,
      Value<String>? saleUuid,
      Value<String>? branchId,
      Value<String>? cashierId,
      Value<String>? payloadJson,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt}) {
    return PendingSalesCompanion(
      localId: localId ?? this.localId,
      saleUuid: saleUuid ?? this.saleUuid,
      branchId: branchId ?? this.branchId,
      cashierId: cashierId ?? this.cashierId,
      payloadJson: payloadJson ?? this.payloadJson,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (saleUuid.present) {
      map['sale_uuid'] = Variable<String>(saleUuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (cashierId.present) {
      map['cashier_id'] = Variable<String>(cashierId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSalesCompanion(')
          ..write('localId: $localId, ')
          ..write('saleUuid: $saleUuid, ')
          ..write('branchId: $branchId, ')
          ..write('cashierId: $cashierId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PendingWastageLogsTable extends PendingWastageLogs
    with TableInfo<$PendingWastageLogsTable, PendingWastageLog> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingWastageLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta =
      const VerificationMeta('localId');
  @override
  late final GeneratedColumn<int> localId = GeneratedColumn<int>(
      'local_id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _logUuidMeta =
      const VerificationMeta('logUuid');
  @override
  late final GeneratedColumn<String> logUuid = GeneratedColumn<String>(
      'log_uuid', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isSyncedMeta =
      const VerificationMeta('isSynced');
  @override
  late final GeneratedColumn<bool> isSynced = GeneratedColumn<bool>(
      'is_synced', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_synced" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [localId, logUuid, branchId, payloadJson, isSynced, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_wastage_logs';
  @override
  VerificationContext validateIntegrity(Insertable<PendingWastageLog> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(_localIdMeta,
          localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta));
    }
    if (data.containsKey('log_uuid')) {
      context.handle(_logUuidMeta,
          logUuid.isAcceptableOrUnknown(data['log_uuid']!, _logUuidMeta));
    } else if (isInserting) {
      context.missing(_logUuidMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('is_synced')) {
      context.handle(_isSyncedMeta,
          isSynced.isAcceptableOrUnknown(data['is_synced']!, _isSyncedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  PendingWastageLog map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingWastageLog(
      localId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}local_id'])!,
      logUuid: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}log_uuid'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      isSynced: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_synced'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PendingWastageLogsTable createAlias(String alias) {
    return $PendingWastageLogsTable(attachedDatabase, alias);
  }
}

class PendingWastageLog extends DataClass
    implements Insertable<PendingWastageLog> {
  final int localId;
  final String logUuid;
  final String branchId;
  final String payloadJson;
  final bool isSynced;
  final DateTime createdAt;
  const PendingWastageLog(
      {required this.localId,
      required this.logUuid,
      required this.branchId,
      required this.payloadJson,
      required this.isSynced,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<int>(localId);
    map['log_uuid'] = Variable<String>(logUuid);
    map['branch_id'] = Variable<String>(branchId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['is_synced'] = Variable<bool>(isSynced);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PendingWastageLogsCompanion toCompanion(bool nullToAbsent) {
    return PendingWastageLogsCompanion(
      localId: Value(localId),
      logUuid: Value(logUuid),
      branchId: Value(branchId),
      payloadJson: Value(payloadJson),
      isSynced: Value(isSynced),
      createdAt: Value(createdAt),
    );
  }

  factory PendingWastageLog.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingWastageLog(
      localId: serializer.fromJson<int>(json['localId']),
      logUuid: serializer.fromJson<String>(json['logUuid']),
      branchId: serializer.fromJson<String>(json['branchId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      isSynced: serializer.fromJson<bool>(json['isSynced']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<int>(localId),
      'logUuid': serializer.toJson<String>(logUuid),
      'branchId': serializer.toJson<String>(branchId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'isSynced': serializer.toJson<bool>(isSynced),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PendingWastageLog copyWith(
          {int? localId,
          String? logUuid,
          String? branchId,
          String? payloadJson,
          bool? isSynced,
          DateTime? createdAt}) =>
      PendingWastageLog(
        localId: localId ?? this.localId,
        logUuid: logUuid ?? this.logUuid,
        branchId: branchId ?? this.branchId,
        payloadJson: payloadJson ?? this.payloadJson,
        isSynced: isSynced ?? this.isSynced,
        createdAt: createdAt ?? this.createdAt,
      );
  PendingWastageLog copyWithCompanion(PendingWastageLogsCompanion data) {
    return PendingWastageLog(
      localId: data.localId.present ? data.localId.value : this.localId,
      logUuid: data.logUuid.present ? data.logUuid.value : this.logUuid,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      isSynced: data.isSynced.present ? data.isSynced.value : this.isSynced,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingWastageLog(')
          ..write('localId: $localId, ')
          ..write('logUuid: $logUuid, ')
          ..write('branchId: $branchId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(localId, logUuid, branchId, payloadJson, isSynced, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingWastageLog &&
          other.localId == this.localId &&
          other.logUuid == this.logUuid &&
          other.branchId == this.branchId &&
          other.payloadJson == this.payloadJson &&
          other.isSynced == this.isSynced &&
          other.createdAt == this.createdAt);
}

class PendingWastageLogsCompanion extends UpdateCompanion<PendingWastageLog> {
  final Value<int> localId;
  final Value<String> logUuid;
  final Value<String> branchId;
  final Value<String> payloadJson;
  final Value<bool> isSynced;
  final Value<DateTime> createdAt;
  const PendingWastageLogsCompanion({
    this.localId = const Value.absent(),
    this.logUuid = const Value.absent(),
    this.branchId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.isSynced = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PendingWastageLogsCompanion.insert({
    this.localId = const Value.absent(),
    required String logUuid,
    required String branchId,
    required String payloadJson,
    this.isSynced = const Value.absent(),
    required DateTime createdAt,
  })  : logUuid = Value(logUuid),
        branchId = Value(branchId),
        payloadJson = Value(payloadJson),
        createdAt = Value(createdAt);
  static Insertable<PendingWastageLog> custom({
    Expression<int>? localId,
    Expression<String>? logUuid,
    Expression<String>? branchId,
    Expression<String>? payloadJson,
    Expression<bool>? isSynced,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (logUuid != null) 'log_uuid': logUuid,
      if (branchId != null) 'branch_id': branchId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (isSynced != null) 'is_synced': isSynced,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PendingWastageLogsCompanion copyWith(
      {Value<int>? localId,
      Value<String>? logUuid,
      Value<String>? branchId,
      Value<String>? payloadJson,
      Value<bool>? isSynced,
      Value<DateTime>? createdAt}) {
    return PendingWastageLogsCompanion(
      localId: localId ?? this.localId,
      logUuid: logUuid ?? this.logUuid,
      branchId: branchId ?? this.branchId,
      payloadJson: payloadJson ?? this.payloadJson,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<int>(localId.value);
    }
    if (logUuid.present) {
      map['log_uuid'] = Variable<String>(logUuid.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (isSynced.present) {
      map['is_synced'] = Variable<bool>(isSynced.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingWastageLogsCompanion(')
          ..write('localId: $localId, ')
          ..write('logUuid: $logUuid, ')
          ..write('branchId: $branchId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('isSynced: $isSynced, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $VendorsCacheTable extends VendorsCache
    with TableInfo<$VendorsCacheTable, VendorsCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VendorsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, phone, address, notes, isActive, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vendors_cache';
  @override
  VerificationContext validateIntegrity(Insertable<VendorsCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VendorsCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VendorsCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $VendorsCacheTable createAlias(String alias) {
    return $VendorsCacheTable(attachedDatabase, alias);
  }
}

class VendorsCacheData extends DataClass
    implements Insertable<VendorsCacheData> {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const VendorsCacheData(
      {required this.id,
      required this.name,
      this.phone,
      this.address,
      this.notes,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  VendorsCacheCompanion toCompanion(bool nullToAbsent) {
    return VendorsCacheCompanion(
      id: Value(id),
      name: Value(name),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory VendorsCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VendorsCacheData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  VendorsCacheData copyWith(
          {String? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      VendorsCacheData(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        address: address.present ? address.value : this.address,
        notes: notes.present ? notes.value : this.notes,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  VendorsCacheData copyWithCompanion(VendorsCacheCompanion data) {
    return VendorsCacheData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VendorsCacheData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, phone, address, notes, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VendorsCacheData &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class VendorsCacheCompanion extends UpdateCompanion<VendorsCacheData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const VendorsCacheCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VendorsCacheCompanion.insert({
    required String id,
    required String name,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<VendorsCacheData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VendorsCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<String?>? phone,
      Value<String?>? address,
      Value<String?>? notes,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return VendorsCacheCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VendorsCacheCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchasesCacheTable extends PurchasesCache
    with TableInfo<$PurchasesCacheTable, PurchasesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _purchaseNoMeta =
      const VerificationMeta('purchaseNo');
  @override
  late final GeneratedColumn<String> purchaseNo = GeneratedColumn<String>(
      'purchase_no', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _vendorIdMeta =
      const VerificationMeta('vendorId');
  @override
  late final GeneratedColumn<String> vendorId = GeneratedColumn<String>(
      'vendor_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _vendorNameMeta =
      const VerificationMeta('vendorName');
  @override
  late final GeneratedColumn<String> vendorName = GeneratedColumn<String>(
      'vendor_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _purchaseDateMeta =
      const VerificationMeta('purchaseDate');
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
      'purchase_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _subtotalMeta =
      const VerificationMeta('subtotal');
  @override
  late final GeneratedColumn<double> subtotal = GeneratedColumn<double>(
      'subtotal', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _discountMeta =
      const VerificationMeta('discount');
  @override
  late final GeneratedColumn<double> discount = GeneratedColumn<double>(
      'discount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _totalAmountMeta =
      const VerificationMeta('totalAmount');
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
      'total_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _paidAmountMeta =
      const VerificationMeta('paidAmount');
  @override
  late final GeneratedColumn<double> paidAmount = GeneratedColumn<double>(
      'paid_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _paymentStatusMeta =
      const VerificationMeta('paymentStatus');
  @override
  late final GeneratedColumn<String> paymentStatus = GeneratedColumn<String>(
      'payment_status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('unpaid'));
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdByMeta =
      const VerificationMeta('createdBy');
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
      'created_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        purchaseNo,
        branchId,
        vendorId,
        vendorName,
        purchaseDate,
        subtotal,
        discount,
        totalAmount,
        paidAmount,
        paymentStatus,
        notes,
        createdBy,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchases_cache';
  @override
  VerificationContext validateIntegrity(Insertable<PurchasesCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('purchase_no')) {
      context.handle(
          _purchaseNoMeta,
          purchaseNo.isAcceptableOrUnknown(
              data['purchase_no']!, _purchaseNoMeta));
    } else if (isInserting) {
      context.missing(_purchaseNoMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('vendor_id')) {
      context.handle(_vendorIdMeta,
          vendorId.isAcceptableOrUnknown(data['vendor_id']!, _vendorIdMeta));
    }
    if (data.containsKey('vendor_name')) {
      context.handle(
          _vendorNameMeta,
          vendorName.isAcceptableOrUnknown(
              data['vendor_name']!, _vendorNameMeta));
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
          _purchaseDateMeta,
          purchaseDate.isAcceptableOrUnknown(
              data['purchase_date']!, _purchaseDateMeta));
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(_subtotalMeta,
          subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta));
    }
    if (data.containsKey('discount')) {
      context.handle(_discountMeta,
          discount.isAcceptableOrUnknown(data['discount']!, _discountMeta));
    }
    if (data.containsKey('total_amount')) {
      context.handle(
          _totalAmountMeta,
          totalAmount.isAcceptableOrUnknown(
              data['total_amount']!, _totalAmountMeta));
    }
    if (data.containsKey('paid_amount')) {
      context.handle(
          _paidAmountMeta,
          paidAmount.isAcceptableOrUnknown(
              data['paid_amount']!, _paidAmountMeta));
    }
    if (data.containsKey('payment_status')) {
      context.handle(
          _paymentStatusMeta,
          paymentStatus.isAcceptableOrUnknown(
              data['payment_status']!, _paymentStatusMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_by')) {
      context.handle(_createdByMeta,
          createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchasesCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchasesCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      purchaseNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purchase_no'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      vendorId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vendor_id']),
      vendorName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}vendor_name']),
      purchaseDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}purchase_date'])!,
      subtotal: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}subtotal'])!,
      discount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}discount'])!,
      totalAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_amount'])!,
      paidAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}paid_amount'])!,
      paymentStatus: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_status'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}created_by']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PurchasesCacheTable createAlias(String alias) {
    return $PurchasesCacheTable(attachedDatabase, alias);
  }
}

class PurchasesCacheData extends DataClass
    implements Insertable<PurchasesCacheData> {
  final String id;
  final String purchaseNo;
  final String branchId;
  final String? vendorId;
  final String? vendorName;
  final DateTime purchaseDate;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final double paidAmount;

  /// 'paid' | 'unpaid' | 'partial'
  final String paymentStatus;
  final String? notes;
  final String? createdBy;
  final DateTime createdAt;
  const PurchasesCacheData(
      {required this.id,
      required this.purchaseNo,
      required this.branchId,
      this.vendorId,
      this.vendorName,
      required this.purchaseDate,
      required this.subtotal,
      required this.discount,
      required this.totalAmount,
      required this.paidAmount,
      required this.paymentStatus,
      this.notes,
      this.createdBy,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['purchase_no'] = Variable<String>(purchaseNo);
    map['branch_id'] = Variable<String>(branchId);
    if (!nullToAbsent || vendorId != null) {
      map['vendor_id'] = Variable<String>(vendorId);
    }
    if (!nullToAbsent || vendorName != null) {
      map['vendor_name'] = Variable<String>(vendorName);
    }
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    map['subtotal'] = Variable<double>(subtotal);
    map['discount'] = Variable<double>(discount);
    map['total_amount'] = Variable<double>(totalAmount);
    map['paid_amount'] = Variable<double>(paidAmount);
    map['payment_status'] = Variable<String>(paymentStatus);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || createdBy != null) {
      map['created_by'] = Variable<String>(createdBy);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PurchasesCacheCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCacheCompanion(
      id: Value(id),
      purchaseNo: Value(purchaseNo),
      branchId: Value(branchId),
      vendorId: vendorId == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorId),
      vendorName: vendorName == null && nullToAbsent
          ? const Value.absent()
          : Value(vendorName),
      purchaseDate: Value(purchaseDate),
      subtotal: Value(subtotal),
      discount: Value(discount),
      totalAmount: Value(totalAmount),
      paidAmount: Value(paidAmount),
      paymentStatus: Value(paymentStatus),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdBy: createdBy == null && nullToAbsent
          ? const Value.absent()
          : Value(createdBy),
      createdAt: Value(createdAt),
    );
  }

  factory PurchasesCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchasesCacheData(
      id: serializer.fromJson<String>(json['id']),
      purchaseNo: serializer.fromJson<String>(json['purchaseNo']),
      branchId: serializer.fromJson<String>(json['branchId']),
      vendorId: serializer.fromJson<String?>(json['vendorId']),
      vendorName: serializer.fromJson<String?>(json['vendorName']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchaseDate']),
      subtotal: serializer.fromJson<double>(json['subtotal']),
      discount: serializer.fromJson<double>(json['discount']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      paidAmount: serializer.fromJson<double>(json['paidAmount']),
      paymentStatus: serializer.fromJson<String>(json['paymentStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdBy: serializer.fromJson<String?>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'purchaseNo': serializer.toJson<String>(purchaseNo),
      'branchId': serializer.toJson<String>(branchId),
      'vendorId': serializer.toJson<String?>(vendorId),
      'vendorName': serializer.toJson<String?>(vendorName),
      'purchaseDate': serializer.toJson<DateTime>(purchaseDate),
      'subtotal': serializer.toJson<double>(subtotal),
      'discount': serializer.toJson<double>(discount),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'paidAmount': serializer.toJson<double>(paidAmount),
      'paymentStatus': serializer.toJson<String>(paymentStatus),
      'notes': serializer.toJson<String?>(notes),
      'createdBy': serializer.toJson<String?>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PurchasesCacheData copyWith(
          {String? id,
          String? purchaseNo,
          String? branchId,
          Value<String?> vendorId = const Value.absent(),
          Value<String?> vendorName = const Value.absent(),
          DateTime? purchaseDate,
          double? subtotal,
          double? discount,
          double? totalAmount,
          double? paidAmount,
          String? paymentStatus,
          Value<String?> notes = const Value.absent(),
          Value<String?> createdBy = const Value.absent(),
          DateTime? createdAt}) =>
      PurchasesCacheData(
        id: id ?? this.id,
        purchaseNo: purchaseNo ?? this.purchaseNo,
        branchId: branchId ?? this.branchId,
        vendorId: vendorId.present ? vendorId.value : this.vendorId,
        vendorName: vendorName.present ? vendorName.value : this.vendorName,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        subtotal: subtotal ?? this.subtotal,
        discount: discount ?? this.discount,
        totalAmount: totalAmount ?? this.totalAmount,
        paidAmount: paidAmount ?? this.paidAmount,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        notes: notes.present ? notes.value : this.notes,
        createdBy: createdBy.present ? createdBy.value : this.createdBy,
        createdAt: createdAt ?? this.createdAt,
      );
  PurchasesCacheData copyWithCompanion(PurchasesCacheCompanion data) {
    return PurchasesCacheData(
      id: data.id.present ? data.id.value : this.id,
      purchaseNo:
          data.purchaseNo.present ? data.purchaseNo.value : this.purchaseNo,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      vendorId: data.vendorId.present ? data.vendorId.value : this.vendorId,
      vendorName:
          data.vendorName.present ? data.vendorName.value : this.vendorName,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discount: data.discount.present ? data.discount.value : this.discount,
      totalAmount:
          data.totalAmount.present ? data.totalAmount.value : this.totalAmount,
      paidAmount:
          data.paidAmount.present ? data.paidAmount.value : this.paidAmount,
      paymentStatus: data.paymentStatus.present
          ? data.paymentStatus.value
          : this.paymentStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchasesCacheData(')
          ..write('id: $id, ')
          ..write('purchaseNo: $purchaseNo, ')
          ..write('branchId: $branchId, ')
          ..write('vendorId: $vendorId, ')
          ..write('vendorName: $vendorName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      purchaseNo,
      branchId,
      vendorId,
      vendorName,
      purchaseDate,
      subtotal,
      discount,
      totalAmount,
      paidAmount,
      paymentStatus,
      notes,
      createdBy,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchasesCacheData &&
          other.id == this.id &&
          other.purchaseNo == this.purchaseNo &&
          other.branchId == this.branchId &&
          other.vendorId == this.vendorId &&
          other.vendorName == this.vendorName &&
          other.purchaseDate == this.purchaseDate &&
          other.subtotal == this.subtotal &&
          other.discount == this.discount &&
          other.totalAmount == this.totalAmount &&
          other.paidAmount == this.paidAmount &&
          other.paymentStatus == this.paymentStatus &&
          other.notes == this.notes &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt);
}

class PurchasesCacheCompanion extends UpdateCompanion<PurchasesCacheData> {
  final Value<String> id;
  final Value<String> purchaseNo;
  final Value<String> branchId;
  final Value<String?> vendorId;
  final Value<String?> vendorName;
  final Value<DateTime> purchaseDate;
  final Value<double> subtotal;
  final Value<double> discount;
  final Value<double> totalAmount;
  final Value<double> paidAmount;
  final Value<String> paymentStatus;
  final Value<String?> notes;
  final Value<String?> createdBy;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PurchasesCacheCompanion({
    this.id = const Value.absent(),
    this.purchaseNo = const Value.absent(),
    this.branchId = const Value.absent(),
    this.vendorId = const Value.absent(),
    this.vendorName = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchasesCacheCompanion.insert({
    required String id,
    required String purchaseNo,
    required String branchId,
    this.vendorId = const Value.absent(),
    this.vendorName = const Value.absent(),
    required DateTime purchaseDate,
    this.subtotal = const Value.absent(),
    this.discount = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.paidAmount = const Value.absent(),
    this.paymentStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdBy = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        purchaseNo = Value(purchaseNo),
        branchId = Value(branchId),
        purchaseDate = Value(purchaseDate),
        createdAt = Value(createdAt);
  static Insertable<PurchasesCacheData> custom({
    Expression<String>? id,
    Expression<String>? purchaseNo,
    Expression<String>? branchId,
    Expression<String>? vendorId,
    Expression<String>? vendorName,
    Expression<DateTime>? purchaseDate,
    Expression<double>? subtotal,
    Expression<double>? discount,
    Expression<double>? totalAmount,
    Expression<double>? paidAmount,
    Expression<String>? paymentStatus,
    Expression<String>? notes,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseNo != null) 'purchase_no': purchaseNo,
      if (branchId != null) 'branch_id': branchId,
      if (vendorId != null) 'vendor_id': vendorId,
      if (vendorName != null) 'vendor_name': vendorName,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (subtotal != null) 'subtotal': subtotal,
      if (discount != null) 'discount': discount,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (paidAmount != null) 'paid_amount': paidAmount,
      if (paymentStatus != null) 'payment_status': paymentStatus,
      if (notes != null) 'notes': notes,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchasesCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? purchaseNo,
      Value<String>? branchId,
      Value<String?>? vendorId,
      Value<String?>? vendorName,
      Value<DateTime>? purchaseDate,
      Value<double>? subtotal,
      Value<double>? discount,
      Value<double>? totalAmount,
      Value<double>? paidAmount,
      Value<String>? paymentStatus,
      Value<String?>? notes,
      Value<String?>? createdBy,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PurchasesCacheCompanion(
      id: id ?? this.id,
      purchaseNo: purchaseNo ?? this.purchaseNo,
      branchId: branchId ?? this.branchId,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      createdBy: createdBy ?? this.createdBy,
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
    if (purchaseNo.present) {
      map['purchase_no'] = Variable<String>(purchaseNo.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (vendorId.present) {
      map['vendor_id'] = Variable<String>(vendorId.value);
    }
    if (vendorName.present) {
      map['vendor_name'] = Variable<String>(vendorName.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<double>(subtotal.value);
    }
    if (discount.present) {
      map['discount'] = Variable<double>(discount.value);
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (paidAmount.present) {
      map['paid_amount'] = Variable<double>(paidAmount.value);
    }
    if (paymentStatus.present) {
      map['payment_status'] = Variable<String>(paymentStatus.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
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
    return (StringBuffer('PurchasesCacheCompanion(')
          ..write('id: $id, ')
          ..write('purchaseNo: $purchaseNo, ')
          ..write('branchId: $branchId, ')
          ..write('vendorId: $vendorId, ')
          ..write('vendorName: $vendorName, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('subtotal: $subtotal, ')
          ..write('discount: $discount, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('paidAmount: $paidAmount, ')
          ..write('paymentStatus: $paymentStatus, ')
          ..write('notes: $notes, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseItemsCacheTable extends PurchaseItemsCache
    with TableInfo<$PurchaseItemsCacheTable, PurchaseItemsCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseItemsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _purchaseIdMeta =
      const VerificationMeta('purchaseId');
  @override
  late final GeneratedColumn<String> purchaseId = GeneratedColumn<String>(
      'purchase_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productIdMeta =
      const VerificationMeta('productId');
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
      'product_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameSnapshotMeta =
      const VerificationMeta('productNameSnapshot');
  @override
  late final GeneratedColumn<String> productNameSnapshot =
      GeneratedColumn<String>('product_name_snapshot', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
      'quantity', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _unitCostMeta =
      const VerificationMeta('unitCost');
  @override
  late final GeneratedColumn<double> unitCost = GeneratedColumn<double>(
      'unit_cost', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, purchaseId, productId, productNameSnapshot, quantity, unitCost];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_items_cache';
  @override
  VerificationContext validateIntegrity(
      Insertable<PurchaseItemsCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
          _purchaseIdMeta,
          purchaseId.isAcceptableOrUnknown(
              data['purchase_id']!, _purchaseIdMeta));
    } else if (isInserting) {
      context.missing(_purchaseIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(_productIdMeta,
          productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta));
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name_snapshot')) {
      context.handle(
          _productNameSnapshotMeta,
          productNameSnapshot.isAcceptableOrUnknown(
              data['product_name_snapshot']!, _productNameSnapshotMeta));
    } else if (isInserting) {
      context.missing(_productNameSnapshotMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit_cost')) {
      context.handle(_unitCostMeta,
          unitCost.isAcceptableOrUnknown(data['unit_cost']!, _unitCostMeta));
    } else if (isInserting) {
      context.missing(_unitCostMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseItemsCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseItemsCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      purchaseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}purchase_id'])!,
      productId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_id'])!,
      productNameSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}product_name_snapshot'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}quantity'])!,
      unitCost: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}unit_cost'])!,
    );
  }

  @override
  $PurchaseItemsCacheTable createAlias(String alias) {
    return $PurchaseItemsCacheTable(attachedDatabase, alias);
  }
}

class PurchaseItemsCacheData extends DataClass
    implements Insertable<PurchaseItemsCacheData> {
  final String id;
  final String purchaseId;
  final String productId;
  final String productNameSnapshot;
  final double quantity;
  final double unitCost;
  const PurchaseItemsCacheData(
      {required this.id,
      required this.purchaseId,
      required this.productId,
      required this.productNameSnapshot,
      required this.quantity,
      required this.unitCost});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['purchase_id'] = Variable<String>(purchaseId);
    map['product_id'] = Variable<String>(productId);
    map['product_name_snapshot'] = Variable<String>(productNameSnapshot);
    map['quantity'] = Variable<double>(quantity);
    map['unit_cost'] = Variable<double>(unitCost);
    return map;
  }

  PurchaseItemsCacheCompanion toCompanion(bool nullToAbsent) {
    return PurchaseItemsCacheCompanion(
      id: Value(id),
      purchaseId: Value(purchaseId),
      productId: Value(productId),
      productNameSnapshot: Value(productNameSnapshot),
      quantity: Value(quantity),
      unitCost: Value(unitCost),
    );
  }

  factory PurchaseItemsCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseItemsCacheData(
      id: serializer.fromJson<String>(json['id']),
      purchaseId: serializer.fromJson<String>(json['purchaseId']),
      productId: serializer.fromJson<String>(json['productId']),
      productNameSnapshot:
          serializer.fromJson<String>(json['productNameSnapshot']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unitCost: serializer.fromJson<double>(json['unitCost']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'purchaseId': serializer.toJson<String>(purchaseId),
      'productId': serializer.toJson<String>(productId),
      'productNameSnapshot': serializer.toJson<String>(productNameSnapshot),
      'quantity': serializer.toJson<double>(quantity),
      'unitCost': serializer.toJson<double>(unitCost),
    };
  }

  PurchaseItemsCacheData copyWith(
          {String? id,
          String? purchaseId,
          String? productId,
          String? productNameSnapshot,
          double? quantity,
          double? unitCost}) =>
      PurchaseItemsCacheData(
        id: id ?? this.id,
        purchaseId: purchaseId ?? this.purchaseId,
        productId: productId ?? this.productId,
        productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
        quantity: quantity ?? this.quantity,
        unitCost: unitCost ?? this.unitCost,
      );
  PurchaseItemsCacheData copyWithCompanion(PurchaseItemsCacheCompanion data) {
    return PurchaseItemsCacheData(
      id: data.id.present ? data.id.value : this.id,
      purchaseId:
          data.purchaseId.present ? data.purchaseId.value : this.purchaseId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productNameSnapshot: data.productNameSnapshot.present
          ? data.productNameSnapshot.value
          : this.productNameSnapshot,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unitCost: data.unitCost.present ? data.unitCost.value : this.unitCost,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseItemsCacheData(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, purchaseId, productId, productNameSnapshot, quantity, unitCost);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseItemsCacheData &&
          other.id == this.id &&
          other.purchaseId == this.purchaseId &&
          other.productId == this.productId &&
          other.productNameSnapshot == this.productNameSnapshot &&
          other.quantity == this.quantity &&
          other.unitCost == this.unitCost);
}

class PurchaseItemsCacheCompanion
    extends UpdateCompanion<PurchaseItemsCacheData> {
  final Value<String> id;
  final Value<String> purchaseId;
  final Value<String> productId;
  final Value<String> productNameSnapshot;
  final Value<double> quantity;
  final Value<double> unitCost;
  final Value<int> rowid;
  const PurchaseItemsCacheCompanion({
    this.id = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productNameSnapshot = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unitCost = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseItemsCacheCompanion.insert({
    required String id,
    required String purchaseId,
    required String productId,
    required String productNameSnapshot,
    required double quantity,
    required double unitCost,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        purchaseId = Value(purchaseId),
        productId = Value(productId),
        productNameSnapshot = Value(productNameSnapshot),
        quantity = Value(quantity),
        unitCost = Value(unitCost);
  static Insertable<PurchaseItemsCacheData> custom({
    Expression<String>? id,
    Expression<String>? purchaseId,
    Expression<String>? productId,
    Expression<String>? productNameSnapshot,
    Expression<double>? quantity,
    Expression<double>? unitCost,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (productId != null) 'product_id': productId,
      if (productNameSnapshot != null)
        'product_name_snapshot': productNameSnapshot,
      if (quantity != null) 'quantity': quantity,
      if (unitCost != null) 'unit_cost': unitCost,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseItemsCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? purchaseId,
      Value<String>? productId,
      Value<String>? productNameSnapshot,
      Value<double>? quantity,
      Value<double>? unitCost,
      Value<int>? rowid}) {
    return PurchaseItemsCacheCompanion(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      quantity: quantity ?? this.quantity,
      unitCost: unitCost ?? this.unitCost,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<String>(purchaseId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productNameSnapshot.present) {
      map['product_name_snapshot'] =
          Variable<String>(productNameSnapshot.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unitCost.present) {
      map['unit_cost'] = Variable<double>(unitCost.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseItemsCacheCompanion(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('productId: $productId, ')
          ..write('productNameSnapshot: $productNameSnapshot, ')
          ..write('quantity: $quantity, ')
          ..write('unitCost: $unitCost, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EmployeesCacheTable extends EmployeesCache
    with TableInfo<$EmployeesCacheTable, EmployeesCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployeesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
      'role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _basicSalaryMeta =
      const VerificationMeta('basicSalary');
  @override
  late final GeneratedColumn<double> basicSalary = GeneratedColumn<double>(
      'basic_salary', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _joinDateMeta =
      const VerificationMeta('joinDate');
  @override
  late final GeneratedColumn<DateTime> joinDate = GeneratedColumn<DateTime>(
      'join_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _isActiveMeta =
      const VerificationMeta('isActive');
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
      'is_active', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_active" IN (0, 1))'),
      defaultValue: const Constant(true));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        branchId,
        name,
        role,
        phone,
        address,
        basicSalary,
        joinDate,
        isActive,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employees_cache';
  @override
  VerificationContext validateIntegrity(Insertable<EmployeesCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
          _roleMeta, role.isAcceptableOrUnknown(data['role']!, _roleMeta));
    } else if (isInserting) {
      context.missing(_roleMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('basic_salary')) {
      context.handle(
          _basicSalaryMeta,
          basicSalary.isAcceptableOrUnknown(
              data['basic_salary']!, _basicSalaryMeta));
    }
    if (data.containsKey('join_date')) {
      context.handle(_joinDateMeta,
          joinDate.isAcceptableOrUnknown(data['join_date']!, _joinDateMeta));
    } else if (isInserting) {
      context.missing(_joinDateMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(_isActiveMeta,
          isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EmployeesCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EmployeesCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      role: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}role'])!,
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      basicSalary: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}basic_salary'])!,
      joinDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}join_date'])!,
      isActive: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_active'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $EmployeesCacheTable createAlias(String alias) {
    return $EmployeesCacheTable(attachedDatabase, alias);
  }
}

class EmployeesCacheData extends DataClass
    implements Insertable<EmployeesCacheData> {
  final String id;
  final String branchId;
  final String name;
  final String role;
  final String? phone;
  final String? address;
  final double basicSalary;
  final DateTime joinDate;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EmployeesCacheData(
      {required this.id,
      required this.branchId,
      required this.name,
      required this.role,
      this.phone,
      this.address,
      required this.basicSalary,
      required this.joinDate,
      required this.isActive,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['branch_id'] = Variable<String>(branchId);
    map['name'] = Variable<String>(name);
    map['role'] = Variable<String>(role);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['basic_salary'] = Variable<double>(basicSalary);
    map['join_date'] = Variable<DateTime>(joinDate);
    map['is_active'] = Variable<bool>(isActive);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EmployeesCacheCompanion toCompanion(bool nullToAbsent) {
    return EmployeesCacheCompanion(
      id: Value(id),
      branchId: Value(branchId),
      name: Value(name),
      role: Value(role),
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      basicSalary: Value(basicSalary),
      joinDate: Value(joinDate),
      isActive: Value(isActive),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EmployeesCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EmployeesCacheData(
      id: serializer.fromJson<String>(json['id']),
      branchId: serializer.fromJson<String>(json['branchId']),
      name: serializer.fromJson<String>(json['name']),
      role: serializer.fromJson<String>(json['role']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      basicSalary: serializer.fromJson<double>(json['basicSalary']),
      joinDate: serializer.fromJson<DateTime>(json['joinDate']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'branchId': serializer.toJson<String>(branchId),
      'name': serializer.toJson<String>(name),
      'role': serializer.toJson<String>(role),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'basicSalary': serializer.toJson<double>(basicSalary),
      'joinDate': serializer.toJson<DateTime>(joinDate),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EmployeesCacheData copyWith(
          {String? id,
          String? branchId,
          String? name,
          String? role,
          Value<String?> phone = const Value.absent(),
          Value<String?> address = const Value.absent(),
          double? basicSalary,
          DateTime? joinDate,
          bool? isActive,
          DateTime? createdAt,
          DateTime? updatedAt}) =>
      EmployeesCacheData(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        name: name ?? this.name,
        role: role ?? this.role,
        phone: phone.present ? phone.value : this.phone,
        address: address.present ? address.value : this.address,
        basicSalary: basicSalary ?? this.basicSalary,
        joinDate: joinDate ?? this.joinDate,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  EmployeesCacheData copyWithCompanion(EmployeesCacheCompanion data) {
    return EmployeesCacheData(
      id: data.id.present ? data.id.value : this.id,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      name: data.name.present ? data.name.value : this.name,
      role: data.role.present ? data.role.value : this.role,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      basicSalary:
          data.basicSalary.present ? data.basicSalary.value : this.basicSalary,
      joinDate: data.joinDate.present ? data.joinDate.value : this.joinDate,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesCacheData(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('basicSalary: $basicSalary, ')
          ..write('joinDate: $joinDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, branchId, name, role, phone, address,
      basicSalary, joinDate, isActive, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EmployeesCacheData &&
          other.id == this.id &&
          other.branchId == this.branchId &&
          other.name == this.name &&
          other.role == this.role &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.basicSalary == this.basicSalary &&
          other.joinDate == this.joinDate &&
          other.isActive == this.isActive &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EmployeesCacheCompanion extends UpdateCompanion<EmployeesCacheData> {
  final Value<String> id;
  final Value<String> branchId;
  final Value<String> name;
  final Value<String> role;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<double> basicSalary;
  final Value<DateTime> joinDate;
  final Value<bool> isActive;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EmployeesCacheCompanion({
    this.id = const Value.absent(),
    this.branchId = const Value.absent(),
    this.name = const Value.absent(),
    this.role = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.basicSalary = const Value.absent(),
    this.joinDate = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EmployeesCacheCompanion.insert({
    required String id,
    required String branchId,
    required String name,
    required String role,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.basicSalary = const Value.absent(),
    required DateTime joinDate,
    this.isActive = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        branchId = Value(branchId),
        name = Value(name),
        role = Value(role),
        joinDate = Value(joinDate),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<EmployeesCacheData> custom({
    Expression<String>? id,
    Expression<String>? branchId,
    Expression<String>? name,
    Expression<String>? role,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<double>? basicSalary,
    Expression<DateTime>? joinDate,
    Expression<bool>? isActive,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (branchId != null) 'branch_id': branchId,
      if (name != null) 'name': name,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (basicSalary != null) 'basic_salary': basicSalary,
      if (joinDate != null) 'join_date': joinDate,
      if (isActive != null) 'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EmployeesCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? branchId,
      Value<String>? name,
      Value<String>? role,
      Value<String?>? phone,
      Value<String?>? address,
      Value<double>? basicSalary,
      Value<DateTime>? joinDate,
      Value<bool>? isActive,
      Value<DateTime>? createdAt,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return EmployeesCacheCompanion(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      basicSalary: basicSalary ?? this.basicSalary,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (basicSalary.present) {
      map['basic_salary'] = Variable<double>(basicSalary.value);
    }
    if (joinDate.present) {
      map['join_date'] = Variable<DateTime>(joinDate.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployeesCacheCompanion(')
          ..write('id: $id, ')
          ..write('branchId: $branchId, ')
          ..write('name: $name, ')
          ..write('role: $role, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('basicSalary: $basicSalary, ')
          ..write('joinDate: $joinDate, ')
          ..write('isActive: $isActive, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PayrollsCacheTable extends PayrollsCache
    with TableInfo<$PayrollsCacheTable, PayrollsCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PayrollsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _employeeIdMeta =
      const VerificationMeta('employeeId');
  @override
  late final GeneratedColumn<String> employeeId = GeneratedColumn<String>(
      'employee_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _branchIdMeta =
      const VerificationMeta('branchId');
  @override
  late final GeneratedColumn<String> branchId = GeneratedColumn<String>(
      'branch_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payrollPeriodMeta =
      const VerificationMeta('payrollPeriod');
  @override
  late final GeneratedColumn<String> payrollPeriod = GeneratedColumn<String>(
      'payroll_period', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _basicSalaryMeta =
      const VerificationMeta('basicSalary');
  @override
  late final GeneratedColumn<double> basicSalary = GeneratedColumn<double>(
      'basic_salary', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _bonusAmountMeta =
      const VerificationMeta('bonusAmount');
  @override
  late final GeneratedColumn<double> bonusAmount = GeneratedColumn<double>(
      'bonus_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _bonusDescriptionMeta =
      const VerificationMeta('bonusDescription');
  @override
  late final GeneratedColumn<String> bonusDescription = GeneratedColumn<String>(
      'bonus_description', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _deductionAmountMeta =
      const VerificationMeta('deductionAmount');
  @override
  late final GeneratedColumn<double> deductionAmount = GeneratedColumn<double>(
      'deduction_amount', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0.0));
  static const VerificationMeta _deductionDescriptionMeta =
      const VerificationMeta('deductionDescription');
  @override
  late final GeneratedColumn<String> deductionDescription =
      GeneratedColumn<String>('deduction_description', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _netSalaryMeta =
      const VerificationMeta('netSalary');
  @override
  late final GeneratedColumn<double> netSalary = GeneratedColumn<double>(
      'net_salary', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _paymentMethodMeta =
      const VerificationMeta('paymentMethod');
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
      'payment_method', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('cash'));
  static const VerificationMeta _paymentDateMeta =
      const VerificationMeta('paymentDate');
  @override
  late final GeneratedColumn<DateTime> paymentDate = GeneratedColumn<DateTime>(
      'payment_date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _paidByMeta = const VerificationMeta('paidBy');
  @override
  late final GeneratedColumn<String> paidBy = GeneratedColumn<String>(
      'paid_by', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        employeeId,
        branchId,
        payrollPeriod,
        basicSalary,
        bonusAmount,
        bonusDescription,
        deductionAmount,
        deductionDescription,
        netSalary,
        paymentMethod,
        paymentDate,
        paidBy,
        notes,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payrolls_cache';
  @override
  VerificationContext validateIntegrity(Insertable<PayrollsCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('employee_id')) {
      context.handle(
          _employeeIdMeta,
          employeeId.isAcceptableOrUnknown(
              data['employee_id']!, _employeeIdMeta));
    } else if (isInserting) {
      context.missing(_employeeIdMeta);
    }
    if (data.containsKey('branch_id')) {
      context.handle(_branchIdMeta,
          branchId.isAcceptableOrUnknown(data['branch_id']!, _branchIdMeta));
    } else if (isInserting) {
      context.missing(_branchIdMeta);
    }
    if (data.containsKey('payroll_period')) {
      context.handle(
          _payrollPeriodMeta,
          payrollPeriod.isAcceptableOrUnknown(
              data['payroll_period']!, _payrollPeriodMeta));
    } else if (isInserting) {
      context.missing(_payrollPeriodMeta);
    }
    if (data.containsKey('basic_salary')) {
      context.handle(
          _basicSalaryMeta,
          basicSalary.isAcceptableOrUnknown(
              data['basic_salary']!, _basicSalaryMeta));
    } else if (isInserting) {
      context.missing(_basicSalaryMeta);
    }
    if (data.containsKey('bonus_amount')) {
      context.handle(
          _bonusAmountMeta,
          bonusAmount.isAcceptableOrUnknown(
              data['bonus_amount']!, _bonusAmountMeta));
    }
    if (data.containsKey('bonus_description')) {
      context.handle(
          _bonusDescriptionMeta,
          bonusDescription.isAcceptableOrUnknown(
              data['bonus_description']!, _bonusDescriptionMeta));
    }
    if (data.containsKey('deduction_amount')) {
      context.handle(
          _deductionAmountMeta,
          deductionAmount.isAcceptableOrUnknown(
              data['deduction_amount']!, _deductionAmountMeta));
    }
    if (data.containsKey('deduction_description')) {
      context.handle(
          _deductionDescriptionMeta,
          deductionDescription.isAcceptableOrUnknown(
              data['deduction_description']!, _deductionDescriptionMeta));
    }
    if (data.containsKey('net_salary')) {
      context.handle(_netSalaryMeta,
          netSalary.isAcceptableOrUnknown(data['net_salary']!, _netSalaryMeta));
    } else if (isInserting) {
      context.missing(_netSalaryMeta);
    }
    if (data.containsKey('payment_method')) {
      context.handle(
          _paymentMethodMeta,
          paymentMethod.isAcceptableOrUnknown(
              data['payment_method']!, _paymentMethodMeta));
    }
    if (data.containsKey('payment_date')) {
      context.handle(
          _paymentDateMeta,
          paymentDate.isAcceptableOrUnknown(
              data['payment_date']!, _paymentDateMeta));
    } else if (isInserting) {
      context.missing(_paymentDateMeta);
    }
    if (data.containsKey('paid_by')) {
      context.handle(_paidByMeta,
          paidBy.isAcceptableOrUnknown(data['paid_by']!, _paidByMeta));
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PayrollsCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PayrollsCacheData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      employeeId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}employee_id'])!,
      branchId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}branch_id'])!,
      payrollPeriod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payroll_period'])!,
      basicSalary: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}basic_salary'])!,
      bonusAmount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}bonus_amount'])!,
      bonusDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}bonus_description']),
      deductionAmount: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}deduction_amount'])!,
      deductionDescription: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}deduction_description']),
      netSalary: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}net_salary'])!,
      paymentMethod: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payment_method'])!,
      paymentDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}payment_date'])!,
      paidBy: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}paid_by']),
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PayrollsCacheTable createAlias(String alias) {
    return $PayrollsCacheTable(attachedDatabase, alias);
  }
}

class PayrollsCacheData extends DataClass
    implements Insertable<PayrollsCacheData> {
  final String id;
  final String employeeId;
  final String branchId;
  final String payrollPeriod;
  final double basicSalary;
  final double bonusAmount;
  final String? bonusDescription;
  final double deductionAmount;
  final String? deductionDescription;
  final double netSalary;
  final String paymentMethod;
  final DateTime paymentDate;
  final String? paidBy;
  final String? notes;
  final DateTime createdAt;
  const PayrollsCacheData(
      {required this.id,
      required this.employeeId,
      required this.branchId,
      required this.payrollPeriod,
      required this.basicSalary,
      required this.bonusAmount,
      this.bonusDescription,
      required this.deductionAmount,
      this.deductionDescription,
      required this.netSalary,
      required this.paymentMethod,
      required this.paymentDate,
      this.paidBy,
      this.notes,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['employee_id'] = Variable<String>(employeeId);
    map['branch_id'] = Variable<String>(branchId);
    map['payroll_period'] = Variable<String>(payrollPeriod);
    map['basic_salary'] = Variable<double>(basicSalary);
    map['bonus_amount'] = Variable<double>(bonusAmount);
    if (!nullToAbsent || bonusDescription != null) {
      map['bonus_description'] = Variable<String>(bonusDescription);
    }
    map['deduction_amount'] = Variable<double>(deductionAmount);
    if (!nullToAbsent || deductionDescription != null) {
      map['deduction_description'] = Variable<String>(deductionDescription);
    }
    map['net_salary'] = Variable<double>(netSalary);
    map['payment_method'] = Variable<String>(paymentMethod);
    map['payment_date'] = Variable<DateTime>(paymentDate);
    if (!nullToAbsent || paidBy != null) {
      map['paid_by'] = Variable<String>(paidBy);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  PayrollsCacheCompanion toCompanion(bool nullToAbsent) {
    return PayrollsCacheCompanion(
      id: Value(id),
      employeeId: Value(employeeId),
      branchId: Value(branchId),
      payrollPeriod: Value(payrollPeriod),
      basicSalary: Value(basicSalary),
      bonusAmount: Value(bonusAmount),
      bonusDescription: bonusDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(bonusDescription),
      deductionAmount: Value(deductionAmount),
      deductionDescription: deductionDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(deductionDescription),
      netSalary: Value(netSalary),
      paymentMethod: Value(paymentMethod),
      paymentDate: Value(paymentDate),
      paidBy:
          paidBy == null && nullToAbsent ? const Value.absent() : Value(paidBy),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory PayrollsCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PayrollsCacheData(
      id: serializer.fromJson<String>(json['id']),
      employeeId: serializer.fromJson<String>(json['employeeId']),
      branchId: serializer.fromJson<String>(json['branchId']),
      payrollPeriod: serializer.fromJson<String>(json['payrollPeriod']),
      basicSalary: serializer.fromJson<double>(json['basicSalary']),
      bonusAmount: serializer.fromJson<double>(json['bonusAmount']),
      bonusDescription: serializer.fromJson<String?>(json['bonusDescription']),
      deductionAmount: serializer.fromJson<double>(json['deductionAmount']),
      deductionDescription:
          serializer.fromJson<String?>(json['deductionDescription']),
      netSalary: serializer.fromJson<double>(json['netSalary']),
      paymentMethod: serializer.fromJson<String>(json['paymentMethod']),
      paymentDate: serializer.fromJson<DateTime>(json['paymentDate']),
      paidBy: serializer.fromJson<String?>(json['paidBy']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'employeeId': serializer.toJson<String>(employeeId),
      'branchId': serializer.toJson<String>(branchId),
      'payrollPeriod': serializer.toJson<String>(payrollPeriod),
      'basicSalary': serializer.toJson<double>(basicSalary),
      'bonusAmount': serializer.toJson<double>(bonusAmount),
      'bonusDescription': serializer.toJson<String?>(bonusDescription),
      'deductionAmount': serializer.toJson<double>(deductionAmount),
      'deductionDescription': serializer.toJson<String?>(deductionDescription),
      'netSalary': serializer.toJson<double>(netSalary),
      'paymentMethod': serializer.toJson<String>(paymentMethod),
      'paymentDate': serializer.toJson<DateTime>(paymentDate),
      'paidBy': serializer.toJson<String?>(paidBy),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  PayrollsCacheData copyWith(
          {String? id,
          String? employeeId,
          String? branchId,
          String? payrollPeriod,
          double? basicSalary,
          double? bonusAmount,
          Value<String?> bonusDescription = const Value.absent(),
          double? deductionAmount,
          Value<String?> deductionDescription = const Value.absent(),
          double? netSalary,
          String? paymentMethod,
          DateTime? paymentDate,
          Value<String?> paidBy = const Value.absent(),
          Value<String?> notes = const Value.absent(),
          DateTime? createdAt}) =>
      PayrollsCacheData(
        id: id ?? this.id,
        employeeId: employeeId ?? this.employeeId,
        branchId: branchId ?? this.branchId,
        payrollPeriod: payrollPeriod ?? this.payrollPeriod,
        basicSalary: basicSalary ?? this.basicSalary,
        bonusAmount: bonusAmount ?? this.bonusAmount,
        bonusDescription: bonusDescription.present
            ? bonusDescription.value
            : this.bonusDescription,
        deductionAmount: deductionAmount ?? this.deductionAmount,
        deductionDescription: deductionDescription.present
            ? deductionDescription.value
            : this.deductionDescription,
        netSalary: netSalary ?? this.netSalary,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentDate: paymentDate ?? this.paymentDate,
        paidBy: paidBy.present ? paidBy.value : this.paidBy,
        notes: notes.present ? notes.value : this.notes,
        createdAt: createdAt ?? this.createdAt,
      );
  PayrollsCacheData copyWithCompanion(PayrollsCacheCompanion data) {
    return PayrollsCacheData(
      id: data.id.present ? data.id.value : this.id,
      employeeId:
          data.employeeId.present ? data.employeeId.value : this.employeeId,
      branchId: data.branchId.present ? data.branchId.value : this.branchId,
      payrollPeriod: data.payrollPeriod.present
          ? data.payrollPeriod.value
          : this.payrollPeriod,
      basicSalary:
          data.basicSalary.present ? data.basicSalary.value : this.basicSalary,
      bonusAmount:
          data.bonusAmount.present ? data.bonusAmount.value : this.bonusAmount,
      bonusDescription: data.bonusDescription.present
          ? data.bonusDescription.value
          : this.bonusDescription,
      deductionAmount: data.deductionAmount.present
          ? data.deductionAmount.value
          : this.deductionAmount,
      deductionDescription: data.deductionDescription.present
          ? data.deductionDescription.value
          : this.deductionDescription,
      netSalary: data.netSalary.present ? data.netSalary.value : this.netSalary,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      paymentDate:
          data.paymentDate.present ? data.paymentDate.value : this.paymentDate,
      paidBy: data.paidBy.present ? data.paidBy.value : this.paidBy,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PayrollsCacheData(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('branchId: $branchId, ')
          ..write('payrollPeriod: $payrollPeriod, ')
          ..write('basicSalary: $basicSalary, ')
          ..write('bonusAmount: $bonusAmount, ')
          ..write('bonusDescription: $bonusDescription, ')
          ..write('deductionAmount: $deductionAmount, ')
          ..write('deductionDescription: $deductionDescription, ')
          ..write('netSalary: $netSalary, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paidBy: $paidBy, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      employeeId,
      branchId,
      payrollPeriod,
      basicSalary,
      bonusAmount,
      bonusDescription,
      deductionAmount,
      deductionDescription,
      netSalary,
      paymentMethod,
      paymentDate,
      paidBy,
      notes,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PayrollsCacheData &&
          other.id == this.id &&
          other.employeeId == this.employeeId &&
          other.branchId == this.branchId &&
          other.payrollPeriod == this.payrollPeriod &&
          other.basicSalary == this.basicSalary &&
          other.bonusAmount == this.bonusAmount &&
          other.bonusDescription == this.bonusDescription &&
          other.deductionAmount == this.deductionAmount &&
          other.deductionDescription == this.deductionDescription &&
          other.netSalary == this.netSalary &&
          other.paymentMethod == this.paymentMethod &&
          other.paymentDate == this.paymentDate &&
          other.paidBy == this.paidBy &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class PayrollsCacheCompanion extends UpdateCompanion<PayrollsCacheData> {
  final Value<String> id;
  final Value<String> employeeId;
  final Value<String> branchId;
  final Value<String> payrollPeriod;
  final Value<double> basicSalary;
  final Value<double> bonusAmount;
  final Value<String?> bonusDescription;
  final Value<double> deductionAmount;
  final Value<String?> deductionDescription;
  final Value<double> netSalary;
  final Value<String> paymentMethod;
  final Value<DateTime> paymentDate;
  final Value<String?> paidBy;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const PayrollsCacheCompanion({
    this.id = const Value.absent(),
    this.employeeId = const Value.absent(),
    this.branchId = const Value.absent(),
    this.payrollPeriod = const Value.absent(),
    this.basicSalary = const Value.absent(),
    this.bonusAmount = const Value.absent(),
    this.bonusDescription = const Value.absent(),
    this.deductionAmount = const Value.absent(),
    this.deductionDescription = const Value.absent(),
    this.netSalary = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.paymentDate = const Value.absent(),
    this.paidBy = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PayrollsCacheCompanion.insert({
    required String id,
    required String employeeId,
    required String branchId,
    required String payrollPeriod,
    required double basicSalary,
    this.bonusAmount = const Value.absent(),
    this.bonusDescription = const Value.absent(),
    this.deductionAmount = const Value.absent(),
    this.deductionDescription = const Value.absent(),
    required double netSalary,
    this.paymentMethod = const Value.absent(),
    required DateTime paymentDate,
    this.paidBy = const Value.absent(),
    this.notes = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        employeeId = Value(employeeId),
        branchId = Value(branchId),
        payrollPeriod = Value(payrollPeriod),
        basicSalary = Value(basicSalary),
        netSalary = Value(netSalary),
        paymentDate = Value(paymentDate),
        createdAt = Value(createdAt);
  static Insertable<PayrollsCacheData> custom({
    Expression<String>? id,
    Expression<String>? employeeId,
    Expression<String>? branchId,
    Expression<String>? payrollPeriod,
    Expression<double>? basicSalary,
    Expression<double>? bonusAmount,
    Expression<String>? bonusDescription,
    Expression<double>? deductionAmount,
    Expression<String>? deductionDescription,
    Expression<double>? netSalary,
    Expression<String>? paymentMethod,
    Expression<DateTime>? paymentDate,
    Expression<String>? paidBy,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employeeId != null) 'employee_id': employeeId,
      if (branchId != null) 'branch_id': branchId,
      if (payrollPeriod != null) 'payroll_period': payrollPeriod,
      if (basicSalary != null) 'basic_salary': basicSalary,
      if (bonusAmount != null) 'bonus_amount': bonusAmount,
      if (bonusDescription != null) 'bonus_description': bonusDescription,
      if (deductionAmount != null) 'deduction_amount': deductionAmount,
      if (deductionDescription != null)
        'deduction_description': deductionDescription,
      if (netSalary != null) 'net_salary': netSalary,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (paymentDate != null) 'payment_date': paymentDate,
      if (paidBy != null) 'paid_by': paidBy,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PayrollsCacheCompanion copyWith(
      {Value<String>? id,
      Value<String>? employeeId,
      Value<String>? branchId,
      Value<String>? payrollPeriod,
      Value<double>? basicSalary,
      Value<double>? bonusAmount,
      Value<String?>? bonusDescription,
      Value<double>? deductionAmount,
      Value<String?>? deductionDescription,
      Value<double>? netSalary,
      Value<String>? paymentMethod,
      Value<DateTime>? paymentDate,
      Value<String?>? paidBy,
      Value<String?>? notes,
      Value<DateTime>? createdAt,
      Value<int>? rowid}) {
    return PayrollsCacheCompanion(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      branchId: branchId ?? this.branchId,
      payrollPeriod: payrollPeriod ?? this.payrollPeriod,
      basicSalary: basicSalary ?? this.basicSalary,
      bonusAmount: bonusAmount ?? this.bonusAmount,
      bonusDescription: bonusDescription ?? this.bonusDescription,
      deductionAmount: deductionAmount ?? this.deductionAmount,
      deductionDescription: deductionDescription ?? this.deductionDescription,
      netSalary: netSalary ?? this.netSalary,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      paidBy: paidBy ?? this.paidBy,
      notes: notes ?? this.notes,
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
    if (employeeId.present) {
      map['employee_id'] = Variable<String>(employeeId.value);
    }
    if (branchId.present) {
      map['branch_id'] = Variable<String>(branchId.value);
    }
    if (payrollPeriod.present) {
      map['payroll_period'] = Variable<String>(payrollPeriod.value);
    }
    if (basicSalary.present) {
      map['basic_salary'] = Variable<double>(basicSalary.value);
    }
    if (bonusAmount.present) {
      map['bonus_amount'] = Variable<double>(bonusAmount.value);
    }
    if (bonusDescription.present) {
      map['bonus_description'] = Variable<String>(bonusDescription.value);
    }
    if (deductionAmount.present) {
      map['deduction_amount'] = Variable<double>(deductionAmount.value);
    }
    if (deductionDescription.present) {
      map['deduction_description'] =
          Variable<String>(deductionDescription.value);
    }
    if (netSalary.present) {
      map['net_salary'] = Variable<double>(netSalary.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (paymentDate.present) {
      map['payment_date'] = Variable<DateTime>(paymentDate.value);
    }
    if (paidBy.present) {
      map['paid_by'] = Variable<String>(paidBy.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
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
    return (StringBuffer('PayrollsCacheCompanion(')
          ..write('id: $id, ')
          ..write('employeeId: $employeeId, ')
          ..write('branchId: $branchId, ')
          ..write('payrollPeriod: $payrollPeriod, ')
          ..write('basicSalary: $basicSalary, ')
          ..write('bonusAmount: $bonusAmount, ')
          ..write('bonusDescription: $bonusDescription, ')
          ..write('deductionAmount: $deductionAmount, ')
          ..write('deductionDescription: $deductionDescription, ')
          ..write('netSalary: $netSalary, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('paymentDate: $paymentDate, ')
          ..write('paidBy: $paidBy, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BranchesCacheTable branchesCache = $BranchesCacheTable(this);
  late final $CategoriesCacheTable categoriesCache =
      $CategoriesCacheTable(this);
  late final $SubcategoriesCacheTable subcategoriesCache =
      $SubcategoriesCacheTable(this);
  late final $ProductsCacheTable productsCache = $ProductsCacheTable(this);
  late final $BranchInventoriesCacheTable branchInventoriesCache =
      $BranchInventoriesCacheTable(this);
  late final $PendingSalesTable pendingSales = $PendingSalesTable(this);
  late final $PendingWastageLogsTable pendingWastageLogs =
      $PendingWastageLogsTable(this);
  late final $VendorsCacheTable vendorsCache = $VendorsCacheTable(this);
  late final $PurchasesCacheTable purchasesCache = $PurchasesCacheTable(this);
  late final $PurchaseItemsCacheTable purchaseItemsCache =
      $PurchaseItemsCacheTable(this);
  late final $EmployeesCacheTable employeesCache = $EmployeesCacheTable(this);
  late final $PayrollsCacheTable payrollsCache = $PayrollsCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        branchesCache,
        categoriesCache,
        subcategoriesCache,
        productsCache,
        branchInventoriesCache,
        pendingSales,
        pendingWastageLogs,
        vendorsCache,
        purchasesCache,
        purchaseItemsCache,
        employeesCache,
        payrollsCache
      ];
}

typedef $$BranchesCacheTableCreateCompanionBuilder = BranchesCacheCompanion
    Function({
  required String id,
  required String name,
  Value<String?> address,
  Value<bool> isActive,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BranchesCacheTableUpdateCompanionBuilder = BranchesCacheCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> address,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BranchesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $BranchesCacheTable> {
  $$BranchesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BranchesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $BranchesCacheTable> {
  $$BranchesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BranchesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $BranchesCacheTable> {
  $$BranchesCacheTableAnnotationComposer({
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

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BranchesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BranchesCacheTable,
    BranchesCacheData,
    $$BranchesCacheTableFilterComposer,
    $$BranchesCacheTableOrderingComposer,
    $$BranchesCacheTableAnnotationComposer,
    $$BranchesCacheTableCreateCompanionBuilder,
    $$BranchesCacheTableUpdateCompanionBuilder,
    (
      BranchesCacheData,
      BaseReferences<_$AppDatabase, $BranchesCacheTable, BranchesCacheData>
    ),
    BranchesCacheData,
    PrefetchHooks Function()> {
  $$BranchesCacheTableTableManager(_$AppDatabase db, $BranchesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BranchesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BranchesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BranchesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BranchesCacheCompanion(
            id: id,
            name: name,
            address: address,
            isActive: isActive,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> address = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BranchesCacheCompanion.insert(
            id: id,
            name: name,
            address: address,
            isActive: isActive,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BranchesCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $BranchesCacheTable,
    BranchesCacheData,
    $$BranchesCacheTableFilterComposer,
    $$BranchesCacheTableOrderingComposer,
    $$BranchesCacheTableAnnotationComposer,
    $$BranchesCacheTableCreateCompanionBuilder,
    $$BranchesCacheTableUpdateCompanionBuilder,
    (
      BranchesCacheData,
      BaseReferences<_$AppDatabase, $BranchesCacheTable, BranchesCacheData>
    ),
    BranchesCacheData,
    PrefetchHooks Function()>;
typedef $$CategoriesCacheTableCreateCompanionBuilder = CategoriesCacheCompanion
    Function({
  required String id,
  required String name,
  Value<int> sortOrder,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$CategoriesCacheTableUpdateCompanionBuilder = CategoriesCacheCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<int> sortOrder,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$CategoriesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesCacheTable> {
  $$CategoriesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$CategoriesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesCacheTable> {
  $$CategoriesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesCacheTable> {
  $$CategoriesCacheTableAnnotationComposer({
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

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CategoriesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesCacheTable,
    CategoriesCacheData,
    $$CategoriesCacheTableFilterComposer,
    $$CategoriesCacheTableOrderingComposer,
    $$CategoriesCacheTableAnnotationComposer,
    $$CategoriesCacheTableCreateCompanionBuilder,
    $$CategoriesCacheTableUpdateCompanionBuilder,
    (
      CategoriesCacheData,
      BaseReferences<_$AppDatabase, $CategoriesCacheTable, CategoriesCacheData>
    ),
    CategoriesCacheData,
    PrefetchHooks Function()> {
  $$CategoriesCacheTableTableManager(
      _$AppDatabase db, $CategoriesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCacheCompanion(
            id: id,
            name: name,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<int> sortOrder = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CategoriesCacheCompanion.insert(
            id: id,
            name: name,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CategoriesCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesCacheTable,
    CategoriesCacheData,
    $$CategoriesCacheTableFilterComposer,
    $$CategoriesCacheTableOrderingComposer,
    $$CategoriesCacheTableAnnotationComposer,
    $$CategoriesCacheTableCreateCompanionBuilder,
    $$CategoriesCacheTableUpdateCompanionBuilder,
    (
      CategoriesCacheData,
      BaseReferences<_$AppDatabase, $CategoriesCacheTable, CategoriesCacheData>
    ),
    CategoriesCacheData,
    PrefetchHooks Function()>;
typedef $$SubcategoriesCacheTableCreateCompanionBuilder
    = SubcategoriesCacheCompanion Function({
  required String id,
  required String categoryId,
  required String name,
  Value<int> sortOrder,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$SubcategoriesCacheTableUpdateCompanionBuilder
    = SubcategoriesCacheCompanion Function({
  Value<String> id,
  Value<String> categoryId,
  Value<String> name,
  Value<int> sortOrder,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$SubcategoriesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $SubcategoriesCacheTable> {
  $$SubcategoriesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SubcategoriesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $SubcategoriesCacheTable> {
  $$SubcategoriesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SubcategoriesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $SubcategoriesCacheTable> {
  $$SubcategoriesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SubcategoriesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SubcategoriesCacheTable,
    SubcategoriesCacheData,
    $$SubcategoriesCacheTableFilterComposer,
    $$SubcategoriesCacheTableOrderingComposer,
    $$SubcategoriesCacheTableAnnotationComposer,
    $$SubcategoriesCacheTableCreateCompanionBuilder,
    $$SubcategoriesCacheTableUpdateCompanionBuilder,
    (
      SubcategoriesCacheData,
      BaseReferences<_$AppDatabase, $SubcategoriesCacheTable,
          SubcategoriesCacheData>
    ),
    SubcategoriesCacheData,
    PrefetchHooks Function()> {
  $$SubcategoriesCacheTableTableManager(
      _$AppDatabase db, $SubcategoriesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubcategoriesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubcategoriesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubcategoriesCacheTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SubcategoriesCacheCompanion(
            id: id,
            categoryId: categoryId,
            name: name,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String categoryId,
            required String name,
            Value<int> sortOrder = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              SubcategoriesCacheCompanion.insert(
            id: id,
            categoryId: categoryId,
            name: name,
            sortOrder: sortOrder,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SubcategoriesCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SubcategoriesCacheTable,
    SubcategoriesCacheData,
    $$SubcategoriesCacheTableFilterComposer,
    $$SubcategoriesCacheTableOrderingComposer,
    $$SubcategoriesCacheTableAnnotationComposer,
    $$SubcategoriesCacheTableCreateCompanionBuilder,
    $$SubcategoriesCacheTableUpdateCompanionBuilder,
    (
      SubcategoriesCacheData,
      BaseReferences<_$AppDatabase, $SubcategoriesCacheTable,
          SubcategoriesCacheData>
    ),
    SubcategoriesCacheData,
    PrefetchHooks Function()>;
typedef $$ProductsCacheTableCreateCompanionBuilder = ProductsCacheCompanion
    Function({
  required String id,
  required String categoryId,
  Value<String?> subcategoryId,
  required String name,
  Value<String?> sku,
  Value<String?> barcode,
  Value<double> costPrice,
  Value<double> salePrice,
  Value<String?> originType,
  Value<String?> sizeLabel,
  Value<String> unitOfMeasure,
  Value<String> attributesJson,
  Value<bool> isActive,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProductsCacheTableUpdateCompanionBuilder = ProductsCacheCompanion
    Function({
  Value<String> id,
  Value<String> categoryId,
  Value<String?> subcategoryId,
  Value<String> name,
  Value<String?> sku,
  Value<String?> barcode,
  Value<double> costPrice,
  Value<double> salePrice,
  Value<String?> originType,
  Value<String?> sizeLabel,
  Value<String> unitOfMeasure,
  Value<String> attributesJson,
  Value<bool> isActive,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProductsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsCacheTable> {
  $$ProductsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get subcategoryId => $composableBuilder(
      column: $table.subcategoryId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get salePrice => $composableBuilder(
      column: $table.salePrice, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get originType => $composableBuilder(
      column: $table.originType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sizeLabel => $composableBuilder(
      column: $table.sizeLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get unitOfMeasure => $composableBuilder(
      column: $table.unitOfMeasure, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$ProductsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsCacheTable> {
  $$ProductsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get subcategoryId => $composableBuilder(
      column: $table.subcategoryId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sku => $composableBuilder(
      column: $table.sku, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get barcode => $composableBuilder(
      column: $table.barcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get costPrice => $composableBuilder(
      column: $table.costPrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get salePrice => $composableBuilder(
      column: $table.salePrice, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get originType => $composableBuilder(
      column: $table.originType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sizeLabel => $composableBuilder(
      column: $table.sizeLabel, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get unitOfMeasure => $composableBuilder(
      column: $table.unitOfMeasure,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ProductsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsCacheTable> {
  $$ProductsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
      column: $table.categoryId, builder: (column) => column);

  GeneratedColumn<String> get subcategoryId => $composableBuilder(
      column: $table.subcategoryId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<double> get costPrice =>
      $composableBuilder(column: $table.costPrice, builder: (column) => column);

  GeneratedColumn<double> get salePrice =>
      $composableBuilder(column: $table.salePrice, builder: (column) => column);

  GeneratedColumn<String> get originType => $composableBuilder(
      column: $table.originType, builder: (column) => column);

  GeneratedColumn<String> get sizeLabel =>
      $composableBuilder(column: $table.sizeLabel, builder: (column) => column);

  GeneratedColumn<String> get unitOfMeasure => $composableBuilder(
      column: $table.unitOfMeasure, builder: (column) => column);

  GeneratedColumn<String> get attributesJson => $composableBuilder(
      column: $table.attributesJson, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductsCacheTable,
    ProductsCacheData,
    $$ProductsCacheTableFilterComposer,
    $$ProductsCacheTableOrderingComposer,
    $$ProductsCacheTableAnnotationComposer,
    $$ProductsCacheTableCreateCompanionBuilder,
    $$ProductsCacheTableUpdateCompanionBuilder,
    (
      ProductsCacheData,
      BaseReferences<_$AppDatabase, $ProductsCacheTable, ProductsCacheData>
    ),
    ProductsCacheData,
    PrefetchHooks Function()> {
  $$ProductsCacheTableTableManager(_$AppDatabase db, $ProductsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> categoryId = const Value.absent(),
            Value<String?> subcategoryId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<double> salePrice = const Value.absent(),
            Value<String?> originType = const Value.absent(),
            Value<String?> sizeLabel = const Value.absent(),
            Value<String> unitOfMeasure = const Value.absent(),
            Value<String> attributesJson = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCacheCompanion(
            id: id,
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            name: name,
            sku: sku,
            barcode: barcode,
            costPrice: costPrice,
            salePrice: salePrice,
            originType: originType,
            sizeLabel: sizeLabel,
            unitOfMeasure: unitOfMeasure,
            attributesJson: attributesJson,
            isActive: isActive,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String categoryId,
            Value<String?> subcategoryId = const Value.absent(),
            required String name,
            Value<String?> sku = const Value.absent(),
            Value<String?> barcode = const Value.absent(),
            Value<double> costPrice = const Value.absent(),
            Value<double> salePrice = const Value.absent(),
            Value<String?> originType = const Value.absent(),
            Value<String?> sizeLabel = const Value.absent(),
            Value<String> unitOfMeasure = const Value.absent(),
            Value<String> attributesJson = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              ProductsCacheCompanion.insert(
            id: id,
            categoryId: categoryId,
            subcategoryId: subcategoryId,
            name: name,
            sku: sku,
            barcode: barcode,
            costPrice: costPrice,
            salePrice: salePrice,
            originType: originType,
            sizeLabel: sizeLabel,
            unitOfMeasure: unitOfMeasure,
            attributesJson: attributesJson,
            isActive: isActive,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$ProductsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductsCacheTable,
    ProductsCacheData,
    $$ProductsCacheTableFilterComposer,
    $$ProductsCacheTableOrderingComposer,
    $$ProductsCacheTableAnnotationComposer,
    $$ProductsCacheTableCreateCompanionBuilder,
    $$ProductsCacheTableUpdateCompanionBuilder,
    (
      ProductsCacheData,
      BaseReferences<_$AppDatabase, $ProductsCacheTable, ProductsCacheData>
    ),
    ProductsCacheData,
    PrefetchHooks Function()>;
typedef $$BranchInventoriesCacheTableCreateCompanionBuilder
    = BranchInventoriesCacheCompanion Function({
  required String id,
  required String branchId,
  required String productId,
  Value<double> stockQuantity,
  Value<double> minAlertThreshold,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$BranchInventoriesCacheTableUpdateCompanionBuilder
    = BranchInventoriesCacheCompanion Function({
  Value<String> id,
  Value<String> branchId,
  Value<String> productId,
  Value<double> stockQuantity,
  Value<double> minAlertThreshold,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$BranchInventoriesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $BranchInventoriesCacheTable> {
  $$BranchInventoriesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minAlertThreshold => $composableBuilder(
      column: $table.minAlertThreshold,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$BranchInventoriesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $BranchInventoriesCacheTable> {
  $$BranchInventoriesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minAlertThreshold => $composableBuilder(
      column: $table.minAlertThreshold,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$BranchInventoriesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $BranchInventoriesCacheTable> {
  $$BranchInventoriesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<double> get stockQuantity => $composableBuilder(
      column: $table.stockQuantity, builder: (column) => column);

  GeneratedColumn<double> get minAlertThreshold => $composableBuilder(
      column: $table.minAlertThreshold, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$BranchInventoriesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $BranchInventoriesCacheTable,
    BranchInventoriesCacheData,
    $$BranchInventoriesCacheTableFilterComposer,
    $$BranchInventoriesCacheTableOrderingComposer,
    $$BranchInventoriesCacheTableAnnotationComposer,
    $$BranchInventoriesCacheTableCreateCompanionBuilder,
    $$BranchInventoriesCacheTableUpdateCompanionBuilder,
    (
      BranchInventoriesCacheData,
      BaseReferences<_$AppDatabase, $BranchInventoriesCacheTable,
          BranchInventoriesCacheData>
    ),
    BranchInventoriesCacheData,
    PrefetchHooks Function()> {
  $$BranchInventoriesCacheTableTableManager(
      _$AppDatabase db, $BranchInventoriesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BranchInventoriesCacheTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$BranchInventoriesCacheTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BranchInventoriesCacheTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<double> stockQuantity = const Value.absent(),
            Value<double> minAlertThreshold = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              BranchInventoriesCacheCompanion(
            id: id,
            branchId: branchId,
            productId: productId,
            stockQuantity: stockQuantity,
            minAlertThreshold: minAlertThreshold,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String branchId,
            required String productId,
            Value<double> stockQuantity = const Value.absent(),
            Value<double> minAlertThreshold = const Value.absent(),
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              BranchInventoriesCacheCompanion.insert(
            id: id,
            branchId: branchId,
            productId: productId,
            stockQuantity: stockQuantity,
            minAlertThreshold: minAlertThreshold,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$BranchInventoriesCacheTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $BranchInventoriesCacheTable,
        BranchInventoriesCacheData,
        $$BranchInventoriesCacheTableFilterComposer,
        $$BranchInventoriesCacheTableOrderingComposer,
        $$BranchInventoriesCacheTableAnnotationComposer,
        $$BranchInventoriesCacheTableCreateCompanionBuilder,
        $$BranchInventoriesCacheTableUpdateCompanionBuilder,
        (
          BranchInventoriesCacheData,
          BaseReferences<_$AppDatabase, $BranchInventoriesCacheTable,
              BranchInventoriesCacheData>
        ),
        BranchInventoriesCacheData,
        PrefetchHooks Function()>;
typedef $$PendingSalesTableCreateCompanionBuilder = PendingSalesCompanion
    Function({
  Value<int> localId,
  required String saleUuid,
  required String branchId,
  required String cashierId,
  required String payloadJson,
  Value<bool> isSynced,
  required DateTime createdAt,
});
typedef $$PendingSalesTableUpdateCompanionBuilder = PendingSalesCompanion
    Function({
  Value<int> localId,
  Value<String> saleUuid,
  Value<String> branchId,
  Value<String> cashierId,
  Value<String> payloadJson,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
});

class $$PendingSalesTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get saleUuid => $composableBuilder(
      column: $table.saleUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get cashierId => $composableBuilder(
      column: $table.cashierId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PendingSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get saleUuid => $composableBuilder(
      column: $table.saleUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get cashierId => $composableBuilder(
      column: $table.cashierId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSalesTable> {
  $$PendingSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get saleUuid =>
      $composableBuilder(column: $table.saleUuid, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get cashierId =>
      $composableBuilder(column: $table.cashierId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingSalesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingSalesTable,
    PendingSale,
    $$PendingSalesTableFilterComposer,
    $$PendingSalesTableOrderingComposer,
    $$PendingSalesTableAnnotationComposer,
    $$PendingSalesTableCreateCompanionBuilder,
    $$PendingSalesTableUpdateCompanionBuilder,
    (
      PendingSale,
      BaseReferences<_$AppDatabase, $PendingSalesTable, PendingSale>
    ),
    PendingSale,
    PrefetchHooks Function()> {
  $$PendingSalesTableTableManager(_$AppDatabase db, $PendingSalesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> saleUuid = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> cashierId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PendingSalesCompanion(
            localId: localId,
            saleUuid: saleUuid,
            branchId: branchId,
            cashierId: cashierId,
            payloadJson: payloadJson,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            required String saleUuid,
            required String branchId,
            required String cashierId,
            required String payloadJson,
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
          }) =>
              PendingSalesCompanion.insert(
            localId: localId,
            saleUuid: saleUuid,
            branchId: branchId,
            cashierId: cashierId,
            payloadJson: payloadJson,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingSalesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingSalesTable,
    PendingSale,
    $$PendingSalesTableFilterComposer,
    $$PendingSalesTableOrderingComposer,
    $$PendingSalesTableAnnotationComposer,
    $$PendingSalesTableCreateCompanionBuilder,
    $$PendingSalesTableUpdateCompanionBuilder,
    (
      PendingSale,
      BaseReferences<_$AppDatabase, $PendingSalesTable, PendingSale>
    ),
    PendingSale,
    PrefetchHooks Function()>;
typedef $$PendingWastageLogsTableCreateCompanionBuilder
    = PendingWastageLogsCompanion Function({
  Value<int> localId,
  required String logUuid,
  required String branchId,
  required String payloadJson,
  Value<bool> isSynced,
  required DateTime createdAt,
});
typedef $$PendingWastageLogsTableUpdateCompanionBuilder
    = PendingWastageLogsCompanion Function({
  Value<int> localId,
  Value<String> logUuid,
  Value<String> branchId,
  Value<String> payloadJson,
  Value<bool> isSynced,
  Value<DateTime> createdAt,
});

class $$PendingWastageLogsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingWastageLogsTable> {
  $$PendingWastageLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get logUuid => $composableBuilder(
      column: $table.logUuid, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PendingWastageLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingWastageLogsTable> {
  $$PendingWastageLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get localId => $composableBuilder(
      column: $table.localId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get logUuid => $composableBuilder(
      column: $table.logUuid, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isSynced => $composableBuilder(
      column: $table.isSynced, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PendingWastageLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingWastageLogsTable> {
  $$PendingWastageLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get logUuid =>
      $composableBuilder(column: $table.logUuid, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<bool> get isSynced =>
      $composableBuilder(column: $table.isSynced, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PendingWastageLogsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingWastageLogsTable,
    PendingWastageLog,
    $$PendingWastageLogsTableFilterComposer,
    $$PendingWastageLogsTableOrderingComposer,
    $$PendingWastageLogsTableAnnotationComposer,
    $$PendingWastageLogsTableCreateCompanionBuilder,
    $$PendingWastageLogsTableUpdateCompanionBuilder,
    (
      PendingWastageLog,
      BaseReferences<_$AppDatabase, $PendingWastageLogsTable, PendingWastageLog>
    ),
    PendingWastageLog,
    PrefetchHooks Function()> {
  $$PendingWastageLogsTableTableManager(
      _$AppDatabase db, $PendingWastageLogsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingWastageLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingWastageLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingWastageLogsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            Value<String> logUuid = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<bool> isSynced = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              PendingWastageLogsCompanion(
            localId: localId,
            logUuid: logUuid,
            branchId: branchId,
            payloadJson: payloadJson,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> localId = const Value.absent(),
            required String logUuid,
            required String branchId,
            required String payloadJson,
            Value<bool> isSynced = const Value.absent(),
            required DateTime createdAt,
          }) =>
              PendingWastageLogsCompanion.insert(
            localId: localId,
            logUuid: logUuid,
            branchId: branchId,
            payloadJson: payloadJson,
            isSynced: isSynced,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingWastageLogsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PendingWastageLogsTable,
    PendingWastageLog,
    $$PendingWastageLogsTableFilterComposer,
    $$PendingWastageLogsTableOrderingComposer,
    $$PendingWastageLogsTableAnnotationComposer,
    $$PendingWastageLogsTableCreateCompanionBuilder,
    $$PendingWastageLogsTableUpdateCompanionBuilder,
    (
      PendingWastageLog,
      BaseReferences<_$AppDatabase, $PendingWastageLogsTable, PendingWastageLog>
    ),
    PendingWastageLog,
    PrefetchHooks Function()>;
typedef $$VendorsCacheTableCreateCompanionBuilder = VendorsCacheCompanion
    Function({
  required String id,
  required String name,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> notes,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$VendorsCacheTableUpdateCompanionBuilder = VendorsCacheCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<String?> phone,
  Value<String?> address,
  Value<String?> notes,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$VendorsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $VendorsCacheTable> {
  $$VendorsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$VendorsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $VendorsCacheTable> {
  $$VendorsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$VendorsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $VendorsCacheTable> {
  $$VendorsCacheTableAnnotationComposer({
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

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$VendorsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $VendorsCacheTable,
    VendorsCacheData,
    $$VendorsCacheTableFilterComposer,
    $$VendorsCacheTableOrderingComposer,
    $$VendorsCacheTableAnnotationComposer,
    $$VendorsCacheTableCreateCompanionBuilder,
    $$VendorsCacheTableUpdateCompanionBuilder,
    (
      VendorsCacheData,
      BaseReferences<_$AppDatabase, $VendorsCacheTable, VendorsCacheData>
    ),
    VendorsCacheData,
    PrefetchHooks Function()> {
  $$VendorsCacheTableTableManager(_$AppDatabase db, $VendorsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VendorsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VendorsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VendorsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              VendorsCacheCompanion(
            id: id,
            name: name,
            phone: phone,
            address: address,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              VendorsCacheCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            address: address,
            notes: notes,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$VendorsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $VendorsCacheTable,
    VendorsCacheData,
    $$VendorsCacheTableFilterComposer,
    $$VendorsCacheTableOrderingComposer,
    $$VendorsCacheTableAnnotationComposer,
    $$VendorsCacheTableCreateCompanionBuilder,
    $$VendorsCacheTableUpdateCompanionBuilder,
    (
      VendorsCacheData,
      BaseReferences<_$AppDatabase, $VendorsCacheTable, VendorsCacheData>
    ),
    VendorsCacheData,
    PrefetchHooks Function()>;
typedef $$PurchasesCacheTableCreateCompanionBuilder = PurchasesCacheCompanion
    Function({
  required String id,
  required String purchaseNo,
  required String branchId,
  Value<String?> vendorId,
  Value<String?> vendorName,
  required DateTime purchaseDate,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> totalAmount,
  Value<double> paidAmount,
  Value<String> paymentStatus,
  Value<String?> notes,
  Value<String?> createdBy,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PurchasesCacheTableUpdateCompanionBuilder = PurchasesCacheCompanion
    Function({
  Value<String> id,
  Value<String> purchaseNo,
  Value<String> branchId,
  Value<String?> vendorId,
  Value<String?> vendorName,
  Value<DateTime> purchaseDate,
  Value<double> subtotal,
  Value<double> discount,
  Value<double> totalAmount,
  Value<double> paidAmount,
  Value<String> paymentStatus,
  Value<String?> notes,
  Value<String?> createdBy,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PurchasesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PurchasesCacheTable> {
  $$PurchasesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purchaseNo => $composableBuilder(
      column: $table.purchaseNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vendorId => $composableBuilder(
      column: $table.vendorId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get vendorName => $composableBuilder(
      column: $table.vendorName, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PurchasesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchasesCacheTable> {
  $$PurchasesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purchaseNo => $composableBuilder(
      column: $table.purchaseNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vendorId => $composableBuilder(
      column: $table.vendorId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get vendorName => $composableBuilder(
      column: $table.vendorName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get subtotal => $composableBuilder(
      column: $table.subtotal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get discount => $composableBuilder(
      column: $table.discount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdBy => $composableBuilder(
      column: $table.createdBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PurchasesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchasesCacheTable> {
  $$PurchasesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchaseNo => $composableBuilder(
      column: $table.purchaseNo, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get vendorId =>
      $composableBuilder(column: $table.vendorId, builder: (column) => column);

  GeneratedColumn<String> get vendorName => $composableBuilder(
      column: $table.vendorName, builder: (column) => column);

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
      column: $table.purchaseDate, builder: (column) => column);

  GeneratedColumn<double> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<double> get discount =>
      $composableBuilder(column: $table.discount, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
      column: $table.totalAmount, builder: (column) => column);

  GeneratedColumn<double> get paidAmount => $composableBuilder(
      column: $table.paidAmount, builder: (column) => column);

  GeneratedColumn<String> get paymentStatus => $composableBuilder(
      column: $table.paymentStatus, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PurchasesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PurchasesCacheTable,
    PurchasesCacheData,
    $$PurchasesCacheTableFilterComposer,
    $$PurchasesCacheTableOrderingComposer,
    $$PurchasesCacheTableAnnotationComposer,
    $$PurchasesCacheTableCreateCompanionBuilder,
    $$PurchasesCacheTableUpdateCompanionBuilder,
    (
      PurchasesCacheData,
      BaseReferences<_$AppDatabase, $PurchasesCacheTable, PurchasesCacheData>
    ),
    PurchasesCacheData,
    PrefetchHooks Function()> {
  $$PurchasesCacheTableTableManager(
      _$AppDatabase db, $PurchasesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> purchaseNo = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String?> vendorId = const Value.absent(),
            Value<String?> vendorName = const Value.absent(),
            Value<DateTime> purchaseDate = const Value.absent(),
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<double> paidAmount = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchasesCacheCompanion(
            id: id,
            purchaseNo: purchaseNo,
            branchId: branchId,
            vendorId: vendorId,
            vendorName: vendorName,
            purchaseDate: purchaseDate,
            subtotal: subtotal,
            discount: discount,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            paymentStatus: paymentStatus,
            notes: notes,
            createdBy: createdBy,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String purchaseNo,
            required String branchId,
            Value<String?> vendorId = const Value.absent(),
            Value<String?> vendorName = const Value.absent(),
            required DateTime purchaseDate,
            Value<double> subtotal = const Value.absent(),
            Value<double> discount = const Value.absent(),
            Value<double> totalAmount = const Value.absent(),
            Value<double> paidAmount = const Value.absent(),
            Value<String> paymentStatus = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<String?> createdBy = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchasesCacheCompanion.insert(
            id: id,
            purchaseNo: purchaseNo,
            branchId: branchId,
            vendorId: vendorId,
            vendorName: vendorName,
            purchaseDate: purchaseDate,
            subtotal: subtotal,
            discount: discount,
            totalAmount: totalAmount,
            paidAmount: paidAmount,
            paymentStatus: paymentStatus,
            notes: notes,
            createdBy: createdBy,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PurchasesCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PurchasesCacheTable,
    PurchasesCacheData,
    $$PurchasesCacheTableFilterComposer,
    $$PurchasesCacheTableOrderingComposer,
    $$PurchasesCacheTableAnnotationComposer,
    $$PurchasesCacheTableCreateCompanionBuilder,
    $$PurchasesCacheTableUpdateCompanionBuilder,
    (
      PurchasesCacheData,
      BaseReferences<_$AppDatabase, $PurchasesCacheTable, PurchasesCacheData>
    ),
    PurchasesCacheData,
    PrefetchHooks Function()>;
typedef $$PurchaseItemsCacheTableCreateCompanionBuilder
    = PurchaseItemsCacheCompanion Function({
  required String id,
  required String purchaseId,
  required String productId,
  required String productNameSnapshot,
  required double quantity,
  required double unitCost,
  Value<int> rowid,
});
typedef $$PurchaseItemsCacheTableUpdateCompanionBuilder
    = PurchaseItemsCacheCompanion Function({
  Value<String> id,
  Value<String> purchaseId,
  Value<String> productId,
  Value<String> productNameSnapshot,
  Value<double> quantity,
  Value<double> unitCost,
  Value<int> rowid,
});

class $$PurchaseItemsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseItemsCacheTable> {
  $$PurchaseItemsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get purchaseId => $composableBuilder(
      column: $table.purchaseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productNameSnapshot => $composableBuilder(
      column: $table.productNameSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get unitCost => $composableBuilder(
      column: $table.unitCost, builder: (column) => ColumnFilters(column));
}

class $$PurchaseItemsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseItemsCacheTable> {
  $$PurchaseItemsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get purchaseId => $composableBuilder(
      column: $table.purchaseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productId => $composableBuilder(
      column: $table.productId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productNameSnapshot => $composableBuilder(
      column: $table.productNameSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get unitCost => $composableBuilder(
      column: $table.unitCost, builder: (column) => ColumnOrderings(column));
}

class $$PurchaseItemsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseItemsCacheTable> {
  $$PurchaseItemsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchaseId => $composableBuilder(
      column: $table.purchaseId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productNameSnapshot => $composableBuilder(
      column: $table.productNameSnapshot, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get unitCost =>
      $composableBuilder(column: $table.unitCost, builder: (column) => column);
}

class $$PurchaseItemsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PurchaseItemsCacheTable,
    PurchaseItemsCacheData,
    $$PurchaseItemsCacheTableFilterComposer,
    $$PurchaseItemsCacheTableOrderingComposer,
    $$PurchaseItemsCacheTableAnnotationComposer,
    $$PurchaseItemsCacheTableCreateCompanionBuilder,
    $$PurchaseItemsCacheTableUpdateCompanionBuilder,
    (
      PurchaseItemsCacheData,
      BaseReferences<_$AppDatabase, $PurchaseItemsCacheTable,
          PurchaseItemsCacheData>
    ),
    PurchaseItemsCacheData,
    PrefetchHooks Function()> {
  $$PurchaseItemsCacheTableTableManager(
      _$AppDatabase db, $PurchaseItemsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseItemsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseItemsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchaseItemsCacheTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> purchaseId = const Value.absent(),
            Value<String> productId = const Value.absent(),
            Value<String> productNameSnapshot = const Value.absent(),
            Value<double> quantity = const Value.absent(),
            Value<double> unitCost = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchaseItemsCacheCompanion(
            id: id,
            purchaseId: purchaseId,
            productId: productId,
            productNameSnapshot: productNameSnapshot,
            quantity: quantity,
            unitCost: unitCost,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String purchaseId,
            required String productId,
            required String productNameSnapshot,
            required double quantity,
            required double unitCost,
            Value<int> rowid = const Value.absent(),
          }) =>
              PurchaseItemsCacheCompanion.insert(
            id: id,
            purchaseId: purchaseId,
            productId: productId,
            productNameSnapshot: productNameSnapshot,
            quantity: quantity,
            unitCost: unitCost,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PurchaseItemsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PurchaseItemsCacheTable,
    PurchaseItemsCacheData,
    $$PurchaseItemsCacheTableFilterComposer,
    $$PurchaseItemsCacheTableOrderingComposer,
    $$PurchaseItemsCacheTableAnnotationComposer,
    $$PurchaseItemsCacheTableCreateCompanionBuilder,
    $$PurchaseItemsCacheTableUpdateCompanionBuilder,
    (
      PurchaseItemsCacheData,
      BaseReferences<_$AppDatabase, $PurchaseItemsCacheTable,
          PurchaseItemsCacheData>
    ),
    PurchaseItemsCacheData,
    PrefetchHooks Function()>;
typedef $$EmployeesCacheTableCreateCompanionBuilder = EmployeesCacheCompanion
    Function({
  required String id,
  required String branchId,
  required String name,
  required String role,
  Value<String?> phone,
  Value<String?> address,
  Value<double> basicSalary,
  required DateTime joinDate,
  Value<bool> isActive,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$EmployeesCacheTableUpdateCompanionBuilder = EmployeesCacheCompanion
    Function({
  Value<String> id,
  Value<String> branchId,
  Value<String> name,
  Value<String> role,
  Value<String?> phone,
  Value<String?> address,
  Value<double> basicSalary,
  Value<DateTime> joinDate,
  Value<bool> isActive,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$EmployeesCacheTableFilterComposer
    extends Composer<_$AppDatabase, $EmployeesCacheTable> {
  $$EmployeesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get joinDate => $composableBuilder(
      column: $table.joinDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$EmployeesCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployeesCacheTable> {
  $$EmployeesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get role => $composableBuilder(
      column: $table.role, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get joinDate => $composableBuilder(
      column: $table.joinDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isActive => $composableBuilder(
      column: $table.isActive, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$EmployeesCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployeesCacheTable> {
  $$EmployeesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => column);

  GeneratedColumn<DateTime> get joinDate =>
      $composableBuilder(column: $table.joinDate, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EmployeesCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $EmployeesCacheTable,
    EmployeesCacheData,
    $$EmployeesCacheTableFilterComposer,
    $$EmployeesCacheTableOrderingComposer,
    $$EmployeesCacheTableAnnotationComposer,
    $$EmployeesCacheTableCreateCompanionBuilder,
    $$EmployeesCacheTableUpdateCompanionBuilder,
    (
      EmployeesCacheData,
      BaseReferences<_$AppDatabase, $EmployeesCacheTable, EmployeesCacheData>
    ),
    EmployeesCacheData,
    PrefetchHooks Function()> {
  $$EmployeesCacheTableTableManager(
      _$AppDatabase db, $EmployeesCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployeesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployeesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployeesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> role = const Value.absent(),
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<double> basicSalary = const Value.absent(),
            Value<DateTime> joinDate = const Value.absent(),
            Value<bool> isActive = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              EmployeesCacheCompanion(
            id: id,
            branchId: branchId,
            name: name,
            role: role,
            phone: phone,
            address: address,
            basicSalary: basicSalary,
            joinDate: joinDate,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String branchId,
            required String name,
            required String role,
            Value<String?> phone = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<double> basicSalary = const Value.absent(),
            required DateTime joinDate,
            Value<bool> isActive = const Value.absent(),
            required DateTime createdAt,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              EmployeesCacheCompanion.insert(
            id: id,
            branchId: branchId,
            name: name,
            role: role,
            phone: phone,
            address: address,
            basicSalary: basicSalary,
            joinDate: joinDate,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$EmployeesCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $EmployeesCacheTable,
    EmployeesCacheData,
    $$EmployeesCacheTableFilterComposer,
    $$EmployeesCacheTableOrderingComposer,
    $$EmployeesCacheTableAnnotationComposer,
    $$EmployeesCacheTableCreateCompanionBuilder,
    $$EmployeesCacheTableUpdateCompanionBuilder,
    (
      EmployeesCacheData,
      BaseReferences<_$AppDatabase, $EmployeesCacheTable, EmployeesCacheData>
    ),
    EmployeesCacheData,
    PrefetchHooks Function()>;
typedef $$PayrollsCacheTableCreateCompanionBuilder = PayrollsCacheCompanion
    Function({
  required String id,
  required String employeeId,
  required String branchId,
  required String payrollPeriod,
  required double basicSalary,
  Value<double> bonusAmount,
  Value<String?> bonusDescription,
  Value<double> deductionAmount,
  Value<String?> deductionDescription,
  required double netSalary,
  Value<String> paymentMethod,
  required DateTime paymentDate,
  Value<String?> paidBy,
  Value<String?> notes,
  required DateTime createdAt,
  Value<int> rowid,
});
typedef $$PayrollsCacheTableUpdateCompanionBuilder = PayrollsCacheCompanion
    Function({
  Value<String> id,
  Value<String> employeeId,
  Value<String> branchId,
  Value<String> payrollPeriod,
  Value<double> basicSalary,
  Value<double> bonusAmount,
  Value<String?> bonusDescription,
  Value<double> deductionAmount,
  Value<String?> deductionDescription,
  Value<double> netSalary,
  Value<String> paymentMethod,
  Value<DateTime> paymentDate,
  Value<String?> paidBy,
  Value<String?> notes,
  Value<DateTime> createdAt,
  Value<int> rowid,
});

class $$PayrollsCacheTableFilterComposer
    extends Composer<_$AppDatabase, $PayrollsCacheTable> {
  $$PayrollsCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payrollPeriod => $composableBuilder(
      column: $table.payrollPeriod, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get bonusAmount => $composableBuilder(
      column: $table.bonusAmount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get bonusDescription => $composableBuilder(
      column: $table.bonusDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get deductionAmount => $composableBuilder(
      column: $table.deductionAmount,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deductionDescription => $composableBuilder(
      column: $table.deductionDescription,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get netSalary => $composableBuilder(
      column: $table.netSalary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get paidBy => $composableBuilder(
      column: $table.paidBy, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$PayrollsCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $PayrollsCacheTable> {
  $$PayrollsCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get branchId => $composableBuilder(
      column: $table.branchId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payrollPeriod => $composableBuilder(
      column: $table.payrollPeriod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get bonusAmount => $composableBuilder(
      column: $table.bonusAmount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get bonusDescription => $composableBuilder(
      column: $table.bonusDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get deductionAmount => $composableBuilder(
      column: $table.deductionAmount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deductionDescription => $composableBuilder(
      column: $table.deductionDescription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get netSalary => $composableBuilder(
      column: $table.netSalary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get paidBy => $composableBuilder(
      column: $table.paidBy, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$PayrollsCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $PayrollsCacheTable> {
  $$PayrollsCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get employeeId => $composableBuilder(
      column: $table.employeeId, builder: (column) => column);

  GeneratedColumn<String> get branchId =>
      $composableBuilder(column: $table.branchId, builder: (column) => column);

  GeneratedColumn<String> get payrollPeriod => $composableBuilder(
      column: $table.payrollPeriod, builder: (column) => column);

  GeneratedColumn<double> get basicSalary => $composableBuilder(
      column: $table.basicSalary, builder: (column) => column);

  GeneratedColumn<double> get bonusAmount => $composableBuilder(
      column: $table.bonusAmount, builder: (column) => column);

  GeneratedColumn<String> get bonusDescription => $composableBuilder(
      column: $table.bonusDescription, builder: (column) => column);

  GeneratedColumn<double> get deductionAmount => $composableBuilder(
      column: $table.deductionAmount, builder: (column) => column);

  GeneratedColumn<String> get deductionDescription => $composableBuilder(
      column: $table.deductionDescription, builder: (column) => column);

  GeneratedColumn<double> get netSalary =>
      $composableBuilder(column: $table.netSalary, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
      column: $table.paymentMethod, builder: (column) => column);

  GeneratedColumn<DateTime> get paymentDate => $composableBuilder(
      column: $table.paymentDate, builder: (column) => column);

  GeneratedColumn<String> get paidBy =>
      $composableBuilder(column: $table.paidBy, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$PayrollsCacheTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PayrollsCacheTable,
    PayrollsCacheData,
    $$PayrollsCacheTableFilterComposer,
    $$PayrollsCacheTableOrderingComposer,
    $$PayrollsCacheTableAnnotationComposer,
    $$PayrollsCacheTableCreateCompanionBuilder,
    $$PayrollsCacheTableUpdateCompanionBuilder,
    (
      PayrollsCacheData,
      BaseReferences<_$AppDatabase, $PayrollsCacheTable, PayrollsCacheData>
    ),
    PayrollsCacheData,
    PrefetchHooks Function()> {
  $$PayrollsCacheTableTableManager(_$AppDatabase db, $PayrollsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PayrollsCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PayrollsCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PayrollsCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> employeeId = const Value.absent(),
            Value<String> branchId = const Value.absent(),
            Value<String> payrollPeriod = const Value.absent(),
            Value<double> basicSalary = const Value.absent(),
            Value<double> bonusAmount = const Value.absent(),
            Value<String?> bonusDescription = const Value.absent(),
            Value<double> deductionAmount = const Value.absent(),
            Value<String?> deductionDescription = const Value.absent(),
            Value<double> netSalary = const Value.absent(),
            Value<String> paymentMethod = const Value.absent(),
            Value<DateTime> paymentDate = const Value.absent(),
            Value<String?> paidBy = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PayrollsCacheCompanion(
            id: id,
            employeeId: employeeId,
            branchId: branchId,
            payrollPeriod: payrollPeriod,
            basicSalary: basicSalary,
            bonusAmount: bonusAmount,
            bonusDescription: bonusDescription,
            deductionAmount: deductionAmount,
            deductionDescription: deductionDescription,
            netSalary: netSalary,
            paymentMethod: paymentMethod,
            paymentDate: paymentDate,
            paidBy: paidBy,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String employeeId,
            required String branchId,
            required String payrollPeriod,
            required double basicSalary,
            Value<double> bonusAmount = const Value.absent(),
            Value<String?> bonusDescription = const Value.absent(),
            Value<double> deductionAmount = const Value.absent(),
            Value<String?> deductionDescription = const Value.absent(),
            required double netSalary,
            Value<String> paymentMethod = const Value.absent(),
            required DateTime paymentDate,
            Value<String?> paidBy = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            required DateTime createdAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PayrollsCacheCompanion.insert(
            id: id,
            employeeId: employeeId,
            branchId: branchId,
            payrollPeriod: payrollPeriod,
            basicSalary: basicSalary,
            bonusAmount: bonusAmount,
            bonusDescription: bonusDescription,
            deductionAmount: deductionAmount,
            deductionDescription: deductionDescription,
            netSalary: netSalary,
            paymentMethod: paymentMethod,
            paymentDate: paymentDate,
            paidBy: paidBy,
            notes: notes,
            createdAt: createdAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PayrollsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PayrollsCacheTable,
    PayrollsCacheData,
    $$PayrollsCacheTableFilterComposer,
    $$PayrollsCacheTableOrderingComposer,
    $$PayrollsCacheTableAnnotationComposer,
    $$PayrollsCacheTableCreateCompanionBuilder,
    $$PayrollsCacheTableUpdateCompanionBuilder,
    (
      PayrollsCacheData,
      BaseReferences<_$AppDatabase, $PayrollsCacheTable, PayrollsCacheData>
    ),
    PayrollsCacheData,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BranchesCacheTableTableManager get branchesCache =>
      $$BranchesCacheTableTableManager(_db, _db.branchesCache);
  $$CategoriesCacheTableTableManager get categoriesCache =>
      $$CategoriesCacheTableTableManager(_db, _db.categoriesCache);
  $$SubcategoriesCacheTableTableManager get subcategoriesCache =>
      $$SubcategoriesCacheTableTableManager(_db, _db.subcategoriesCache);
  $$ProductsCacheTableTableManager get productsCache =>
      $$ProductsCacheTableTableManager(_db, _db.productsCache);
  $$BranchInventoriesCacheTableTableManager get branchInventoriesCache =>
      $$BranchInventoriesCacheTableTableManager(
          _db, _db.branchInventoriesCache);
  $$PendingSalesTableTableManager get pendingSales =>
      $$PendingSalesTableTableManager(_db, _db.pendingSales);
  $$PendingWastageLogsTableTableManager get pendingWastageLogs =>
      $$PendingWastageLogsTableTableManager(_db, _db.pendingWastageLogs);
  $$VendorsCacheTableTableManager get vendorsCache =>
      $$VendorsCacheTableTableManager(_db, _db.vendorsCache);
  $$PurchasesCacheTableTableManager get purchasesCache =>
      $$PurchasesCacheTableTableManager(_db, _db.purchasesCache);
  $$PurchaseItemsCacheTableTableManager get purchaseItemsCache =>
      $$PurchaseItemsCacheTableTableManager(_db, _db.purchaseItemsCache);
  $$EmployeesCacheTableTableManager get employeesCache =>
      $$EmployeesCacheTableTableManager(_db, _db.employeesCache);
  $$PayrollsCacheTableTableManager get payrollsCache =>
      $$PayrollsCacheTableTableManager(_db, _db.payrollsCache);
}
