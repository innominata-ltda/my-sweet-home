// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconKeyMeta = const VerificationMeta(
    'iconKey',
  );
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
    'icon_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isSystemMeta = const VerificationMeta(
    'isSystem',
  );
  @override
  late final GeneratedColumn<bool> isSystem = GeneratedColumn<bool>(
    'is_system',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_system" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    kind,
    iconKey,
    colorHex,
    isSystem,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
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
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(
        _iconKeyMeta,
        iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_iconKeyMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('is_system')) {
      context.handle(
        _isSystemMeta,
        isSystem.isAcceptableOrUnknown(data['is_system']!, _isSystemMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      iconKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_key'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      isSystem: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_system'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String kind;
  final String iconKey;
  final String? colorHex;
  final bool isSystem;
  final int? sortOrder;
  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    this.colorHex,
    required this.isSystem,
    this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['kind'] = Variable<String>(kind);
    map['icon_key'] = Variable<String>(iconKey);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['is_system'] = Variable<bool>(isSystem);
    if (!nullToAbsent || sortOrder != null) {
      map['sort_order'] = Variable<int>(sortOrder);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      kind: Value(kind),
      iconKey: Value(iconKey),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      isSystem: Value(isSystem),
      sortOrder: sortOrder == null && nullToAbsent
          ? const Value.absent()
          : Value(sortOrder),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      kind: serializer.fromJson<String>(json['kind']),
      iconKey: serializer.fromJson<String>(json['iconKey']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      isSystem: serializer.fromJson<bool>(json['isSystem']),
      sortOrder: serializer.fromJson<int?>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'kind': serializer.toJson<String>(kind),
      'iconKey': serializer.toJson<String>(iconKey),
      'colorHex': serializer.toJson<String?>(colorHex),
      'isSystem': serializer.toJson<bool>(isSystem),
      'sortOrder': serializer.toJson<int?>(sortOrder),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    String? kind,
    String? iconKey,
    Value<String?> colorHex = const Value.absent(),
    bool? isSystem,
    Value<int?> sortOrder = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    kind: kind ?? this.kind,
    iconKey: iconKey ?? this.iconKey,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    isSystem: isSystem ?? this.isSystem,
    sortOrder: sortOrder.present ? sortOrder.value : this.sortOrder,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      kind: data.kind.present ? data.kind.value : this.kind,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      isSystem: data.isSystem.present ? data.isSystem.value : this.isSystem,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorHex: $colorHex, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, kind, iconKey, colorHex, isSystem, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.kind == this.kind &&
          other.iconKey == this.iconKey &&
          other.colorHex == this.colorHex &&
          other.isSystem == this.isSystem &&
          other.sortOrder == this.sortOrder);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> kind;
  final Value<String> iconKey;
  final Value<String?> colorHex;
  final Value<bool> isSystem;
  final Value<int?> sortOrder;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.kind = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String name,
    required String kind,
    required String iconKey,
    this.colorHex = const Value.absent(),
    this.isSystem = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       kind = Value(kind),
       iconKey = Value(iconKey);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? kind,
    Expression<String>? iconKey,
    Expression<String>? colorHex,
    Expression<bool>? isSystem,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (kind != null) 'kind': kind,
      if (iconKey != null) 'icon_key': iconKey,
      if (colorHex != null) 'color_hex': colorHex,
      if (isSystem != null) 'is_system': isSystem,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? kind,
    Value<String>? iconKey,
    Value<String?>? colorHex,
    Value<bool>? isSystem,
    Value<int?>? sortOrder,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconKey: iconKey ?? this.iconKey,
      colorHex: colorHex ?? this.colorHex,
      isSystem: isSystem ?? this.isSystem,
      sortOrder: sortOrder ?? this.sortOrder,
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
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (isSystem.present) {
      map['is_system'] = Variable<bool>(isSystem.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('kind: $kind, ')
          ..write('iconKey: $iconKey, ')
          ..write('colorHex: $colorHex, ')
          ..write('isSystem: $isSystem, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _canonicalNameMeta = const VerificationMeta(
    'canonicalName',
  );
  @override
  late final GeneratedColumn<String> canonicalName = GeneratedColumn<String>(
    'canonical_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _defaultUnitMeta = const VerificationMeta(
    'defaultUnit',
  );
  @override
  late final GeneratedColumn<String> defaultUnit = GeneratedColumn<String>(
    'default_unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageSizeMilliMeta = const VerificationMeta(
    'packageSizeMilli',
  );
  @override
  late final GeneratedColumn<int> packageSizeMilli = GeneratedColumn<int>(
    'package_size_milli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    canonicalName,
    categoryId,
    defaultUnit,
    packageSizeMilli,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('canonical_name')) {
      context.handle(
        _canonicalNameMeta,
        canonicalName.isAcceptableOrUnknown(
          data['canonical_name']!,
          _canonicalNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalNameMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('default_unit')) {
      context.handle(
        _defaultUnitMeta,
        defaultUnit.isAcceptableOrUnknown(
          data['default_unit']!,
          _defaultUnitMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultUnitMeta);
    }
    if (data.containsKey('package_size_milli')) {
      context.handle(
        _packageSizeMilliMeta,
        packageSizeMilli.isAcceptableOrUnknown(
          data['package_size_milli']!,
          _packageSizeMilliMeta,
        ),
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
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      canonicalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_name'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      defaultUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_unit'],
      )!,
      packageSizeMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}package_size_milli'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String canonicalName;
  final String? categoryId;
  final String defaultUnit;
  final int? packageSizeMilli;
  final bool isArchived;
  final String? createdAt;
  final String? updatedAt;
  const Product({
    required this.id,
    required this.canonicalName,
    this.categoryId,
    required this.defaultUnit,
    this.packageSizeMilli,
    required this.isArchived,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['canonical_name'] = Variable<String>(canonicalName);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['default_unit'] = Variable<String>(defaultUnit);
    if (!nullToAbsent || packageSizeMilli != null) {
      map['package_size_milli'] = Variable<int>(packageSizeMilli);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      canonicalName: Value(canonicalName),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      defaultUnit: Value(defaultUnit),
      packageSizeMilli: packageSizeMilli == null && nullToAbsent
          ? const Value.absent()
          : Value(packageSizeMilli),
      isArchived: Value(isArchived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      canonicalName: serializer.fromJson<String>(json['canonicalName']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      defaultUnit: serializer.fromJson<String>(json['defaultUnit']),
      packageSizeMilli: serializer.fromJson<int?>(json['packageSizeMilli']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'canonicalName': serializer.toJson<String>(canonicalName),
      'categoryId': serializer.toJson<String?>(categoryId),
      'defaultUnit': serializer.toJson<String>(defaultUnit),
      'packageSizeMilli': serializer.toJson<int?>(packageSizeMilli),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  Product copyWith({
    String? id,
    String? canonicalName,
    Value<String?> categoryId = const Value.absent(),
    String? defaultUnit,
    Value<int?> packageSizeMilli = const Value.absent(),
    bool? isArchived,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => Product(
    id: id ?? this.id,
    canonicalName: canonicalName ?? this.canonicalName,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    defaultUnit: defaultUnit ?? this.defaultUnit,
    packageSizeMilli: packageSizeMilli.present
        ? packageSizeMilli.value
        : this.packageSizeMilli,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      canonicalName: data.canonicalName.present
          ? data.canonicalName.value
          : this.canonicalName,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      defaultUnit: data.defaultUnit.present
          ? data.defaultUnit.value
          : this.defaultUnit,
      packageSizeMilli: data.packageSizeMilli.present
          ? data.packageSizeMilli.value
          : this.packageSizeMilli,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('canonicalName: $canonicalName, ')
          ..write('categoryId: $categoryId, ')
          ..write('defaultUnit: $defaultUnit, ')
          ..write('packageSizeMilli: $packageSizeMilli, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    canonicalName,
    categoryId,
    defaultUnit,
    packageSizeMilli,
    isArchived,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.canonicalName == this.canonicalName &&
          other.categoryId == this.categoryId &&
          other.defaultUnit == this.defaultUnit &&
          other.packageSizeMilli == this.packageSizeMilli &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> canonicalName;
  final Value<String?> categoryId;
  final Value<String> defaultUnit;
  final Value<int?> packageSizeMilli;
  final Value<bool> isArchived;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.canonicalName = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.defaultUnit = const Value.absent(),
    this.packageSizeMilli = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String canonicalName,
    this.categoryId = const Value.absent(),
    required String defaultUnit,
    this.packageSizeMilli = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       canonicalName = Value(canonicalName),
       defaultUnit = Value(defaultUnit);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? canonicalName,
    Expression<String>? categoryId,
    Expression<String>? defaultUnit,
    Expression<int>? packageSizeMilli,
    Expression<bool>? isArchived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (canonicalName != null) 'canonical_name': canonicalName,
      if (categoryId != null) 'category_id': categoryId,
      if (defaultUnit != null) 'default_unit': defaultUnit,
      if (packageSizeMilli != null) 'package_size_milli': packageSizeMilli,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? canonicalName,
    Value<String?>? categoryId,
    Value<String>? defaultUnit,
    Value<int?>? packageSizeMilli,
    Value<bool>? isArchived,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      canonicalName: canonicalName ?? this.canonicalName,
      categoryId: categoryId ?? this.categoryId,
      defaultUnit: defaultUnit ?? this.defaultUnit,
      packageSizeMilli: packageSizeMilli ?? this.packageSizeMilli,
      isArchived: isArchived ?? this.isArchived,
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
    if (canonicalName.present) {
      map['canonical_name'] = Variable<String>(canonicalName.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (defaultUnit.present) {
      map['default_unit'] = Variable<String>(defaultUnit.value);
    }
    if (packageSizeMilli.present) {
      map['package_size_milli'] = Variable<int>(packageSizeMilli.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('canonicalName: $canonicalName, ')
          ..write('categoryId: $categoryId, ')
          ..write('defaultUnit: $defaultUnit, ')
          ..write('packageSizeMilli: $packageSizeMilli, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductAliasesTable extends ProductAliases
    with TableInfo<$ProductAliasesTable, ProductAliase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductAliasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  @override
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedAliasMeta = const VerificationMeta(
    'normalizedAlias',
  );
  @override
  late final GeneratedColumn<String> normalizedAlias = GeneratedColumn<String>(
    'normalized_alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    alias,
    normalizedAlias,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductAliase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('normalized_alias')) {
      context.handle(
        _normalizedAliasMeta,
        normalizedAlias.isAcceptableOrUnknown(
          data['normalized_alias']!,
          _normalizedAliasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedAliasMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {normalizedAlias, productId},
  ];
  @override
  ProductAliase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductAliase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      normalizedAlias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_alias'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $ProductAliasesTable createAlias(String alias) {
    return $ProductAliasesTable(attachedDatabase, alias);
  }
}

class ProductAliase extends DataClass implements Insertable<ProductAliase> {
  final String id;
  final String productId;
  final String alias;
  final String normalizedAlias;
  final String source;
  final String? createdAt;
  const ProductAliase({
    required this.id,
    required this.productId,
    required this.alias,
    required this.normalizedAlias,
    required this.source,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['alias'] = Variable<String>(alias);
    map['normalized_alias'] = Variable<String>(normalizedAlias);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  ProductAliasesCompanion toCompanion(bool nullToAbsent) {
    return ProductAliasesCompanion(
      id: Value(id),
      productId: Value(productId),
      alias: Value(alias),
      normalizedAlias: Value(normalizedAlias),
      source: Value(source),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory ProductAliase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductAliase(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      alias: serializer.fromJson<String>(json['alias']),
      normalizedAlias: serializer.fromJson<String>(json['normalizedAlias']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'alias': serializer.toJson<String>(alias),
      'normalizedAlias': serializer.toJson<String>(normalizedAlias),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  ProductAliase copyWith({
    String? id,
    String? productId,
    String? alias,
    String? normalizedAlias,
    String? source,
    Value<String?> createdAt = const Value.absent(),
  }) => ProductAliase(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    alias: alias ?? this.alias,
    normalizedAlias: normalizedAlias ?? this.normalizedAlias,
    source: source ?? this.source,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  ProductAliase copyWithCompanion(ProductAliasesCompanion data) {
    return ProductAliase(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      alias: data.alias.present ? data.alias.value : this.alias,
      normalizedAlias: data.normalizedAlias.present
          ? data.normalizedAlias.value
          : this.normalizedAlias,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductAliase(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('alias: $alias, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, alias, normalizedAlias, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductAliase &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.alias == this.alias &&
          other.normalizedAlias == this.normalizedAlias &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class ProductAliasesCompanion extends UpdateCompanion<ProductAliase> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> alias;
  final Value<String> normalizedAlias;
  final Value<String> source;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const ProductAliasesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.alias = const Value.absent(),
    this.normalizedAlias = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductAliasesCompanion.insert({
    required String id,
    required String productId,
    required String alias,
    required String normalizedAlias,
    required String source,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       alias = Value(alias),
       normalizedAlias = Value(normalizedAlias),
       source = Value(source);
  static Insertable<ProductAliase> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? alias,
    Expression<String>? normalizedAlias,
    Expression<String>? source,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (alias != null) 'alias': alias,
      if (normalizedAlias != null) 'normalized_alias': normalizedAlias,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductAliasesCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? alias,
    Value<String>? normalizedAlias,
    Value<String>? source,
    Value<String?>? createdAt,
    Value<int>? rowid,
  }) {
    return ProductAliasesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      alias: alias ?? this.alias,
      normalizedAlias: normalizedAlias ?? this.normalizedAlias,
      source: source ?? this.source,
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
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (normalizedAlias.present) {
      map['normalized_alias'] = Variable<String>(normalizedAlias.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductAliasesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('alias: $alias, ')
          ..write('normalizedAlias: $normalizedAlias, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductDenialsTable extends ProductDenials
    with TableInfo<$ProductDenialsTable, ProductDenial> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductDenialsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id) ON DELETE CASCADE',
    ),
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
  static const VerificationMeta _normalizedTextMeta = const VerificationMeta(
    'normalizedText',
  );
  @override
  late final GeneratedColumn<String> normalizedText = GeneratedColumn<String>(
    'normalized_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    rawText,
    normalizedText,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_denials';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductDenial> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('normalized_text')) {
      context.handle(
        _normalizedTextMeta,
        normalizedText.isAcceptableOrUnknown(
          data['normalized_text']!,
          _normalizedTextMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedTextMeta);
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {normalizedText, productId},
  ];
  @override
  ProductDenial map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductDenial(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      normalizedText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_text'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $ProductDenialsTable createAlias(String alias) {
    return $ProductDenialsTable(attachedDatabase, alias);
  }
}

class ProductDenial extends DataClass implements Insertable<ProductDenial> {
  final String id;
  final String productId;
  final String rawText;
  final String normalizedText;
  final String? createdAt;
  const ProductDenial({
    required this.id,
    required this.productId,
    required this.rawText,
    required this.normalizedText,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['raw_text'] = Variable<String>(rawText);
    map['normalized_text'] = Variable<String>(normalizedText);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  ProductDenialsCompanion toCompanion(bool nullToAbsent) {
    return ProductDenialsCompanion(
      id: Value(id),
      productId: Value(productId),
      rawText: Value(rawText),
      normalizedText: Value(normalizedText),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory ProductDenial.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductDenial(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      rawText: serializer.fromJson<String>(json['rawText']),
      normalizedText: serializer.fromJson<String>(json['normalizedText']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'rawText': serializer.toJson<String>(rawText),
      'normalizedText': serializer.toJson<String>(normalizedText),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  ProductDenial copyWith({
    String? id,
    String? productId,
    String? rawText,
    String? normalizedText,
    Value<String?> createdAt = const Value.absent(),
  }) => ProductDenial(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    rawText: rawText ?? this.rawText,
    normalizedText: normalizedText ?? this.normalizedText,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  ProductDenial copyWithCompanion(ProductDenialsCompanion data) {
    return ProductDenial(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      normalizedText: data.normalizedText.present
          ? data.normalizedText.value
          : this.normalizedText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductDenial(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('rawText: $rawText, ')
          ..write('normalizedText: $normalizedText, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, rawText, normalizedText, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductDenial &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.rawText == this.rawText &&
          other.normalizedText == this.normalizedText &&
          other.createdAt == this.createdAt);
}

class ProductDenialsCompanion extends UpdateCompanion<ProductDenial> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> rawText;
  final Value<String> normalizedText;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const ProductDenialsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.rawText = const Value.absent(),
    this.normalizedText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductDenialsCompanion.insert({
    required String id,
    required String productId,
    required String rawText,
    required String normalizedText,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       rawText = Value(rawText),
       normalizedText = Value(normalizedText);
  static Insertable<ProductDenial> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? rawText,
    Expression<String>? normalizedText,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (rawText != null) 'raw_text': rawText,
      if (normalizedText != null) 'normalized_text': normalizedText,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductDenialsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? rawText,
    Value<String>? normalizedText,
    Value<String?>? createdAt,
    Value<int>? rowid,
  }) {
    return ProductDenialsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      rawText: rawText ?? this.rawText,
      normalizedText: normalizedText ?? this.normalizedText,
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
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (normalizedText.present) {
      map['normalized_text'] = Variable<String>(normalizedText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductDenialsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('rawText: $rawText, ')
          ..write('normalizedText: $normalizedText, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoresTable extends Stores with TableInfo<$StoresTable, Store> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoresTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _cnpjMeta = const VerificationMeta('cnpj');
  @override
  late final GeneratedColumn<String> cnpj = GeneratedColumn<String>(
    'cnpj',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
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
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    cnpj,
    address,
    latitude,
    longitude,
    createdAt,
    updatedAt,
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
    if (data.containsKey('cnpj')) {
      context.handle(
        _cnpjMeta,
        cnpj.isAcceptableOrUnknown(data['cnpj']!, _cnpjMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
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
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
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
      cnpj: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cnpj'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $StoresTable createAlias(String alias) {
    return $StoresTable(attachedDatabase, alias);
  }
}

class Store extends DataClass implements Insertable<Store> {
  final String id;
  final String name;
  final String? cnpj;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? createdAt;
  final String? updatedAt;
  const Store({
    required this.id,
    required this.name,
    this.cnpj,
    this.address,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || cnpj != null) {
      map['cnpj'] = Variable<String>(cnpj);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  StoresCompanion toCompanion(bool nullToAbsent) {
    return StoresCompanion(
      id: Value(id),
      name: Value(name),
      cnpj: cnpj == null && nullToAbsent ? const Value.absent() : Value(cnpj),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
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
      cnpj: serializer.fromJson<String?>(json['cnpj']),
      address: serializer.fromJson<String?>(json['address']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'cnpj': serializer.toJson<String?>(cnpj),
      'address': serializer.toJson<String?>(address),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  Store copyWith({
    String? id,
    String? name,
    Value<String?> cnpj = const Value.absent(),
    Value<String?> address = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => Store(
    id: id ?? this.id,
    name: name ?? this.name,
    cnpj: cnpj.present ? cnpj.value : this.cnpj,
    address: address.present ? address.value : this.address,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Store copyWithCompanion(StoresCompanion data) {
    return Store(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      cnpj: data.cnpj.present ? data.cnpj.value : this.cnpj,
      address: data.address.present ? data.address.value : this.address,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Store(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('cnpj: $cnpj, ')
          ..write('address: $address, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    cnpj,
    address,
    latitude,
    longitude,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Store &&
          other.id == this.id &&
          other.name == this.name &&
          other.cnpj == this.cnpj &&
          other.address == this.address &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StoresCompanion extends UpdateCompanion<Store> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> cnpj;
  final Value<String?> address;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const StoresCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.cnpj = const Value.absent(),
    this.address = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoresCompanion.insert({
    required String id,
    required String name,
    this.cnpj = const Value.absent(),
    this.address = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Store> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? cnpj,
    Expression<String>? address,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (cnpj != null) 'cnpj': cnpj,
      if (address != null) 'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoresCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? cnpj,
    Value<String?>? address,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return StoresCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      cnpj: cnpj ?? this.cnpj,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
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
    if (cnpj.present) {
      map['cnpj'] = Variable<String>(cnpj.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
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
          ..write('cnpj: $cnpj, ')
          ..write('address: $address, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecurringRulesTable extends RecurringRules
    with TableInfo<$RecurringRulesTable, RecurringRule> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecurringRulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startsOnMeta = const VerificationMeta(
    'startsOn',
  );
  @override
  late final GeneratedColumn<String> startsOn = GeneratedColumn<String>(
    'starts_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endsOnMeta = const VerificationMeta('endsOn');
  @override
  late final GeneratedColumn<String> endsOn = GeneratedColumn<String>(
    'ends_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMaterializedOnMeta =
      const VerificationMeta('lastMaterializedOn');
  @override
  late final GeneratedColumn<String> lastMaterializedOn =
      GeneratedColumn<String>(
        'last_materialized_on',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    rrule,
    startsOn,
    endsOn,
    amountCents,
    categoryId,
    title,
    lastMaterializedOn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recurring_rules';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringRule> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('rrule')) {
      context.handle(
        _rruleMeta,
        rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta),
      );
    } else if (isInserting) {
      context.missing(_rruleMeta);
    }
    if (data.containsKey('starts_on')) {
      context.handle(
        _startsOnMeta,
        startsOn.isAcceptableOrUnknown(data['starts_on']!, _startsOnMeta),
      );
    } else if (isInserting) {
      context.missing(_startsOnMeta);
    }
    if (data.containsKey('ends_on')) {
      context.handle(
        _endsOnMeta,
        endsOn.isAcceptableOrUnknown(data['ends_on']!, _endsOnMeta),
      );
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('last_materialized_on')) {
      context.handle(
        _lastMaterializedOnMeta,
        lastMaterializedOn.isAcceptableOrUnknown(
          data['last_materialized_on']!,
          _lastMaterializedOnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringRule map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringRule(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      rrule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rrule'],
      )!,
      startsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starts_on'],
      )!,
      endsOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ends_on'],
      ),
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      lastMaterializedOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_materialized_on'],
      ),
    );
  }

  @override
  $RecurringRulesTable createAlias(String alias) {
    return $RecurringRulesTable(attachedDatabase, alias);
  }
}

class RecurringRule extends DataClass implements Insertable<RecurringRule> {
  final String id;
  final String kind;
  final String rrule;
  final String startsOn;
  final String? endsOn;
  final int? amountCents;
  final String? categoryId;
  final String title;
  final String? lastMaterializedOn;
  const RecurringRule({
    required this.id,
    required this.kind,
    required this.rrule,
    required this.startsOn,
    this.endsOn,
    this.amountCents,
    this.categoryId,
    required this.title,
    this.lastMaterializedOn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['rrule'] = Variable<String>(rrule);
    map['starts_on'] = Variable<String>(startsOn);
    if (!nullToAbsent || endsOn != null) {
      map['ends_on'] = Variable<String>(endsOn);
    }
    if (!nullToAbsent || amountCents != null) {
      map['amount_cents'] = Variable<int>(amountCents);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || lastMaterializedOn != null) {
      map['last_materialized_on'] = Variable<String>(lastMaterializedOn);
    }
    return map;
  }

  RecurringRulesCompanion toCompanion(bool nullToAbsent) {
    return RecurringRulesCompanion(
      id: Value(id),
      kind: Value(kind),
      rrule: Value(rrule),
      startsOn: Value(startsOn),
      endsOn: endsOn == null && nullToAbsent
          ? const Value.absent()
          : Value(endsOn),
      amountCents: amountCents == null && nullToAbsent
          ? const Value.absent()
          : Value(amountCents),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      title: Value(title),
      lastMaterializedOn: lastMaterializedOn == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMaterializedOn),
    );
  }

  factory RecurringRule.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringRule(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      rrule: serializer.fromJson<String>(json['rrule']),
      startsOn: serializer.fromJson<String>(json['startsOn']),
      endsOn: serializer.fromJson<String?>(json['endsOn']),
      amountCents: serializer.fromJson<int?>(json['amountCents']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      title: serializer.fromJson<String>(json['title']),
      lastMaterializedOn: serializer.fromJson<String?>(
        json['lastMaterializedOn'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'rrule': serializer.toJson<String>(rrule),
      'startsOn': serializer.toJson<String>(startsOn),
      'endsOn': serializer.toJson<String?>(endsOn),
      'amountCents': serializer.toJson<int?>(amountCents),
      'categoryId': serializer.toJson<String?>(categoryId),
      'title': serializer.toJson<String>(title),
      'lastMaterializedOn': serializer.toJson<String?>(lastMaterializedOn),
    };
  }

  RecurringRule copyWith({
    String? id,
    String? kind,
    String? rrule,
    String? startsOn,
    Value<String?> endsOn = const Value.absent(),
    Value<int?> amountCents = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? title,
    Value<String?> lastMaterializedOn = const Value.absent(),
  }) => RecurringRule(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    rrule: rrule ?? this.rrule,
    startsOn: startsOn ?? this.startsOn,
    endsOn: endsOn.present ? endsOn.value : this.endsOn,
    amountCents: amountCents.present ? amountCents.value : this.amountCents,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    title: title ?? this.title,
    lastMaterializedOn: lastMaterializedOn.present
        ? lastMaterializedOn.value
        : this.lastMaterializedOn,
  );
  RecurringRule copyWithCompanion(RecurringRulesCompanion data) {
    return RecurringRule(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      startsOn: data.startsOn.present ? data.startsOn.value : this.startsOn,
      endsOn: data.endsOn.present ? data.endsOn.value : this.endsOn,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      title: data.title.present ? data.title.value : this.title,
      lastMaterializedOn: data.lastMaterializedOn.present
          ? data.lastMaterializedOn.value
          : this.lastMaterializedOn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRule(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('rrule: $rrule, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('amountCents: $amountCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('lastMaterializedOn: $lastMaterializedOn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    rrule,
    startsOn,
    endsOn,
    amountCents,
    categoryId,
    title,
    lastMaterializedOn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringRule &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.rrule == this.rrule &&
          other.startsOn == this.startsOn &&
          other.endsOn == this.endsOn &&
          other.amountCents == this.amountCents &&
          other.categoryId == this.categoryId &&
          other.title == this.title &&
          other.lastMaterializedOn == this.lastMaterializedOn);
}

class RecurringRulesCompanion extends UpdateCompanion<RecurringRule> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> rrule;
  final Value<String> startsOn;
  final Value<String?> endsOn;
  final Value<int?> amountCents;
  final Value<String?> categoryId;
  final Value<String> title;
  final Value<String?> lastMaterializedOn;
  final Value<int> rowid;
  const RecurringRulesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.rrule = const Value.absent(),
    this.startsOn = const Value.absent(),
    this.endsOn = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.lastMaterializedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecurringRulesCompanion.insert({
    required String id,
    required String kind,
    required String rrule,
    required String startsOn,
    this.endsOn = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.categoryId = const Value.absent(),
    required String title,
    this.lastMaterializedOn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       rrule = Value(rrule),
       startsOn = Value(startsOn),
       title = Value(title);
  static Insertable<RecurringRule> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? rrule,
    Expression<String>? startsOn,
    Expression<String>? endsOn,
    Expression<int>? amountCents,
    Expression<String>? categoryId,
    Expression<String>? title,
    Expression<String>? lastMaterializedOn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (rrule != null) 'rrule': rrule,
      if (startsOn != null) 'starts_on': startsOn,
      if (endsOn != null) 'ends_on': endsOn,
      if (amountCents != null) 'amount_cents': amountCents,
      if (categoryId != null) 'category_id': categoryId,
      if (title != null) 'title': title,
      if (lastMaterializedOn != null)
        'last_materialized_on': lastMaterializedOn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecurringRulesCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? rrule,
    Value<String>? startsOn,
    Value<String?>? endsOn,
    Value<int?>? amountCents,
    Value<String?>? categoryId,
    Value<String>? title,
    Value<String?>? lastMaterializedOn,
    Value<int>? rowid,
  }) {
    return RecurringRulesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      rrule: rrule ?? this.rrule,
      startsOn: startsOn ?? this.startsOn,
      endsOn: endsOn ?? this.endsOn,
      amountCents: amountCents ?? this.amountCents,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      lastMaterializedOn: lastMaterializedOn ?? this.lastMaterializedOn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (startsOn.present) {
      map['starts_on'] = Variable<String>(startsOn.value);
    }
    if (endsOn.present) {
      map['ends_on'] = Variable<String>(endsOn.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (lastMaterializedOn.present) {
      map['last_materialized_on'] = Variable<String>(lastMaterializedOn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecurringRulesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('rrule: $rrule, ')
          ..write('startsOn: $startsOn, ')
          ..write('endsOn: $endsOn, ')
          ..write('amountCents: $amountCents, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('lastMaterializedOn: $lastMaterializedOn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillsTable extends Bills with TableInfo<$BillsTable, Bill> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAmountVariableMeta = const VerificationMeta(
    'isAmountVariable',
  );
  @override
  late final GeneratedColumn<bool> isAmountVariable = GeneratedColumn<bool>(
    'is_amount_variable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_amount_variable" IN (0, 1))',
    ),
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderDaysBeforeMeta =
      const VerificationMeta('reminderDaysBefore');
  @override
  late final GeneratedColumn<int> reminderDaysBefore = GeneratedColumn<int>(
    'reminder_days_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
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
    title,
    amountCents,
    isAmountVariable,
    dueDay,
    categoryId,
    paymentMethod,
    reminderDaysBefore,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bills';
  @override
  VerificationContext validateIntegrity(
    Insertable<Bill> instance, {
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
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    }
    if (data.containsKey('is_amount_variable')) {
      context.handle(
        _isAmountVariableMeta,
        isAmountVariable.isAcceptableOrUnknown(
          data['is_amount_variable']!,
          _isAmountVariableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isAmountVariableMeta);
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    } else if (isInserting) {
      context.missing(_dueDayMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('reminder_days_before')) {
      context.handle(
        _reminderDaysBeforeMeta,
        reminderDaysBefore.isAcceptableOrUnknown(
          data['reminder_days_before']!,
          _reminderDaysBeforeMeta,
        ),
      );
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
  Bill map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Bill(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      ),
      isAmountVariable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_amount_variable'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      reminderDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_days_before'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $BillsTable createAlias(String alias) {
    return $BillsTable(attachedDatabase, alias);
  }
}

class Bill extends DataClass implements Insertable<Bill> {
  final String id;
  final String title;
  final int? amountCents;
  final bool isAmountVariable;
  final int dueDay;
  final String? categoryId;
  final String? paymentMethod;
  final int reminderDaysBefore;
  final bool isActive;
  const Bill({
    required this.id,
    required this.title,
    this.amountCents,
    required this.isAmountVariable,
    required this.dueDay,
    this.categoryId,
    this.paymentMethod,
    required this.reminderDaysBefore,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || amountCents != null) {
      map['amount_cents'] = Variable<int>(amountCents);
    }
    map['is_amount_variable'] = Variable<bool>(isAmountVariable);
    map['due_day'] = Variable<int>(dueDay);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    map['reminder_days_before'] = Variable<int>(reminderDaysBefore);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  BillsCompanion toCompanion(bool nullToAbsent) {
    return BillsCompanion(
      id: Value(id),
      title: Value(title),
      amountCents: amountCents == null && nullToAbsent
          ? const Value.absent()
          : Value(amountCents),
      isAmountVariable: Value(isAmountVariable),
      dueDay: Value(dueDay),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      reminderDaysBefore: Value(reminderDaysBefore),
      isActive: Value(isActive),
    );
  }

  factory Bill.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Bill(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      amountCents: serializer.fromJson<int?>(json['amountCents']),
      isAmountVariable: serializer.fromJson<bool>(json['isAmountVariable']),
      dueDay: serializer.fromJson<int>(json['dueDay']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      reminderDaysBefore: serializer.fromJson<int>(json['reminderDaysBefore']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'amountCents': serializer.toJson<int?>(amountCents),
      'isAmountVariable': serializer.toJson<bool>(isAmountVariable),
      'dueDay': serializer.toJson<int>(dueDay),
      'categoryId': serializer.toJson<String?>(categoryId),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'reminderDaysBefore': serializer.toJson<int>(reminderDaysBefore),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  Bill copyWith({
    String? id,
    String? title,
    Value<int?> amountCents = const Value.absent(),
    bool? isAmountVariable,
    int? dueDay,
    Value<String?> categoryId = const Value.absent(),
    Value<String?> paymentMethod = const Value.absent(),
    int? reminderDaysBefore,
    bool? isActive,
  }) => Bill(
    id: id ?? this.id,
    title: title ?? this.title,
    amountCents: amountCents.present ? amountCents.value : this.amountCents,
    isAmountVariable: isAmountVariable ?? this.isAmountVariable,
    dueDay: dueDay ?? this.dueDay,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    isActive: isActive ?? this.isActive,
  );
  Bill copyWithCompanion(BillsCompanion data) {
    return Bill(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      isAmountVariable: data.isAmountVariable.present
          ? data.isAmountVariable.value
          : this.isAmountVariable,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      reminderDaysBefore: data.reminderDaysBefore.present
          ? data.reminderDaysBefore.value
          : this.reminderDaysBefore,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Bill(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amountCents: $amountCents, ')
          ..write('isAmountVariable: $isAmountVariable, ')
          ..write('dueDay: $dueDay, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('reminderDaysBefore: $reminderDaysBefore, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    amountCents,
    isAmountVariable,
    dueDay,
    categoryId,
    paymentMethod,
    reminderDaysBefore,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Bill &&
          other.id == this.id &&
          other.title == this.title &&
          other.amountCents == this.amountCents &&
          other.isAmountVariable == this.isAmountVariable &&
          other.dueDay == this.dueDay &&
          other.categoryId == this.categoryId &&
          other.paymentMethod == this.paymentMethod &&
          other.reminderDaysBefore == this.reminderDaysBefore &&
          other.isActive == this.isActive);
}

class BillsCompanion extends UpdateCompanion<Bill> {
  final Value<String> id;
  final Value<String> title;
  final Value<int?> amountCents;
  final Value<bool> isAmountVariable;
  final Value<int> dueDay;
  final Value<String?> categoryId;
  final Value<String?> paymentMethod;
  final Value<int> reminderDaysBefore;
  final Value<bool> isActive;
  final Value<int> rowid;
  const BillsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.isAmountVariable = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.reminderDaysBefore = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillsCompanion.insert({
    required String id,
    required String title,
    this.amountCents = const Value.absent(),
    required bool isAmountVariable,
    required int dueDay,
    this.categoryId = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.reminderDaysBefore = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       isAmountVariable = Value(isAmountVariable),
       dueDay = Value(dueDay);
  static Insertable<Bill> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? amountCents,
    Expression<bool>? isAmountVariable,
    Expression<int>? dueDay,
    Expression<String>? categoryId,
    Expression<String>? paymentMethod,
    Expression<int>? reminderDaysBefore,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (amountCents != null) 'amount_cents': amountCents,
      if (isAmountVariable != null) 'is_amount_variable': isAmountVariable,
      if (dueDay != null) 'due_day': dueDay,
      if (categoryId != null) 'category_id': categoryId,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (reminderDaysBefore != null)
        'reminder_days_before': reminderDaysBefore,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int?>? amountCents,
    Value<bool>? isAmountVariable,
    Value<int>? dueDay,
    Value<String?>? categoryId,
    Value<String?>? paymentMethod,
    Value<int>? reminderDaysBefore,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return BillsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      isAmountVariable: isAmountVariable ?? this.isAmountVariable,
      dueDay: dueDay ?? this.dueDay,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (isAmountVariable.present) {
      map['is_amount_variable'] = Variable<bool>(isAmountVariable.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (reminderDaysBefore.present) {
      map['reminder_days_before'] = Variable<int>(reminderDaysBefore.value);
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
    return (StringBuffer('BillsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('amountCents: $amountCents, ')
          ..write('isAmountVariable: $isAmountVariable, ')
          ..write('dueDay: $dueDay, ')
          ..write('categoryId: $categoryId, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('reminderDaysBefore: $reminderDaysBefore, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredOnMeta = const VerificationMeta(
    'occurredOn',
  );
  @override
  late final GeneratedColumn<String> occurredOn = GeneratedColumn<String>(
    'occurred_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
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
  static const VerificationMeta _recurringRuleIdMeta = const VerificationMeta(
    'recurringRuleId',
  );
  @override
  late final GeneratedColumn<String> recurringRuleId = GeneratedColumn<String>(
    'recurring_rule_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurring_rules (id)',
    ),
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bills (id)',
    ),
  );
  static const VerificationMeta _purchaseIdMeta = const VerificationMeta(
    'purchaseId',
  );
  @override
  late final GeneratedColumn<String> purchaseId = GeneratedColumn<String>(
    'purchase_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES purchases (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    amountCents,
    occurredOn,
    description,
    notes,
    recurringRuleId,
    billId,
    purchaseId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
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
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('occurred_on')) {
      context.handle(
        _occurredOnMeta,
        occurredOn.isAcceptableOrUnknown(data['occurred_on']!, _occurredOnMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredOnMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('recurring_rule_id')) {
      context.handle(
        _recurringRuleIdMeta,
        recurringRuleId.isAcceptableOrUnknown(
          data['recurring_rule_id']!,
          _recurringRuleIdMeta,
        ),
      );
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    }
    if (data.containsKey('purchase_id')) {
      context.handle(
        _purchaseIdMeta,
        purchaseId.isAcceptableOrUnknown(data['purchase_id']!, _purchaseIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      occurredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurred_on'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      recurringRuleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_rule_id'],
      ),
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      ),
      purchaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final String id;
  final String? categoryId;
  final int amountCents;
  final String occurredOn;
  final String? description;
  final String? notes;
  final String? recurringRuleId;
  final String? billId;
  final String? purchaseId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  const Expense({
    required this.id,
    this.categoryId,
    required this.amountCents,
    required this.occurredOn,
    this.description,
    this.notes,
    this.recurringRuleId,
    this.billId,
    this.purchaseId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount_cents'] = Variable<int>(amountCents);
    map['occurred_on'] = Variable<String>(occurredOn);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || recurringRuleId != null) {
      map['recurring_rule_id'] = Variable<String>(recurringRuleId);
    }
    if (!nullToAbsent || billId != null) {
      map['bill_id'] = Variable<String>(billId);
    }
    if (!nullToAbsent || purchaseId != null) {
      map['purchase_id'] = Variable<String>(purchaseId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amountCents: Value(amountCents),
      occurredOn: Value(occurredOn),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      recurringRuleId: recurringRuleId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringRuleId),
      billId: billId == null && nullToAbsent
          ? const Value.absent()
          : Value(billId),
      purchaseId: purchaseId == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      occurredOn: serializer.fromJson<String>(json['occurredOn']),
      description: serializer.fromJson<String?>(json['description']),
      notes: serializer.fromJson<String?>(json['notes']),
      recurringRuleId: serializer.fromJson<String?>(json['recurringRuleId']),
      billId: serializer.fromJson<String?>(json['billId']),
      purchaseId: serializer.fromJson<String?>(json['purchaseId']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amountCents': serializer.toJson<int>(amountCents),
      'occurredOn': serializer.toJson<String>(occurredOn),
      'description': serializer.toJson<String?>(description),
      'notes': serializer.toJson<String?>(notes),
      'recurringRuleId': serializer.toJson<String?>(recurringRuleId),
      'billId': serializer.toJson<String?>(billId),
      'purchaseId': serializer.toJson<String?>(purchaseId),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  Expense copyWith({
    String? id,
    Value<String?> categoryId = const Value.absent(),
    int? amountCents,
    String? occurredOn,
    Value<String?> description = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> recurringRuleId = const Value.absent(),
    Value<String?> billId = const Value.absent(),
    Value<String?> purchaseId = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
  }) => Expense(
    id: id ?? this.id,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    amountCents: amountCents ?? this.amountCents,
    occurredOn: occurredOn ?? this.occurredOn,
    description: description.present ? description.value : this.description,
    notes: notes.present ? notes.value : this.notes,
    recurringRuleId: recurringRuleId.present
        ? recurringRuleId.value
        : this.recurringRuleId,
    billId: billId.present ? billId.value : this.billId,
    purchaseId: purchaseId.present ? purchaseId.value : this.purchaseId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      occurredOn: data.occurredOn.present
          ? data.occurredOn.value
          : this.occurredOn,
      description: data.description.present
          ? data.description.value
          : this.description,
      notes: data.notes.present ? data.notes.value : this.notes,
      recurringRuleId: data.recurringRuleId.present
          ? data.recurringRuleId.value
          : this.recurringRuleId,
      billId: data.billId.present ? data.billId.value : this.billId,
      purchaseId: data.purchaseId.present
          ? data.purchaseId.value
          : this.purchaseId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountCents: $amountCents, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('recurringRuleId: $recurringRuleId, ')
          ..write('billId: $billId, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    amountCents,
    occurredOn,
    description,
    notes,
    recurringRuleId,
    billId,
    purchaseId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.amountCents == this.amountCents &&
          other.occurredOn == this.occurredOn &&
          other.description == this.description &&
          other.notes == this.notes &&
          other.recurringRuleId == this.recurringRuleId &&
          other.billId == this.billId &&
          other.purchaseId == this.purchaseId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<String> id;
  final Value<String?> categoryId;
  final Value<int> amountCents;
  final Value<String> occurredOn;
  final Value<String?> description;
  final Value<String?> notes;
  final Value<String?> recurringRuleId;
  final Value<String?> billId;
  final Value<String?> purchaseId;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.occurredOn = const Value.absent(),
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.recurringRuleId = const Value.absent(),
    this.billId = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    this.categoryId = const Value.absent(),
    required int amountCents,
    required String occurredOn,
    this.description = const Value.absent(),
    this.notes = const Value.absent(),
    this.recurringRuleId = const Value.absent(),
    this.billId = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       amountCents = Value(amountCents),
       occurredOn = Value(occurredOn);
  static Insertable<Expense> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<int>? amountCents,
    Expression<String>? occurredOn,
    Expression<String>? description,
    Expression<String>? notes,
    Expression<String>? recurringRuleId,
    Expression<String>? billId,
    Expression<String>? purchaseId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (occurredOn != null) 'occurred_on': occurredOn,
      if (description != null) 'description': description,
      if (notes != null) 'notes': notes,
      if (recurringRuleId != null) 'recurring_rule_id': recurringRuleId,
      if (billId != null) 'bill_id': billId,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String?>? categoryId,
    Value<int>? amountCents,
    Value<String>? occurredOn,
    Value<String?>? description,
    Value<String?>? notes,
    Value<String?>? recurringRuleId,
    Value<String?>? billId,
    Value<String?>? purchaseId,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      occurredOn: occurredOn ?? this.occurredOn,
      description: description ?? this.description,
      notes: notes ?? this.notes,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      billId: billId ?? this.billId,
      purchaseId: purchaseId ?? this.purchaseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (occurredOn.present) {
      map['occurred_on'] = Variable<String>(occurredOn.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (recurringRuleId.present) {
      map['recurring_rule_id'] = Variable<String>(recurringRuleId.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (purchaseId.present) {
      map['purchase_id'] = Variable<String>(purchaseId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountCents: $amountCents, ')
          ..write('occurredOn: $occurredOn, ')
          ..write('description: $description, ')
          ..write('notes: $notes, ')
          ..write('recurringRuleId: $recurringRuleId, ')
          ..write('billId: $billId, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchasesTable extends Purchases
    with TableInfo<$PurchasesTable, Purchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  static const VerificationMeta _purchasedAtMeta = const VerificationMeta(
    'purchasedAt',
  );
  @override
  late final GeneratedColumn<String> purchasedAt = GeneratedColumn<String>(
    'purchased_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalCentsMeta = const VerificationMeta(
    'totalCents',
  );
  @override
  late final GeneratedColumn<int> totalCents = GeneratedColumn<int>(
    'total_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountCentsMeta = const VerificationMeta(
    'discountCents',
  );
  @override
  late final GeneratedColumn<int> discountCents = GeneratedColumn<int>(
    'discount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _paymentMethodMeta = const VerificationMeta(
    'paymentMethod',
  );
  @override
  late final GeneratedColumn<String> paymentMethod = GeneratedColumn<String>(
    'payment_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptImagePathMeta = const VerificationMeta(
    'receiptImagePath',
  );
  @override
  late final GeneratedColumn<String> receiptImagePath = GeneratedColumn<String>(
    'receipt_image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _receiptKeyMeta = const VerificationMeta(
    'receiptKey',
  );
  @override
  late final GeneratedColumn<String> receiptKey = GeneratedColumn<String>(
    'receipt_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    purchasedAt,
    totalCents,
    discountCents,
    paymentMethod,
    receiptImagePath,
    receiptKey,
    source,
    expenseId,
    createdAt,
    updatedAt,
    deletedAt,
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
    }
    if (data.containsKey('purchased_at')) {
      context.handle(
        _purchasedAtMeta,
        purchasedAt.isAcceptableOrUnknown(
          data['purchased_at']!,
          _purchasedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchasedAtMeta);
    }
    if (data.containsKey('total_cents')) {
      context.handle(
        _totalCentsMeta,
        totalCents.isAcceptableOrUnknown(data['total_cents']!, _totalCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_totalCentsMeta);
    }
    if (data.containsKey('discount_cents')) {
      context.handle(
        _discountCentsMeta,
        discountCents.isAcceptableOrUnknown(
          data['discount_cents']!,
          _discountCentsMeta,
        ),
      );
    }
    if (data.containsKey('payment_method')) {
      context.handle(
        _paymentMethodMeta,
        paymentMethod.isAcceptableOrUnknown(
          data['payment_method']!,
          _paymentMethodMeta,
        ),
      );
    }
    if (data.containsKey('receipt_image_path')) {
      context.handle(
        _receiptImagePathMeta,
        receiptImagePath.isAcceptableOrUnknown(
          data['receipt_image_path']!,
          _receiptImagePathMeta,
        ),
      );
    }
    if (data.containsKey('receipt_key')) {
      context.handle(
        _receiptKeyMeta,
        receiptKey.isAcceptableOrUnknown(data['receipt_key']!, _receiptKeyMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
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
      ),
      purchasedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchased_at'],
      )!,
      totalCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_cents'],
      )!,
      discountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_cents'],
      )!,
      paymentMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payment_method'],
      ),
      receiptImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_image_path'],
      ),
      receiptKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_key'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PurchasesTable createAlias(String alias) {
    return $PurchasesTable(attachedDatabase, alias);
  }
}

class Purchase extends DataClass implements Insertable<Purchase> {
  final String id;
  final String? storeId;
  final String purchasedAt;
  final int totalCents;
  final int discountCents;
  final String? paymentMethod;
  final String? receiptImagePath;
  final String? receiptKey;
  final String source;
  final String? expenseId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  const Purchase({
    required this.id,
    this.storeId,
    required this.purchasedAt,
    required this.totalCents,
    required this.discountCents,
    this.paymentMethod,
    this.receiptImagePath,
    this.receiptKey,
    required this.source,
    this.expenseId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['purchased_at'] = Variable<String>(purchasedAt);
    map['total_cents'] = Variable<int>(totalCents);
    map['discount_cents'] = Variable<int>(discountCents);
    if (!nullToAbsent || paymentMethod != null) {
      map['payment_method'] = Variable<String>(paymentMethod);
    }
    if (!nullToAbsent || receiptImagePath != null) {
      map['receipt_image_path'] = Variable<String>(receiptImagePath);
    }
    if (!nullToAbsent || receiptKey != null) {
      map['receipt_key'] = Variable<String>(receiptKey);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || expenseId != null) {
      map['expense_id'] = Variable<String>(expenseId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  PurchasesCompanion toCompanion(bool nullToAbsent) {
    return PurchasesCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      purchasedAt: Value(purchasedAt),
      totalCents: Value(totalCents),
      discountCents: Value(discountCents),
      paymentMethod: paymentMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(paymentMethod),
      receiptImagePath: receiptImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptImagePath),
      receiptKey: receiptKey == null && nullToAbsent
          ? const Value.absent()
          : Value(receiptKey),
      source: Value(source),
      expenseId: expenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(expenseId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Purchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Purchase(
      id: serializer.fromJson<String>(json['id']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      purchasedAt: serializer.fromJson<String>(json['purchasedAt']),
      totalCents: serializer.fromJson<int>(json['totalCents']),
      discountCents: serializer.fromJson<int>(json['discountCents']),
      paymentMethod: serializer.fromJson<String?>(json['paymentMethod']),
      receiptImagePath: serializer.fromJson<String?>(json['receiptImagePath']),
      receiptKey: serializer.fromJson<String?>(json['receiptKey']),
      source: serializer.fromJson<String>(json['source']),
      expenseId: serializer.fromJson<String?>(json['expenseId']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'storeId': serializer.toJson<String?>(storeId),
      'purchasedAt': serializer.toJson<String>(purchasedAt),
      'totalCents': serializer.toJson<int>(totalCents),
      'discountCents': serializer.toJson<int>(discountCents),
      'paymentMethod': serializer.toJson<String?>(paymentMethod),
      'receiptImagePath': serializer.toJson<String?>(receiptImagePath),
      'receiptKey': serializer.toJson<String?>(receiptKey),
      'source': serializer.toJson<String>(source),
      'expenseId': serializer.toJson<String?>(expenseId),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  Purchase copyWith({
    String? id,
    Value<String?> storeId = const Value.absent(),
    String? purchasedAt,
    int? totalCents,
    int? discountCents,
    Value<String?> paymentMethod = const Value.absent(),
    Value<String?> receiptImagePath = const Value.absent(),
    Value<String?> receiptKey = const Value.absent(),
    String? source,
    Value<String?> expenseId = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
  }) => Purchase(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    purchasedAt: purchasedAt ?? this.purchasedAt,
    totalCents: totalCents ?? this.totalCents,
    discountCents: discountCents ?? this.discountCents,
    paymentMethod: paymentMethod.present
        ? paymentMethod.value
        : this.paymentMethod,
    receiptImagePath: receiptImagePath.present
        ? receiptImagePath.value
        : this.receiptImagePath,
    receiptKey: receiptKey.present ? receiptKey.value : this.receiptKey,
    source: source ?? this.source,
    expenseId: expenseId.present ? expenseId.value : this.expenseId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Purchase copyWithCompanion(PurchasesCompanion data) {
    return Purchase(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      purchasedAt: data.purchasedAt.present
          ? data.purchasedAt.value
          : this.purchasedAt,
      totalCents: data.totalCents.present
          ? data.totalCents.value
          : this.totalCents,
      discountCents: data.discountCents.present
          ? data.discountCents.value
          : this.discountCents,
      paymentMethod: data.paymentMethod.present
          ? data.paymentMethod.value
          : this.paymentMethod,
      receiptImagePath: data.receiptImagePath.present
          ? data.receiptImagePath.value
          : this.receiptImagePath,
      receiptKey: data.receiptKey.present
          ? data.receiptKey.value
          : this.receiptKey,
      source: data.source.present ? data.source.value : this.source,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Purchase(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('purchasedAt: $purchasedAt, ')
          ..write('totalCents: $totalCents, ')
          ..write('discountCents: $discountCents, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('receiptImagePath: $receiptImagePath, ')
          ..write('receiptKey: $receiptKey, ')
          ..write('source: $source, ')
          ..write('expenseId: $expenseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    purchasedAt,
    totalCents,
    discountCents,
    paymentMethod,
    receiptImagePath,
    receiptKey,
    source,
    expenseId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Purchase &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.purchasedAt == this.purchasedAt &&
          other.totalCents == this.totalCents &&
          other.discountCents == this.discountCents &&
          other.paymentMethod == this.paymentMethod &&
          other.receiptImagePath == this.receiptImagePath &&
          other.receiptKey == this.receiptKey &&
          other.source == this.source &&
          other.expenseId == this.expenseId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class PurchasesCompanion extends UpdateCompanion<Purchase> {
  final Value<String> id;
  final Value<String?> storeId;
  final Value<String> purchasedAt;
  final Value<int> totalCents;
  final Value<int> discountCents;
  final Value<String?> paymentMethod;
  final Value<String?> receiptImagePath;
  final Value<String?> receiptKey;
  final Value<String> source;
  final Value<String?> expenseId;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const PurchasesCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.purchasedAt = const Value.absent(),
    this.totalCents = const Value.absent(),
    this.discountCents = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.receiptImagePath = const Value.absent(),
    this.receiptKey = const Value.absent(),
    this.source = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchasesCompanion.insert({
    required String id,
    this.storeId = const Value.absent(),
    required String purchasedAt,
    required int totalCents,
    this.discountCents = const Value.absent(),
    this.paymentMethod = const Value.absent(),
    this.receiptImagePath = const Value.absent(),
    this.receiptKey = const Value.absent(),
    required String source,
    this.expenseId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       purchasedAt = Value(purchasedAt),
       totalCents = Value(totalCents),
       source = Value(source);
  static Insertable<Purchase> custom({
    Expression<String>? id,
    Expression<String>? storeId,
    Expression<String>? purchasedAt,
    Expression<int>? totalCents,
    Expression<int>? discountCents,
    Expression<String>? paymentMethod,
    Expression<String>? receiptImagePath,
    Expression<String>? receiptKey,
    Expression<String>? source,
    Expression<String>? expenseId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (purchasedAt != null) 'purchased_at': purchasedAt,
      if (totalCents != null) 'total_cents': totalCents,
      if (discountCents != null) 'discount_cents': discountCents,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (receiptImagePath != null) 'receipt_image_path': receiptImagePath,
      if (receiptKey != null) 'receipt_key': receiptKey,
      if (source != null) 'source': source,
      if (expenseId != null) 'expense_id': expenseId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchasesCompanion copyWith({
    Value<String>? id,
    Value<String?>? storeId,
    Value<String>? purchasedAt,
    Value<int>? totalCents,
    Value<int>? discountCents,
    Value<String?>? paymentMethod,
    Value<String?>? receiptImagePath,
    Value<String?>? receiptKey,
    Value<String>? source,
    Value<String?>? expenseId,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PurchasesCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      purchasedAt: purchasedAt ?? this.purchasedAt,
      totalCents: totalCents ?? this.totalCents,
      discountCents: discountCents ?? this.discountCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      receiptKey: receiptKey ?? this.receiptKey,
      source: source ?? this.source,
      expenseId: expenseId ?? this.expenseId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (purchasedAt.present) {
      map['purchased_at'] = Variable<String>(purchasedAt.value);
    }
    if (totalCents.present) {
      map['total_cents'] = Variable<int>(totalCents.value);
    }
    if (discountCents.present) {
      map['discount_cents'] = Variable<int>(discountCents.value);
    }
    if (paymentMethod.present) {
      map['payment_method'] = Variable<String>(paymentMethod.value);
    }
    if (receiptImagePath.present) {
      map['receipt_image_path'] = Variable<String>(receiptImagePath.value);
    }
    if (receiptKey.present) {
      map['receipt_key'] = Variable<String>(receiptKey.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
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
          ..write('purchasedAt: $purchasedAt, ')
          ..write('totalCents: $totalCents, ')
          ..write('discountCents: $discountCents, ')
          ..write('paymentMethod: $paymentMethod, ')
          ..write('receiptImagePath: $receiptImagePath, ')
          ..write('receiptKey: $receiptKey, ')
          ..write('source: $source, ')
          ..write('expenseId: $expenseId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PurchaseItemsTable extends PurchaseItems
    with TableInfo<$PurchaseItemsTable, PurchaseItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PurchaseItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseIdMeta = const VerificationMeta(
    'purchaseId',
  );
  @override
  late final GeneratedColumn<String> purchaseId = GeneratedColumn<String>(
    'purchase_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES purchases (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _rawDescriptionMeta = const VerificationMeta(
    'rawDescription',
  );
  @override
  late final GeneratedColumn<String> rawDescription = GeneratedColumn<String>(
    'raw_description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMilliMeta = const VerificationMeta(
    'quantityMilli',
  );
  @override
  late final GeneratedColumn<int> quantityMilli = GeneratedColumn<int>(
    'quantity_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceCentsMeta = const VerificationMeta(
    'unitPriceCents',
  );
  @override
  late final GeneratedColumn<int> unitPriceCents = GeneratedColumn<int>(
    'unit_price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalPriceCentsMeta = const VerificationMeta(
    'totalPriceCents',
  );
  @override
  late final GeneratedColumn<int> totalPriceCents = GeneratedColumn<int>(
    'total_price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eanMeta = const VerificationMeta('ean');
  @override
  late final GeneratedColumn<String> ean = GeneratedColumn<String>(
    'ean',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    purchaseId,
    productId,
    rawDescription,
    quantityMilli,
    unit,
    unitPriceCents,
    totalPriceCents,
    ean,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseItem> instance, {
    bool isInserting = false,
  }) {
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
        purchaseId.isAcceptableOrUnknown(data['purchase_id']!, _purchaseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_purchaseIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('raw_description')) {
      context.handle(
        _rawDescriptionMeta,
        rawDescription.isAcceptableOrUnknown(
          data['raw_description']!,
          _rawDescriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rawDescriptionMeta);
    }
    if (data.containsKey('quantity_milli')) {
      context.handle(
        _quantityMilliMeta,
        quantityMilli.isAcceptableOrUnknown(
          data['quantity_milli']!,
          _quantityMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityMilliMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('unit_price_cents')) {
      context.handle(
        _unitPriceCentsMeta,
        unitPriceCents.isAcceptableOrUnknown(
          data['unit_price_cents']!,
          _unitPriceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceCentsMeta);
    }
    if (data.containsKey('total_price_cents')) {
      context.handle(
        _totalPriceCentsMeta,
        totalPriceCents.isAcceptableOrUnknown(
          data['total_price_cents']!,
          _totalPriceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalPriceCentsMeta);
    }
    if (data.containsKey('ean')) {
      context.handle(
        _eanMeta,
        ean.isAcceptableOrUnknown(data['ean']!, _eanMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      purchaseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      rawDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_description'],
      )!,
      quantityMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_milli'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      unitPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_cents'],
      )!,
      totalPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_price_cents'],
      )!,
      ean: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ean'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $PurchaseItemsTable createAlias(String alias) {
    return $PurchaseItemsTable(attachedDatabase, alias);
  }
}

class PurchaseItem extends DataClass implements Insertable<PurchaseItem> {
  final String id;
  final String purchaseId;
  final String? productId;
  final String rawDescription;
  final int quantityMilli;
  final String unit;
  final int unitPriceCents;
  final int totalPriceCents;
  final String? ean;
  final int position;
  const PurchaseItem({
    required this.id,
    required this.purchaseId,
    this.productId,
    required this.rawDescription,
    required this.quantityMilli,
    required this.unit,
    required this.unitPriceCents,
    required this.totalPriceCents,
    this.ean,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['purchase_id'] = Variable<String>(purchaseId);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['raw_description'] = Variable<String>(rawDescription);
    map['quantity_milli'] = Variable<int>(quantityMilli);
    map['unit'] = Variable<String>(unit);
    map['unit_price_cents'] = Variable<int>(unitPriceCents);
    map['total_price_cents'] = Variable<int>(totalPriceCents);
    if (!nullToAbsent || ean != null) {
      map['ean'] = Variable<String>(ean);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  PurchaseItemsCompanion toCompanion(bool nullToAbsent) {
    return PurchaseItemsCompanion(
      id: Value(id),
      purchaseId: Value(purchaseId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      rawDescription: Value(rawDescription),
      quantityMilli: Value(quantityMilli),
      unit: Value(unit),
      unitPriceCents: Value(unitPriceCents),
      totalPriceCents: Value(totalPriceCents),
      ean: ean == null && nullToAbsent ? const Value.absent() : Value(ean),
      position: Value(position),
    );
  }

  factory PurchaseItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseItem(
      id: serializer.fromJson<String>(json['id']),
      purchaseId: serializer.fromJson<String>(json['purchaseId']),
      productId: serializer.fromJson<String?>(json['productId']),
      rawDescription: serializer.fromJson<String>(json['rawDescription']),
      quantityMilli: serializer.fromJson<int>(json['quantityMilli']),
      unit: serializer.fromJson<String>(json['unit']),
      unitPriceCents: serializer.fromJson<int>(json['unitPriceCents']),
      totalPriceCents: serializer.fromJson<int>(json['totalPriceCents']),
      ean: serializer.fromJson<String?>(json['ean']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'purchaseId': serializer.toJson<String>(purchaseId),
      'productId': serializer.toJson<String?>(productId),
      'rawDescription': serializer.toJson<String>(rawDescription),
      'quantityMilli': serializer.toJson<int>(quantityMilli),
      'unit': serializer.toJson<String>(unit),
      'unitPriceCents': serializer.toJson<int>(unitPriceCents),
      'totalPriceCents': serializer.toJson<int>(totalPriceCents),
      'ean': serializer.toJson<String?>(ean),
      'position': serializer.toJson<int>(position),
    };
  }

  PurchaseItem copyWith({
    String? id,
    String? purchaseId,
    Value<String?> productId = const Value.absent(),
    String? rawDescription,
    int? quantityMilli,
    String? unit,
    int? unitPriceCents,
    int? totalPriceCents,
    Value<String?> ean = const Value.absent(),
    int? position,
  }) => PurchaseItem(
    id: id ?? this.id,
    purchaseId: purchaseId ?? this.purchaseId,
    productId: productId.present ? productId.value : this.productId,
    rawDescription: rawDescription ?? this.rawDescription,
    quantityMilli: quantityMilli ?? this.quantityMilli,
    unit: unit ?? this.unit,
    unitPriceCents: unitPriceCents ?? this.unitPriceCents,
    totalPriceCents: totalPriceCents ?? this.totalPriceCents,
    ean: ean.present ? ean.value : this.ean,
    position: position ?? this.position,
  );
  PurchaseItem copyWithCompanion(PurchaseItemsCompanion data) {
    return PurchaseItem(
      id: data.id.present ? data.id.value : this.id,
      purchaseId: data.purchaseId.present
          ? data.purchaseId.value
          : this.purchaseId,
      productId: data.productId.present ? data.productId.value : this.productId,
      rawDescription: data.rawDescription.present
          ? data.rawDescription.value
          : this.rawDescription,
      quantityMilli: data.quantityMilli.present
          ? data.quantityMilli.value
          : this.quantityMilli,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPriceCents: data.unitPriceCents.present
          ? data.unitPriceCents.value
          : this.unitPriceCents,
      totalPriceCents: data.totalPriceCents.present
          ? data.totalPriceCents.value
          : this.totalPriceCents,
      ean: data.ean.present ? data.ean.value : this.ean,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseItem(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('productId: $productId, ')
          ..write('rawDescription: $rawDescription, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('totalPriceCents: $totalPriceCents, ')
          ..write('ean: $ean, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    purchaseId,
    productId,
    rawDescription,
    quantityMilli,
    unit,
    unitPriceCents,
    totalPriceCents,
    ean,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseItem &&
          other.id == this.id &&
          other.purchaseId == this.purchaseId &&
          other.productId == this.productId &&
          other.rawDescription == this.rawDescription &&
          other.quantityMilli == this.quantityMilli &&
          other.unit == this.unit &&
          other.unitPriceCents == this.unitPriceCents &&
          other.totalPriceCents == this.totalPriceCents &&
          other.ean == this.ean &&
          other.position == this.position);
}

class PurchaseItemsCompanion extends UpdateCompanion<PurchaseItem> {
  final Value<String> id;
  final Value<String> purchaseId;
  final Value<String?> productId;
  final Value<String> rawDescription;
  final Value<int> quantityMilli;
  final Value<String> unit;
  final Value<int> unitPriceCents;
  final Value<int> totalPriceCents;
  final Value<String?> ean;
  final Value<int> position;
  final Value<int> rowid;
  const PurchaseItemsCompanion({
    this.id = const Value.absent(),
    this.purchaseId = const Value.absent(),
    this.productId = const Value.absent(),
    this.rawDescription = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPriceCents = const Value.absent(),
    this.totalPriceCents = const Value.absent(),
    this.ean = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseItemsCompanion.insert({
    required String id,
    required String purchaseId,
    this.productId = const Value.absent(),
    required String rawDescription,
    required int quantityMilli,
    required String unit,
    required int unitPriceCents,
    required int totalPriceCents,
    this.ean = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       purchaseId = Value(purchaseId),
       rawDescription = Value(rawDescription),
       quantityMilli = Value(quantityMilli),
       unit = Value(unit),
       unitPriceCents = Value(unitPriceCents),
       totalPriceCents = Value(totalPriceCents),
       position = Value(position);
  static Insertable<PurchaseItem> custom({
    Expression<String>? id,
    Expression<String>? purchaseId,
    Expression<String>? productId,
    Expression<String>? rawDescription,
    Expression<int>? quantityMilli,
    Expression<String>? unit,
    Expression<int>? unitPriceCents,
    Expression<int>? totalPriceCents,
    Expression<String>? ean,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (purchaseId != null) 'purchase_id': purchaseId,
      if (productId != null) 'product_id': productId,
      if (rawDescription != null) 'raw_description': rawDescription,
      if (quantityMilli != null) 'quantity_milli': quantityMilli,
      if (unit != null) 'unit': unit,
      if (unitPriceCents != null) 'unit_price_cents': unitPriceCents,
      if (totalPriceCents != null) 'total_price_cents': totalPriceCents,
      if (ean != null) 'ean': ean,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? purchaseId,
    Value<String?>? productId,
    Value<String>? rawDescription,
    Value<int>? quantityMilli,
    Value<String>? unit,
    Value<int>? unitPriceCents,
    Value<int>? totalPriceCents,
    Value<String?>? ean,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return PurchaseItemsCompanion(
      id: id ?? this.id,
      purchaseId: purchaseId ?? this.purchaseId,
      productId: productId ?? this.productId,
      rawDescription: rawDescription ?? this.rawDescription,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      unit: unit ?? this.unit,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      totalPriceCents: totalPriceCents ?? this.totalPriceCents,
      ean: ean ?? this.ean,
      position: position ?? this.position,
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
    if (rawDescription.present) {
      map['raw_description'] = Variable<String>(rawDescription.value);
    }
    if (quantityMilli.present) {
      map['quantity_milli'] = Variable<int>(quantityMilli.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitPriceCents.present) {
      map['unit_price_cents'] = Variable<int>(unitPriceCents.value);
    }
    if (totalPriceCents.present) {
      map['total_price_cents'] = Variable<int>(totalPriceCents.value);
    }
    if (ean.present) {
      map['ean'] = Variable<String>(ean.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseItemsCompanion(')
          ..write('id: $id, ')
          ..write('purchaseId: $purchaseId, ')
          ..write('productId: $productId, ')
          ..write('rawDescription: $rawDescription, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('totalPriceCents: $totalPriceCents, ')
          ..write('ean: $ean, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PricePointsTable extends PricePoints
    with TableInfo<$PricePointsTable, PricePoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PricePointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  @override
  late final GeneratedColumn<String> observedAt = GeneratedColumn<String>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceCentsMeta = const VerificationMeta(
    'unitPriceCents',
  );
  @override
  late final GeneratedColumn<int> unitPriceCents = GeneratedColumn<int>(
    'unit_price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedPriceCentsMeta =
      const VerificationMeta('normalizedPriceCents');
  @override
  late final GeneratedColumn<int> normalizedPriceCents = GeneratedColumn<int>(
    'normalized_price_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMilliMeta = const VerificationMeta(
    'quantityMilli',
  );
  @override
  late final GeneratedColumn<int> quantityMilli = GeneratedColumn<int>(
    'quantity_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseItemIdMeta = const VerificationMeta(
    'purchaseItemId',
  );
  @override
  late final GeneratedColumn<String> purchaseItemId = GeneratedColumn<String>(
    'purchase_item_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES purchase_items (id)',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    storeId,
    observedAt,
    unitPriceCents,
    normalizedPriceCents,
    quantityMilli,
    unit,
    purchaseItemId,
    source,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'price_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<PricePoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_observedAtMeta);
    }
    if (data.containsKey('unit_price_cents')) {
      context.handle(
        _unitPriceCentsMeta,
        unitPriceCents.isAcceptableOrUnknown(
          data['unit_price_cents']!,
          _unitPriceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceCentsMeta);
    }
    if (data.containsKey('normalized_price_cents')) {
      context.handle(
        _normalizedPriceCentsMeta,
        normalizedPriceCents.isAcceptableOrUnknown(
          data['normalized_price_cents']!,
          _normalizedPriceCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedPriceCentsMeta);
    }
    if (data.containsKey('quantity_milli')) {
      context.handle(
        _quantityMilliMeta,
        quantityMilli.isAcceptableOrUnknown(
          data['quantity_milli']!,
          _quantityMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_quantityMilliMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('purchase_item_id')) {
      context.handle(
        _purchaseItemIdMeta,
        purchaseItemId.isAcceptableOrUnknown(
          data['purchase_item_id']!,
          _purchaseItemIdMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PricePoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PricePoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_at'],
      )!,
      unitPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_cents'],
      )!,
      normalizedPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}normalized_price_cents'],
      )!,
      quantityMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_milli'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      purchaseItemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_item_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $PricePointsTable createAlias(String alias) {
    return $PricePointsTable(attachedDatabase, alias);
  }
}

class PricePoint extends DataClass implements Insertable<PricePoint> {
  final String id;
  final String? productId;
  final String? storeId;
  final String observedAt;
  final int unitPriceCents;
  final int normalizedPriceCents;
  final int quantityMilli;
  final String unit;
  final String? purchaseItemId;
  final String source;
  final String? deletedAt;
  const PricePoint({
    required this.id,
    this.productId,
    this.storeId,
    required this.observedAt,
    required this.unitPriceCents,
    required this.normalizedPriceCents,
    required this.quantityMilli,
    required this.unit,
    this.purchaseItemId,
    required this.source,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['observed_at'] = Variable<String>(observedAt);
    map['unit_price_cents'] = Variable<int>(unitPriceCents);
    map['normalized_price_cents'] = Variable<int>(normalizedPriceCents);
    map['quantity_milli'] = Variable<int>(quantityMilli);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || purchaseItemId != null) {
      map['purchase_item_id'] = Variable<String>(purchaseItemId);
    }
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  PricePointsCompanion toCompanion(bool nullToAbsent) {
    return PricePointsCompanion(
      id: Value(id),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      observedAt: Value(observedAt),
      unitPriceCents: Value(unitPriceCents),
      normalizedPriceCents: Value(normalizedPriceCents),
      quantityMilli: Value(quantityMilli),
      unit: Value(unit),
      purchaseItemId: purchaseItemId == null && nullToAbsent
          ? const Value.absent()
          : Value(purchaseItemId),
      source: Value(source),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory PricePoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PricePoint(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String?>(json['productId']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      observedAt: serializer.fromJson<String>(json['observedAt']),
      unitPriceCents: serializer.fromJson<int>(json['unitPriceCents']),
      normalizedPriceCents: serializer.fromJson<int>(
        json['normalizedPriceCents'],
      ),
      quantityMilli: serializer.fromJson<int>(json['quantityMilli']),
      unit: serializer.fromJson<String>(json['unit']),
      purchaseItemId: serializer.fromJson<String?>(json['purchaseItemId']),
      source: serializer.fromJson<String>(json['source']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String?>(productId),
      'storeId': serializer.toJson<String?>(storeId),
      'observedAt': serializer.toJson<String>(observedAt),
      'unitPriceCents': serializer.toJson<int>(unitPriceCents),
      'normalizedPriceCents': serializer.toJson<int>(normalizedPriceCents),
      'quantityMilli': serializer.toJson<int>(quantityMilli),
      'unit': serializer.toJson<String>(unit),
      'purchaseItemId': serializer.toJson<String?>(purchaseItemId),
      'source': serializer.toJson<String>(source),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  PricePoint copyWith({
    String? id,
    Value<String?> productId = const Value.absent(),
    Value<String?> storeId = const Value.absent(),
    String? observedAt,
    int? unitPriceCents,
    int? normalizedPriceCents,
    int? quantityMilli,
    String? unit,
    Value<String?> purchaseItemId = const Value.absent(),
    String? source,
    Value<String?> deletedAt = const Value.absent(),
  }) => PricePoint(
    id: id ?? this.id,
    productId: productId.present ? productId.value : this.productId,
    storeId: storeId.present ? storeId.value : this.storeId,
    observedAt: observedAt ?? this.observedAt,
    unitPriceCents: unitPriceCents ?? this.unitPriceCents,
    normalizedPriceCents: normalizedPriceCents ?? this.normalizedPriceCents,
    quantityMilli: quantityMilli ?? this.quantityMilli,
    unit: unit ?? this.unit,
    purchaseItemId: purchaseItemId.present
        ? purchaseItemId.value
        : this.purchaseItemId,
    source: source ?? this.source,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  PricePoint copyWithCompanion(PricePointsCompanion data) {
    return PricePoint(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
      unitPriceCents: data.unitPriceCents.present
          ? data.unitPriceCents.value
          : this.unitPriceCents,
      normalizedPriceCents: data.normalizedPriceCents.present
          ? data.normalizedPriceCents.value
          : this.normalizedPriceCents,
      quantityMilli: data.quantityMilli.present
          ? data.quantityMilli.value
          : this.quantityMilli,
      unit: data.unit.present ? data.unit.value : this.unit,
      purchaseItemId: data.purchaseItemId.present
          ? data.purchaseItemId.value
          : this.purchaseItemId,
      source: data.source.present ? data.source.value : this.source,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PricePoint(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('observedAt: $observedAt, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('normalizedPriceCents: $normalizedPriceCents, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('purchaseItemId: $purchaseItemId, ')
          ..write('source: $source, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    storeId,
    observedAt,
    unitPriceCents,
    normalizedPriceCents,
    quantityMilli,
    unit,
    purchaseItemId,
    source,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PricePoint &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.storeId == this.storeId &&
          other.observedAt == this.observedAt &&
          other.unitPriceCents == this.unitPriceCents &&
          other.normalizedPriceCents == this.normalizedPriceCents &&
          other.quantityMilli == this.quantityMilli &&
          other.unit == this.unit &&
          other.purchaseItemId == this.purchaseItemId &&
          other.source == this.source &&
          other.deletedAt == this.deletedAt);
}

class PricePointsCompanion extends UpdateCompanion<PricePoint> {
  final Value<String> id;
  final Value<String?> productId;
  final Value<String?> storeId;
  final Value<String> observedAt;
  final Value<int> unitPriceCents;
  final Value<int> normalizedPriceCents;
  final Value<int> quantityMilli;
  final Value<String> unit;
  final Value<String?> purchaseItemId;
  final Value<String> source;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const PricePointsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.storeId = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.unitPriceCents = const Value.absent(),
    this.normalizedPriceCents = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    this.purchaseItemId = const Value.absent(),
    this.source = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PricePointsCompanion.insert({
    required String id,
    this.productId = const Value.absent(),
    this.storeId = const Value.absent(),
    required String observedAt,
    required int unitPriceCents,
    required int normalizedPriceCents,
    required int quantityMilli,
    required String unit,
    this.purchaseItemId = const Value.absent(),
    required String source,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       observedAt = Value(observedAt),
       unitPriceCents = Value(unitPriceCents),
       normalizedPriceCents = Value(normalizedPriceCents),
       quantityMilli = Value(quantityMilli),
       unit = Value(unit),
       source = Value(source);
  static Insertable<PricePoint> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? storeId,
    Expression<String>? observedAt,
    Expression<int>? unitPriceCents,
    Expression<int>? normalizedPriceCents,
    Expression<int>? quantityMilli,
    Expression<String>? unit,
    Expression<String>? purchaseItemId,
    Expression<String>? source,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (storeId != null) 'store_id': storeId,
      if (observedAt != null) 'observed_at': observedAt,
      if (unitPriceCents != null) 'unit_price_cents': unitPriceCents,
      if (normalizedPriceCents != null)
        'normalized_price_cents': normalizedPriceCents,
      if (quantityMilli != null) 'quantity_milli': quantityMilli,
      if (unit != null) 'unit': unit,
      if (purchaseItemId != null) 'purchase_item_id': purchaseItemId,
      if (source != null) 'source': source,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PricePointsCompanion copyWith({
    Value<String>? id,
    Value<String?>? productId,
    Value<String?>? storeId,
    Value<String>? observedAt,
    Value<int>? unitPriceCents,
    Value<int>? normalizedPriceCents,
    Value<int>? quantityMilli,
    Value<String>? unit,
    Value<String?>? purchaseItemId,
    Value<String>? source,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return PricePointsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      storeId: storeId ?? this.storeId,
      observedAt: observedAt ?? this.observedAt,
      unitPriceCents: unitPriceCents ?? this.unitPriceCents,
      normalizedPriceCents: normalizedPriceCents ?? this.normalizedPriceCents,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      unit: unit ?? this.unit,
      purchaseItemId: purchaseItemId ?? this.purchaseItemId,
      source: source ?? this.source,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<String>(observedAt.value);
    }
    if (unitPriceCents.present) {
      map['unit_price_cents'] = Variable<int>(unitPriceCents.value);
    }
    if (normalizedPriceCents.present) {
      map['normalized_price_cents'] = Variable<int>(normalizedPriceCents.value);
    }
    if (quantityMilli.present) {
      map['quantity_milli'] = Variable<int>(quantityMilli.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (purchaseItemId.present) {
      map['purchase_item_id'] = Variable<String>(purchaseItemId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PricePointsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('storeId: $storeId, ')
          ..write('observedAt: $observedAt, ')
          ..write('unitPriceCents: $unitPriceCents, ')
          ..write('normalizedPriceCents: $normalizedPriceCents, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('purchaseItemId: $purchaseItemId, ')
          ..write('source: $source, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _yearMonthMeta = const VerificationMeta(
    'yearMonth',
  );
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
    'year_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _limitCentsMeta = const VerificationMeta(
    'limitCents',
  );
  @override
  late final GeneratedColumn<int> limitCents = GeneratedColumn<int>(
    'limit_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseIncomeCentsMeta = const VerificationMeta(
    'baseIncomeCents',
  );
  @override
  late final GeneratedColumn<int> baseIncomeCents = GeneratedColumn<int>(
    'base_income_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _extraIncomeCentsMeta = const VerificationMeta(
    'extraIncomeCents',
  );
  @override
  late final GeneratedColumn<int> extraIncomeCents = GeneratedColumn<int>(
    'extra_income_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    yearMonth,
    categoryId,
    limitCents,
    baseIncomeCents,
    extraIncomeCents,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('year_month')) {
      context.handle(
        _yearMonthMeta,
        yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('limit_cents')) {
      context.handle(
        _limitCentsMeta,
        limitCents.isAcceptableOrUnknown(data['limit_cents']!, _limitCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_limitCentsMeta);
    }
    if (data.containsKey('base_income_cents')) {
      context.handle(
        _baseIncomeCentsMeta,
        baseIncomeCents.isAcceptableOrUnknown(
          data['base_income_cents']!,
          _baseIncomeCentsMeta,
        ),
      );
    }
    if (data.containsKey('extra_income_cents')) {
      context.handle(
        _extraIncomeCentsMeta,
        extraIncomeCents.isAcceptableOrUnknown(
          data['extra_income_cents']!,
          _extraIncomeCentsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {yearMonth, categoryId},
  ];
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      yearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_month'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      limitCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}limit_cents'],
      )!,
      baseIncomeCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_income_cents'],
      )!,
      extraIncomeCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}extra_income_cents'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;
  final String yearMonth;
  final String? categoryId;
  final int limitCents;
  final int baseIncomeCents;
  final int extraIncomeCents;
  const Budget({
    required this.id,
    required this.yearMonth,
    this.categoryId,
    required this.limitCents,
    required this.baseIncomeCents,
    required this.extraIncomeCents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['year_month'] = Variable<String>(yearMonth);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['limit_cents'] = Variable<int>(limitCents);
    map['base_income_cents'] = Variable<int>(baseIncomeCents);
    map['extra_income_cents'] = Variable<int>(extraIncomeCents);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      yearMonth: Value(yearMonth),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      limitCents: Value(limitCents),
      baseIncomeCents: Value(baseIncomeCents),
      extraIncomeCents: Value(extraIncomeCents),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      limitCents: serializer.fromJson<int>(json['limitCents']),
      baseIncomeCents: serializer.fromJson<int>(json['baseIncomeCents']),
      extraIncomeCents: serializer.fromJson<int>(json['extraIncomeCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'yearMonth': serializer.toJson<String>(yearMonth),
      'categoryId': serializer.toJson<String?>(categoryId),
      'limitCents': serializer.toJson<int>(limitCents),
      'baseIncomeCents': serializer.toJson<int>(baseIncomeCents),
      'extraIncomeCents': serializer.toJson<int>(extraIncomeCents),
    };
  }

  Budget copyWith({
    String? id,
    String? yearMonth,
    Value<String?> categoryId = const Value.absent(),
    int? limitCents,
    int? baseIncomeCents,
    int? extraIncomeCents,
  }) => Budget(
    id: id ?? this.id,
    yearMonth: yearMonth ?? this.yearMonth,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    limitCents: limitCents ?? this.limitCents,
    baseIncomeCents: baseIncomeCents ?? this.baseIncomeCents,
    extraIncomeCents: extraIncomeCents ?? this.extraIncomeCents,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      limitCents: data.limitCents.present
          ? data.limitCents.value
          : this.limitCents,
      baseIncomeCents: data.baseIncomeCents.present
          ? data.baseIncomeCents.value
          : this.baseIncomeCents,
      extraIncomeCents: data.extraIncomeCents.present
          ? data.extraIncomeCents.value
          : this.extraIncomeCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('categoryId: $categoryId, ')
          ..write('limitCents: $limitCents, ')
          ..write('baseIncomeCents: $baseIncomeCents, ')
          ..write('extraIncomeCents: $extraIncomeCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    yearMonth,
    categoryId,
    limitCents,
    baseIncomeCents,
    extraIncomeCents,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.yearMonth == this.yearMonth &&
          other.categoryId == this.categoryId &&
          other.limitCents == this.limitCents &&
          other.baseIncomeCents == this.baseIncomeCents &&
          other.extraIncomeCents == this.extraIncomeCents);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> yearMonth;
  final Value<String?> categoryId;
  final Value<int> limitCents;
  final Value<int> baseIncomeCents;
  final Value<int> extraIncomeCents;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.limitCents = const Value.absent(),
    this.baseIncomeCents = const Value.absent(),
    this.extraIncomeCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String yearMonth,
    this.categoryId = const Value.absent(),
    required int limitCents,
    this.baseIncomeCents = const Value.absent(),
    this.extraIncomeCents = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       yearMonth = Value(yearMonth),
       limitCents = Value(limitCents);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? yearMonth,
    Expression<String>? categoryId,
    Expression<int>? limitCents,
    Expression<int>? baseIncomeCents,
    Expression<int>? extraIncomeCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (yearMonth != null) 'year_month': yearMonth,
      if (categoryId != null) 'category_id': categoryId,
      if (limitCents != null) 'limit_cents': limitCents,
      if (baseIncomeCents != null) 'base_income_cents': baseIncomeCents,
      if (extraIncomeCents != null) 'extra_income_cents': extraIncomeCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? yearMonth,
    Value<String?>? categoryId,
    Value<int>? limitCents,
    Value<int>? baseIncomeCents,
    Value<int>? extraIncomeCents,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      yearMonth: yearMonth ?? this.yearMonth,
      categoryId: categoryId ?? this.categoryId,
      limitCents: limitCents ?? this.limitCents,
      baseIncomeCents: baseIncomeCents ?? this.baseIncomeCents,
      extraIncomeCents: extraIncomeCents ?? this.extraIncomeCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (limitCents.present) {
      map['limit_cents'] = Variable<int>(limitCents.value);
    }
    if (baseIncomeCents.present) {
      map['base_income_cents'] = Variable<int>(baseIncomeCents.value);
    }
    if (extraIncomeCents.present) {
      map['extra_income_cents'] = Variable<int>(extraIncomeCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('categoryId: $categoryId, ')
          ..write('limitCents: $limitCents, ')
          ..write('baseIncomeCents: $baseIncomeCents, ')
          ..write('extraIncomeCents: $extraIncomeCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BillPaymentsTable extends BillPayments
    with TableInfo<$BillPaymentsTable, BillPayment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BillPaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _billIdMeta = const VerificationMeta('billId');
  @override
  late final GeneratedColumn<String> billId = GeneratedColumn<String>(
    'bill_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bills (id)',
    ),
  );
  static const VerificationMeta _dueOnMeta = const VerificationMeta('dueOn');
  @override
  late final GeneratedColumn<String> dueOn = GeneratedColumn<String>(
    'due_on',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paidOnMeta = const VerificationMeta('paidOn');
  @override
  late final GeneratedColumn<String> paidOn = GeneratedColumn<String>(
    'paid_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
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
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    billId,
    dueOn,
    paidOn,
    amountCents,
    status,
    expenseId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bill_payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<BillPayment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('bill_id')) {
      context.handle(
        _billIdMeta,
        billId.isAcceptableOrUnknown(data['bill_id']!, _billIdMeta),
      );
    }
    if (data.containsKey('due_on')) {
      context.handle(
        _dueOnMeta,
        dueOn.isAcceptableOrUnknown(data['due_on']!, _dueOnMeta),
      );
    } else if (isInserting) {
      context.missing(_dueOnMeta);
    }
    if (data.containsKey('paid_on')) {
      context.handle(
        _paidOnMeta,
        paidOn.isAcceptableOrUnknown(data['paid_on']!, _paidOnMeta),
      );
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
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
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {billId, dueOn},
  ];
  @override
  BillPayment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BillPayment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      billId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bill_id'],
      ),
      dueOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_on'],
      )!,
      paidOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_on'],
      ),
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      ),
    );
  }

  @override
  $BillPaymentsTable createAlias(String alias) {
    return $BillPaymentsTable(attachedDatabase, alias);
  }
}

class BillPayment extends DataClass implements Insertable<BillPayment> {
  final String id;
  final String? billId;
  final String dueOn;
  final String? paidOn;
  final int? amountCents;
  final String status;
  final String? expenseId;
  const BillPayment({
    required this.id,
    this.billId,
    required this.dueOn,
    this.paidOn,
    this.amountCents,
    required this.status,
    this.expenseId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || billId != null) {
      map['bill_id'] = Variable<String>(billId);
    }
    map['due_on'] = Variable<String>(dueOn);
    if (!nullToAbsent || paidOn != null) {
      map['paid_on'] = Variable<String>(paidOn);
    }
    if (!nullToAbsent || amountCents != null) {
      map['amount_cents'] = Variable<int>(amountCents);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || expenseId != null) {
      map['expense_id'] = Variable<String>(expenseId);
    }
    return map;
  }

  BillPaymentsCompanion toCompanion(bool nullToAbsent) {
    return BillPaymentsCompanion(
      id: Value(id),
      billId: billId == null && nullToAbsent
          ? const Value.absent()
          : Value(billId),
      dueOn: Value(dueOn),
      paidOn: paidOn == null && nullToAbsent
          ? const Value.absent()
          : Value(paidOn),
      amountCents: amountCents == null && nullToAbsent
          ? const Value.absent()
          : Value(amountCents),
      status: Value(status),
      expenseId: expenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(expenseId),
    );
  }

  factory BillPayment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BillPayment(
      id: serializer.fromJson<String>(json['id']),
      billId: serializer.fromJson<String?>(json['billId']),
      dueOn: serializer.fromJson<String>(json['dueOn']),
      paidOn: serializer.fromJson<String?>(json['paidOn']),
      amountCents: serializer.fromJson<int?>(json['amountCents']),
      status: serializer.fromJson<String>(json['status']),
      expenseId: serializer.fromJson<String?>(json['expenseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'billId': serializer.toJson<String?>(billId),
      'dueOn': serializer.toJson<String>(dueOn),
      'paidOn': serializer.toJson<String?>(paidOn),
      'amountCents': serializer.toJson<int?>(amountCents),
      'status': serializer.toJson<String>(status),
      'expenseId': serializer.toJson<String?>(expenseId),
    };
  }

  BillPayment copyWith({
    String? id,
    Value<String?> billId = const Value.absent(),
    String? dueOn,
    Value<String?> paidOn = const Value.absent(),
    Value<int?> amountCents = const Value.absent(),
    String? status,
    Value<String?> expenseId = const Value.absent(),
  }) => BillPayment(
    id: id ?? this.id,
    billId: billId.present ? billId.value : this.billId,
    dueOn: dueOn ?? this.dueOn,
    paidOn: paidOn.present ? paidOn.value : this.paidOn,
    amountCents: amountCents.present ? amountCents.value : this.amountCents,
    status: status ?? this.status,
    expenseId: expenseId.present ? expenseId.value : this.expenseId,
  );
  BillPayment copyWithCompanion(BillPaymentsCompanion data) {
    return BillPayment(
      id: data.id.present ? data.id.value : this.id,
      billId: data.billId.present ? data.billId.value : this.billId,
      dueOn: data.dueOn.present ? data.dueOn.value : this.dueOn,
      paidOn: data.paidOn.present ? data.paidOn.value : this.paidOn,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      status: data.status.present ? data.status.value : this.status,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BillPayment(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('dueOn: $dueOn, ')
          ..write('paidOn: $paidOn, ')
          ..write('amountCents: $amountCents, ')
          ..write('status: $status, ')
          ..write('expenseId: $expenseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, billId, dueOn, paidOn, amountCents, status, expenseId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BillPayment &&
          other.id == this.id &&
          other.billId == this.billId &&
          other.dueOn == this.dueOn &&
          other.paidOn == this.paidOn &&
          other.amountCents == this.amountCents &&
          other.status == this.status &&
          other.expenseId == this.expenseId);
}

class BillPaymentsCompanion extends UpdateCompanion<BillPayment> {
  final Value<String> id;
  final Value<String?> billId;
  final Value<String> dueOn;
  final Value<String?> paidOn;
  final Value<int?> amountCents;
  final Value<String> status;
  final Value<String?> expenseId;
  final Value<int> rowid;
  const BillPaymentsCompanion({
    this.id = const Value.absent(),
    this.billId = const Value.absent(),
    this.dueOn = const Value.absent(),
    this.paidOn = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.status = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BillPaymentsCompanion.insert({
    required String id,
    this.billId = const Value.absent(),
    required String dueOn,
    this.paidOn = const Value.absent(),
    this.amountCents = const Value.absent(),
    required String status,
    this.expenseId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dueOn = Value(dueOn),
       status = Value(status);
  static Insertable<BillPayment> custom({
    Expression<String>? id,
    Expression<String>? billId,
    Expression<String>? dueOn,
    Expression<String>? paidOn,
    Expression<int>? amountCents,
    Expression<String>? status,
    Expression<String>? expenseId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (billId != null) 'bill_id': billId,
      if (dueOn != null) 'due_on': dueOn,
      if (paidOn != null) 'paid_on': paidOn,
      if (amountCents != null) 'amount_cents': amountCents,
      if (status != null) 'status': status,
      if (expenseId != null) 'expense_id': expenseId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BillPaymentsCompanion copyWith({
    Value<String>? id,
    Value<String?>? billId,
    Value<String>? dueOn,
    Value<String?>? paidOn,
    Value<int?>? amountCents,
    Value<String>? status,
    Value<String?>? expenseId,
    Value<int>? rowid,
  }) {
    return BillPaymentsCompanion(
      id: id ?? this.id,
      billId: billId ?? this.billId,
      dueOn: dueOn ?? this.dueOn,
      paidOn: paidOn ?? this.paidOn,
      amountCents: amountCents ?? this.amountCents,
      status: status ?? this.status,
      expenseId: expenseId ?? this.expenseId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (billId.present) {
      map['bill_id'] = Variable<String>(billId.value);
    }
    if (dueOn.present) {
      map['due_on'] = Variable<String>(dueOn.value);
    }
    if (paidOn.present) {
      map['paid_on'] = Variable<String>(paidOn.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BillPaymentsCompanion(')
          ..write('id: $id, ')
          ..write('billId: $billId, ')
          ..write('dueOn: $dueOn, ')
          ..write('paidOn: $paidOn, ')
          ..write('amountCents: $amountCents, ')
          ..write('status: $status, ')
          ..write('expenseId: $expenseId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingListsTable extends ShoppingLists
    with TableInfo<$ShoppingListsTable, ShoppingList> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingListsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  @override
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stores (id)',
    ),
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    storeId,
    isArchived,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_lists';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingList> instance, {
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
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
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
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingList map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingList(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ShoppingListsTable createAlias(String alias) {
    return $ShoppingListsTable(attachedDatabase, alias);
  }
}

class ShoppingList extends DataClass implements Insertable<ShoppingList> {
  final String id;
  final String name;
  final String? storeId;
  final bool isArchived;
  final String? createdAt;
  final String? updatedAt;
  const ShoppingList({
    required this.id,
    required this.name,
    this.storeId,
    required this.isArchived,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  ShoppingListsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingListsCompanion(
      id: Value(id),
      name: Value(name),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      isArchived: Value(isArchived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ShoppingList.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingList(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      storeId: serializer.fromJson<String?>(json['storeId']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'storeId': serializer.toJson<String?>(storeId),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  ShoppingList copyWith({
    String? id,
    String? name,
    Value<String?> storeId = const Value.absent(),
    bool? isArchived,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => ShoppingList(
    id: id ?? this.id,
    name: name ?? this.name,
    storeId: storeId.present ? storeId.value : this.storeId,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ShoppingList copyWithCompanion(ShoppingListsCompanion data) {
    return ShoppingList(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingList(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('storeId: $storeId, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, storeId, isArchived, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingList &&
          other.id == this.id &&
          other.name == this.name &&
          other.storeId == this.storeId &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ShoppingListsCompanion extends UpdateCompanion<ShoppingList> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> storeId;
  final Value<bool> isArchived;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const ShoppingListsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.storeId = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingListsCompanion.insert({
    required String id,
    required String name,
    this.storeId = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<ShoppingList> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? storeId,
    Expression<bool>? isArchived,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (storeId != null) 'store_id': storeId,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingListsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? storeId,
    Value<bool>? isArchived,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ShoppingListsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
      isArchived: isArchived ?? this.isArchived,
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
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingListsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('storeId: $storeId, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ShoppingItemsTable extends ShoppingItems
    with TableInfo<$ShoppingItemsTable, ShoppingItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ShoppingItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _listIdMeta = const VerificationMeta('listId');
  @override
  late final GeneratedColumn<String> listId = GeneratedColumn<String>(
    'list_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES shopping_lists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
  );
  static const VerificationMeta _freeTextMeta = const VerificationMeta(
    'freeText',
  );
  @override
  late final GeneratedColumn<String> freeText = GeneratedColumn<String>(
    'free_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMilliMeta = const VerificationMeta(
    'quantityMilli',
  );
  @override
  late final GeneratedColumn<int> quantityMilli = GeneratedColumn<int>(
    'quantity_milli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedPriceCentsMeta =
      const VerificationMeta('estimatedPriceCents');
  @override
  late final GeneratedColumn<int> estimatedPriceCents = GeneratedColumn<int>(
    'estimated_price_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCheckedMeta = const VerificationMeta(
    'isChecked',
  );
  @override
  late final GeneratedColumn<bool> isChecked = GeneratedColumn<bool>(
    'is_checked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_checked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  @override
  late final GeneratedColumn<String> checkedAt = GeneratedColumn<String>(
    'checked_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    listId,
    productId,
    freeText,
    quantityMilli,
    unit,
    estimatedPriceCents,
    isChecked,
    checkedAt,
    source,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shopping_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShoppingItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('list_id')) {
      context.handle(
        _listIdMeta,
        listId.isAcceptableOrUnknown(data['list_id']!, _listIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('free_text')) {
      context.handle(
        _freeTextMeta,
        freeText.isAcceptableOrUnknown(data['free_text']!, _freeTextMeta),
      );
    }
    if (data.containsKey('quantity_milli')) {
      context.handle(
        _quantityMilliMeta,
        quantityMilli.isAcceptableOrUnknown(
          data['quantity_milli']!,
          _quantityMilliMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('estimated_price_cents')) {
      context.handle(
        _estimatedPriceCentsMeta,
        estimatedPriceCents.isAcceptableOrUnknown(
          data['estimated_price_cents']!,
          _estimatedPriceCentsMeta,
        ),
      );
    }
    if (data.containsKey('is_checked')) {
      context.handle(
        _isCheckedMeta,
        isChecked.isAcceptableOrUnknown(data['is_checked']!, _isCheckedMeta),
      );
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ShoppingItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShoppingItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      listId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}list_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      freeText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}free_text'],
      ),
      quantityMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_milli'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      estimatedPriceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimated_price_cents'],
      ),
      isChecked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_checked'],
      )!,
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checked_at'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $ShoppingItemsTable createAlias(String alias) {
    return $ShoppingItemsTable(attachedDatabase, alias);
  }
}

class ShoppingItem extends DataClass implements Insertable<ShoppingItem> {
  final String id;
  final String? listId;
  final String? productId;
  final String? freeText;
  final int? quantityMilli;
  final String? unit;
  final int? estimatedPriceCents;
  final bool isChecked;
  final String? checkedAt;
  final String source;
  final int position;
  const ShoppingItem({
    required this.id,
    this.listId,
    this.productId,
    this.freeText,
    this.quantityMilli,
    this.unit,
    this.estimatedPriceCents,
    required this.isChecked,
    this.checkedAt,
    required this.source,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || listId != null) {
      map['list_id'] = Variable<String>(listId);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    if (!nullToAbsent || freeText != null) {
      map['free_text'] = Variable<String>(freeText);
    }
    if (!nullToAbsent || quantityMilli != null) {
      map['quantity_milli'] = Variable<int>(quantityMilli);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || estimatedPriceCents != null) {
      map['estimated_price_cents'] = Variable<int>(estimatedPriceCents);
    }
    map['is_checked'] = Variable<bool>(isChecked);
    if (!nullToAbsent || checkedAt != null) {
      map['checked_at'] = Variable<String>(checkedAt);
    }
    map['source'] = Variable<String>(source);
    map['position'] = Variable<int>(position);
    return map;
  }

  ShoppingItemsCompanion toCompanion(bool nullToAbsent) {
    return ShoppingItemsCompanion(
      id: Value(id),
      listId: listId == null && nullToAbsent
          ? const Value.absent()
          : Value(listId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      freeText: freeText == null && nullToAbsent
          ? const Value.absent()
          : Value(freeText),
      quantityMilli: quantityMilli == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityMilli),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      estimatedPriceCents: estimatedPriceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedPriceCents),
      isChecked: Value(isChecked),
      checkedAt: checkedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedAt),
      source: Value(source),
      position: Value(position),
    );
  }

  factory ShoppingItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShoppingItem(
      id: serializer.fromJson<String>(json['id']),
      listId: serializer.fromJson<String?>(json['listId']),
      productId: serializer.fromJson<String?>(json['productId']),
      freeText: serializer.fromJson<String?>(json['freeText']),
      quantityMilli: serializer.fromJson<int?>(json['quantityMilli']),
      unit: serializer.fromJson<String?>(json['unit']),
      estimatedPriceCents: serializer.fromJson<int?>(
        json['estimatedPriceCents'],
      ),
      isChecked: serializer.fromJson<bool>(json['isChecked']),
      checkedAt: serializer.fromJson<String?>(json['checkedAt']),
      source: serializer.fromJson<String>(json['source']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'listId': serializer.toJson<String?>(listId),
      'productId': serializer.toJson<String?>(productId),
      'freeText': serializer.toJson<String?>(freeText),
      'quantityMilli': serializer.toJson<int?>(quantityMilli),
      'unit': serializer.toJson<String?>(unit),
      'estimatedPriceCents': serializer.toJson<int?>(estimatedPriceCents),
      'isChecked': serializer.toJson<bool>(isChecked),
      'checkedAt': serializer.toJson<String?>(checkedAt),
      'source': serializer.toJson<String>(source),
      'position': serializer.toJson<int>(position),
    };
  }

  ShoppingItem copyWith({
    String? id,
    Value<String?> listId = const Value.absent(),
    Value<String?> productId = const Value.absent(),
    Value<String?> freeText = const Value.absent(),
    Value<int?> quantityMilli = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<int?> estimatedPriceCents = const Value.absent(),
    bool? isChecked,
    Value<String?> checkedAt = const Value.absent(),
    String? source,
    int? position,
  }) => ShoppingItem(
    id: id ?? this.id,
    listId: listId.present ? listId.value : this.listId,
    productId: productId.present ? productId.value : this.productId,
    freeText: freeText.present ? freeText.value : this.freeText,
    quantityMilli: quantityMilli.present
        ? quantityMilli.value
        : this.quantityMilli,
    unit: unit.present ? unit.value : this.unit,
    estimatedPriceCents: estimatedPriceCents.present
        ? estimatedPriceCents.value
        : this.estimatedPriceCents,
    isChecked: isChecked ?? this.isChecked,
    checkedAt: checkedAt.present ? checkedAt.value : this.checkedAt,
    source: source ?? this.source,
    position: position ?? this.position,
  );
  ShoppingItem copyWithCompanion(ShoppingItemsCompanion data) {
    return ShoppingItem(
      id: data.id.present ? data.id.value : this.id,
      listId: data.listId.present ? data.listId.value : this.listId,
      productId: data.productId.present ? data.productId.value : this.productId,
      freeText: data.freeText.present ? data.freeText.value : this.freeText,
      quantityMilli: data.quantityMilli.present
          ? data.quantityMilli.value
          : this.quantityMilli,
      unit: data.unit.present ? data.unit.value : this.unit,
      estimatedPriceCents: data.estimatedPriceCents.present
          ? data.estimatedPriceCents.value
          : this.estimatedPriceCents,
      isChecked: data.isChecked.present ? data.isChecked.value : this.isChecked,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
      source: data.source.present ? data.source.value : this.source,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItem(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('productId: $productId, ')
          ..write('freeText: $freeText, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('estimatedPriceCents: $estimatedPriceCents, ')
          ..write('isChecked: $isChecked, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('source: $source, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    listId,
    productId,
    freeText,
    quantityMilli,
    unit,
    estimatedPriceCents,
    isChecked,
    checkedAt,
    source,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShoppingItem &&
          other.id == this.id &&
          other.listId == this.listId &&
          other.productId == this.productId &&
          other.freeText == this.freeText &&
          other.quantityMilli == this.quantityMilli &&
          other.unit == this.unit &&
          other.estimatedPriceCents == this.estimatedPriceCents &&
          other.isChecked == this.isChecked &&
          other.checkedAt == this.checkedAt &&
          other.source == this.source &&
          other.position == this.position);
}

class ShoppingItemsCompanion extends UpdateCompanion<ShoppingItem> {
  final Value<String> id;
  final Value<String?> listId;
  final Value<String?> productId;
  final Value<String?> freeText;
  final Value<int?> quantityMilli;
  final Value<String?> unit;
  final Value<int?> estimatedPriceCents;
  final Value<bool> isChecked;
  final Value<String?> checkedAt;
  final Value<String> source;
  final Value<int> position;
  final Value<int> rowid;
  const ShoppingItemsCompanion({
    this.id = const Value.absent(),
    this.listId = const Value.absent(),
    this.productId = const Value.absent(),
    this.freeText = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    this.estimatedPriceCents = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.source = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShoppingItemsCompanion.insert({
    required String id,
    this.listId = const Value.absent(),
    this.productId = const Value.absent(),
    this.freeText = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    this.estimatedPriceCents = const Value.absent(),
    this.isChecked = const Value.absent(),
    this.checkedAt = const Value.absent(),
    required String source,
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       source = Value(source),
       position = Value(position);
  static Insertable<ShoppingItem> custom({
    Expression<String>? id,
    Expression<String>? listId,
    Expression<String>? productId,
    Expression<String>? freeText,
    Expression<int>? quantityMilli,
    Expression<String>? unit,
    Expression<int>? estimatedPriceCents,
    Expression<bool>? isChecked,
    Expression<String>? checkedAt,
    Expression<String>? source,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (listId != null) 'list_id': listId,
      if (productId != null) 'product_id': productId,
      if (freeText != null) 'free_text': freeText,
      if (quantityMilli != null) 'quantity_milli': quantityMilli,
      if (unit != null) 'unit': unit,
      if (estimatedPriceCents != null)
        'estimated_price_cents': estimatedPriceCents,
      if (isChecked != null) 'is_checked': isChecked,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (source != null) 'source': source,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShoppingItemsCompanion copyWith({
    Value<String>? id,
    Value<String?>? listId,
    Value<String?>? productId,
    Value<String?>? freeText,
    Value<int?>? quantityMilli,
    Value<String?>? unit,
    Value<int?>? estimatedPriceCents,
    Value<bool>? isChecked,
    Value<String?>? checkedAt,
    Value<String>? source,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return ShoppingItemsCompanion(
      id: id ?? this.id,
      listId: listId ?? this.listId,
      productId: productId ?? this.productId,
      freeText: freeText ?? this.freeText,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      unit: unit ?? this.unit,
      estimatedPriceCents: estimatedPriceCents ?? this.estimatedPriceCents,
      isChecked: isChecked ?? this.isChecked,
      checkedAt: checkedAt ?? this.checkedAt,
      source: source ?? this.source,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (listId.present) {
      map['list_id'] = Variable<String>(listId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (freeText.present) {
      map['free_text'] = Variable<String>(freeText.value);
    }
    if (quantityMilli.present) {
      map['quantity_milli'] = Variable<int>(quantityMilli.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (estimatedPriceCents.present) {
      map['estimated_price_cents'] = Variable<int>(estimatedPriceCents.value);
    }
    if (isChecked.present) {
      map['is_checked'] = Variable<bool>(isChecked.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<String>(checkedAt.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShoppingItemsCompanion(')
          ..write('id: $id, ')
          ..write('listId: $listId, ')
          ..write('productId: $productId, ')
          ..write('freeText: $freeText, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('estimatedPriceCents: $estimatedPriceCents, ')
          ..write('isChecked: $isChecked, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('source: $source, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _dueAtMeta = const VerificationMeta('dueAt');
  @override
  late final GeneratedColumn<String> dueAt = GeneratedColumn<String>(
    'due_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allDayMeta = const VerificationMeta('allDay');
  @override
  late final GeneratedColumn<bool> allDay = GeneratedColumn<bool>(
    'all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<String> completedAt = GeneratedColumn<String>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurringRuleIdMeta = const VerificationMeta(
    'recurringRuleId',
  );
  @override
  late final GeneratedColumn<String> recurringRuleId = GeneratedColumn<String>(
    'recurring_rule_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recurring_rules (id)',
    ),
  );
  static const VerificationMeta _remoteEventIdMeta = const VerificationMeta(
    'remoteEventId',
  );
  @override
  late final GeneratedColumn<String> remoteEventId = GeneratedColumn<String>(
    'remote_event_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteEtagMeta = const VerificationMeta(
    'remoteEtag',
  );
  @override
  late final GeneratedColumn<String> remoteEtag = GeneratedColumn<String>(
    'remote_etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourcePresetIdMeta = const VerificationMeta(
    'sourcePresetId',
  );
  @override
  late final GeneratedColumn<String> sourcePresetId = GeneratedColumn<String>(
    'source_preset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    notes,
    categoryId,
    dueAt,
    allDay,
    isCompleted,
    completedAt,
    recurringRuleId,
    remoteEventId,
    remoteEtag,
    syncState,
    sourcePresetId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
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
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('due_at')) {
      context.handle(
        _dueAtMeta,
        dueAt.isAcceptableOrUnknown(data['due_at']!, _dueAtMeta),
      );
    }
    if (data.containsKey('all_day')) {
      context.handle(
        _allDayMeta,
        allDay.isAcceptableOrUnknown(data['all_day']!, _allDayMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('recurring_rule_id')) {
      context.handle(
        _recurringRuleIdMeta,
        recurringRuleId.isAcceptableOrUnknown(
          data['recurring_rule_id']!,
          _recurringRuleIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_event_id')) {
      context.handle(
        _remoteEventIdMeta,
        remoteEventId.isAcceptableOrUnknown(
          data['remote_event_id']!,
          _remoteEventIdMeta,
        ),
      );
    }
    if (data.containsKey('remote_etag')) {
      context.handle(
        _remoteEtagMeta,
        remoteEtag.isAcceptableOrUnknown(data['remote_etag']!, _remoteEtagMeta),
      );
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('source_preset_id')) {
      context.handle(
        _sourcePresetIdMeta,
        sourcePresetId.isAcceptableOrUnknown(
          data['source_preset_id']!,
          _sourcePresetIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
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
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      dueAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_at'],
      ),
      allDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}all_day'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}completed_at'],
      ),
      recurringRuleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurring_rule_id'],
      ),
      remoteEventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_event_id'],
      ),
      remoteEtag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_etag'],
      ),
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      ),
      sourcePresetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_preset_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String title;
  final String? notes;
  final String? categoryId;
  final String? dueAt;
  final bool allDay;
  final bool isCompleted;
  final String? completedAt;
  final String? recurringRuleId;
  final String? remoteEventId;
  final String? remoteEtag;
  final String? syncState;
  final String? sourcePresetId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  const Task({
    required this.id,
    required this.title,
    this.notes,
    this.categoryId,
    this.dueAt,
    required this.allDay,
    required this.isCompleted,
    this.completedAt,
    this.recurringRuleId,
    this.remoteEventId,
    this.remoteEtag,
    this.syncState,
    this.sourcePresetId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || dueAt != null) {
      map['due_at'] = Variable<String>(dueAt);
    }
    map['all_day'] = Variable<bool>(allDay);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<String>(completedAt);
    }
    if (!nullToAbsent || recurringRuleId != null) {
      map['recurring_rule_id'] = Variable<String>(recurringRuleId);
    }
    if (!nullToAbsent || remoteEventId != null) {
      map['remote_event_id'] = Variable<String>(remoteEventId);
    }
    if (!nullToAbsent || remoteEtag != null) {
      map['remote_etag'] = Variable<String>(remoteEtag);
    }
    if (!nullToAbsent || syncState != null) {
      map['sync_state'] = Variable<String>(syncState);
    }
    if (!nullToAbsent || sourcePresetId != null) {
      map['source_preset_id'] = Variable<String>(sourcePresetId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      dueAt: dueAt == null && nullToAbsent
          ? const Value.absent()
          : Value(dueAt),
      allDay: Value(allDay),
      isCompleted: Value(isCompleted),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      recurringRuleId: recurringRuleId == null && nullToAbsent
          ? const Value.absent()
          : Value(recurringRuleId),
      remoteEventId: remoteEventId == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteEventId),
      remoteEtag: remoteEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteEtag),
      syncState: syncState == null && nullToAbsent
          ? const Value.absent()
          : Value(syncState),
      sourcePresetId: sourcePresetId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePresetId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      dueAt: serializer.fromJson<String?>(json['dueAt']),
      allDay: serializer.fromJson<bool>(json['allDay']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAt: serializer.fromJson<String?>(json['completedAt']),
      recurringRuleId: serializer.fromJson<String?>(json['recurringRuleId']),
      remoteEventId: serializer.fromJson<String?>(json['remoteEventId']),
      remoteEtag: serializer.fromJson<String?>(json['remoteEtag']),
      syncState: serializer.fromJson<String?>(json['syncState']),
      sourcePresetId: serializer.fromJson<String?>(json['sourcePresetId']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      deletedAt: serializer.fromJson<String?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'categoryId': serializer.toJson<String?>(categoryId),
      'dueAt': serializer.toJson<String?>(dueAt),
      'allDay': serializer.toJson<bool>(allDay),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAt': serializer.toJson<String?>(completedAt),
      'recurringRuleId': serializer.toJson<String?>(recurringRuleId),
      'remoteEventId': serializer.toJson<String?>(remoteEventId),
      'remoteEtag': serializer.toJson<String?>(remoteEtag),
      'syncState': serializer.toJson<String?>(syncState),
      'sourcePresetId': serializer.toJson<String?>(sourcePresetId),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'deletedAt': serializer.toJson<String?>(deletedAt),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    Value<String?> notes = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<String?> dueAt = const Value.absent(),
    bool? allDay,
    bool? isCompleted,
    Value<String?> completedAt = const Value.absent(),
    Value<String?> recurringRuleId = const Value.absent(),
    Value<String?> remoteEventId = const Value.absent(),
    Value<String?> remoteEtag = const Value.absent(),
    Value<String?> syncState = const Value.absent(),
    Value<String?> sourcePresetId = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
    Value<String?> deletedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    dueAt: dueAt.present ? dueAt.value : this.dueAt,
    allDay: allDay ?? this.allDay,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    recurringRuleId: recurringRuleId.present
        ? recurringRuleId.value
        : this.recurringRuleId,
    remoteEventId: remoteEventId.present
        ? remoteEventId.value
        : this.remoteEventId,
    remoteEtag: remoteEtag.present ? remoteEtag.value : this.remoteEtag,
    syncState: syncState.present ? syncState.value : this.syncState,
    sourcePresetId: sourcePresetId.present
        ? sourcePresetId.value
        : this.sourcePresetId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      dueAt: data.dueAt.present ? data.dueAt.value : this.dueAt,
      allDay: data.allDay.present ? data.allDay.value : this.allDay,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      recurringRuleId: data.recurringRuleId.present
          ? data.recurringRuleId.value
          : this.recurringRuleId,
      remoteEventId: data.remoteEventId.present
          ? data.remoteEventId.value
          : this.remoteEventId,
      remoteEtag: data.remoteEtag.present
          ? data.remoteEtag.value
          : this.remoteEtag,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      sourcePresetId: data.sourcePresetId.present
          ? data.sourcePresetId.value
          : this.sourcePresetId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('categoryId: $categoryId, ')
          ..write('dueAt: $dueAt, ')
          ..write('allDay: $allDay, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('recurringRuleId: $recurringRuleId, ')
          ..write('remoteEventId: $remoteEventId, ')
          ..write('remoteEtag: $remoteEtag, ')
          ..write('syncState: $syncState, ')
          ..write('sourcePresetId: $sourcePresetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    notes,
    categoryId,
    dueAt,
    allDay,
    isCompleted,
    completedAt,
    recurringRuleId,
    remoteEventId,
    remoteEtag,
    syncState,
    sourcePresetId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.categoryId == this.categoryId &&
          other.dueAt == this.dueAt &&
          other.allDay == this.allDay &&
          other.isCompleted == this.isCompleted &&
          other.completedAt == this.completedAt &&
          other.recurringRuleId == this.recurringRuleId &&
          other.remoteEventId == this.remoteEventId &&
          other.remoteEtag == this.remoteEtag &&
          other.syncState == this.syncState &&
          other.sourcePresetId == this.sourcePresetId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> notes;
  final Value<String?> categoryId;
  final Value<String?> dueAt;
  final Value<bool> allDay;
  final Value<bool> isCompleted;
  final Value<String?> completedAt;
  final Value<String?> recurringRuleId;
  final Value<String?> remoteEventId;
  final Value<String?> remoteEtag;
  final Value<String?> syncState;
  final Value<String?> sourcePresetId;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<String?> deletedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.allDay = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.recurringRuleId = const Value.absent(),
    this.remoteEventId = const Value.absent(),
    this.remoteEtag = const Value.absent(),
    this.syncState = const Value.absent(),
    this.sourcePresetId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.notes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.dueAt = const Value.absent(),
    this.allDay = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.recurringRuleId = const Value.absent(),
    this.remoteEventId = const Value.absent(),
    this.remoteEtag = const Value.absent(),
    this.syncState = const Value.absent(),
    this.sourcePresetId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? categoryId,
    Expression<String>? dueAt,
    Expression<bool>? allDay,
    Expression<bool>? isCompleted,
    Expression<String>? completedAt,
    Expression<String>? recurringRuleId,
    Expression<String>? remoteEventId,
    Expression<String>? remoteEtag,
    Expression<String>? syncState,
    Expression<String>? sourcePresetId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (categoryId != null) 'category_id': categoryId,
      if (dueAt != null) 'due_at': dueAt,
      if (allDay != null) 'all_day': allDay,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt,
      if (recurringRuleId != null) 'recurring_rule_id': recurringRuleId,
      if (remoteEventId != null) 'remote_event_id': remoteEventId,
      if (remoteEtag != null) 'remote_etag': remoteEtag,
      if (syncState != null) 'sync_state': syncState,
      if (sourcePresetId != null) 'source_preset_id': sourcePresetId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? notes,
    Value<String?>? categoryId,
    Value<String?>? dueAt,
    Value<bool>? allDay,
    Value<bool>? isCompleted,
    Value<String?>? completedAt,
    Value<String?>? recurringRuleId,
    Value<String?>? remoteEventId,
    Value<String?>? remoteEtag,
    Value<String?>? syncState,
    Value<String?>? sourcePresetId,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<String?>? deletedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      categoryId: categoryId ?? this.categoryId,
      dueAt: dueAt ?? this.dueAt,
      allDay: allDay ?? this.allDay,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      recurringRuleId: recurringRuleId ?? this.recurringRuleId,
      remoteEventId: remoteEventId ?? this.remoteEventId,
      remoteEtag: remoteEtag ?? this.remoteEtag,
      syncState: syncState ?? this.syncState,
      sourcePresetId: sourcePresetId ?? this.sourcePresetId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (dueAt.present) {
      map['due_at'] = Variable<String>(dueAt.value);
    }
    if (allDay.present) {
      map['all_day'] = Variable<bool>(allDay.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<String>(completedAt.value);
    }
    if (recurringRuleId.present) {
      map['recurring_rule_id'] = Variable<String>(recurringRuleId.value);
    }
    if (remoteEventId.present) {
      map['remote_event_id'] = Variable<String>(remoteEventId.value);
    }
    if (remoteEtag.present) {
      map['remote_etag'] = Variable<String>(remoteEtag.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (sourcePresetId.present) {
      map['source_preset_id'] = Variable<String>(sourcePresetId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('categoryId: $categoryId, ')
          ..write('dueAt: $dueAt, ')
          ..write('allDay: $allDay, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAt: $completedAt, ')
          ..write('recurringRuleId: $recurringRuleId, ')
          ..write('remoteEventId: $remoteEventId, ')
          ..write('remoteEtag: $remoteEtag, ')
          ..write('syncState: $syncState, ')
          ..write('sourcePresetId: $sourcePresetId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipesTable extends Recipes with TableInfo<$RecipesTable, Recipe> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipesTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _instructionsMeta = const VerificationMeta(
    'instructions',
  );
  @override
  late final GeneratedColumn<String> instructions = GeneratedColumn<String>(
    'instructions',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prepMinutesMeta = const VerificationMeta(
    'prepMinutes',
  );
  @override
  late final GeneratedColumn<int> prepMinutes = GeneratedColumn<int>(
    'prep_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingsMeta = const VerificationMeta(
    'servings',
  );
  @override
  late final GeneratedColumn<int> servings = GeneratedColumn<int>(
    'servings',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(2),
  );
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  @override
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    instructions,
    prepMinutes,
    servings,
    photoPath,
    isFavorite,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Recipe> instance, {
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
    if (data.containsKey('instructions')) {
      context.handle(
        _instructionsMeta,
        instructions.isAcceptableOrUnknown(
          data['instructions']!,
          _instructionsMeta,
        ),
      );
    }
    if (data.containsKey('prep_minutes')) {
      context.handle(
        _prepMinutesMeta,
        prepMinutes.isAcceptableOrUnknown(
          data['prep_minutes']!,
          _prepMinutesMeta,
        ),
      );
    }
    if (data.containsKey('servings')) {
      context.handle(
        _servingsMeta,
        servings.isAcceptableOrUnknown(data['servings']!, _servingsMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Recipe map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Recipe(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      instructions: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instructions'],
      ),
      prepMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prep_minutes'],
      ),
      servings: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}servings'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $RecipesTable createAlias(String alias) {
    return $RecipesTable(attachedDatabase, alias);
  }
}

class Recipe extends DataClass implements Insertable<Recipe> {
  final String id;
  final String title;
  final String? instructions;
  final int? prepMinutes;
  final int servings;
  final String? photoPath;
  final bool isFavorite;
  final String? createdAt;
  final String? updatedAt;
  const Recipe({
    required this.id,
    required this.title,
    this.instructions,
    this.prepMinutes,
    required this.servings,
    this.photoPath,
    required this.isFavorite,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || instructions != null) {
      map['instructions'] = Variable<String>(instructions);
    }
    if (!nullToAbsent || prepMinutes != null) {
      map['prep_minutes'] = Variable<int>(prepMinutes);
    }
    map['servings'] = Variable<int>(servings);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  RecipesCompanion toCompanion(bool nullToAbsent) {
    return RecipesCompanion(
      id: Value(id),
      title: Value(title),
      instructions: instructions == null && nullToAbsent
          ? const Value.absent()
          : Value(instructions),
      prepMinutes: prepMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(prepMinutes),
      servings: Value(servings),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      isFavorite: Value(isFavorite),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Recipe.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Recipe(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      instructions: serializer.fromJson<String?>(json['instructions']),
      prepMinutes: serializer.fromJson<int?>(json['prepMinutes']),
      servings: serializer.fromJson<int>(json['servings']),
      photoPath: serializer.fromJson<String?>(json['photoPath']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'instructions': serializer.toJson<String?>(instructions),
      'prepMinutes': serializer.toJson<int?>(prepMinutes),
      'servings': serializer.toJson<int>(servings),
      'photoPath': serializer.toJson<String?>(photoPath),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  Recipe copyWith({
    String? id,
    String? title,
    Value<String?> instructions = const Value.absent(),
    Value<int?> prepMinutes = const Value.absent(),
    int? servings,
    Value<String?> photoPath = const Value.absent(),
    bool? isFavorite,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => Recipe(
    id: id ?? this.id,
    title: title ?? this.title,
    instructions: instructions.present ? instructions.value : this.instructions,
    prepMinutes: prepMinutes.present ? prepMinutes.value : this.prepMinutes,
    servings: servings ?? this.servings,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Recipe copyWithCompanion(RecipesCompanion data) {
    return Recipe(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      instructions: data.instructions.present
          ? data.instructions.value
          : this.instructions,
      prepMinutes: data.prepMinutes.present
          ? data.prepMinutes.value
          : this.prepMinutes,
      servings: data.servings.present ? data.servings.value : this.servings,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Recipe(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('instructions: $instructions, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('servings: $servings, ')
          ..write('photoPath: $photoPath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    instructions,
    prepMinutes,
    servings,
    photoPath,
    isFavorite,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Recipe &&
          other.id == this.id &&
          other.title == this.title &&
          other.instructions == this.instructions &&
          other.prepMinutes == this.prepMinutes &&
          other.servings == this.servings &&
          other.photoPath == this.photoPath &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class RecipesCompanion extends UpdateCompanion<Recipe> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> instructions;
  final Value<int?> prepMinutes;
  final Value<int> servings;
  final Value<String?> photoPath;
  final Value<bool> isFavorite;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const RecipesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.instructions = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.servings = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipesCompanion.insert({
    required String id,
    required String title,
    this.instructions = const Value.absent(),
    this.prepMinutes = const Value.absent(),
    this.servings = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title);
  static Insertable<Recipe> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? instructions,
    Expression<int>? prepMinutes,
    Expression<int>? servings,
    Expression<String>? photoPath,
    Expression<bool>? isFavorite,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (instructions != null) 'instructions': instructions,
      if (prepMinutes != null) 'prep_minutes': prepMinutes,
      if (servings != null) 'servings': servings,
      if (photoPath != null) 'photo_path': photoPath,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? instructions,
    Value<int?>? prepMinutes,
    Value<int>? servings,
    Value<String?>? photoPath,
    Value<bool>? isFavorite,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return RecipesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      instructions: instructions ?? this.instructions,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      servings: servings ?? this.servings,
      photoPath: photoPath ?? this.photoPath,
      isFavorite: isFavorite ?? this.isFavorite,
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
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (instructions.present) {
      map['instructions'] = Variable<String>(instructions.value);
    }
    if (prepMinutes.present) {
      map['prep_minutes'] = Variable<int>(prepMinutes.value);
    }
    if (servings.present) {
      map['servings'] = Variable<int>(servings.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('instructions: $instructions, ')
          ..write('prepMinutes: $prepMinutes, ')
          ..write('servings: $servings, ')
          ..write('photoPath: $photoPath, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeIngredientsTable extends RecipeIngredients
    with TableInfo<$RecipeIngredientsTable, RecipeIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeIngredientsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES recipes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id)',
    ),
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
  static const VerificationMeta _quantityMilliMeta = const VerificationMeta(
    'quantityMilli',
  );
  @override
  late final GeneratedColumn<int> quantityMilli = GeneratedColumn<int>(
    'quantity_milli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    recipeId,
    productId,
    rawText,
    quantityMilli,
    unit,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    }
    if (data.containsKey('raw_text')) {
      context.handle(
        _rawTextMeta,
        rawText.isAcceptableOrUnknown(data['raw_text']!, _rawTextMeta),
      );
    } else if (isInserting) {
      context.missing(_rawTextMeta);
    }
    if (data.containsKey('quantity_milli')) {
      context.handle(
        _quantityMilliMeta,
        quantityMilli.isAcceptableOrUnknown(
          data['quantity_milli']!,
          _quantityMilliMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecipeIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeIngredient(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      ),
      rawText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_text'],
      )!,
      quantityMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_milli'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $RecipeIngredientsTable createAlias(String alias) {
    return $RecipeIngredientsTable(attachedDatabase, alias);
  }
}

class RecipeIngredient extends DataClass
    implements Insertable<RecipeIngredient> {
  final String id;
  final String? recipeId;
  final String? productId;
  final String rawText;
  final int? quantityMilli;
  final String? unit;
  final int position;
  const RecipeIngredient({
    required this.id,
    this.recipeId,
    this.productId,
    required this.rawText,
    this.quantityMilli,
    this.unit,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<String>(recipeId);
    }
    if (!nullToAbsent || productId != null) {
      map['product_id'] = Variable<String>(productId);
    }
    map['raw_text'] = Variable<String>(rawText);
    if (!nullToAbsent || quantityMilli != null) {
      map['quantity_milli'] = Variable<int>(quantityMilli);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    map['position'] = Variable<int>(position);
    return map;
  }

  RecipeIngredientsCompanion toCompanion(bool nullToAbsent) {
    return RecipeIngredientsCompanion(
      id: Value(id),
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      productId: productId == null && nullToAbsent
          ? const Value.absent()
          : Value(productId),
      rawText: Value(rawText),
      quantityMilli: quantityMilli == null && nullToAbsent
          ? const Value.absent()
          : Value(quantityMilli),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      position: Value(position),
    );
  }

  factory RecipeIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeIngredient(
      id: serializer.fromJson<String>(json['id']),
      recipeId: serializer.fromJson<String?>(json['recipeId']),
      productId: serializer.fromJson<String?>(json['productId']),
      rawText: serializer.fromJson<String>(json['rawText']),
      quantityMilli: serializer.fromJson<int?>(json['quantityMilli']),
      unit: serializer.fromJson<String?>(json['unit']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'recipeId': serializer.toJson<String?>(recipeId),
      'productId': serializer.toJson<String?>(productId),
      'rawText': serializer.toJson<String>(rawText),
      'quantityMilli': serializer.toJson<int?>(quantityMilli),
      'unit': serializer.toJson<String?>(unit),
      'position': serializer.toJson<int>(position),
    };
  }

  RecipeIngredient copyWith({
    String? id,
    Value<String?> recipeId = const Value.absent(),
    Value<String?> productId = const Value.absent(),
    String? rawText,
    Value<int?> quantityMilli = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    int? position,
  }) => RecipeIngredient(
    id: id ?? this.id,
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    productId: productId.present ? productId.value : this.productId,
    rawText: rawText ?? this.rawText,
    quantityMilli: quantityMilli.present
        ? quantityMilli.value
        : this.quantityMilli,
    unit: unit.present ? unit.value : this.unit,
    position: position ?? this.position,
  );
  RecipeIngredient copyWithCompanion(RecipeIngredientsCompanion data) {
    return RecipeIngredient(
      id: data.id.present ? data.id.value : this.id,
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      productId: data.productId.present ? data.productId.value : this.productId,
      rawText: data.rawText.present ? data.rawText.value : this.rawText,
      quantityMilli: data.quantityMilli.present
          ? data.quantityMilli.value
          : this.quantityMilli,
      unit: data.unit.present ? data.unit.value : this.unit,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredient(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('productId: $productId, ')
          ..write('rawText: $rawText, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    recipeId,
    productId,
    rawText,
    quantityMilli,
    unit,
    position,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeIngredient &&
          other.id == this.id &&
          other.recipeId == this.recipeId &&
          other.productId == this.productId &&
          other.rawText == this.rawText &&
          other.quantityMilli == this.quantityMilli &&
          other.unit == this.unit &&
          other.position == this.position);
}

class RecipeIngredientsCompanion extends UpdateCompanion<RecipeIngredient> {
  final Value<String> id;
  final Value<String?> recipeId;
  final Value<String?> productId;
  final Value<String> rawText;
  final Value<int?> quantityMilli;
  final Value<String?> unit;
  final Value<int> position;
  final Value<int> rowid;
  const RecipeIngredientsCompanion({
    this.id = const Value.absent(),
    this.recipeId = const Value.absent(),
    this.productId = const Value.absent(),
    this.rawText = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeIngredientsCompanion.insert({
    required String id,
    this.recipeId = const Value.absent(),
    this.productId = const Value.absent(),
    required String rawText,
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rawText = Value(rawText),
       position = Value(position);
  static Insertable<RecipeIngredient> custom({
    Expression<String>? id,
    Expression<String>? recipeId,
    Expression<String>? productId,
    Expression<String>? rawText,
    Expression<int>? quantityMilli,
    Expression<String>? unit,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (recipeId != null) 'recipe_id': recipeId,
      if (productId != null) 'product_id': productId,
      if (rawText != null) 'raw_text': rawText,
      if (quantityMilli != null) 'quantity_milli': quantityMilli,
      if (unit != null) 'unit': unit,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeIngredientsCompanion copyWith({
    Value<String>? id,
    Value<String?>? recipeId,
    Value<String?>? productId,
    Value<String>? rawText,
    Value<int?>? quantityMilli,
    Value<String?>? unit,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return RecipeIngredientsCompanion(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      productId: productId ?? this.productId,
      rawText: rawText ?? this.rawText,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      unit: unit ?? this.unit,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (rawText.present) {
      map['raw_text'] = Variable<String>(rawText.value);
    }
    if (quantityMilli.present) {
      map['quantity_milli'] = Variable<int>(quantityMilli.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientsCompanion(')
          ..write('id: $id, ')
          ..write('recipeId: $recipeId, ')
          ..write('productId: $productId, ')
          ..write('rawText: $rawText, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecipeTagsTable extends RecipeTags
    with TableInfo<$RecipeTagsTable, RecipeTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecipeTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  @override
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  @override
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [recipeId, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId, tag};
  @override
  RecipeTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeTag(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  $RecipeTagsTable createAlias(String alias) {
    return $RecipeTagsTable(attachedDatabase, alias);
  }
}

class RecipeTag extends DataClass implements Insertable<RecipeTag> {
  final String recipeId;
  final String tag;
  const RecipeTag({required this.recipeId, required this.tag});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  RecipeTagsCompanion toCompanion(bool nullToAbsent) {
    return RecipeTagsCompanion(recipeId: Value(recipeId), tag: Value(tag));
  }

  factory RecipeTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeTag(
      recipeId: serializer.fromJson<String>(json['recipeId']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipeId': serializer.toJson<String>(recipeId),
      'tag': serializer.toJson<String>(tag),
    };
  }

  RecipeTag copyWith({String? recipeId, String? tag}) =>
      RecipeTag(recipeId: recipeId ?? this.recipeId, tag: tag ?? this.tag);
  RecipeTag copyWithCompanion(RecipeTagsCompanion data) {
    return RecipeTag(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTag(')
          ..write('recipeId: $recipeId, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeTag &&
          other.recipeId == this.recipeId &&
          other.tag == this.tag);
}

class RecipeTagsCompanion extends UpdateCompanion<RecipeTag> {
  final Value<String> recipeId;
  final Value<String> tag;
  final Value<int> rowid;
  const RecipeTagsCompanion({
    this.recipeId = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecipeTagsCompanion.insert({
    required String recipeId,
    required String tag,
    this.rowid = const Value.absent(),
  }) : recipeId = Value(recipeId),
       tag = Value(tag);
  static Insertable<RecipeTag> custom({
    Expression<String>? recipeId,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecipeTagsCompanion copyWith({
    Value<String>? recipeId,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return RecipeTagsCompanion(
      recipeId: recipeId ?? this.recipeId,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeTagsCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StockItemsTable extends StockItems
    with TableInfo<$StockItemsTable, StockItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StockItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES products (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _quantityMilliMeta = const VerificationMeta(
    'quantityMilli',
  );
  @override
  late final GeneratedColumn<int> quantityMilli = GeneratedColumn<int>(
    'quantity_milli',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('un'),
  );
  static const VerificationMeta _lowStockThresholdMilliMeta =
      const VerificationMeta('lowStockThresholdMilli');
  @override
  late final GeneratedColumn<int> lowStockThresholdMilli = GeneratedColumn<int>(
    'low_stock_threshold_milli',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastRestockedAtMeta = const VerificationMeta(
    'lastRestockedAt',
  );
  @override
  late final GeneratedColumn<String> lastRestockedAt = GeneratedColumn<String>(
    'last_restocked_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    quantityMilli,
    unit,
    lowStockThresholdMilli,
    lastRestockedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stock_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<StockItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('quantity_milli')) {
      context.handle(
        _quantityMilliMeta,
        quantityMilli.isAcceptableOrUnknown(
          data['quantity_milli']!,
          _quantityMilliMeta,
        ),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('low_stock_threshold_milli')) {
      context.handle(
        _lowStockThresholdMilliMeta,
        lowStockThresholdMilli.isAcceptableOrUnknown(
          data['low_stock_threshold_milli']!,
          _lowStockThresholdMilliMeta,
        ),
      );
    }
    if (data.containsKey('last_restocked_at')) {
      context.handle(
        _lastRestockedAtMeta,
        lastRestockedAt.isAcceptableOrUnknown(
          data['last_restocked_at']!,
          _lastRestockedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StockItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StockItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      quantityMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity_milli'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      lowStockThresholdMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}low_stock_threshold_milli'],
      ),
      lastRestockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_restocked_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $StockItemsTable createAlias(String alias) {
    return $StockItemsTable(attachedDatabase, alias);
  }
}

class StockItem extends DataClass implements Insertable<StockItem> {
  final String id;
  final String productId;
  final int quantityMilli;
  final String unit;
  final int? lowStockThresholdMilli;
  final String? lastRestockedAt;
  final String? createdAt;
  final String? updatedAt;
  const StockItem({
    required this.id,
    required this.productId,
    required this.quantityMilli,
    required this.unit,
    this.lowStockThresholdMilli,
    this.lastRestockedAt,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['quantity_milli'] = Variable<int>(quantityMilli);
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || lowStockThresholdMilli != null) {
      map['low_stock_threshold_milli'] = Variable<int>(lowStockThresholdMilli);
    }
    if (!nullToAbsent || lastRestockedAt != null) {
      map['last_restocked_at'] = Variable<String>(lastRestockedAt);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  StockItemsCompanion toCompanion(bool nullToAbsent) {
    return StockItemsCompanion(
      id: Value(id),
      productId: Value(productId),
      quantityMilli: Value(quantityMilli),
      unit: Value(unit),
      lowStockThresholdMilli: lowStockThresholdMilli == null && nullToAbsent
          ? const Value.absent()
          : Value(lowStockThresholdMilli),
      lastRestockedAt: lastRestockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRestockedAt),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory StockItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StockItem(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      quantityMilli: serializer.fromJson<int>(json['quantityMilli']),
      unit: serializer.fromJson<String>(json['unit']),
      lowStockThresholdMilli: serializer.fromJson<int?>(
        json['lowStockThresholdMilli'],
      ),
      lastRestockedAt: serializer.fromJson<String?>(json['lastRestockedAt']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'quantityMilli': serializer.toJson<int>(quantityMilli),
      'unit': serializer.toJson<String>(unit),
      'lowStockThresholdMilli': serializer.toJson<int?>(lowStockThresholdMilli),
      'lastRestockedAt': serializer.toJson<String?>(lastRestockedAt),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  StockItem copyWith({
    String? id,
    String? productId,
    int? quantityMilli,
    String? unit,
    Value<int?> lowStockThresholdMilli = const Value.absent(),
    Value<String?> lastRestockedAt = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => StockItem(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    quantityMilli: quantityMilli ?? this.quantityMilli,
    unit: unit ?? this.unit,
    lowStockThresholdMilli: lowStockThresholdMilli.present
        ? lowStockThresholdMilli.value
        : this.lowStockThresholdMilli,
    lastRestockedAt: lastRestockedAt.present
        ? lastRestockedAt.value
        : this.lastRestockedAt,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  StockItem copyWithCompanion(StockItemsCompanion data) {
    return StockItem(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      quantityMilli: data.quantityMilli.present
          ? data.quantityMilli.value
          : this.quantityMilli,
      unit: data.unit.present ? data.unit.value : this.unit,
      lowStockThresholdMilli: data.lowStockThresholdMilli.present
          ? data.lowStockThresholdMilli.value
          : this.lowStockThresholdMilli,
      lastRestockedAt: data.lastRestockedAt.present
          ? data.lastRestockedAt.value
          : this.lastRestockedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StockItem(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('lowStockThresholdMilli: $lowStockThresholdMilli, ')
          ..write('lastRestockedAt: $lastRestockedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    quantityMilli,
    unit,
    lowStockThresholdMilli,
    lastRestockedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StockItem &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.quantityMilli == this.quantityMilli &&
          other.unit == this.unit &&
          other.lowStockThresholdMilli == this.lowStockThresholdMilli &&
          other.lastRestockedAt == this.lastRestockedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class StockItemsCompanion extends UpdateCompanion<StockItem> {
  final Value<String> id;
  final Value<String> productId;
  final Value<int> quantityMilli;
  final Value<String> unit;
  final Value<int?> lowStockThresholdMilli;
  final Value<String?> lastRestockedAt;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const StockItemsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    this.lowStockThresholdMilli = const Value.absent(),
    this.lastRestockedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StockItemsCompanion.insert({
    required String id,
    required String productId,
    this.quantityMilli = const Value.absent(),
    this.unit = const Value.absent(),
    this.lowStockThresholdMilli = const Value.absent(),
    this.lastRestockedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId);
  static Insertable<StockItem> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<int>? quantityMilli,
    Expression<String>? unit,
    Expression<int>? lowStockThresholdMilli,
    Expression<String>? lastRestockedAt,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (quantityMilli != null) 'quantity_milli': quantityMilli,
      if (unit != null) 'unit': unit,
      if (lowStockThresholdMilli != null)
        'low_stock_threshold_milli': lowStockThresholdMilli,
      if (lastRestockedAt != null) 'last_restocked_at': lastRestockedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StockItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<int>? quantityMilli,
    Value<String>? unit,
    Value<int?>? lowStockThresholdMilli,
    Value<String?>? lastRestockedAt,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return StockItemsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      quantityMilli: quantityMilli ?? this.quantityMilli,
      unit: unit ?? this.unit,
      lowStockThresholdMilli:
          lowStockThresholdMilli ?? this.lowStockThresholdMilli,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
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
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (quantityMilli.present) {
      map['quantity_milli'] = Variable<int>(quantityMilli.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (lowStockThresholdMilli.present) {
      map['low_stock_threshold_milli'] = Variable<int>(
        lowStockThresholdMilli.value,
      );
    }
    if (lastRestockedAt.present) {
      map['last_restocked_at'] = Variable<String>(lastRestockedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StockItemsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('quantityMilli: $quantityMilli, ')
          ..write('unit: $unit, ')
          ..write('lowStockThresholdMilli: $lowStockThresholdMilli, ')
          ..write('lastRestockedAt: $lastRestockedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChecklistItemsTable extends ChecklistItems
    with TableInfo<$ChecklistItemsTable, ChecklistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChecklistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roomCategoryMeta = const VerificationMeta(
    'roomCategory',
  );
  @override
  late final GeneratedColumn<String> roomCategory = GeneratedColumn<String>(
    'room_category',
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
  static const VerificationMeta _isMarkedMeta = const VerificationMeta(
    'isMarked',
  );
  @override
  late final GeneratedColumn<bool> isMarked = GeneratedColumn<bool>(
    'is_marked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_marked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    roomCategory,
    title,
    isMarked,
    position,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'checklist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChecklistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('room_category')) {
      context.handle(
        _roomCategoryMeta,
        roomCategory.isAcceptableOrUnknown(
          data['room_category']!,
          _roomCategoryMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_roomCategoryMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_marked')) {
      context.handle(
        _isMarkedMeta,
        isMarked.isAcceptableOrUnknown(data['is_marked']!, _isMarkedMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChecklistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChecklistItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      roomCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}room_category'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isMarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_marked'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ChecklistItemsTable createAlias(String alias) {
    return $ChecklistItemsTable(attachedDatabase, alias);
  }
}

class ChecklistItem extends DataClass implements Insertable<ChecklistItem> {
  final String id;
  final String roomCategory;
  final String title;
  final bool isMarked;
  final int position;
  final String? createdAt;
  final String? updatedAt;
  const ChecklistItem({
    required this.id,
    required this.roomCategory,
    required this.title,
    required this.isMarked,
    required this.position,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['room_category'] = Variable<String>(roomCategory);
    map['title'] = Variable<String>(title);
    map['is_marked'] = Variable<bool>(isMarked);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  ChecklistItemsCompanion toCompanion(bool nullToAbsent) {
    return ChecklistItemsCompanion(
      id: Value(id),
      roomCategory: Value(roomCategory),
      title: Value(title),
      isMarked: Value(isMarked),
      position: Value(position),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ChecklistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChecklistItem(
      id: serializer.fromJson<String>(json['id']),
      roomCategory: serializer.fromJson<String>(json['roomCategory']),
      title: serializer.fromJson<String>(json['title']),
      isMarked: serializer.fromJson<bool>(json['isMarked']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'roomCategory': serializer.toJson<String>(roomCategory),
      'title': serializer.toJson<String>(title),
      'isMarked': serializer.toJson<bool>(isMarked),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? roomCategory,
    String? title,
    bool? isMarked,
    int? position,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => ChecklistItem(
    id: id ?? this.id,
    roomCategory: roomCategory ?? this.roomCategory,
    title: title ?? this.title,
    isMarked: isMarked ?? this.isMarked,
    position: position ?? this.position,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ChecklistItem copyWithCompanion(ChecklistItemsCompanion data) {
    return ChecklistItem(
      id: data.id.present ? data.id.value : this.id,
      roomCategory: data.roomCategory.present
          ? data.roomCategory.value
          : this.roomCategory,
      title: data.title.present ? data.title.value : this.title,
      isMarked: data.isMarked.present ? data.isMarked.value : this.isMarked,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItem(')
          ..write('id: $id, ')
          ..write('roomCategory: $roomCategory, ')
          ..write('title: $title, ')
          ..write('isMarked: $isMarked, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    roomCategory,
    title,
    isMarked,
    position,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChecklistItem &&
          other.id == this.id &&
          other.roomCategory == this.roomCategory &&
          other.title == this.title &&
          other.isMarked == this.isMarked &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ChecklistItemsCompanion extends UpdateCompanion<ChecklistItem> {
  final Value<String> id;
  final Value<String> roomCategory;
  final Value<String> title;
  final Value<bool> isMarked;
  final Value<int> position;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const ChecklistItemsCompanion({
    this.id = const Value.absent(),
    this.roomCategory = const Value.absent(),
    this.title = const Value.absent(),
    this.isMarked = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChecklistItemsCompanion.insert({
    required String id,
    required String roomCategory,
    required String title,
    this.isMarked = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       roomCategory = Value(roomCategory),
       title = Value(title);
  static Insertable<ChecklistItem> custom({
    Expression<String>? id,
    Expression<String>? roomCategory,
    Expression<String>? title,
    Expression<bool>? isMarked,
    Expression<int>? position,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (roomCategory != null) 'room_category': roomCategory,
      if (title != null) 'title': title,
      if (isMarked != null) 'is_marked': isMarked,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChecklistItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? roomCategory,
    Value<String>? title,
    Value<bool>? isMarked,
    Value<int>? position,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChecklistItemsCompanion(
      id: id ?? this.id,
      roomCategory: roomCategory ?? this.roomCategory,
      title: title ?? this.title,
      isMarked: isMarked ?? this.isMarked,
      position: position ?? this.position,
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
    if (roomCategory.present) {
      map['room_category'] = Variable<String>(roomCategory.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isMarked.present) {
      map['is_marked'] = Variable<bool>(isMarked.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChecklistItemsCompanion(')
          ..write('id: $id, ')
          ..write('roomCategory: $roomCategory, ')
          ..write('title: $title, ')
          ..write('isMarked: $isMarked, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _testColumnMeta = const VerificationMeta(
    'testColumn',
  );
  @override
  late final GeneratedColumn<String> testColumn = GeneratedColumn<String>(
    'test_column',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt, testColumn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('test_column')) {
      context.handle(
        _testColumnMeta,
        testColumn.isAcceptableOrUnknown(data['test_column']!, _testColumnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
      testColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}test_column'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  final String? updatedAt;
  final String? testColumn;
  const Setting({
    required this.key,
    required this.value,
    this.updatedAt,
    this.testColumn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    if (!nullToAbsent || testColumn != null) {
      map['test_column'] = Variable<String>(testColumn);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      testColumn: testColumn == null && nullToAbsent
          ? const Value.absent()
          : Value(testColumn),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
      testColumn: serializer.fromJson<String?>(json['testColumn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<String?>(updatedAt),
      'testColumn': serializer.toJson<String?>(testColumn),
    };
  }

  Setting copyWith({
    String? key,
    String? value,
    Value<String?> updatedAt = const Value.absent(),
    Value<String?> testColumn = const Value.absent(),
  }) => Setting(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    testColumn: testColumn.present ? testColumn.value : this.testColumn,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      testColumn: data.testColumn.present
          ? data.testColumn.value
          : this.testColumn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('testColumn: $testColumn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt, testColumn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt &&
          other.testColumn == this.testColumn);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<String?> updatedAt;
  final Value<String?> testColumn;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.testColumn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.testColumn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? updatedAt,
    Expression<String>? testColumn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (testColumn != null) 'test_column': testColumn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<String?>? updatedAt,
    Value<String?>? testColumn,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      testColumn: testColumn ?? this.testColumn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (testColumn.present) {
      map['test_column'] = Variable<String>(testColumn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('testColumn: $testColumn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConsentsTable extends Consents with TableInfo<$ConsentsTable, Consent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConsentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _grantedMeta = const VerificationMeta(
    'granted',
  );
  @override
  late final GeneratedColumn<bool> granted = GeneratedColumn<bool>(
    'granted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("granted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _grantedAtMeta = const VerificationMeta(
    'grantedAt',
  );
  @override
  late final GeneratedColumn<String> grantedAt = GeneratedColumn<String>(
    'granted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _revokedAtMeta = const VerificationMeta(
    'revokedAt',
  );
  @override
  late final GeneratedColumn<String> revokedAt = GeneratedColumn<String>(
    'revoked_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, granted, grantedAt, revokedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'consents';
  @override
  VerificationContext validateIntegrity(
    Insertable<Consent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('granted')) {
      context.handle(
        _grantedMeta,
        granted.isAcceptableOrUnknown(data['granted']!, _grantedMeta),
      );
    } else if (isInserting) {
      context.missing(_grantedMeta);
    }
    if (data.containsKey('granted_at')) {
      context.handle(
        _grantedAtMeta,
        grantedAt.isAcceptableOrUnknown(data['granted_at']!, _grantedAtMeta),
      );
    }
    if (data.containsKey('revoked_at')) {
      context.handle(
        _revokedAtMeta,
        revokedAt.isAcceptableOrUnknown(data['revoked_at']!, _revokedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Consent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Consent(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      granted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}granted'],
      )!,
      grantedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}granted_at'],
      ),
      revokedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revoked_at'],
      ),
    );
  }

  @override
  $ConsentsTable createAlias(String alias) {
    return $ConsentsTable(attachedDatabase, alias);
  }
}

class Consent extends DataClass implements Insertable<Consent> {
  final String key;
  final bool granted;
  final String? grantedAt;
  final String? revokedAt;
  const Consent({
    required this.key,
    required this.granted,
    this.grantedAt,
    this.revokedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['granted'] = Variable<bool>(granted);
    if (!nullToAbsent || grantedAt != null) {
      map['granted_at'] = Variable<String>(grantedAt);
    }
    if (!nullToAbsent || revokedAt != null) {
      map['revoked_at'] = Variable<String>(revokedAt);
    }
    return map;
  }

  ConsentsCompanion toCompanion(bool nullToAbsent) {
    return ConsentsCompanion(
      key: Value(key),
      granted: Value(granted),
      grantedAt: grantedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(grantedAt),
      revokedAt: revokedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(revokedAt),
    );
  }

  factory Consent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Consent(
      key: serializer.fromJson<String>(json['key']),
      granted: serializer.fromJson<bool>(json['granted']),
      grantedAt: serializer.fromJson<String?>(json['grantedAt']),
      revokedAt: serializer.fromJson<String?>(json['revokedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'granted': serializer.toJson<bool>(granted),
      'grantedAt': serializer.toJson<String?>(grantedAt),
      'revokedAt': serializer.toJson<String?>(revokedAt),
    };
  }

  Consent copyWith({
    String? key,
    bool? granted,
    Value<String?> grantedAt = const Value.absent(),
    Value<String?> revokedAt = const Value.absent(),
  }) => Consent(
    key: key ?? this.key,
    granted: granted ?? this.granted,
    grantedAt: grantedAt.present ? grantedAt.value : this.grantedAt,
    revokedAt: revokedAt.present ? revokedAt.value : this.revokedAt,
  );
  Consent copyWithCompanion(ConsentsCompanion data) {
    return Consent(
      key: data.key.present ? data.key.value : this.key,
      granted: data.granted.present ? data.granted.value : this.granted,
      grantedAt: data.grantedAt.present ? data.grantedAt.value : this.grantedAt,
      revokedAt: data.revokedAt.present ? data.revokedAt.value : this.revokedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Consent(')
          ..write('key: $key, ')
          ..write('granted: $granted, ')
          ..write('grantedAt: $grantedAt, ')
          ..write('revokedAt: $revokedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, granted, grantedAt, revokedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Consent &&
          other.key == this.key &&
          other.granted == this.granted &&
          other.grantedAt == this.grantedAt &&
          other.revokedAt == this.revokedAt);
}

class ConsentsCompanion extends UpdateCompanion<Consent> {
  final Value<String> key;
  final Value<bool> granted;
  final Value<String?> grantedAt;
  final Value<String?> revokedAt;
  final Value<int> rowid;
  const ConsentsCompanion({
    this.key = const Value.absent(),
    this.granted = const Value.absent(),
    this.grantedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConsentsCompanion.insert({
    required String key,
    required bool granted,
    this.grantedAt = const Value.absent(),
    this.revokedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       granted = Value(granted);
  static Insertable<Consent> custom({
    Expression<String>? key,
    Expression<bool>? granted,
    Expression<String>? grantedAt,
    Expression<String>? revokedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (granted != null) 'granted': granted,
      if (grantedAt != null) 'granted_at': grantedAt,
      if (revokedAt != null) 'revoked_at': revokedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConsentsCompanion copyWith({
    Value<String>? key,
    Value<bool>? granted,
    Value<String?>? grantedAt,
    Value<String?>? revokedAt,
    Value<int>? rowid,
  }) {
    return ConsentsCompanion(
      key: key ?? this.key,
      granted: granted ?? this.granted,
      grantedAt: grantedAt ?? this.grantedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (granted.present) {
      map['granted'] = Variable<bool>(granted.value);
    }
    if (grantedAt.present) {
      map['granted_at'] = Variable<String>(grantedAt.value);
    }
    if (revokedAt.present) {
      map['revoked_at'] = Variable<String>(revokedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConsentsCompanion(')
          ..write('key: $key, ')
          ..write('granted: $granted, ')
          ..write('grantedAt: $grantedAt, ')
          ..write('revokedAt: $revokedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerTypeMeta = const VerificationMeta(
    'ownerType',
  );
  @override
  late final GeneratedColumn<String> ownerType = GeneratedColumn<String>(
    'owner_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    path,
    kind,
    ownerType,
    ownerId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('owner_type')) {
      context.handle(
        _ownerTypeMeta,
        ownerType.isAcceptableOrUnknown(data['owner_type']!, _ownerTypeMeta),
      );
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
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
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      ownerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_type'],
      ),
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String id;
  final String path;
  final String? kind;
  final String? ownerType;
  final String? ownerId;
  final String? createdAt;
  const Attachment({
    required this.id,
    required this.path,
    this.kind,
    this.ownerType,
    this.ownerId,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['path'] = Variable<String>(path);
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    if (!nullToAbsent || ownerType != null) {
      map['owner_type'] = Variable<String>(ownerType);
    }
    if (!nullToAbsent || ownerId != null) {
      map['owner_id'] = Variable<String>(ownerId);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      id: Value(id),
      path: Value(path),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      ownerType: ownerType == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerType),
      ownerId: ownerId == null && nullToAbsent
          ? const Value.absent()
          : Value(ownerId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      id: serializer.fromJson<String>(json['id']),
      path: serializer.fromJson<String>(json['path']),
      kind: serializer.fromJson<String?>(json['kind']),
      ownerType: serializer.fromJson<String?>(json['ownerType']),
      ownerId: serializer.fromJson<String?>(json['ownerId']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'path': serializer.toJson<String>(path),
      'kind': serializer.toJson<String?>(kind),
      'ownerType': serializer.toJson<String?>(ownerType),
      'ownerId': serializer.toJson<String?>(ownerId),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  Attachment copyWith({
    String? id,
    String? path,
    Value<String?> kind = const Value.absent(),
    Value<String?> ownerType = const Value.absent(),
    Value<String?> ownerId = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
  }) => Attachment(
    id: id ?? this.id,
    path: path ?? this.path,
    kind: kind.present ? kind.value : this.kind,
    ownerType: ownerType.present ? ownerType.value : this.ownerType,
    ownerId: ownerId.present ? ownerId.value : this.ownerId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      id: data.id.present ? data.id.value : this.id,
      path: data.path.present ? data.path.value : this.path,
      kind: data.kind.present ? data.kind.value : this.kind,
      ownerType: data.ownerType.present ? data.ownerType.value : this.ownerType,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, path, kind, ownerType, ownerId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.id == this.id &&
          other.path == this.path &&
          other.kind == this.kind &&
          other.ownerType == this.ownerType &&
          other.ownerId == this.ownerId &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> id;
  final Value<String> path;
  final Value<String?> kind;
  final Value<String?> ownerType;
  final Value<String?> ownerId;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.id = const Value.absent(),
    this.path = const Value.absent(),
    this.kind = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String id,
    required String path,
    this.kind = const Value.absent(),
    this.ownerType = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       path = Value(path);
  static Insertable<Attachment> custom({
    Expression<String>? id,
    Expression<String>? path,
    Expression<String>? kind,
    Expression<String>? ownerType,
    Expression<String>? ownerId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (path != null) 'path': path,
      if (kind != null) 'kind': kind,
      if (ownerType != null) 'owner_type': ownerType,
      if (ownerId != null) 'owner_id': ownerId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? id,
    Value<String>? path,
    Value<String?>? kind,
    Value<String?>? ownerType,
    Value<String?>? ownerId,
    Value<String?>? createdAt,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      id: id ?? this.id,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
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
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (ownerType.present) {
      map['owner_type'] = Variable<String>(ownerType.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('id: $id, ')
          ..write('path: $path, ')
          ..write('kind: $kind, ')
          ..write('ownerType: $ownerType, ')
          ..write('ownerId: $ownerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncHouseholdsTable extends SyncHouseholds
    with TableInfo<$SyncHouseholdsTable, SyncHousehold> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncHouseholdsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _localSiteIdMeta = const VerificationMeta(
    'localSiteId',
  );
  @override
  late final GeneratedColumn<String> localSiteId = GeneratedColumn<String>(
    'local_site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sharedAreasMeta = const VerificationMeta(
    'sharedAreas',
  );
  @override
  late final GeneratedColumn<String> sharedAreas = GeneratedColumn<String>(
    'shared_areas',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<String> joinedAt = GeneratedColumn<String>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    localSiteId,
    sharedAreas,
    createdAt,
    joinedAt,
    active,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_household';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncHousehold> instance, {
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
    if (data.containsKey('local_site_id')) {
      context.handle(
        _localSiteIdMeta,
        localSiteId.isAcceptableOrUnknown(
          data['local_site_id']!,
          _localSiteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localSiteIdMeta);
    }
    if (data.containsKey('shared_areas')) {
      context.handle(
        _sharedAreasMeta,
        sharedAreas.isAcceptableOrUnknown(
          data['shared_areas']!,
          _sharedAreasMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sharedAreasMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncHousehold map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncHousehold(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      localSiteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_site_id'],
      )!,
      sharedAreas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shared_areas'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}joined_at'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
    );
  }

  @override
  $SyncHouseholdsTable createAlias(String alias) {
    return $SyncHouseholdsTable(attachedDatabase, alias);
  }
}

class SyncHousehold extends DataClass implements Insertable<SyncHousehold> {
  /// Identificador UUID da casa.
  final String id;

  /// Apelido da casa (ex.: "Casa da Duda").
  final String name;

  /// Identificador do aparelho local nesta casa.
  final String localSiteId;

  /// Active shared areas separated by comma (e.g. "catalog,home,finance").
  final String sharedAreas;

  /// Household creation date (ISO-8601 UTC).
  final String createdAt;

  /// Data em que este aparelho entrou na casa (ISO-8601 UTC).
  final String joinedAt;

  /// Whether synchronization is active on this device.
  final bool active;
  const SyncHousehold({
    required this.id,
    required this.name,
    required this.localSiteId,
    required this.sharedAreas,
    required this.createdAt,
    required this.joinedAt,
    required this.active,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['local_site_id'] = Variable<String>(localSiteId);
    map['shared_areas'] = Variable<String>(sharedAreas);
    map['created_at'] = Variable<String>(createdAt);
    map['joined_at'] = Variable<String>(joinedAt);
    map['active'] = Variable<bool>(active);
    return map;
  }

  SyncHouseholdsCompanion toCompanion(bool nullToAbsent) {
    return SyncHouseholdsCompanion(
      id: Value(id),
      name: Value(name),
      localSiteId: Value(localSiteId),
      sharedAreas: Value(sharedAreas),
      createdAt: Value(createdAt),
      joinedAt: Value(joinedAt),
      active: Value(active),
    );
  }

  factory SyncHousehold.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncHousehold(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      localSiteId: serializer.fromJson<String>(json['localSiteId']),
      sharedAreas: serializer.fromJson<String>(json['sharedAreas']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      joinedAt: serializer.fromJson<String>(json['joinedAt']),
      active: serializer.fromJson<bool>(json['active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'localSiteId': serializer.toJson<String>(localSiteId),
      'sharedAreas': serializer.toJson<String>(sharedAreas),
      'createdAt': serializer.toJson<String>(createdAt),
      'joinedAt': serializer.toJson<String>(joinedAt),
      'active': serializer.toJson<bool>(active),
    };
  }

  SyncHousehold copyWith({
    String? id,
    String? name,
    String? localSiteId,
    String? sharedAreas,
    String? createdAt,
    String? joinedAt,
    bool? active,
  }) => SyncHousehold(
    id: id ?? this.id,
    name: name ?? this.name,
    localSiteId: localSiteId ?? this.localSiteId,
    sharedAreas: sharedAreas ?? this.sharedAreas,
    createdAt: createdAt ?? this.createdAt,
    joinedAt: joinedAt ?? this.joinedAt,
    active: active ?? this.active,
  );
  SyncHousehold copyWithCompanion(SyncHouseholdsCompanion data) {
    return SyncHousehold(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      localSiteId: data.localSiteId.present
          ? data.localSiteId.value
          : this.localSiteId,
      sharedAreas: data.sharedAreas.present
          ? data.sharedAreas.value
          : this.sharedAreas,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      active: data.active.present ? data.active.value : this.active,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncHousehold(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('localSiteId: $localSiteId, ')
          ..write('sharedAreas: $sharedAreas, ')
          ..write('createdAt: $createdAt, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('active: $active')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    localSiteId,
    sharedAreas,
    createdAt,
    joinedAt,
    active,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncHousehold &&
          other.id == this.id &&
          other.name == this.name &&
          other.localSiteId == this.localSiteId &&
          other.sharedAreas == this.sharedAreas &&
          other.createdAt == this.createdAt &&
          other.joinedAt == this.joinedAt &&
          other.active == this.active);
}

class SyncHouseholdsCompanion extends UpdateCompanion<SyncHousehold> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> localSiteId;
  final Value<String> sharedAreas;
  final Value<String> createdAt;
  final Value<String> joinedAt;
  final Value<bool> active;
  final Value<int> rowid;
  const SyncHouseholdsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.localSiteId = const Value.absent(),
    this.sharedAreas = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncHouseholdsCompanion.insert({
    required String id,
    required String name,
    required String localSiteId,
    required String sharedAreas,
    required String createdAt,
    required String joinedAt,
    this.active = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       localSiteId = Value(localSiteId),
       sharedAreas = Value(sharedAreas),
       createdAt = Value(createdAt),
       joinedAt = Value(joinedAt);
  static Insertable<SyncHousehold> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? localSiteId,
    Expression<String>? sharedAreas,
    Expression<String>? createdAt,
    Expression<String>? joinedAt,
    Expression<bool>? active,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (localSiteId != null) 'local_site_id': localSiteId,
      if (sharedAreas != null) 'shared_areas': sharedAreas,
      if (createdAt != null) 'created_at': createdAt,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (active != null) 'active': active,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncHouseholdsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? localSiteId,
    Value<String>? sharedAreas,
    Value<String>? createdAt,
    Value<String>? joinedAt,
    Value<bool>? active,
    Value<int>? rowid,
  }) {
    return SyncHouseholdsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      localSiteId: localSiteId ?? this.localSiteId,
      sharedAreas: sharedAreas ?? this.sharedAreas,
      createdAt: createdAt ?? this.createdAt,
      joinedAt: joinedAt ?? this.joinedAt,
      active: active ?? this.active,
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
    if (localSiteId.present) {
      map['local_site_id'] = Variable<String>(localSiteId.value);
    }
    if (sharedAreas.present) {
      map['shared_areas'] = Variable<String>(sharedAreas.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<String>(joinedAt.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncHouseholdsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('localSiteId: $localSiteId, ')
          ..write('sharedAreas: $sharedAreas, ')
          ..write('createdAt: $createdAt, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('active: $active, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMembersTable extends SyncMembers
    with TableInfo<$SyncMembersTable, SyncMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sync_household (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
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
  static const VerificationMeta _joinedAtMeta = const VerificationMeta(
    'joinedAt',
  );
  @override
  late final GeneratedColumn<String> joinedAt = GeneratedColumn<String>(
    'joined_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSeenAtMeta = const VerificationMeta(
    'lastSeenAt',
  );
  @override
  late final GeneratedColumn<String> lastSeenAt = GeneratedColumn<String>(
    'last_seen_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    householdId,
    siteId,
    name,
    joinedAt,
    lastSeenAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('joined_at')) {
      context.handle(
        _joinedAtMeta,
        joinedAt.isAcceptableOrUnknown(data['joined_at']!, _joinedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_joinedAtMeta);
    }
    if (data.containsKey('last_seen_at')) {
      context.handle(
        _lastSeenAtMeta,
        lastSeenAt.isAcceptableOrUnknown(
          data['last_seen_at']!,
          _lastSeenAtMeta,
        ),
      );
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
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {householdId, siteId},
  ];
  @override
  SyncMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMember(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      joinedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}joined_at'],
      )!,
      lastSeenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_seen_at'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $SyncMembersTable createAlias(String alias) {
    return $SyncMembersTable(attachedDatabase, alias);
  }
}

class SyncMember extends DataClass implements Insertable<SyncMember> {
  /// Identificador UUID do membro.
  final String id;

  /// Chave estrangeira para a casa.
  final String householdId;

  /// Unique device identifier of member.
  final String siteId;

  /// Visible nickname of device (e.g. "John's Phone") (RN-306).
  final String name;

  /// Data de ingresso na casa (ISO-8601 UTC).
  final String joinedAt;

  /// Last time this device was seen in synchronization.
  final String? lastSeenAt;

  /// Whether device is still an active member (deactivated when removed).
  final bool isActive;
  const SyncMember({
    required this.id,
    required this.householdId,
    required this.siteId,
    required this.name,
    required this.joinedAt,
    this.lastSeenAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['household_id'] = Variable<String>(householdId);
    map['site_id'] = Variable<String>(siteId);
    map['name'] = Variable<String>(name);
    map['joined_at'] = Variable<String>(joinedAt);
    if (!nullToAbsent || lastSeenAt != null) {
      map['last_seen_at'] = Variable<String>(lastSeenAt);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  SyncMembersCompanion toCompanion(bool nullToAbsent) {
    return SyncMembersCompanion(
      id: Value(id),
      householdId: Value(householdId),
      siteId: Value(siteId),
      name: Value(name),
      joinedAt: Value(joinedAt),
      lastSeenAt: lastSeenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAt),
      isActive: Value(isActive),
    );
  }

  factory SyncMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMember(
      id: serializer.fromJson<String>(json['id']),
      householdId: serializer.fromJson<String>(json['householdId']),
      siteId: serializer.fromJson<String>(json['siteId']),
      name: serializer.fromJson<String>(json['name']),
      joinedAt: serializer.fromJson<String>(json['joinedAt']),
      lastSeenAt: serializer.fromJson<String?>(json['lastSeenAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'householdId': serializer.toJson<String>(householdId),
      'siteId': serializer.toJson<String>(siteId),
      'name': serializer.toJson<String>(name),
      'joinedAt': serializer.toJson<String>(joinedAt),
      'lastSeenAt': serializer.toJson<String?>(lastSeenAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  SyncMember copyWith({
    String? id,
    String? householdId,
    String? siteId,
    String? name,
    String? joinedAt,
    Value<String?> lastSeenAt = const Value.absent(),
    bool? isActive,
  }) => SyncMember(
    id: id ?? this.id,
    householdId: householdId ?? this.householdId,
    siteId: siteId ?? this.siteId,
    name: name ?? this.name,
    joinedAt: joinedAt ?? this.joinedAt,
    lastSeenAt: lastSeenAt.present ? lastSeenAt.value : this.lastSeenAt,
    isActive: isActive ?? this.isActive,
  );
  SyncMember copyWithCompanion(SyncMembersCompanion data) {
    return SyncMember(
      id: data.id.present ? data.id.value : this.id,
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      name: data.name.present ? data.name.value : this.name,
      joinedAt: data.joinedAt.present ? data.joinedAt.value : this.joinedAt,
      lastSeenAt: data.lastSeenAt.present
          ? data.lastSeenAt.value
          : this.lastSeenAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMember(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('siteId: $siteId, ')
          ..write('name: $name, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    householdId,
    siteId,
    name,
    joinedAt,
    lastSeenAt,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMember &&
          other.id == this.id &&
          other.householdId == this.householdId &&
          other.siteId == this.siteId &&
          other.name == this.name &&
          other.joinedAt == this.joinedAt &&
          other.lastSeenAt == this.lastSeenAt &&
          other.isActive == this.isActive);
}

class SyncMembersCompanion extends UpdateCompanion<SyncMember> {
  final Value<String> id;
  final Value<String> householdId;
  final Value<String> siteId;
  final Value<String> name;
  final Value<String> joinedAt;
  final Value<String?> lastSeenAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const SyncMembersCompanion({
    this.id = const Value.absent(),
    this.householdId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.name = const Value.absent(),
    this.joinedAt = const Value.absent(),
    this.lastSeenAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMembersCompanion.insert({
    required String id,
    required String householdId,
    required String siteId,
    required String name,
    required String joinedAt,
    this.lastSeenAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       householdId = Value(householdId),
       siteId = Value(siteId),
       name = Value(name),
       joinedAt = Value(joinedAt);
  static Insertable<SyncMember> custom({
    Expression<String>? id,
    Expression<String>? householdId,
    Expression<String>? siteId,
    Expression<String>? name,
    Expression<String>? joinedAt,
    Expression<String>? lastSeenAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (householdId != null) 'household_id': householdId,
      if (siteId != null) 'site_id': siteId,
      if (name != null) 'name': name,
      if (joinedAt != null) 'joined_at': joinedAt,
      if (lastSeenAt != null) 'last_seen_at': lastSeenAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMembersCompanion copyWith({
    Value<String>? id,
    Value<String>? householdId,
    Value<String>? siteId,
    Value<String>? name,
    Value<String>? joinedAt,
    Value<String?>? lastSeenAt,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return SyncMembersCompanion(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      siteId: siteId ?? this.siteId,
      name: name ?? this.name,
      joinedAt: joinedAt ?? this.joinedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
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
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (joinedAt.present) {
      map['joined_at'] = Variable<String>(joinedAt.value);
    }
    if (lastSeenAt.present) {
      map['last_seen_at'] = Variable<String>(lastSeenAt.value);
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
    return (StringBuffer('SyncMembersCompanion(')
          ..write('id: $id, ')
          ..write('householdId: $householdId, ')
          ..write('siteId: $siteId, ')
          ..write('name: $name, ')
          ..write('joinedAt: $joinedAt, ')
          ..write('lastSeenAt: $lastSeenAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncColumnVersionsTable extends SyncColumnVersions
    with TableInfo<$SyncColumnVersionsTable, SyncColumnVersion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncColumnVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tableNameColMeta = const VerificationMeta(
    'tableNameCol',
  );
  @override
  late final GeneratedColumn<String> tableNameCol = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _columnNameMeta = const VerificationMeta(
    'columnName',
  );
  @override
  late final GeneratedColumn<String> columnName = GeneratedColumn<String>(
    'column_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    tableNameCol,
    rowId,
    columnName,
    hlc,
    siteId,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_column_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncColumnVersion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_name')) {
      context.handle(
        _tableNameColMeta,
        tableNameCol.isAcceptableOrUnknown(
          data['table_name']!,
          _tableNameColMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tableNameColMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('column_name')) {
      context.handle(
        _columnNameMeta,
        columnName.isAcceptableOrUnknown(data['column_name']!, _columnNameMeta),
      );
    } else if (isInserting) {
      context.missing(_columnNameMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tableNameCol, rowId, columnName};
  @override
  SyncColumnVersion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncColumnVersion(
      tableNameCol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      columnName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}column_name'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncColumnVersionsTable createAlias(String alias) {
    return $SyncColumnVersionsTable(attachedDatabase, alias);
  }
}

class SyncColumnVersion extends DataClass
    implements Insertable<SyncColumnVersion> {
  /// Nome da tabela no banco.
  final String tableNameCol;

  /// Primary row identifier.
  final String rowId;

  /// Nome da coluna.
  final String columnName;

  /// HLC empacotado lexicograficamente.
  final String hlc;

  /// Device that originated change.
  final String siteId;

  /// Local record date (ISO-8601 UTC).
  final String updatedAt;
  const SyncColumnVersion({
    required this.tableNameCol,
    required this.rowId,
    required this.columnName,
    required this.hlc,
    required this.siteId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['table_name'] = Variable<String>(tableNameCol);
    map['row_id'] = Variable<String>(rowId);
    map['column_name'] = Variable<String>(columnName);
    map['hlc'] = Variable<String>(hlc);
    map['site_id'] = Variable<String>(siteId);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SyncColumnVersionsCompanion toCompanion(bool nullToAbsent) {
    return SyncColumnVersionsCompanion(
      tableNameCol: Value(tableNameCol),
      rowId: Value(rowId),
      columnName: Value(columnName),
      hlc: Value(hlc),
      siteId: Value(siteId),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncColumnVersion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncColumnVersion(
      tableNameCol: serializer.fromJson<String>(json['tableNameCol']),
      rowId: serializer.fromJson<String>(json['rowId']),
      columnName: serializer.fromJson<String>(json['columnName']),
      hlc: serializer.fromJson<String>(json['hlc']),
      siteId: serializer.fromJson<String>(json['siteId']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tableNameCol': serializer.toJson<String>(tableNameCol),
      'rowId': serializer.toJson<String>(rowId),
      'columnName': serializer.toJson<String>(columnName),
      'hlc': serializer.toJson<String>(hlc),
      'siteId': serializer.toJson<String>(siteId),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SyncColumnVersion copyWith({
    String? tableNameCol,
    String? rowId,
    String? columnName,
    String? hlc,
    String? siteId,
    String? updatedAt,
  }) => SyncColumnVersion(
    tableNameCol: tableNameCol ?? this.tableNameCol,
    rowId: rowId ?? this.rowId,
    columnName: columnName ?? this.columnName,
    hlc: hlc ?? this.hlc,
    siteId: siteId ?? this.siteId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncColumnVersion copyWithCompanion(SyncColumnVersionsCompanion data) {
    return SyncColumnVersion(
      tableNameCol: data.tableNameCol.present
          ? data.tableNameCol.value
          : this.tableNameCol,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      columnName: data.columnName.present
          ? data.columnName.value
          : this.columnName,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncColumnVersion(')
          ..write('tableNameCol: $tableNameCol, ')
          ..write('rowId: $rowId, ')
          ..write('columnName: $columnName, ')
          ..write('hlc: $hlc, ')
          ..write('siteId: $siteId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(tableNameCol, rowId, columnName, hlc, siteId, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncColumnVersion &&
          other.tableNameCol == this.tableNameCol &&
          other.rowId == this.rowId &&
          other.columnName == this.columnName &&
          other.hlc == this.hlc &&
          other.siteId == this.siteId &&
          other.updatedAt == this.updatedAt);
}

class SyncColumnVersionsCompanion extends UpdateCompanion<SyncColumnVersion> {
  final Value<String> tableNameCol;
  final Value<String> rowId;
  final Value<String> columnName;
  final Value<String> hlc;
  final Value<String> siteId;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SyncColumnVersionsCompanion({
    this.tableNameCol = const Value.absent(),
    this.rowId = const Value.absent(),
    this.columnName = const Value.absent(),
    this.hlc = const Value.absent(),
    this.siteId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncColumnVersionsCompanion.insert({
    required String tableNameCol,
    required String rowId,
    required String columnName,
    required String hlc,
    required String siteId,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : tableNameCol = Value(tableNameCol),
       rowId = Value(rowId),
       columnName = Value(columnName),
       hlc = Value(hlc),
       siteId = Value(siteId),
       updatedAt = Value(updatedAt);
  static Insertable<SyncColumnVersion> custom({
    Expression<String>? tableNameCol,
    Expression<String>? rowId,
    Expression<String>? columnName,
    Expression<String>? hlc,
    Expression<String>? siteId,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tableNameCol != null) 'table_name': tableNameCol,
      if (rowId != null) 'row_id': rowId,
      if (columnName != null) 'column_name': columnName,
      if (hlc != null) 'hlc': hlc,
      if (siteId != null) 'site_id': siteId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncColumnVersionsCompanion copyWith({
    Value<String>? tableNameCol,
    Value<String>? rowId,
    Value<String>? columnName,
    Value<String>? hlc,
    Value<String>? siteId,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncColumnVersionsCompanion(
      tableNameCol: tableNameCol ?? this.tableNameCol,
      rowId: rowId ?? this.rowId,
      columnName: columnName ?? this.columnName,
      hlc: hlc ?? this.hlc,
      siteId: siteId ?? this.siteId,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tableNameCol.present) {
      map['table_name'] = Variable<String>(tableNameCol.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (columnName.present) {
      map['column_name'] = Variable<String>(columnName.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncColumnVersionsCompanion(')
          ..write('tableNameCol: $tableNameCol, ')
          ..write('rowId: $rowId, ')
          ..write('columnName: $columnName, ')
          ..write('hlc: $hlc, ')
          ..write('siteId: $siteId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncRowTombstonesTable extends SyncRowTombstones
    with TableInfo<$SyncRowTombstonesTable, SyncRowTombstone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRowTombstonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tableNameColMeta = const VerificationMeta(
    'tableNameCol',
  );
  @override
  late final GeneratedColumn<String> tableNameCol = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowIdMeta = const VerificationMeta('rowId');
  @override
  late final GeneratedColumn<String> rowId = GeneratedColumn<String>(
    'row_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purgedAtMeta = const VerificationMeta(
    'purgedAt',
  );
  @override
  late final GeneratedColumn<String> purgedAt = GeneratedColumn<String>(
    'purged_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    tableNameCol,
    rowId,
    hlc,
    purgedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_row_tombstones';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRowTombstone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _tableNameColMeta,
        tableNameCol.isAcceptableOrUnknown(
          data['table_name']!,
          _tableNameColMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tableNameColMeta);
    }
    if (data.containsKey('row_id')) {
      context.handle(
        _rowIdMeta,
        rowId.isAcceptableOrUnknown(data['row_id']!, _rowIdMeta),
      );
    } else if (isInserting) {
      context.missing(_rowIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('purged_at')) {
      context.handle(
        _purgedAtMeta,
        purgedAt.isAcceptableOrUnknown(data['purged_at']!, _purgedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_purgedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {tableNameCol, rowId},
  ];
  @override
  SyncRowTombstone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRowTombstone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      tableNameCol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      rowId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}row_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      purgedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purged_at'],
      )!,
    );
  }

  @override
  $SyncRowTombstonesTable createAlias(String alias) {
    return $SyncRowTombstonesTable(attachedDatabase, alias);
  }
}

class SyncRowTombstone extends DataClass
    implements Insertable<SyncRowTombstone> {
  /// Unique tombstone identifier.
  final String id;

  /// Nome da tabela da linha purgada.
  final String tableNameCol;

  /// Identificador da linha purgada.
  final String rowId;

  /// HLC do momento do expurgo.
  final String hlc;

  /// Data do expurgo (ISO-8601 UTC).
  final String purgedAt;
  const SyncRowTombstone({
    required this.id,
    required this.tableNameCol,
    required this.rowId,
    required this.hlc,
    required this.purgedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['table_name'] = Variable<String>(tableNameCol);
    map['row_id'] = Variable<String>(rowId);
    map['hlc'] = Variable<String>(hlc);
    map['purged_at'] = Variable<String>(purgedAt);
    return map;
  }

  SyncRowTombstonesCompanion toCompanion(bool nullToAbsent) {
    return SyncRowTombstonesCompanion(
      id: Value(id),
      tableNameCol: Value(tableNameCol),
      rowId: Value(rowId),
      hlc: Value(hlc),
      purgedAt: Value(purgedAt),
    );
  }

  factory SyncRowTombstone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRowTombstone(
      id: serializer.fromJson<String>(json['id']),
      tableNameCol: serializer.fromJson<String>(json['tableNameCol']),
      rowId: serializer.fromJson<String>(json['rowId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      purgedAt: serializer.fromJson<String>(json['purgedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'tableNameCol': serializer.toJson<String>(tableNameCol),
      'rowId': serializer.toJson<String>(rowId),
      'hlc': serializer.toJson<String>(hlc),
      'purgedAt': serializer.toJson<String>(purgedAt),
    };
  }

  SyncRowTombstone copyWith({
    String? id,
    String? tableNameCol,
    String? rowId,
    String? hlc,
    String? purgedAt,
  }) => SyncRowTombstone(
    id: id ?? this.id,
    tableNameCol: tableNameCol ?? this.tableNameCol,
    rowId: rowId ?? this.rowId,
    hlc: hlc ?? this.hlc,
    purgedAt: purgedAt ?? this.purgedAt,
  );
  SyncRowTombstone copyWithCompanion(SyncRowTombstonesCompanion data) {
    return SyncRowTombstone(
      id: data.id.present ? data.id.value : this.id,
      tableNameCol: data.tableNameCol.present
          ? data.tableNameCol.value
          : this.tableNameCol,
      rowId: data.rowId.present ? data.rowId.value : this.rowId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      purgedAt: data.purgedAt.present ? data.purgedAt.value : this.purgedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRowTombstone(')
          ..write('id: $id, ')
          ..write('tableNameCol: $tableNameCol, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('purgedAt: $purgedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, tableNameCol, rowId, hlc, purgedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRowTombstone &&
          other.id == this.id &&
          other.tableNameCol == this.tableNameCol &&
          other.rowId == this.rowId &&
          other.hlc == this.hlc &&
          other.purgedAt == this.purgedAt);
}

class SyncRowTombstonesCompanion extends UpdateCompanion<SyncRowTombstone> {
  final Value<String> id;
  final Value<String> tableNameCol;
  final Value<String> rowId;
  final Value<String> hlc;
  final Value<String> purgedAt;
  final Value<int> rowid;
  const SyncRowTombstonesCompanion({
    this.id = const Value.absent(),
    this.tableNameCol = const Value.absent(),
    this.rowId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.purgedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRowTombstonesCompanion.insert({
    required String id,
    required String tableNameCol,
    required String rowId,
    required String hlc,
    required String purgedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       tableNameCol = Value(tableNameCol),
       rowId = Value(rowId),
       hlc = Value(hlc),
       purgedAt = Value(purgedAt);
  static Insertable<SyncRowTombstone> custom({
    Expression<String>? id,
    Expression<String>? tableNameCol,
    Expression<String>? rowId,
    Expression<String>? hlc,
    Expression<String>? purgedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tableNameCol != null) 'table_name': tableNameCol,
      if (rowId != null) 'row_id': rowId,
      if (hlc != null) 'hlc': hlc,
      if (purgedAt != null) 'purged_at': purgedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRowTombstonesCompanion copyWith({
    Value<String>? id,
    Value<String>? tableNameCol,
    Value<String>? rowId,
    Value<String>? hlc,
    Value<String>? purgedAt,
    Value<int>? rowid,
  }) {
    return SyncRowTombstonesCompanion(
      id: id ?? this.id,
      tableNameCol: tableNameCol ?? this.tableNameCol,
      rowId: rowId ?? this.rowId,
      hlc: hlc ?? this.hlc,
      purgedAt: purgedAt ?? this.purgedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (tableNameCol.present) {
      map['table_name'] = Variable<String>(tableNameCol.value);
    }
    if (rowId.present) {
      map['row_id'] = Variable<String>(rowId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (purgedAt.present) {
      map['purged_at'] = Variable<String>(purgedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRowTombstonesCompanion(')
          ..write('id: $id, ')
          ..write('tableNameCol: $tableNameCol, ')
          ..write('rowId: $rowId, ')
          ..write('hlc: $hlc, ')
          ..write('purgedAt: $purgedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncPeerVectorsTable extends SyncPeerVectors
    with TableInfo<$SyncPeerVectorsTable, SyncPeerVector> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPeerVectorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteIdMeta = const VerificationMeta('siteId');
  @override
  late final GeneratedColumn<String> siteId = GeneratedColumn<String>(
    'site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [householdId, siteId, hlc, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_peer_vectors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPeerVector> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('site_id')) {
      context.handle(
        _siteIdMeta,
        siteId.isAcceptableOrUnknown(data['site_id']!, _siteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_siteIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {householdId, siteId};
  @override
  SyncPeerVector map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPeerVector(
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      siteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}site_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncPeerVectorsTable createAlias(String alias) {
    return $SyncPeerVectorsTable(attachedDatabase, alias);
  }
}

class SyncPeerVector extends DataClass implements Insertable<SyncPeerVector> {
  /// Identificador da casa.
  final String householdId;

  /// Identificador do aparelho remoto.
  final String siteId;

  /// Maior HLC conhecido desse aparelho.
  final String hlc;

  /// Last update date of this vector (ISO-8601 UTC).
  final String updatedAt;
  const SyncPeerVector({
    required this.householdId,
    required this.siteId,
    required this.hlc,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['household_id'] = Variable<String>(householdId);
    map['site_id'] = Variable<String>(siteId);
    map['hlc'] = Variable<String>(hlc);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SyncPeerVectorsCompanion toCompanion(bool nullToAbsent) {
    return SyncPeerVectorsCompanion(
      householdId: Value(householdId),
      siteId: Value(siteId),
      hlc: Value(hlc),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncPeerVector.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPeerVector(
      householdId: serializer.fromJson<String>(json['householdId']),
      siteId: serializer.fromJson<String>(json['siteId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'householdId': serializer.toJson<String>(householdId),
      'siteId': serializer.toJson<String>(siteId),
      'hlc': serializer.toJson<String>(hlc),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SyncPeerVector copyWith({
    String? householdId,
    String? siteId,
    String? hlc,
    String? updatedAt,
  }) => SyncPeerVector(
    householdId: householdId ?? this.householdId,
    siteId: siteId ?? this.siteId,
    hlc: hlc ?? this.hlc,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncPeerVector copyWithCompanion(SyncPeerVectorsCompanion data) {
    return SyncPeerVector(
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      siteId: data.siteId.present ? data.siteId.value : this.siteId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPeerVector(')
          ..write('householdId: $householdId, ')
          ..write('siteId: $siteId, ')
          ..write('hlc: $hlc, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(householdId, siteId, hlc, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPeerVector &&
          other.householdId == this.householdId &&
          other.siteId == this.siteId &&
          other.hlc == this.hlc &&
          other.updatedAt == this.updatedAt);
}

class SyncPeerVectorsCompanion extends UpdateCompanion<SyncPeerVector> {
  final Value<String> householdId;
  final Value<String> siteId;
  final Value<String> hlc;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SyncPeerVectorsCompanion({
    this.householdId = const Value.absent(),
    this.siteId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPeerVectorsCompanion.insert({
    required String householdId,
    required String siteId,
    required String hlc,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : householdId = Value(householdId),
       siteId = Value(siteId),
       hlc = Value(hlc),
       updatedAt = Value(updatedAt);
  static Insertable<SyncPeerVector> custom({
    Expression<String>? householdId,
    Expression<String>? siteId,
    Expression<String>? hlc,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (householdId != null) 'household_id': householdId,
      if (siteId != null) 'site_id': siteId,
      if (hlc != null) 'hlc': hlc,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPeerVectorsCompanion copyWith({
    Value<String>? householdId,
    Value<String>? siteId,
    Value<String>? hlc,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncPeerVectorsCompanion(
      householdId: householdId ?? this.householdId,
      siteId: siteId ?? this.siteId,
      hlc: hlc ?? this.hlc,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (siteId.present) {
      map['site_id'] = Variable<String>(siteId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPeerVectorsCompanion(')
          ..write('householdId: $householdId, ')
          ..write('siteId: $siteId, ')
          ..write('hlc: $hlc, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncMemberAcksTable extends SyncMemberAcks
    with TableInfo<$SyncMemberAcksTable, SyncMemberAck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMemberAcksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberSiteIdMeta = const VerificationMeta(
    'memberSiteId',
  );
  @override
  late final GeneratedColumn<String> memberSiteId = GeneratedColumn<String>(
    'member_site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originSiteIdMeta = const VerificationMeta(
    'originSiteId',
  );
  @override
  late final GeneratedColumn<String> originSiteId = GeneratedColumn<String>(
    'origin_site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    householdId,
    memberSiteId,
    originSiteId,
    hlc,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_member_acks';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMemberAck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('member_site_id')) {
      context.handle(
        _memberSiteIdMeta,
        memberSiteId.isAcceptableOrUnknown(
          data['member_site_id']!,
          _memberSiteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_memberSiteIdMeta);
    }
    if (data.containsKey('origin_site_id')) {
      context.handle(
        _originSiteIdMeta,
        originSiteId.isAcceptableOrUnknown(
          data['origin_site_id']!,
          _originSiteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originSiteIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    householdId,
    memberSiteId,
    originSiteId,
  };
  @override
  SyncMemberAck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMemberAck(
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      memberSiteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_site_id'],
      )!,
      originSiteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_site_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SyncMemberAcksTable createAlias(String alias) {
    return $SyncMemberAcksTable(attachedDatabase, alias);
  }
}

class SyncMemberAck extends DataClass implements Insertable<SyncMemberAck> {
  final String householdId;
  final String memberSiteId;
  final String originSiteId;
  final String hlc;
  final String updatedAt;
  const SyncMemberAck({
    required this.householdId,
    required this.memberSiteId,
    required this.originSiteId,
    required this.hlc,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['household_id'] = Variable<String>(householdId);
    map['member_site_id'] = Variable<String>(memberSiteId);
    map['origin_site_id'] = Variable<String>(originSiteId);
    map['hlc'] = Variable<String>(hlc);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  SyncMemberAcksCompanion toCompanion(bool nullToAbsent) {
    return SyncMemberAcksCompanion(
      householdId: Value(householdId),
      memberSiteId: Value(memberSiteId),
      originSiteId: Value(originSiteId),
      hlc: Value(hlc),
      updatedAt: Value(updatedAt),
    );
  }

  factory SyncMemberAck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMemberAck(
      householdId: serializer.fromJson<String>(json['householdId']),
      memberSiteId: serializer.fromJson<String>(json['memberSiteId']),
      originSiteId: serializer.fromJson<String>(json['originSiteId']),
      hlc: serializer.fromJson<String>(json['hlc']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'householdId': serializer.toJson<String>(householdId),
      'memberSiteId': serializer.toJson<String>(memberSiteId),
      'originSiteId': serializer.toJson<String>(originSiteId),
      'hlc': serializer.toJson<String>(hlc),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  SyncMemberAck copyWith({
    String? householdId,
    String? memberSiteId,
    String? originSiteId,
    String? hlc,
    String? updatedAt,
  }) => SyncMemberAck(
    householdId: householdId ?? this.householdId,
    memberSiteId: memberSiteId ?? this.memberSiteId,
    originSiteId: originSiteId ?? this.originSiteId,
    hlc: hlc ?? this.hlc,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SyncMemberAck copyWithCompanion(SyncMemberAcksCompanion data) {
    return SyncMemberAck(
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      memberSiteId: data.memberSiteId.present
          ? data.memberSiteId.value
          : this.memberSiteId,
      originSiteId: data.originSiteId.present
          ? data.originSiteId.value
          : this.originSiteId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMemberAck(')
          ..write('householdId: $householdId, ')
          ..write('memberSiteId: $memberSiteId, ')
          ..write('originSiteId: $originSiteId, ')
          ..write('hlc: $hlc, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(householdId, memberSiteId, originSiteId, hlc, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMemberAck &&
          other.householdId == this.householdId &&
          other.memberSiteId == this.memberSiteId &&
          other.originSiteId == this.originSiteId &&
          other.hlc == this.hlc &&
          other.updatedAt == this.updatedAt);
}

class SyncMemberAcksCompanion extends UpdateCompanion<SyncMemberAck> {
  final Value<String> householdId;
  final Value<String> memberSiteId;
  final Value<String> originSiteId;
  final Value<String> hlc;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const SyncMemberAcksCompanion({
    this.householdId = const Value.absent(),
    this.memberSiteId = const Value.absent(),
    this.originSiteId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMemberAcksCompanion.insert({
    required String householdId,
    required String memberSiteId,
    required String originSiteId,
    required String hlc,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : householdId = Value(householdId),
       memberSiteId = Value(memberSiteId),
       originSiteId = Value(originSiteId),
       hlc = Value(hlc),
       updatedAt = Value(updatedAt);
  static Insertable<SyncMemberAck> custom({
    Expression<String>? householdId,
    Expression<String>? memberSiteId,
    Expression<String>? originSiteId,
    Expression<String>? hlc,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (householdId != null) 'household_id': householdId,
      if (memberSiteId != null) 'member_site_id': memberSiteId,
      if (originSiteId != null) 'origin_site_id': originSiteId,
      if (hlc != null) 'hlc': hlc,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMemberAcksCompanion copyWith({
    Value<String>? householdId,
    Value<String>? memberSiteId,
    Value<String>? originSiteId,
    Value<String>? hlc,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return SyncMemberAcksCompanion(
      householdId: householdId ?? this.householdId,
      memberSiteId: memberSiteId ?? this.memberSiteId,
      originSiteId: originSiteId ?? this.originSiteId,
      hlc: hlc ?? this.hlc,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (memberSiteId.present) {
      map['member_site_id'] = Variable<String>(memberSiteId.value);
    }
    if (originSiteId.present) {
      map['origin_site_id'] = Variable<String>(originSiteId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMemberAcksCompanion(')
          ..write('householdId: $householdId, ')
          ..write('memberSiteId: $memberSiteId, ')
          ..write('originSiteId: $originSiteId, ')
          ..write('hlc: $hlc, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncAppliedBundlesTable extends SyncAppliedBundles
    with TableInfo<$SyncAppliedBundlesTable, SyncAppliedBundle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncAppliedBundlesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _digestMeta = const VerificationMeta('digest');
  @override
  late final GeneratedColumn<String> digest = GeneratedColumn<String>(
    'digest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _appliedAtMeta = const VerificationMeta(
    'appliedAt',
  );
  @override
  late final GeneratedColumn<String> appliedAt = GeneratedColumn<String>(
    'applied_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [digest, appliedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_applied_bundles';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncAppliedBundle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('digest')) {
      context.handle(
        _digestMeta,
        digest.isAcceptableOrUnknown(data['digest']!, _digestMeta),
      );
    } else if (isInserting) {
      context.missing(_digestMeta);
    }
    if (data.containsKey('applied_at')) {
      context.handle(
        _appliedAtMeta,
        appliedAt.isAcceptableOrUnknown(data['applied_at']!, _appliedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {digest};
  @override
  SyncAppliedBundle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncAppliedBundle(
      digest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}digest'],
      )!,
      appliedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}applied_at'],
      )!,
    );
  }

  @override
  $SyncAppliedBundlesTable createAlias(String alias) {
    return $SyncAppliedBundlesTable(attachedDatabase, alias);
  }
}

class SyncAppliedBundle extends DataClass
    implements Insertable<SyncAppliedBundle> {
  final String digest;
  final String appliedAt;
  const SyncAppliedBundle({required this.digest, required this.appliedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['digest'] = Variable<String>(digest);
    map['applied_at'] = Variable<String>(appliedAt);
    return map;
  }

  SyncAppliedBundlesCompanion toCompanion(bool nullToAbsent) {
    return SyncAppliedBundlesCompanion(
      digest: Value(digest),
      appliedAt: Value(appliedAt),
    );
  }

  factory SyncAppliedBundle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncAppliedBundle(
      digest: serializer.fromJson<String>(json['digest']),
      appliedAt: serializer.fromJson<String>(json['appliedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'digest': serializer.toJson<String>(digest),
      'appliedAt': serializer.toJson<String>(appliedAt),
    };
  }

  SyncAppliedBundle copyWith({String? digest, String? appliedAt}) =>
      SyncAppliedBundle(
        digest: digest ?? this.digest,
        appliedAt: appliedAt ?? this.appliedAt,
      );
  SyncAppliedBundle copyWithCompanion(SyncAppliedBundlesCompanion data) {
    return SyncAppliedBundle(
      digest: data.digest.present ? data.digest.value : this.digest,
      appliedAt: data.appliedAt.present ? data.appliedAt.value : this.appliedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncAppliedBundle(')
          ..write('digest: $digest, ')
          ..write('appliedAt: $appliedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(digest, appliedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncAppliedBundle &&
          other.digest == this.digest &&
          other.appliedAt == this.appliedAt);
}

class SyncAppliedBundlesCompanion extends UpdateCompanion<SyncAppliedBundle> {
  final Value<String> digest;
  final Value<String> appliedAt;
  final Value<int> rowid;
  const SyncAppliedBundlesCompanion({
    this.digest = const Value.absent(),
    this.appliedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncAppliedBundlesCompanion.insert({
    required String digest,
    required String appliedAt,
    this.rowid = const Value.absent(),
  }) : digest = Value(digest),
       appliedAt = Value(appliedAt);
  static Insertable<SyncAppliedBundle> custom({
    Expression<String>? digest,
    Expression<String>? appliedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (digest != null) 'digest': digest,
      if (appliedAt != null) 'applied_at': appliedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncAppliedBundlesCompanion copyWith({
    Value<String>? digest,
    Value<String>? appliedAt,
    Value<int>? rowid,
  }) {
    return SyncAppliedBundlesCompanion(
      digest: digest ?? this.digest,
      appliedAt: appliedAt ?? this.appliedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (digest.present) {
      map['digest'] = Variable<String>(digest.value);
    }
    if (appliedAt.present) {
      map['applied_at'] = Variable<String>(appliedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncAppliedBundlesCompanion(')
          ..write('digest: $digest, ')
          ..write('appliedAt: $appliedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncCompactionHorizonTable extends SyncCompactionHorizon
    with TableInfo<$SyncCompactionHorizonTable, SyncCompactionHorizonData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCompactionHorizonTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _householdIdMeta = const VerificationMeta(
    'householdId',
  );
  @override
  late final GeneratedColumn<String> householdId = GeneratedColumn<String>(
    'household_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originSiteIdMeta = const VerificationMeta(
    'originSiteId',
  );
  @override
  late final GeneratedColumn<String> originSiteId = GeneratedColumn<String>(
    'origin_site_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hlcMeta = const VerificationMeta('hlc');
  @override
  late final GeneratedColumn<String> hlc = GeneratedColumn<String>(
    'hlc',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [householdId, originSiteId, hlc];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_compaction_horizon';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCompactionHorizonData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('household_id')) {
      context.handle(
        _householdIdMeta,
        householdId.isAcceptableOrUnknown(
          data['household_id']!,
          _householdIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_householdIdMeta);
    }
    if (data.containsKey('origin_site_id')) {
      context.handle(
        _originSiteIdMeta,
        originSiteId.isAcceptableOrUnknown(
          data['origin_site_id']!,
          _originSiteIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originSiteIdMeta);
    }
    if (data.containsKey('hlc')) {
      context.handle(
        _hlcMeta,
        hlc.isAcceptableOrUnknown(data['hlc']!, _hlcMeta),
      );
    } else if (isInserting) {
      context.missing(_hlcMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {householdId, originSiteId};
  @override
  SyncCompactionHorizonData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCompactionHorizonData(
      householdId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}household_id'],
      )!,
      originSiteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_site_id'],
      )!,
      hlc: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hlc'],
      )!,
    );
  }

  @override
  $SyncCompactionHorizonTable createAlias(String alias) {
    return $SyncCompactionHorizonTable(attachedDatabase, alias);
  }
}

class SyncCompactionHorizonData extends DataClass
    implements Insertable<SyncCompactionHorizonData> {
  final String householdId;
  final String originSiteId;
  final String hlc;
  const SyncCompactionHorizonData({
    required this.householdId,
    required this.originSiteId,
    required this.hlc,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['household_id'] = Variable<String>(householdId);
    map['origin_site_id'] = Variable<String>(originSiteId);
    map['hlc'] = Variable<String>(hlc);
    return map;
  }

  SyncCompactionHorizonCompanion toCompanion(bool nullToAbsent) {
    return SyncCompactionHorizonCompanion(
      householdId: Value(householdId),
      originSiteId: Value(originSiteId),
      hlc: Value(hlc),
    );
  }

  factory SyncCompactionHorizonData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCompactionHorizonData(
      householdId: serializer.fromJson<String>(json['householdId']),
      originSiteId: serializer.fromJson<String>(json['originSiteId']),
      hlc: serializer.fromJson<String>(json['hlc']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'householdId': serializer.toJson<String>(householdId),
      'originSiteId': serializer.toJson<String>(originSiteId),
      'hlc': serializer.toJson<String>(hlc),
    };
  }

  SyncCompactionHorizonData copyWith({
    String? householdId,
    String? originSiteId,
    String? hlc,
  }) => SyncCompactionHorizonData(
    householdId: householdId ?? this.householdId,
    originSiteId: originSiteId ?? this.originSiteId,
    hlc: hlc ?? this.hlc,
  );
  SyncCompactionHorizonData copyWithCompanion(
    SyncCompactionHorizonCompanion data,
  ) {
    return SyncCompactionHorizonData(
      householdId: data.householdId.present
          ? data.householdId.value
          : this.householdId,
      originSiteId: data.originSiteId.present
          ? data.originSiteId.value
          : this.originSiteId,
      hlc: data.hlc.present ? data.hlc.value : this.hlc,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCompactionHorizonData(')
          ..write('householdId: $householdId, ')
          ..write('originSiteId: $originSiteId, ')
          ..write('hlc: $hlc')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(householdId, originSiteId, hlc);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCompactionHorizonData &&
          other.householdId == this.householdId &&
          other.originSiteId == this.originSiteId &&
          other.hlc == this.hlc);
}

class SyncCompactionHorizonCompanion
    extends UpdateCompanion<SyncCompactionHorizonData> {
  final Value<String> householdId;
  final Value<String> originSiteId;
  final Value<String> hlc;
  final Value<int> rowid;
  const SyncCompactionHorizonCompanion({
    this.householdId = const Value.absent(),
    this.originSiteId = const Value.absent(),
    this.hlc = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCompactionHorizonCompanion.insert({
    required String householdId,
    required String originSiteId,
    required String hlc,
    this.rowid = const Value.absent(),
  }) : householdId = Value(householdId),
       originSiteId = Value(originSiteId),
       hlc = Value(hlc);
  static Insertable<SyncCompactionHorizonData> custom({
    Expression<String>? householdId,
    Expression<String>? originSiteId,
    Expression<String>? hlc,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (householdId != null) 'household_id': householdId,
      if (originSiteId != null) 'origin_site_id': originSiteId,
      if (hlc != null) 'hlc': hlc,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCompactionHorizonCompanion copyWith({
    Value<String>? householdId,
    Value<String>? originSiteId,
    Value<String>? hlc,
    Value<int>? rowid,
  }) {
    return SyncCompactionHorizonCompanion(
      householdId: householdId ?? this.householdId,
      originSiteId: originSiteId ?? this.originSiteId,
      hlc: hlc ?? this.hlc,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (householdId.present) {
      map['household_id'] = Variable<String>(householdId.value);
    }
    if (originSiteId.present) {
      map['origin_site_id'] = Variable<String>(originSiteId.value);
    }
    if (hlc.present) {
      map['hlc'] = Variable<String>(hlc.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCompactionHorizonCompanion(')
          ..write('householdId: $householdId, ')
          ..write('originSiteId: $originSiteId, ')
          ..write('hlc: $hlc, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ProductsTable products = $ProductsTable(this);
  late final $ProductAliasesTable productAliases = $ProductAliasesTable(this);
  late final $ProductDenialsTable productDenials = $ProductDenialsTable(this);
  late final $StoresTable stores = $StoresTable(this);
  late final $RecurringRulesTable recurringRules = $RecurringRulesTable(this);
  late final $BillsTable bills = $BillsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $PurchasesTable purchases = $PurchasesTable(this);
  late final $PurchaseItemsTable purchaseItems = $PurchaseItemsTable(this);
  late final $PricePointsTable pricePoints = $PricePointsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $BillPaymentsTable billPayments = $BillPaymentsTable(this);
  late final $ShoppingListsTable shoppingLists = $ShoppingListsTable(this);
  late final $ShoppingItemsTable shoppingItems = $ShoppingItemsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $RecipesTable recipes = $RecipesTable(this);
  late final $RecipeIngredientsTable recipeIngredients =
      $RecipeIngredientsTable(this);
  late final $RecipeTagsTable recipeTags = $RecipeTagsTable(this);
  late final $StockItemsTable stockItems = $StockItemsTable(this);
  late final $ChecklistItemsTable checklistItems = $ChecklistItemsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $ConsentsTable consents = $ConsentsTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $SyncHouseholdsTable syncHouseholds = $SyncHouseholdsTable(this);
  late final $SyncMembersTable syncMembers = $SyncMembersTable(this);
  late final $SyncColumnVersionsTable syncColumnVersions =
      $SyncColumnVersionsTable(this);
  late final $SyncRowTombstonesTable syncRowTombstones =
      $SyncRowTombstonesTable(this);
  late final $SyncPeerVectorsTable syncPeerVectors = $SyncPeerVectorsTable(
    this,
  );
  late final $SyncMemberAcksTable syncMemberAcks = $SyncMemberAcksTable(this);
  late final $SyncAppliedBundlesTable syncAppliedBundles =
      $SyncAppliedBundlesTable(this);
  late final $SyncCompactionHorizonTable syncCompactionHorizon =
      $SyncCompactionHorizonTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    products,
    productAliases,
    productDenials,
    stores,
    recurringRules,
    bills,
    expenses,
    purchases,
    purchaseItems,
    pricePoints,
    budgets,
    billPayments,
    shoppingLists,
    shoppingItems,
    tasks,
    recipes,
    recipeIngredients,
    recipeTags,
    stockItems,
    checklistItems,
    settings,
    consents,
    attachments,
    syncHouseholds,
    syncMembers,
    syncColumnVersions,
    syncRowTombstones,
    syncPeerVectors,
    syncMemberAcks,
    syncAppliedBundles,
    syncCompactionHorizon,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('product_aliases', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('product_denials', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'purchases',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('purchase_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'shopping_lists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('shopping_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stock_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sync_household',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sync_members', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String id,
  required String name,
  required String kind,
  required String iconKey,
  Value<String?> colorHex,
  Value<bool> isSystem,
  Value<int?> sortOrder,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> kind,
  Value<String> iconKey,
  Value<String?> colorHex,
  Value<bool> isSystem,
  Value<int?> sortOrder,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ProductsTable, List<Product>> _productsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.products,
    aliasName: 'categories__id__products__category_id',
  );

  $$ProductsTableProcessedTableManager get productsRefs {
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillsTable, List<Bill>> _billsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.bills,
    aliasName: 'categories__id__bills__category_id',
  );

  $$BillsTableProcessedTableManager get billsRefs {
    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'categories__id__expenses__category_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'categories__id__budgets__category_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'categories__id__tasks__category_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsRefs(
    Expression<bool> Function($$ProductsTableFilterComposer f) f,
  ) {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billsRefs(
    Expression<bool> Function($$BillsTableFilterComposer f) f,
  ) {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconKey => $composableBuilder(
    column: $table.iconKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSystem => $composableBuilder(
    column: $table.isSystem,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
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

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<bool> get isSystem =>
      $composableBuilder(column: $table.isSystem, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> productsRefs<T extends Object>(
    Expression<T> Function($$ProductsTableAnnotationComposer a) f,
  ) {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billsRefs<T extends Object>(
    Expression<T> Function($$BillsTableAnnotationComposer a) f,
  ) {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool productsRefs,
            bool billsRefs,
            bool expensesRefs,
            bool budgetsRefs,
            bool tasksRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> iconKey = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                kind: kind,
                iconKey: iconKey,
                colorHex: colorHex,
                isSystem: isSystem,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String kind,
                required String iconKey,
                Value<String?> colorHex = const Value.absent(),
                Value<bool> isSystem = const Value.absent(),
                Value<int?> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                kind: kind,
                iconKey: iconKey,
                colorHex: colorHex,
                isSystem: isSystem,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                productsRefs = false,
                billsRefs = false,
                expensesRefs = false,
                budgetsRefs = false,
                tasksRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productsRefs) db.products,
                    if (billsRefs) db.bills,
                    if (expensesRefs) db.expenses,
                    if (budgetsRefs) db.budgets,
                    if (tasksRefs) db.tasks,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Product
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._productsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).productsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (billsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Bill
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._billsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).billsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Budget
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (tasksRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Task
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).tasksRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
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

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({
        bool productsRefs,
        bool billsRefs,
        bool expensesRefs,
        bool budgetsRefs,
        bool tasksRefs,
      })
    >;
typedef $$ProductsTableCreateCompanionBuilder = ProductsCompanion Function({
  required String id,
  required String canonicalName,
  Value<String?> categoryId,
  required String defaultUnit,
  Value<int?> packageSizeMilli,
  Value<bool> isArchived,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$ProductsTableUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String> id,
  Value<String> canonicalName,
  Value<String?> categoryId,
  Value<String> defaultUnit,
  Value<int?> packageSizeMilli,
  Value<bool> isArchived,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});

final class $$ProductsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductsTable, Product> {
  $$ProductsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('products__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ProductAliasesTable, List<ProductAliase>>
  _productAliasesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productAliases,
    aliasName: 'products__id__product_aliases__product_id',
  );

  $$ProductAliasesTableProcessedTableManager get productAliasesRefs {
    final manager = $$ProductAliasesTableTableManager(
      $_db,
      $_db.productAliases,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productAliasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProductDenialsTable, List<ProductDenial>>
  _productDenialsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.productDenials,
    aliasName: 'products__id__product_denials__product_id',
  );

  $$ProductDenialsTableProcessedTableManager get productDenialsRefs {
    final manager = $$ProductDenialsTableTableManager(
      $_db,
      $_db.productDenials,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_productDenialsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PurchaseItemsTable, List<PurchaseItem>>
  _purchaseItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.purchaseItems,
    aliasName: 'products__id__purchase_items__product_id',
  );

  $$PurchaseItemsTableProcessedTableManager get purchaseItemsRefs {
    final manager = $$PurchaseItemsTableTableManager(
      $_db,
      $_db.purchaseItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchaseItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PricePointsTable, List<PricePoint>>
  _pricePointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pricePoints,
    aliasName: 'products__id__price_points__product_id',
  );

  $$PricePointsTableProcessedTableManager get pricePointsRefs {
    final manager = $$PricePointsTableTableManager(
      $_db,
      $_db.pricePoints,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pricePointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShoppingItemsTable, List<ShoppingItem>>
  _shoppingItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shoppingItems,
    aliasName: 'products__id__shopping_items__product_id',
  );

  $$ShoppingItemsTableProcessedTableManager get shoppingItemsRefs {
    final manager = $$ShoppingItemsTableTableManager(
      $_db,
      $_db.shoppingItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shoppingItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RecipeIngredientsTable, List<RecipeIngredient>>
  _recipeIngredientsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recipeIngredients,
        aliasName: 'products__id__recipe_ingredients__product_id',
      );

  $$RecipeIngredientsTableProcessedTableManager get recipeIngredientsRefs {
    final manager = $$RecipeIngredientsTableTableManager(
      $_db,
      $_db.recipeIngredients,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recipeIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StockItemsTable, List<StockItem>>
  _stockItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.stockItems,
    aliasName: 'products__id__stock_items__product_id',
  );

  $$StockItemsTableProcessedTableManager get stockItemsRefs {
    final manager = $$StockItemsTableTableManager(
      $_db,
      $_db.stockItems,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_stockItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
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

  ColumnFilters<String> get canonicalName => $composableBuilder(
    column: $table.canonicalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get packageSizeMilli => $composableBuilder(
    column: $table.packageSizeMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> productAliasesRefs(
    Expression<bool> Function($$ProductAliasesTableFilterComposer f) f,
  ) {
    final $$ProductAliasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productAliases,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductAliasesTableFilterComposer(
            $db: $db,
            $table: $db.productAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> productDenialsRefs(
    Expression<bool> Function($$ProductDenialsTableFilterComposer f) f,
  ) {
    final $$ProductDenialsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productDenials,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductDenialsTableFilterComposer(
            $db: $db,
            $table: $db.productDenials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> purchaseItemsRefs(
    Expression<bool> Function($$PurchaseItemsTableFilterComposer f) f,
  ) {
    final $$PurchaseItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseItemsTableFilterComposer(
            $db: $db,
            $table: $db.purchaseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pricePointsRefs(
    Expression<bool> Function($$PricePointsTableFilterComposer f) f,
  ) {
    final $$PricePointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pricePoints,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PricePointsTableFilterComposer(
            $db: $db,
            $table: $db.pricePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shoppingItemsRefs(
    Expression<bool> Function($$ShoppingItemsTableFilterComposer f) f,
  ) {
    final $$ShoppingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeIngredientsRefs(
    Expression<bool> Function($$RecipeIngredientsTableFilterComposer f) f,
  ) {
    final $$RecipeIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeIngredients,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.recipeIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> stockItemsRefs(
    Expression<bool> Function($$StockItemsTableFilterComposer f) f,
  ) {
    final $$StockItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockItemsTableFilterComposer(
            $db: $db,
            $table: $db.stockItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
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

  ColumnOrderings<String> get canonicalName => $composableBuilder(
    column: $table.canonicalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get packageSizeMilli => $composableBuilder(
    column: $table.packageSizeMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get canonicalName => $composableBuilder(
    column: $table.canonicalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultUnit => $composableBuilder(
    column: $table.defaultUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get packageSizeMilli => $composableBuilder(
    column: $table.packageSizeMilli,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> productAliasesRefs<T extends Object>(
    Expression<T> Function($$ProductAliasesTableAnnotationComposer a) f,
  ) {
    final $$ProductAliasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productAliases,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductAliasesTableAnnotationComposer(
            $db: $db,
            $table: $db.productAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> productDenialsRefs<T extends Object>(
    Expression<T> Function($$ProductDenialsTableAnnotationComposer a) f,
  ) {
    final $$ProductDenialsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productDenials,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductDenialsTableAnnotationComposer(
            $db: $db,
            $table: $db.productDenials,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> purchaseItemsRefs<T extends Object>(
    Expression<T> Function($$PurchaseItemsTableAnnotationComposer a) f,
  ) {
    final $$PurchaseItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.purchaseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pricePointsRefs<T extends Object>(
    Expression<T> Function($$PricePointsTableAnnotationComposer a) f,
  ) {
    final $$PricePointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pricePoints,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PricePointsTableAnnotationComposer(
            $db: $db,
            $table: $db.pricePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shoppingItemsRefs<T extends Object>(
    Expression<T> Function($$ShoppingItemsTableAnnotationComposer a) f,
  ) {
    final $$ShoppingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeIngredientsRefs<T extends Object>(
    Expression<T> Function($$RecipeIngredientsTableAnnotationComposer a) f,
  ) {
    final $$RecipeIngredientsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recipeIngredients,
          getReferencedColumn: (t) => t.productId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeIngredientsTableAnnotationComposer(
                $db: $db,
                $table: $db.recipeIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> stockItemsRefs<T extends Object>(
    Expression<T> Function($$StockItemsTableAnnotationComposer a) f,
  ) {
    final $$StockItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.stockItems,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StockItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.stockItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, $$ProductsTableReferences),
          Product,
          PrefetchHooks Function({
            bool categoryId,
            bool productAliasesRefs,
            bool productDenialsRefs,
            bool purchaseItemsRefs,
            bool pricePointsRefs,
            bool shoppingItemsRefs,
            bool recipeIngredientsRefs,
            bool stockItemsRefs,
          })
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> canonicalName = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> defaultUnit = const Value.absent(),
                Value<int?> packageSizeMilli = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                canonicalName: canonicalName,
                categoryId: categoryId,
                defaultUnit: defaultUnit,
                packageSizeMilli: packageSizeMilli,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String canonicalName,
                Value<String?> categoryId = const Value.absent(),
                required String defaultUnit,
                Value<int?> packageSizeMilli = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                canonicalName: canonicalName,
                categoryId: categoryId,
                defaultUnit: defaultUnit,
                packageSizeMilli: packageSizeMilli,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductsTable, Product>(table),
                  $$ProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                productAliasesRefs = false,
                productDenialsRefs = false,
                purchaseItemsRefs = false,
                pricePointsRefs = false,
                shoppingItemsRefs = false,
                recipeIngredientsRefs = false,
                stockItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productAliasesRefs) db.productAliases,
                    if (productDenialsRefs) db.productDenials,
                    if (purchaseItemsRefs) db.purchaseItems,
                    if (pricePointsRefs) db.pricePoints,
                    if (shoppingItemsRefs) db.shoppingItems,
                    if (recipeIngredientsRefs) db.recipeIngredients,
                    if (stockItemsRefs) db.stockItems,
                  ],
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
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$ProductsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$ProductsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productAliasesRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          ProductAliase
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._productAliasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).productAliasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (productDenialsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          ProductDenial
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._productDenialsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).productDenialsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (purchaseItemsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          PurchaseItem
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._purchaseItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).purchaseItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pricePointsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          PricePoint
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._pricePointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).pricePointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shoppingItemsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          ShoppingItem
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._shoppingItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).shoppingItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeIngredientsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          RecipeIngredient
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._recipeIngredientsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).recipeIngredientsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (stockItemsRefs)
                        await $_getPrefetchedData<
                          Product,
                          $ProductsTable,
                          StockItem
                        >(
                          currentTable: table,
                          referencedTable: $$ProductsTableReferences
                              ._stockItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ProductsTableReferences(
                                db,
                                table,
                                p0,
                              ).stockItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
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

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, $$ProductsTableReferences),
      Product,
      PrefetchHooks Function({
        bool categoryId,
        bool productAliasesRefs,
        bool productDenialsRefs,
        bool purchaseItemsRefs,
        bool pricePointsRefs,
        bool shoppingItemsRefs,
        bool recipeIngredientsRefs,
        bool stockItemsRefs,
      })
    >;
typedef $$ProductAliasesTableCreateCompanionBuilder =
    ProductAliasesCompanion Function({
      required String id,
      required String productId,
      required String alias,
      required String normalizedAlias,
      required String source,
      Value<String?> createdAt,
      Value<int> rowid,
    });
typedef $$ProductAliasesTableUpdateCompanionBuilder =
    ProductAliasesCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> alias,
      Value<String> normalizedAlias,
      Value<String> source,
      Value<String?> createdAt,
      Value<int> rowid,
    });

final class $$ProductAliasesTableReferences
    extends BaseReferences<_$AppDatabase, $ProductAliasesTable, ProductAliase> {
  $$ProductAliasesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('product_aliases__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductAliasesTableFilterComposer
    extends Composer<_$AppDatabase, $ProductAliasesTable> {
  $$ProductAliasesTableFilterComposer({
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

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductAliasesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductAliasesTable> {
  $$ProductAliasesTableOrderingComposer({
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

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductAliasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductAliasesTable> {
  $$ProductAliasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get normalizedAlias => $composableBuilder(
    column: $table.normalizedAlias,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductAliasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductAliasesTable,
          ProductAliase,
          $$ProductAliasesTableFilterComposer,
          $$ProductAliasesTableOrderingComposer,
          $$ProductAliasesTableAnnotationComposer,
          $$ProductAliasesTableCreateCompanionBuilder,
          $$ProductAliasesTableUpdateCompanionBuilder,
          (ProductAliase, $$ProductAliasesTableReferences),
          ProductAliase,
          PrefetchHooks Function({bool productId})
        > {
  $$ProductAliasesTableTableManager(
    _$AppDatabase db,
    $ProductAliasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductAliasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductAliasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductAliasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<String> normalizedAlias = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductAliasesCompanion(
                id: id,
                productId: productId,
                alias: alias,
                normalizedAlias: normalizedAlias,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String alias,
                required String normalizedAlias,
                required String source,
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductAliasesCompanion.insert(
                id: id,
                productId: productId,
                alias: alias,
                normalizedAlias: normalizedAlias,
                source: source,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductAliasesTable, ProductAliase>(table),
                  $$ProductAliasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
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
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$ProductAliasesTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$ProductAliasesTableReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ProductAliasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductAliasesTable,
      ProductAliase,
      $$ProductAliasesTableFilterComposer,
      $$ProductAliasesTableOrderingComposer,
      $$ProductAliasesTableAnnotationComposer,
      $$ProductAliasesTableCreateCompanionBuilder,
      $$ProductAliasesTableUpdateCompanionBuilder,
      (ProductAliase, $$ProductAliasesTableReferences),
      ProductAliase,
      PrefetchHooks Function({bool productId})
    >;
typedef $$ProductDenialsTableCreateCompanionBuilder =
    ProductDenialsCompanion Function({
      required String id,
      required String productId,
      required String rawText,
      required String normalizedText,
      Value<String?> createdAt,
      Value<int> rowid,
    });
typedef $$ProductDenialsTableUpdateCompanionBuilder =
    ProductDenialsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> rawText,
      Value<String> normalizedText,
      Value<String?> createdAt,
      Value<int> rowid,
    });

final class $$ProductDenialsTableReferences
    extends BaseReferences<_$AppDatabase, $ProductDenialsTable, ProductDenial> {
  $$ProductDenialsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('product_denials__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProductDenialsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductDenialsTable> {
  $$ProductDenialsTableFilterComposer({
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

  ColumnFilters<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductDenialsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductDenialsTable> {
  $$ProductDenialsTableOrderingComposer({
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

  ColumnOrderings<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductDenialsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductDenialsTable> {
  $$ProductDenialsTableAnnotationComposer({
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

  GeneratedColumn<String> get normalizedText => $composableBuilder(
    column: $table.normalizedText,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProductDenialsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductDenialsTable,
          ProductDenial,
          $$ProductDenialsTableFilterComposer,
          $$ProductDenialsTableOrderingComposer,
          $$ProductDenialsTableAnnotationComposer,
          $$ProductDenialsTableCreateCompanionBuilder,
          $$ProductDenialsTableUpdateCompanionBuilder,
          (ProductDenial, $$ProductDenialsTableReferences),
          ProductDenial,
          PrefetchHooks Function({bool productId})
        > {
  $$ProductDenialsTableTableManager(
    _$AppDatabase db,
    $ProductDenialsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductDenialsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductDenialsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductDenialsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<String> normalizedText = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductDenialsCompanion(
                id: id,
                productId: productId,
                rawText: rawText,
                normalizedText: normalizedText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String rawText,
                required String normalizedText,
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductDenialsCompanion.insert(
                id: id,
                productId: productId,
                rawText: rawText,
                normalizedText: normalizedText,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProductDenialsTable, ProductDenial>(table),
                  $$ProductDenialsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
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
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$ProductDenialsTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$ProductDenialsTableReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ProductDenialsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductDenialsTable,
      ProductDenial,
      $$ProductDenialsTableFilterComposer,
      $$ProductDenialsTableOrderingComposer,
      $$ProductDenialsTableAnnotationComposer,
      $$ProductDenialsTableCreateCompanionBuilder,
      $$ProductDenialsTableUpdateCompanionBuilder,
      (ProductDenial, $$ProductDenialsTableReferences),
      ProductDenial,
      PrefetchHooks Function({bool productId})
    >;
typedef $$StoresTableCreateCompanionBuilder = StoresCompanion Function({
  required String id,
  required String name,
  Value<String?> cnpj,
  Value<String?> address,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$StoresTableUpdateCompanionBuilder = StoresCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> cnpj,
  Value<String?> address,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});

final class $$StoresTableReferences
    extends BaseReferences<_$AppDatabase, $StoresTable, Store> {
  $$StoresTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$PurchasesTable, List<Purchase>>
  _purchasesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.purchases,
    aliasName: 'stores__id__purchases__store_id',
  );

  $$PurchasesTableProcessedTableManager get purchasesRefs {
    final manager = $$PurchasesTableTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PricePointsTable, List<PricePoint>>
  _pricePointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pricePoints,
    aliasName: 'stores__id__price_points__store_id',
  );

  $$PricePointsTableProcessedTableManager get pricePointsRefs {
    final manager = $$PricePointsTableTableManager(
      $_db,
      $_db.pricePoints,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pricePointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ShoppingListsTable, List<ShoppingList>>
  _shoppingListsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shoppingLists,
    aliasName: 'stores__id__shopping_lists__store_id',
  );

  $$ShoppingListsTableProcessedTableManager get shoppingListsRefs {
    final manager = $$ShoppingListsTableTableManager(
      $_db,
      $_db.shoppingLists,
    ).filter((f) => f.storeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shoppingListsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoresTableFilterComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableFilterComposer({
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

  ColumnFilters<String> get cnpj => $composableBuilder(
    column: $table.cnpj,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
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

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> purchasesRefs(
    Expression<bool> Function($$PurchasesTableFilterComposer f) f,
  ) {
    final $$PurchasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableFilterComposer(
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

  Expression<bool> pricePointsRefs(
    Expression<bool> Function($$PricePointsTableFilterComposer f) f,
  ) {
    final $$PricePointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pricePoints,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PricePointsTableFilterComposer(
            $db: $db,
            $table: $db.pricePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> shoppingListsRefs(
    Expression<bool> Function($$ShoppingListsTableFilterComposer f) f,
  ) {
    final $$ShoppingListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoresTableOrderingComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableOrderingComposer({
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

  ColumnOrderings<String> get cnpj => $composableBuilder(
    column: $table.cnpj,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
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

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoresTable> {
  $$StoresTableAnnotationComposer({
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

  GeneratedColumn<String> get cnpj =>
      $composableBuilder(column: $table.cnpj, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> purchasesRefs<T extends Object>(
    Expression<T> Function($$PurchasesTableAnnotationComposer a) f,
  ) {
    final $$PurchasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableAnnotationComposer(
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

  Expression<T> pricePointsRefs<T extends Object>(
    Expression<T> Function($$PricePointsTableAnnotationComposer a) f,
  ) {
    final $$PricePointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pricePoints,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PricePointsTableAnnotationComposer(
            $db: $db,
            $table: $db.pricePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> shoppingListsRefs<T extends Object>(
    Expression<T> Function($$ShoppingListsTableAnnotationComposer a) f,
  ) {
    final $$ShoppingListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.storeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoresTable,
          Store,
          $$StoresTableFilterComposer,
          $$StoresTableOrderingComposer,
          $$StoresTableAnnotationComposer,
          $$StoresTableCreateCompanionBuilder,
          $$StoresTableUpdateCompanionBuilder,
          (Store, $$StoresTableReferences),
          Store,
          PrefetchHooks Function({
            bool purchasesRefs,
            bool pricePointsRefs,
            bool shoppingListsRefs,
          })
        > {
  $$StoresTableTableManager(_$AppDatabase db, $StoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> cnpj = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresCompanion(
                id: id,
                name: name,
                cnpj: cnpj,
                address: address,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> cnpj = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoresCompanion.insert(
                id: id,
                name: name,
                cnpj: cnpj,
                address: address,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StoresTable, Store>(table),
                  $$StoresTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                purchasesRefs = false,
                pricePointsRefs = false,
                shoppingListsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (purchasesRefs) db.purchases,
                    if (pricePointsRefs) db.pricePoints,
                    if (shoppingListsRefs) db.shoppingLists,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (purchasesRefs)
                        await $_getPrefetchedData<
                          Store,
                          $StoresTable,
                          Purchase
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableReferences
                              ._purchasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableReferences(
                                db,
                                table,
                                p0,
                              ).purchasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (pricePointsRefs)
                        await $_getPrefetchedData<
                          Store,
                          $StoresTable,
                          PricePoint
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableReferences
                              ._pricePointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableReferences(
                                db,
                                table,
                                p0,
                              ).pricePointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.storeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (shoppingListsRefs)
                        await $_getPrefetchedData<
                          Store,
                          $StoresTable,
                          ShoppingList
                        >(
                          currentTable: table,
                          referencedTable: $$StoresTableReferences
                              ._shoppingListsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StoresTableReferences(
                                db,
                                table,
                                p0,
                              ).shoppingListsRefs,
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

typedef $$StoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoresTable,
      Store,
      $$StoresTableFilterComposer,
      $$StoresTableOrderingComposer,
      $$StoresTableAnnotationComposer,
      $$StoresTableCreateCompanionBuilder,
      $$StoresTableUpdateCompanionBuilder,
      (Store, $$StoresTableReferences),
      Store,
      PrefetchHooks Function({
        bool purchasesRefs,
        bool pricePointsRefs,
        bool shoppingListsRefs,
      })
    >;
typedef $$RecurringRulesTableCreateCompanionBuilder =
    RecurringRulesCompanion Function({
      required String id,
      required String kind,
      required String rrule,
      required String startsOn,
      Value<String?> endsOn,
      Value<int?> amountCents,
      Value<String?> categoryId,
      required String title,
      Value<String?> lastMaterializedOn,
      Value<int> rowid,
    });
typedef $$RecurringRulesTableUpdateCompanionBuilder =
    RecurringRulesCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> rrule,
      Value<String> startsOn,
      Value<String?> endsOn,
      Value<int?> amountCents,
      Value<String?> categoryId,
      Value<String> title,
      Value<String?> lastMaterializedOn,
      Value<int> rowid,
    });

final class $$RecurringRulesTableReferences
    extends BaseReferences<_$AppDatabase, $RecurringRulesTable, RecurringRule> {
  $$RecurringRulesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'recurring_rules__id__expenses__recurring_rule_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager($_db, $_db.expenses).filter(
      (f) => f.recurringRuleId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<Task>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'recurring_rules__id__tasks__recurring_rule_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager($_db, $_db.tasks).filter(
      (f) => f.recurringRuleId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecurringRulesTableFilterComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMaterializedOn => $composableBuilder(
    column: $table.lastMaterializedOn,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.recurringRuleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.recurringRuleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringRulesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rrule => $composableBuilder(
    column: $table.rrule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startsOn => $composableBuilder(
    column: $table.startsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endsOn => $composableBuilder(
    column: $table.endsOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMaterializedOn => $composableBuilder(
    column: $table.lastMaterializedOn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecurringRulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecurringRulesTable> {
  $$RecurringRulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumn<String> get startsOn =>
      $composableBuilder(column: $table.startsOn, builder: (column) => column);

  GeneratedColumn<String> get endsOn =>
      $composableBuilder(column: $table.endsOn, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get lastMaterializedOn => $composableBuilder(
    column: $table.lastMaterializedOn,
    builder: (column) => column,
  );

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.recurringRuleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.recurringRuleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecurringRulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecurringRulesTable,
          RecurringRule,
          $$RecurringRulesTableFilterComposer,
          $$RecurringRulesTableOrderingComposer,
          $$RecurringRulesTableAnnotationComposer,
          $$RecurringRulesTableCreateCompanionBuilder,
          $$RecurringRulesTableUpdateCompanionBuilder,
          (RecurringRule, $$RecurringRulesTableReferences),
          RecurringRule,
          PrefetchHooks Function({bool expensesRefs, bool tasksRefs})
        > {
  $$RecurringRulesTableTableManager(
    _$AppDatabase db,
    $RecurringRulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecurringRulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecurringRulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecurringRulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> rrule = const Value.absent(),
                Value<String> startsOn = const Value.absent(),
                Value<String?> endsOn = const Value.absent(),
                Value<int?> amountCents = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> lastMaterializedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringRulesCompanion(
                id: id,
                kind: kind,
                rrule: rrule,
                startsOn: startsOn,
                endsOn: endsOn,
                amountCents: amountCents,
                categoryId: categoryId,
                title: title,
                lastMaterializedOn: lastMaterializedOn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String rrule,
                required String startsOn,
                Value<String?> endsOn = const Value.absent(),
                Value<int?> amountCents = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required String title,
                Value<String?> lastMaterializedOn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecurringRulesCompanion.insert(
                id: id,
                kind: kind,
                rrule: rrule,
                startsOn: startsOn,
                endsOn: endsOn,
                amountCents: amountCents,
                categoryId: categoryId,
                title: title,
                lastMaterializedOn: lastMaterializedOn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecurringRulesTable, RecurringRule>(table),
                  $$RecurringRulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expensesRefs = false, tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (expensesRefs) db.expenses,
                if (tasksRefs) db.tasks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (expensesRefs)
                    await $_getPrefetchedData<
                      RecurringRule,
                      $RecurringRulesTable,
                      Expense
                    >(
                      currentTable: table,
                      referencedTable: $$RecurringRulesTableReferences
                          ._expensesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurringRulesTableReferences(
                            db,
                            table,
                            p0,
                          ).expensesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.recurringRuleId == item.id,
                          ),
                      typedResults: items,
                    ),
                  if (tasksRefs)
                    await $_getPrefetchedData<
                      RecurringRule,
                      $RecurringRulesTable,
                      Task
                    >(
                      currentTable: table,
                      referencedTable: $$RecurringRulesTableReferences
                          ._tasksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$RecurringRulesTableReferences(
                            db,
                            table,
                            p0,
                          ).tasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.recurringRuleId == item.id,
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

typedef $$RecurringRulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecurringRulesTable,
      RecurringRule,
      $$RecurringRulesTableFilterComposer,
      $$RecurringRulesTableOrderingComposer,
      $$RecurringRulesTableAnnotationComposer,
      $$RecurringRulesTableCreateCompanionBuilder,
      $$RecurringRulesTableUpdateCompanionBuilder,
      (RecurringRule, $$RecurringRulesTableReferences),
      RecurringRule,
      PrefetchHooks Function({bool expensesRefs, bool tasksRefs})
    >;
typedef $$BillsTableCreateCompanionBuilder = BillsCompanion Function({
  required String id,
  required String title,
  Value<int?> amountCents,
  required bool isAmountVariable,
  required int dueDay,
  Value<String?> categoryId,
  Value<String?> paymentMethod,
  Value<int> reminderDaysBefore,
  Value<bool> isActive,
  Value<int> rowid,
});
typedef $$BillsTableUpdateCompanionBuilder = BillsCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<int?> amountCents,
  Value<bool> isAmountVariable,
  Value<int> dueDay,
  Value<String?> categoryId,
  Value<String?> paymentMethod,
  Value<int> reminderDaysBefore,
  Value<bool> isActive,
  Value<int> rowid,
});

final class $$BillsTableReferences
    extends BaseReferences<_$AppDatabase, $BillsTable, Bill> {
  $$BillsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('bills__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'bills__id__expenses__bill_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.billId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillPaymentsTable, List<BillPayment>>
  _billPaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.billPayments,
    aliasName: 'bills__id__bill_payments__bill_id',
  );

  $$BillPaymentsTableProcessedTableManager get billPaymentsRefs {
    final manager = $$BillPaymentsTableTableManager(
      $_db,
      $_db.billPayments,
    ).filter((f) => f.billId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billPaymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BillsTableFilterComposer extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableFilterComposer({
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

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAmountVariable => $composableBuilder(
    column: $table.isAmountVariable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderDaysBefore => $composableBuilder(
    column: $table.reminderDaysBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> billPaymentsRefs(
    Expression<bool> Function($$BillPaymentsTableFilterComposer f) f,
  ) {
    final $$BillPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billPayments,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.billPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableOrderingComposer({
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

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAmountVariable => $composableBuilder(
    column: $table.isAmountVariable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderDaysBefore => $composableBuilder(
    column: $table.reminderDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillsTable> {
  $$BillsTableAnnotationComposer({
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

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAmountVariable => $composableBuilder(
    column: $table.isAmountVariable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderDaysBefore => $composableBuilder(
    column: $table.reminderDaysBefore,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> billPaymentsRefs<T extends Object>(
    Expression<T> Function($$BillPaymentsTableAnnotationComposer a) f,
  ) {
    final $$BillPaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billPayments,
      getReferencedColumn: (t) => t.billId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillPaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.billPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BillsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillsTable,
          Bill,
          $$BillsTableFilterComposer,
          $$BillsTableOrderingComposer,
          $$BillsTableAnnotationComposer,
          $$BillsTableCreateCompanionBuilder,
          $$BillsTableUpdateCompanionBuilder,
          (Bill, $$BillsTableReferences),
          Bill,
          PrefetchHooks Function({
            bool categoryId,
            bool expensesRefs,
            bool billPaymentsRefs,
          })
        > {
  $$BillsTableTableManager(_$AppDatabase db, $BillsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int?> amountCents = const Value.absent(),
                Value<bool> isAmountVariable = const Value.absent(),
                Value<int> dueDay = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<int> reminderDaysBefore = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion(
                id: id,
                title: title,
                amountCents: amountCents,
                isAmountVariable: isAmountVariable,
                dueDay: dueDay,
                categoryId: categoryId,
                paymentMethod: paymentMethod,
                reminderDaysBefore: reminderDaysBefore,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<int?> amountCents = const Value.absent(),
                required bool isAmountVariable,
                required int dueDay,
                Value<String?> categoryId = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<int> reminderDaysBefore = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillsCompanion.insert(
                id: id,
                title: title,
                amountCents: amountCents,
                isAmountVariable: isAmountVariable,
                dueDay: dueDay,
                categoryId: categoryId,
                paymentMethod: paymentMethod,
                reminderDaysBefore: reminderDaysBefore,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillsTable, Bill>(table),
                  $$BillsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                expensesRefs = false,
                billPaymentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensesRefs) db.expenses,
                    if (billPaymentsRefs) db.billPayments,
                  ],
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
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$BillsTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$BillsTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensesRefs)
                        await $_getPrefetchedData<Bill, $BillsTable, Expense>(
                          currentTable: table,
                          referencedTable: $$BillsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BillsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.billId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (billPaymentsRefs)
                        await $_getPrefetchedData<
                          Bill,
                          $BillsTable,
                          BillPayment
                        >(
                          currentTable: table,
                          referencedTable: $$BillsTableReferences
                              ._billPaymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BillsTableReferences(
                                db,
                                table,
                                p0,
                              ).billPaymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.billId == item.id,
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

typedef $$BillsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillsTable,
      Bill,
      $$BillsTableFilterComposer,
      $$BillsTableOrderingComposer,
      $$BillsTableAnnotationComposer,
      $$BillsTableCreateCompanionBuilder,
      $$BillsTableUpdateCompanionBuilder,
      (Bill, $$BillsTableReferences),
      Bill,
      PrefetchHooks Function({
        bool categoryId,
        bool expensesRefs,
        bool billPaymentsRefs,
      })
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  Value<String?> categoryId,
  required int amountCents,
  required String occurredOn,
  Value<String?> description,
  Value<String?> notes,
  Value<String?> recurringRuleId,
  Value<String?> billId,
  Value<String?> purchaseId,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String?> categoryId,
  Value<int> amountCents,
  Value<String> occurredOn,
  Value<String?> description,
  Value<String?> notes,
  Value<String?> recurringRuleId,
  Value<String?> billId,
  Value<String?> purchaseId,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('expenses__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecurringRulesTable _recurringRuleIdTable(_$AppDatabase db) => db
      .recurringRules
      .createAlias('expenses__recurring_rule_id__recurring_rules__id');

  $$RecurringRulesTableProcessedTableManager? get recurringRuleId {
    final $_column = $_itemColumn<String>('recurring_rule_id');
    if ($_column == null) return null;
    final manager = $$RecurringRulesTableTableManager(
      $_db,
      $_db.recurringRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurringRuleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $BillsTable _billIdTable(_$AppDatabase db) =>
      db.bills.createAlias('expenses__bill_id__bills__id');

  $$BillsTableProcessedTableManager? get billId {
    final $_column = $_itemColumn<String>('bill_id');
    if ($_column == null) return null;
    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PurchasesTable _purchaseIdTable(_$AppDatabase db) =>
      db.purchases.createAlias('expenses__purchase_id__purchases__id');

  $$PurchasesTableProcessedTableManager? get purchaseId {
    final $_column = $_itemColumn<String>('purchase_id');
    if ($_column == null) return null;
    final manager = $$PurchasesTableTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_purchaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PurchasesTable, List<Purchase>>
  _purchasesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.purchases,
    aliasName: 'expenses__id__purchases__expense_id',
  );

  $$PurchasesTableProcessedTableManager get purchasesRefs {
    final manager = $$PurchasesTableTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BillPaymentsTable, List<BillPayment>>
  _billPaymentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.billPayments,
    aliasName: 'expenses__id__bill_payments__expense_id',
  );

  $$BillPaymentsTableProcessedTableManager get billPaymentsRefs {
    final manager = $$BillPaymentsTableTableManager(
      $_db,
      $_db.billPayments,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_billPaymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
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

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringRulesTableFilterComposer get recurringRuleId {
    final $$RecurringRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringRuleId,
      referencedTable: $db.recurringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringRulesTableFilterComposer(
            $db: $db,
            $table: $db.recurringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PurchasesTableFilterComposer get purchaseId {
    final $$PurchasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableFilterComposer(
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

  Expression<bool> purchasesRefs(
    Expression<bool> Function($$PurchasesTableFilterComposer f) f,
  ) {
    final $$PurchasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableFilterComposer(
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

  Expression<bool> billPaymentsRefs(
    Expression<bool> Function($$BillPaymentsTableFilterComposer f) f,
  ) {
    final $$BillPaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billPayments,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillPaymentsTableFilterComposer(
            $db: $db,
            $table: $db.billPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
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

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringRulesTableOrderingComposer get recurringRuleId {
    final $$RecurringRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringRuleId,
      referencedTable: $db.recurringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringRulesTableOrderingComposer(
            $db: $db,
            $table: $db.recurringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableOrderingComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PurchasesTableOrderingComposer get purchaseId {
    final $$PurchasesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableOrderingComposer(
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

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get occurredOn => $composableBuilder(
    column: $table.occurredOn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringRulesTableAnnotationComposer get recurringRuleId {
    final $$RecurringRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringRuleId,
      referencedTable: $db.recurringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$BillsTableAnnotationComposer get billId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PurchasesTableAnnotationComposer get purchaseId {
    final $$PurchasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableAnnotationComposer(
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

  Expression<T> purchasesRefs<T extends Object>(
    Expression<T> Function($$PurchasesTableAnnotationComposer a) f,
  ) {
    final $$PurchasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableAnnotationComposer(
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

  Expression<T> billPaymentsRefs<T extends Object>(
    Expression<T> Function($$BillPaymentsTableAnnotationComposer a) f,
  ) {
    final $$BillPaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.billPayments,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillPaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.billPayments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({
            bool categoryId,
            bool recurringRuleId,
            bool billId,
            bool purchaseId,
            bool purchasesRefs,
            bool billPaymentsRefs,
          })
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> occurredOn = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> recurringRuleId = const Value.absent(),
                Value<String?> billId = const Value.absent(),
                Value<String?> purchaseId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                categoryId: categoryId,
                amountCents: amountCents,
                occurredOn: occurredOn,
                description: description,
                notes: notes,
                recurringRuleId: recurringRuleId,
                billId: billId,
                purchaseId: purchaseId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> categoryId = const Value.absent(),
                required int amountCents,
                required String occurredOn,
                Value<String?> description = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> recurringRuleId = const Value.absent(),
                Value<String?> billId = const Value.absent(),
                Value<String?> purchaseId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                categoryId: categoryId,
                amountCents: amountCents,
                occurredOn: occurredOn,
                description: description,
                notes: notes,
                recurringRuleId: recurringRuleId,
                billId: billId,
                purchaseId: purchaseId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, Expense>(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                recurringRuleId = false,
                billId = false,
                purchaseId = false,
                purchasesRefs = false,
                billPaymentsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (purchasesRefs) db.purchases,
                    if (billPaymentsRefs) db.billPayments,
                  ],
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
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$ExpensesTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$ExpensesTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (recurringRuleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.recurringRuleId,
                            referencedTable: $$ExpensesTableReferences
                                ._recurringRuleIdTable(db),
                            referencedColumn: $$ExpensesTableReferences
                                ._recurringRuleIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (billId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.billId,
                            referencedTable: $$ExpensesTableReferences
                                ._billIdTable(db),
                            referencedColumn: $$ExpensesTableReferences
                                ._billIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (purchaseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.purchaseId,
                            referencedTable: $$ExpensesTableReferences
                                ._purchaseIdTable(db),
                            referencedColumn: $$ExpensesTableReferences
                                ._purchaseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (purchasesRefs)
                        await $_getPrefetchedData<
                          Expense,
                          $ExpensesTable,
                          Purchase
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._purchasesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).purchasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.expenseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (billPaymentsRefs)
                        await $_getPrefetchedData<
                          Expense,
                          $ExpensesTable,
                          BillPayment
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._billPaymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).billPaymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.expenseId == item.id,
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

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({
        bool categoryId,
        bool recurringRuleId,
        bool billId,
        bool purchaseId,
        bool purchasesRefs,
        bool billPaymentsRefs,
      })
    >;
typedef $$PurchasesTableCreateCompanionBuilder = PurchasesCompanion Function({
  required String id,
  Value<String?> storeId,
  required String purchasedAt,
  required int totalCents,
  Value<int> discountCents,
  Value<String?> paymentMethod,
  Value<String?> receiptImagePath,
  Value<String?> receiptKey,
  required String source,
  Value<String?> expenseId,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$PurchasesTableUpdateCompanionBuilder = PurchasesCompanion Function({
  Value<String> id,
  Value<String?> storeId,
  Value<String> purchasedAt,
  Value<int> totalCents,
  Value<int> discountCents,
  Value<String?> paymentMethod,
  Value<String?> receiptImagePath,
  Value<String?> receiptKey,
  Value<String> source,
  Value<String?> expenseId,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

final class $$PurchasesTableReferences
    extends BaseReferences<_$AppDatabase, $PurchasesTable, Purchase> {
  $$PurchasesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $StoresTable _storeIdTable(_$AppDatabase db) =>
      db.stores.createAlias('purchases__store_id__stores__id');

  $$StoresTableProcessedTableManager? get storeId {
    final $_column = $_itemColumn<String>('store_id');
    if ($_column == null) return null;
    final manager = $$StoresTableTableManager(
      $_db,
      $_db.stores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias('purchases__expense_id__expenses__id');

  $$ExpensesTableProcessedTableManager? get expenseId {
    final $_column = $_itemColumn<String>('expense_id');
    if ($_column == null) return null;
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'purchases__id__expenses__purchase_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.purchaseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PurchaseItemsTable, List<PurchaseItem>>
  _purchaseItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.purchaseItems,
    aliasName: 'purchases__id__purchase_items__purchase_id',
  );

  $$PurchaseItemsTableProcessedTableManager get purchaseItemsRefs {
    final manager = $$PurchaseItemsTableTableManager(
      $_db,
      $_db.purchaseItems,
    ).filter((f) => f.purchaseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_purchaseItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableFilterComposer({
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

  ColumnFilters<String> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountCents => $composableBuilder(
    column: $table.discountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get receiptKey => $composableBuilder(
    column: $table.receiptKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoresTableFilterComposer get storeId {
    final $$StoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableFilterComposer(
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

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.purchaseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> purchaseItemsRefs(
    Expression<bool> Function($$PurchaseItemsTableFilterComposer f) f,
  ) {
    final $$PurchaseItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseItems,
      getReferencedColumn: (t) => t.purchaseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseItemsTableFilterComposer(
            $db: $db,
            $table: $db.purchaseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableOrderingComposer({
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

  ColumnOrderings<String> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountCents => $composableBuilder(
    column: $table.discountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get receiptKey => $composableBuilder(
    column: $table.receiptKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoresTableOrderingComposer get storeId {
    final $$StoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableOrderingComposer(
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

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchasesTable> {
  $$PurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get purchasedAt => $composableBuilder(
    column: $table.purchasedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCents => $composableBuilder(
    column: $table.totalCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get discountCents => $composableBuilder(
    column: $table.discountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paymentMethod => $composableBuilder(
    column: $table.paymentMethod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptImagePath => $composableBuilder(
    column: $table.receiptImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get receiptKey => $composableBuilder(
    column: $table.receiptKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$StoresTableAnnotationComposer get storeId {
    final $$StoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableAnnotationComposer(
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

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.purchaseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> purchaseItemsRefs<T extends Object>(
    Expression<T> Function($$PurchaseItemsTableAnnotationComposer a) f,
  ) {
    final $$PurchaseItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseItems,
      getReferencedColumn: (t) => t.purchaseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.purchaseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchasesTable,
          Purchase,
          $$PurchasesTableFilterComposer,
          $$PurchasesTableOrderingComposer,
          $$PurchasesTableAnnotationComposer,
          $$PurchasesTableCreateCompanionBuilder,
          $$PurchasesTableUpdateCompanionBuilder,
          (Purchase, $$PurchasesTableReferences),
          Purchase,
          PrefetchHooks Function({
            bool storeId,
            bool expenseId,
            bool expensesRefs,
            bool purchaseItemsRefs,
          })
        > {
  $$PurchasesTableTableManager(_$AppDatabase db, $PurchasesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> purchasedAt = const Value.absent(),
                Value<int> totalCents = const Value.absent(),
                Value<int> discountCents = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> receiptImagePath = const Value.absent(),
                Value<String?> receiptKey = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> expenseId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchasesCompanion(
                id: id,
                storeId: storeId,
                purchasedAt: purchasedAt,
                totalCents: totalCents,
                discountCents: discountCents,
                paymentMethod: paymentMethod,
                receiptImagePath: receiptImagePath,
                receiptKey: receiptKey,
                source: source,
                expenseId: expenseId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> storeId = const Value.absent(),
                required String purchasedAt,
                required int totalCents,
                Value<int> discountCents = const Value.absent(),
                Value<String?> paymentMethod = const Value.absent(),
                Value<String?> receiptImagePath = const Value.absent(),
                Value<String?> receiptKey = const Value.absent(),
                required String source,
                Value<String?> expenseId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchasesCompanion.insert(
                id: id,
                storeId: storeId,
                purchasedAt: purchasedAt,
                totalCents: totalCents,
                discountCents: discountCents,
                paymentMethod: paymentMethod,
                receiptImagePath: receiptImagePath,
                receiptKey: receiptKey,
                source: source,
                expenseId: expenseId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PurchasesTable, Purchase>(table),
                  $$PurchasesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                storeId = false,
                expenseId = false,
                expensesRefs = false,
                purchaseItemsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensesRefs) db.expenses,
                    if (purchaseItemsRefs) db.purchaseItems,
                  ],
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
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.storeId,
                            referencedTable: $$PurchasesTableReferences
                                ._storeIdTable(db),
                            referencedColumn: $$PurchasesTableReferences
                                ._storeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (expenseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.expenseId,
                            referencedTable: $$PurchasesTableReferences
                                ._expenseIdTable(db),
                            referencedColumn: $$PurchasesTableReferences
                                ._expenseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensesRefs)
                        await $_getPrefetchedData<
                          Purchase,
                          $PurchasesTable,
                          Expense
                        >(
                          currentTable: table,
                          referencedTable: $$PurchasesTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PurchasesTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.purchaseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (purchaseItemsRefs)
                        await $_getPrefetchedData<
                          Purchase,
                          $PurchasesTable,
                          PurchaseItem
                        >(
                          currentTable: table,
                          referencedTable: $$PurchasesTableReferences
                              ._purchaseItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PurchasesTableReferences(
                                db,
                                table,
                                p0,
                              ).purchaseItemsRefs,
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

typedef $$PurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchasesTable,
      Purchase,
      $$PurchasesTableFilterComposer,
      $$PurchasesTableOrderingComposer,
      $$PurchasesTableAnnotationComposer,
      $$PurchasesTableCreateCompanionBuilder,
      $$PurchasesTableUpdateCompanionBuilder,
      (Purchase, $$PurchasesTableReferences),
      Purchase,
      PrefetchHooks Function({
        bool storeId,
        bool expenseId,
        bool expensesRefs,
        bool purchaseItemsRefs,
      })
    >;
typedef $$PurchaseItemsTableCreateCompanionBuilder =
    PurchaseItemsCompanion Function({
      required String id,
      required String purchaseId,
      Value<String?> productId,
      required String rawDescription,
      required int quantityMilli,
      required String unit,
      required int unitPriceCents,
      required int totalPriceCents,
      Value<String?> ean,
      required int position,
      Value<int> rowid,
    });
typedef $$PurchaseItemsTableUpdateCompanionBuilder =
    PurchaseItemsCompanion Function({
      Value<String> id,
      Value<String> purchaseId,
      Value<String?> productId,
      Value<String> rawDescription,
      Value<int> quantityMilli,
      Value<String> unit,
      Value<int> unitPriceCents,
      Value<int> totalPriceCents,
      Value<String?> ean,
      Value<int> position,
      Value<int> rowid,
    });

final class $$PurchaseItemsTableReferences
    extends BaseReferences<_$AppDatabase, $PurchaseItemsTable, PurchaseItem> {
  $$PurchaseItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PurchasesTable _purchaseIdTable(_$AppDatabase db) =>
      db.purchases.createAlias('purchase_items__purchase_id__purchases__id');

  $$PurchasesTableProcessedTableManager get purchaseId {
    final $_column = $_itemColumn<String>('purchase_id')!;

    final manager = $$PurchasesTableTableManager(
      $_db,
      $_db.purchases,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_purchaseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('purchase_items__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$PricePointsTable, List<PricePoint>>
  _pricePointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pricePoints,
    aliasName: 'purchase_items__id__price_points__purchase_item_id',
  );

  $$PricePointsTableProcessedTableManager get pricePointsRefs {
    final manager = $$PricePointsTableTableManager(
      $_db,
      $_db.pricePoints,
    ).filter((f) => f.purchaseItemId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pricePointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PurchaseItemsTableFilterComposer
    extends Composer<_$AppDatabase, $PurchaseItemsTable> {
  $$PurchaseItemsTableFilterComposer({
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

  ColumnFilters<String> get rawDescription => $composableBuilder(
    column: $table.rawDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPriceCents => $composableBuilder(
    column: $table.totalPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ean => $composableBuilder(
    column: $table.ean,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$PurchasesTableFilterComposer get purchaseId {
    final $$PurchasesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableFilterComposer(
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

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> pricePointsRefs(
    Expression<bool> Function($$PricePointsTableFilterComposer f) f,
  ) {
    final $$PricePointsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pricePoints,
      getReferencedColumn: (t) => t.purchaseItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PricePointsTableFilterComposer(
            $db: $db,
            $table: $db.pricePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PurchaseItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $PurchaseItemsTable> {
  $$PurchaseItemsTableOrderingComposer({
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

  ColumnOrderings<String> get rawDescription => $composableBuilder(
    column: $table.rawDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPriceCents => $composableBuilder(
    column: $table.totalPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ean => $composableBuilder(
    column: $table.ean,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$PurchasesTableOrderingComposer get purchaseId {
    final $$PurchasesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableOrderingComposer(
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

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PurchaseItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PurchaseItemsTable> {
  $$PurchaseItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rawDescription => $composableBuilder(
    column: $table.rawDescription,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalPriceCents => $composableBuilder(
    column: $table.totalPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ean =>
      $composableBuilder(column: $table.ean, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$PurchasesTableAnnotationComposer get purchaseId {
    final $$PurchasesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseId,
      referencedTable: $db.purchases,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchasesTableAnnotationComposer(
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

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> pricePointsRefs<T extends Object>(
    Expression<T> Function($$PricePointsTableAnnotationComposer a) f,
  ) {
    final $$PricePointsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pricePoints,
      getReferencedColumn: (t) => t.purchaseItemId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PricePointsTableAnnotationComposer(
            $db: $db,
            $table: $db.pricePoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PurchaseItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PurchaseItemsTable,
          PurchaseItem,
          $$PurchaseItemsTableFilterComposer,
          $$PurchaseItemsTableOrderingComposer,
          $$PurchaseItemsTableAnnotationComposer,
          $$PurchaseItemsTableCreateCompanionBuilder,
          $$PurchaseItemsTableUpdateCompanionBuilder,
          (PurchaseItem, $$PurchaseItemsTableReferences),
          PurchaseItem,
          PrefetchHooks Function({
            bool purchaseId,
            bool productId,
            bool pricePointsRefs,
          })
        > {
  $$PurchaseItemsTableTableManager(_$AppDatabase db, $PurchaseItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PurchaseItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PurchaseItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PurchaseItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> purchaseId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String> rawDescription = const Value.absent(),
                Value<int> quantityMilli = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int> unitPriceCents = const Value.absent(),
                Value<int> totalPriceCents = const Value.absent(),
                Value<String?> ean = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseItemsCompanion(
                id: id,
                purchaseId: purchaseId,
                productId: productId,
                rawDescription: rawDescription,
                quantityMilli: quantityMilli,
                unit: unit,
                unitPriceCents: unitPriceCents,
                totalPriceCents: totalPriceCents,
                ean: ean,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String purchaseId,
                Value<String?> productId = const Value.absent(),
                required String rawDescription,
                required int quantityMilli,
                required String unit,
                required int unitPriceCents,
                required int totalPriceCents,
                Value<String?> ean = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => PurchaseItemsCompanion.insert(
                id: id,
                purchaseId: purchaseId,
                productId: productId,
                rawDescription: rawDescription,
                quantityMilli: quantityMilli,
                unit: unit,
                unitPriceCents: unitPriceCents,
                totalPriceCents: totalPriceCents,
                ean: ean,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PurchaseItemsTable, PurchaseItem>(table),
                  $$PurchaseItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                purchaseId = false,
                productId = false,
                pricePointsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (pricePointsRefs) db.pricePoints,
                  ],
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
                        if (purchaseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.purchaseId,
                            referencedTable: $$PurchaseItemsTableReferences
                                ._purchaseIdTable(db),
                            referencedColumn: $$PurchaseItemsTableReferences
                                ._purchaseIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (productId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable: $$PurchaseItemsTableReferences
                                ._productIdTable(db),
                            referencedColumn: $$PurchaseItemsTableReferences
                                ._productIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (pricePointsRefs)
                        await $_getPrefetchedData<
                          PurchaseItem,
                          $PurchaseItemsTable,
                          PricePoint
                        >(
                          currentTable: table,
                          referencedTable: $$PurchaseItemsTableReferences
                              ._pricePointsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PurchaseItemsTableReferences(
                                db,
                                table,
                                p0,
                              ).pricePointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.purchaseItemId == item.id,
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

typedef $$PurchaseItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PurchaseItemsTable,
      PurchaseItem,
      $$PurchaseItemsTableFilterComposer,
      $$PurchaseItemsTableOrderingComposer,
      $$PurchaseItemsTableAnnotationComposer,
      $$PurchaseItemsTableCreateCompanionBuilder,
      $$PurchaseItemsTableUpdateCompanionBuilder,
      (PurchaseItem, $$PurchaseItemsTableReferences),
      PurchaseItem,
      PrefetchHooks Function({
        bool purchaseId,
        bool productId,
        bool pricePointsRefs,
      })
    >;
typedef $$PricePointsTableCreateCompanionBuilder =
    PricePointsCompanion Function({
      required String id,
      Value<String?> productId,
      Value<String?> storeId,
      required String observedAt,
      required int unitPriceCents,
      required int normalizedPriceCents,
      required int quantityMilli,
      required String unit,
      Value<String?> purchaseItemId,
      required String source,
      Value<String?> deletedAt,
      Value<int> rowid,
    });
typedef $$PricePointsTableUpdateCompanionBuilder =
    PricePointsCompanion Function({
      Value<String> id,
      Value<String?> productId,
      Value<String?> storeId,
      Value<String> observedAt,
      Value<int> unitPriceCents,
      Value<int> normalizedPriceCents,
      Value<int> quantityMilli,
      Value<String> unit,
      Value<String?> purchaseItemId,
      Value<String> source,
      Value<String?> deletedAt,
      Value<int> rowid,
    });

final class $$PricePointsTableReferences
    extends BaseReferences<_$AppDatabase, $PricePointsTable, PricePoint> {
  $$PricePointsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('price_points__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StoresTable _storeIdTable(_$AppDatabase db) =>
      db.stores.createAlias('price_points__store_id__stores__id');

  $$StoresTableProcessedTableManager? get storeId {
    final $_column = $_itemColumn<String>('store_id');
    if ($_column == null) return null;
    final manager = $$StoresTableTableManager(
      $_db,
      $_db.stores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PurchaseItemsTable _purchaseItemIdTable(_$AppDatabase db) => db
      .purchaseItems
      .createAlias('price_points__purchase_item_id__purchase_items__id');

  $$PurchaseItemsTableProcessedTableManager? get purchaseItemId {
    final $_column = $_itemColumn<String>('purchase_item_id');
    if ($_column == null) return null;
    final manager = $$PurchaseItemsTableTableManager(
      $_db,
      $_db.purchaseItems,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_purchaseItemIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PricePointsTableFilterComposer
    extends Composer<_$AppDatabase, $PricePointsTable> {
  $$PricePointsTableFilterComposer({
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

  ColumnFilters<String> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get normalizedPriceCents => $composableBuilder(
    column: $table.normalizedPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoresTableFilterComposer get storeId {
    final $$StoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableFilterComposer(
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

  $$PurchaseItemsTableFilterComposer get purchaseItemId {
    final $$PurchaseItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseItemId,
      referencedTable: $db.purchaseItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseItemsTableFilterComposer(
            $db: $db,
            $table: $db.purchaseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PricePointsTableOrderingComposer
    extends Composer<_$AppDatabase, $PricePointsTable> {
  $$PricePointsTableOrderingComposer({
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

  ColumnOrderings<String> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get normalizedPriceCents => $composableBuilder(
    column: $table.normalizedPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoresTableOrderingComposer get storeId {
    final $$StoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableOrderingComposer(
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

  $$PurchaseItemsTableOrderingComposer get purchaseItemId {
    final $$PurchaseItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseItemId,
      referencedTable: $db.purchaseItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseItemsTableOrderingComposer(
            $db: $db,
            $table: $db.purchaseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PricePointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PricePointsTable> {
  $$PricePointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPriceCents => $composableBuilder(
    column: $table.unitPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get normalizedPriceCents => $composableBuilder(
    column: $table.normalizedPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StoresTableAnnotationComposer get storeId {
    final $$StoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableAnnotationComposer(
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

  $$PurchaseItemsTableAnnotationComposer get purchaseItemId {
    final $$PurchaseItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.purchaseItemId,
      referencedTable: $db.purchaseItems,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PurchaseItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.purchaseItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PricePointsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PricePointsTable,
          PricePoint,
          $$PricePointsTableFilterComposer,
          $$PricePointsTableOrderingComposer,
          $$PricePointsTableAnnotationComposer,
          $$PricePointsTableCreateCompanionBuilder,
          $$PricePointsTableUpdateCompanionBuilder,
          (PricePoint, $$PricePointsTableReferences),
          PricePoint,
          PrefetchHooks Function({
            bool productId,
            bool storeId,
            bool purchaseItemId,
          })
        > {
  $$PricePointsTableTableManager(_$AppDatabase db, $PricePointsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PricePointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PricePointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PricePointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<String> observedAt = const Value.absent(),
                Value<int> unitPriceCents = const Value.absent(),
                Value<int> normalizedPriceCents = const Value.absent(),
                Value<int> quantityMilli = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> purchaseItemId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PricePointsCompanion(
                id: id,
                productId: productId,
                storeId: storeId,
                observedAt: observedAt,
                unitPriceCents: unitPriceCents,
                normalizedPriceCents: normalizedPriceCents,
                quantityMilli: quantityMilli,
                unit: unit,
                purchaseItemId: purchaseItemId,
                source: source,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> productId = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                required String observedAt,
                required int unitPriceCents,
                required int normalizedPriceCents,
                required int quantityMilli,
                required String unit,
                Value<String?> purchaseItemId = const Value.absent(),
                required String source,
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PricePointsCompanion.insert(
                id: id,
                productId: productId,
                storeId: storeId,
                observedAt: observedAt,
                unitPriceCents: unitPriceCents,
                normalizedPriceCents: normalizedPriceCents,
                quantityMilli: quantityMilli,
                unit: unit,
                purchaseItemId: purchaseItemId,
                source: source,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PricePointsTable, PricePoint>(table),
                  $$PricePointsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({productId = false, storeId = false, purchaseItemId = false}) {
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
                        if (productId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable: $$PricePointsTableReferences
                                ._productIdTable(db),
                            referencedColumn: $$PricePointsTableReferences
                                ._productIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (storeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.storeId,
                            referencedTable: $$PricePointsTableReferences
                                ._storeIdTable(db),
                            referencedColumn: $$PricePointsTableReferences
                                ._storeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (purchaseItemId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.purchaseItemId,
                            referencedTable: $$PricePointsTableReferences
                                ._purchaseItemIdTable(db),
                            referencedColumn: $$PricePointsTableReferences
                                ._purchaseItemIdTable(db)
                                .id,
                          ) as T;
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

typedef $$PricePointsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PricePointsTable,
      PricePoint,
      $$PricePointsTableFilterComposer,
      $$PricePointsTableOrderingComposer,
      $$PricePointsTableAnnotationComposer,
      $$PricePointsTableCreateCompanionBuilder,
      $$PricePointsTableUpdateCompanionBuilder,
      (PricePoint, $$PricePointsTableReferences),
      PricePoint,
      PrefetchHooks Function({
        bool productId,
        bool storeId,
        bool purchaseItemId,
      })
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  required String id,
  required String yearMonth,
  Value<String?> categoryId,
  required int limitCents,
  Value<int> baseIncomeCents,
  Value<int> extraIncomeCents,
  Value<int> rowid,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<String> id,
  Value<String> yearMonth,
  Value<String?> categoryId,
  Value<int> limitCents,
  Value<int> baseIncomeCents,
  Value<int> extraIncomeCents,
  Value<int> rowid,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
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

  ColumnFilters<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseIncomeCents => $composableBuilder(
    column: $table.baseIncomeCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get extraIncomeCents => $composableBuilder(
    column: $table.extraIncomeCents,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
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

  ColumnOrderings<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseIncomeCents => $composableBuilder(
    column: $table.baseIncomeCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get extraIncomeCents => $composableBuilder(
    column: $table.extraIncomeCents,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<int> get limitCents => $composableBuilder(
    column: $table.limitCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get baseIncomeCents => $composableBuilder(
    column: $table.baseIncomeCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get extraIncomeCents => $composableBuilder(
    column: $table.extraIncomeCents,
    builder: (column) => column,
  );

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> yearMonth = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> limitCents = const Value.absent(),
                Value<int> baseIncomeCents = const Value.absent(),
                Value<int> extraIncomeCents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                yearMonth: yearMonth,
                categoryId: categoryId,
                limitCents: limitCents,
                baseIncomeCents: baseIncomeCents,
                extraIncomeCents: extraIncomeCents,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String yearMonth,
                Value<String?> categoryId = const Value.absent(),
                required int limitCents,
                Value<int> baseIncomeCents = const Value.absent(),
                Value<int> extraIncomeCents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                yearMonth: yearMonth,
                categoryId: categoryId,
                limitCents: limitCents,
                baseIncomeCents: baseIncomeCents,
                extraIncomeCents: extraIncomeCents,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $$BudgetsTableReferences
                            ._categoryIdTable(db),
                        referencedColumn: $$BudgetsTableReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
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

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool categoryId})
    >;
typedef $$BillPaymentsTableCreateCompanionBuilder =
    BillPaymentsCompanion Function({
      required String id,
      Value<String?> billId,
      required String dueOn,
      Value<String?> paidOn,
      Value<int?> amountCents,
      required String status,
      Value<String?> expenseId,
      Value<int> rowid,
    });
typedef $$BillPaymentsTableUpdateCompanionBuilder =
    BillPaymentsCompanion Function({
      Value<String> id,
      Value<String?> billId,
      Value<String> dueOn,
      Value<String?> paidOn,
      Value<int?> amountCents,
      Value<String> status,
      Value<String?> expenseId,
      Value<int> rowid,
    });

final class $$BillPaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $BillPaymentsTable, BillPayment> {
  $$BillPaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BillsTable _billIdTable(_$AppDatabase db) =>
      db.bills.createAlias('bill_payments__bill_id__bills__id');

  $$BillsTableProcessedTableManager? get billId {
    final $_column = $_itemColumn<String>('bill_id');
    if ($_column == null) return null;
    final manager = $$BillsTableTableManager(
      $_db,
      $_db.bills,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_billIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias('bill_payments__expense_id__expenses__id');

  $$ExpensesTableProcessedTableManager? get expenseId {
    final $_column = $_itemColumn<String>('expense_id');
    if ($_column == null) return null;
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BillPaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $BillPaymentsTable> {
  $$BillPaymentsTableFilterComposer({
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

  ColumnFilters<String> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  $$BillsTableFilterComposer get billId {
    final $$BillsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableFilterComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillPaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $BillPaymentsTable> {
  $$BillPaymentsTableOrderingComposer({
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

  ColumnOrderings<String> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paidOn => $composableBuilder(
    column: $table.paidOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  $$BillsTableOrderingComposer get billId {
    final $$BillsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableOrderingComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillPaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BillPaymentsTable> {
  $$BillPaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dueOn =>
      $composableBuilder(column: $table.dueOn, builder: (column) => column);

  GeneratedColumn<String> get paidOn =>
      $composableBuilder(column: $table.paidOn, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  $$BillsTableAnnotationComposer get billId {
    final $$BillsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.billId,
      referencedTable: $db.bills,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BillsTableAnnotationComposer(
            $db: $db,
            $table: $db.bills,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BillPaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BillPaymentsTable,
          BillPayment,
          $$BillPaymentsTableFilterComposer,
          $$BillPaymentsTableOrderingComposer,
          $$BillPaymentsTableAnnotationComposer,
          $$BillPaymentsTableCreateCompanionBuilder,
          $$BillPaymentsTableUpdateCompanionBuilder,
          (BillPayment, $$BillPaymentsTableReferences),
          BillPayment,
          PrefetchHooks Function({bool billId, bool expenseId})
        > {
  $$BillPaymentsTableTableManager(_$AppDatabase db, $BillPaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BillPaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BillPaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BillPaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> billId = const Value.absent(),
                Value<String> dueOn = const Value.absent(),
                Value<String?> paidOn = const Value.absent(),
                Value<int?> amountCents = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> expenseId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillPaymentsCompanion(
                id: id,
                billId: billId,
                dueOn: dueOn,
                paidOn: paidOn,
                amountCents: amountCents,
                status: status,
                expenseId: expenseId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> billId = const Value.absent(),
                required String dueOn,
                Value<String?> paidOn = const Value.absent(),
                Value<int?> amountCents = const Value.absent(),
                required String status,
                Value<String?> expenseId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BillPaymentsCompanion.insert(
                id: id,
                billId: billId,
                dueOn: dueOn,
                paidOn: paidOn,
                amountCents: amountCents,
                status: status,
                expenseId: expenseId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BillPaymentsTable, BillPayment>(table),
                  $$BillPaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({billId = false, expenseId = false}) {
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
                    if (billId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.billId,
                        referencedTable: $$BillPaymentsTableReferences
                            ._billIdTable(db),
                        referencedColumn: $$BillPaymentsTableReferences
                            ._billIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (expenseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.expenseId,
                        referencedTable: $$BillPaymentsTableReferences
                            ._expenseIdTable(db),
                        referencedColumn: $$BillPaymentsTableReferences
                            ._expenseIdTable(db)
                            .id,
                      ) as T;
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

typedef $$BillPaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BillPaymentsTable,
      BillPayment,
      $$BillPaymentsTableFilterComposer,
      $$BillPaymentsTableOrderingComposer,
      $$BillPaymentsTableAnnotationComposer,
      $$BillPaymentsTableCreateCompanionBuilder,
      $$BillPaymentsTableUpdateCompanionBuilder,
      (BillPayment, $$BillPaymentsTableReferences),
      BillPayment,
      PrefetchHooks Function({bool billId, bool expenseId})
    >;
typedef $$ShoppingListsTableCreateCompanionBuilder =
    ShoppingListsCompanion Function({
      required String id,
      required String name,
      Value<String?> storeId,
      Value<bool> isArchived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$ShoppingListsTableUpdateCompanionBuilder =
    ShoppingListsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> storeId,
      Value<bool> isArchived,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

final class $$ShoppingListsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingListsTable, ShoppingList> {
  $$ShoppingListsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoresTable _storeIdTable(_$AppDatabase db) =>
      db.stores.createAlias('shopping_lists__store_id__stores__id');

  $$StoresTableProcessedTableManager? get storeId {
    final $_column = $_itemColumn<String>('store_id');
    if ($_column == null) return null;
    final manager = $$StoresTableTableManager(
      $_db,
      $_db.stores,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_storeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ShoppingItemsTable, List<ShoppingItem>>
  _shoppingItemsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.shoppingItems,
    aliasName: 'shopping_lists__id__shopping_items__list_id',
  );

  $$ShoppingItemsTableProcessedTableManager get shoppingItemsRefs {
    final manager = $$ShoppingItemsTableTableManager(
      $_db,
      $_db.shoppingItems,
    ).filter((f) => f.listId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_shoppingItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ShoppingListsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableFilterComposer({
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

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$StoresTableFilterComposer get storeId {
    final $$StoresTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableFilterComposer(
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

  Expression<bool> shoppingItemsRefs(
    Expression<bool> Function($$ShoppingItemsTableFilterComposer f) f,
  ) {
    final $$ShoppingItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableOrderingComposer({
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

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoresTableOrderingComposer get storeId {
    final $$StoresTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableOrderingComposer(
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

class $$ShoppingListsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingListsTable> {
  $$ShoppingListsTableAnnotationComposer({
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

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$StoresTableAnnotationComposer get storeId {
    final $$StoresTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.storeId,
      referencedTable: $db.stores,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoresTableAnnotationComposer(
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

  Expression<T> shoppingItemsRefs<T extends Object>(
    Expression<T> Function($$ShoppingItemsTableAnnotationComposer a) f,
  ) {
    final $$ShoppingItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.shoppingItems,
      getReferencedColumn: (t) => t.listId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ShoppingListsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingListsTable,
          ShoppingList,
          $$ShoppingListsTableFilterComposer,
          $$ShoppingListsTableOrderingComposer,
          $$ShoppingListsTableAnnotationComposer,
          $$ShoppingListsTableCreateCompanionBuilder,
          $$ShoppingListsTableUpdateCompanionBuilder,
          (ShoppingList, $$ShoppingListsTableReferences),
          ShoppingList,
          PrefetchHooks Function({bool storeId, bool shoppingItemsRefs})
        > {
  $$ShoppingListsTableTableManager(_$AppDatabase db, $ShoppingListsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingListsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingListsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingListsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListsCompanion(
                id: id,
                name: name,
                storeId: storeId,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> storeId = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingListsCompanion.insert(
                id: id,
                name: name,
                storeId: storeId,
                isArchived: isArchived,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShoppingListsTable, ShoppingList>(table),
                  $$ShoppingListsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({storeId = false, shoppingItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (shoppingItemsRefs) db.shoppingItems,
                  ],
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
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.storeId,
                            referencedTable: $$ShoppingListsTableReferences
                                ._storeIdTable(db),
                            referencedColumn: $$ShoppingListsTableReferences
                                ._storeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (shoppingItemsRefs)
                        await $_getPrefetchedData<
                          ShoppingList,
                          $ShoppingListsTable,
                          ShoppingItem
                        >(
                          currentTable: table,
                          referencedTable: $$ShoppingListsTableReferences
                              ._shoppingItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ShoppingListsTableReferences(
                                db,
                                table,
                                p0,
                              ).shoppingItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.listId == item.id,
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

typedef $$ShoppingListsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingListsTable,
      ShoppingList,
      $$ShoppingListsTableFilterComposer,
      $$ShoppingListsTableOrderingComposer,
      $$ShoppingListsTableAnnotationComposer,
      $$ShoppingListsTableCreateCompanionBuilder,
      $$ShoppingListsTableUpdateCompanionBuilder,
      (ShoppingList, $$ShoppingListsTableReferences),
      ShoppingList,
      PrefetchHooks Function({bool storeId, bool shoppingItemsRefs})
    >;
typedef $$ShoppingItemsTableCreateCompanionBuilder =
    ShoppingItemsCompanion Function({
      required String id,
      Value<String?> listId,
      Value<String?> productId,
      Value<String?> freeText,
      Value<int?> quantityMilli,
      Value<String?> unit,
      Value<int?> estimatedPriceCents,
      Value<bool> isChecked,
      Value<String?> checkedAt,
      required String source,
      required int position,
      Value<int> rowid,
    });
typedef $$ShoppingItemsTableUpdateCompanionBuilder =
    ShoppingItemsCompanion Function({
      Value<String> id,
      Value<String?> listId,
      Value<String?> productId,
      Value<String?> freeText,
      Value<int?> quantityMilli,
      Value<String?> unit,
      Value<int?> estimatedPriceCents,
      Value<bool> isChecked,
      Value<String?> checkedAt,
      Value<String> source,
      Value<int> position,
      Value<int> rowid,
    });

final class $$ShoppingItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ShoppingItemsTable, ShoppingItem> {
  $$ShoppingItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ShoppingListsTable _listIdTable(_$AppDatabase db) => db.shoppingLists
      .createAlias('shopping_items__list_id__shopping_lists__id');

  $$ShoppingListsTableProcessedTableManager? get listId {
    final $_column = $_itemColumn<String>('list_id');
    if ($_column == null) return null;
    final manager = $$ShoppingListsTableTableManager(
      $_db,
      $_db.shoppingLists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_listIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('shopping_items__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ShoppingItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableFilterComposer({
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

  ColumnFilters<String> get freeText => $composableBuilder(
    column: $table.freeText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimatedPriceCents => $composableBuilder(
    column: $table.estimatedPriceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$ShoppingListsTableFilterComposer get listId {
    final $$ShoppingListsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableFilterComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableOrderingComposer({
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

  ColumnOrderings<String> get freeText => $composableBuilder(
    column: $table.freeText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimatedPriceCents => $composableBuilder(
    column: $table.estimatedPriceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isChecked => $composableBuilder(
    column: $table.isChecked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$ShoppingListsTableOrderingComposer get listId {
    final $$ShoppingListsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableOrderingComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ShoppingItemsTable> {
  $$ShoppingItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get freeText =>
      $composableBuilder(column: $table.freeText, builder: (column) => column);

  GeneratedColumn<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get estimatedPriceCents => $composableBuilder(
    column: $table.estimatedPriceCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isChecked =>
      $composableBuilder(column: $table.isChecked, builder: (column) => column);

  GeneratedColumn<String> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$ShoppingListsTableAnnotationComposer get listId {
    final $$ShoppingListsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.listId,
      referencedTable: $db.shoppingLists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ShoppingListsTableAnnotationComposer(
            $db: $db,
            $table: $db.shoppingLists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ShoppingItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ShoppingItemsTable,
          ShoppingItem,
          $$ShoppingItemsTableFilterComposer,
          $$ShoppingItemsTableOrderingComposer,
          $$ShoppingItemsTableAnnotationComposer,
          $$ShoppingItemsTableCreateCompanionBuilder,
          $$ShoppingItemsTableUpdateCompanionBuilder,
          (ShoppingItem, $$ShoppingItemsTableReferences),
          ShoppingItem,
          PrefetchHooks Function({bool listId, bool productId})
        > {
  $$ShoppingItemsTableTableManager(_$AppDatabase db, $ShoppingItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ShoppingItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ShoppingItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ShoppingItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> listId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> freeText = const Value.absent(),
                Value<int?> quantityMilli = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> estimatedPriceCents = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<String?> checkedAt = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ShoppingItemsCompanion(
                id: id,
                listId: listId,
                productId: productId,
                freeText: freeText,
                quantityMilli: quantityMilli,
                unit: unit,
                estimatedPriceCents: estimatedPriceCents,
                isChecked: isChecked,
                checkedAt: checkedAt,
                source: source,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> listId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String?> freeText = const Value.absent(),
                Value<int?> quantityMilli = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> estimatedPriceCents = const Value.absent(),
                Value<bool> isChecked = const Value.absent(),
                Value<String?> checkedAt = const Value.absent(),
                required String source,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => ShoppingItemsCompanion.insert(
                id: id,
                listId: listId,
                productId: productId,
                freeText: freeText,
                quantityMilli: quantityMilli,
                unit: unit,
                estimatedPriceCents: estimatedPriceCents,
                isChecked: isChecked,
                checkedAt: checkedAt,
                source: source,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ShoppingItemsTable, ShoppingItem>(table),
                  $$ShoppingItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({listId = false, productId = false}) {
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
                    if (listId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.listId,
                        referencedTable: $$ShoppingItemsTableReferences
                            ._listIdTable(db),
                        referencedColumn: $$ShoppingItemsTableReferences
                            ._listIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$ShoppingItemsTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$ShoppingItemsTableReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
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

typedef $$ShoppingItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ShoppingItemsTable,
      ShoppingItem,
      $$ShoppingItemsTableFilterComposer,
      $$ShoppingItemsTableOrderingComposer,
      $$ShoppingItemsTableAnnotationComposer,
      $$ShoppingItemsTableCreateCompanionBuilder,
      $$ShoppingItemsTableUpdateCompanionBuilder,
      (ShoppingItem, $$ShoppingItemsTableReferences),
      ShoppingItem,
      PrefetchHooks Function({bool listId, bool productId})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String title,
  Value<String?> notes,
  Value<String?> categoryId,
  Value<String?> dueAt,
  Value<bool> allDay,
  Value<bool> isCompleted,
  Value<String?> completedAt,
  Value<String?> recurringRuleId,
  Value<String?> remoteEventId,
  Value<String?> remoteEtag,
  Value<String?> syncState,
  Value<String?> sourcePresetId,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> notes,
  Value<String?> categoryId,
  Value<String?> dueAt,
  Value<bool> allDay,
  Value<bool> isCompleted,
  Value<String?> completedAt,
  Value<String?> recurringRuleId,
  Value<String?> remoteEventId,
  Value<String?> remoteEtag,
  Value<String?> syncState,
  Value<String?> sourcePresetId,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<String?> deletedAt,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, Task> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('tasks__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $RecurringRulesTable _recurringRuleIdTable(_$AppDatabase db) => db
      .recurringRules
      .createAlias('tasks__recurring_rule_id__recurring_rules__id');

  $$RecurringRulesTableProcessedTableManager? get recurringRuleId {
    final $_column = $_itemColumn<String>('recurring_rule_id');
    if ($_column == null) return null;
    final manager = $$RecurringRulesTableTableManager(
      $_db,
      $_db.recurringRules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recurringRuleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
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

  ColumnFilters<String> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteEventId => $composableBuilder(
    column: $table.remoteEventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePresetId => $composableBuilder(
    column: $table.sourcePresetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringRulesTableFilterComposer get recurringRuleId {
    final $$RecurringRulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringRuleId,
      referencedTable: $db.recurringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringRulesTableFilterComposer(
            $db: $db,
            $table: $db.recurringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
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

  ColumnOrderings<String> get dueAt => $composableBuilder(
    column: $table.dueAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allDay => $composableBuilder(
    column: $table.allDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteEventId => $composableBuilder(
    column: $table.remoteEventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePresetId => $composableBuilder(
    column: $table.sourcePresetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringRulesTableOrderingComposer get recurringRuleId {
    final $$RecurringRulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringRuleId,
      referencedTable: $db.recurringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringRulesTableOrderingComposer(
            $db: $db,
            $table: $db.recurringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
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

  GeneratedColumn<String> get dueAt =>
      $composableBuilder(column: $table.dueAt, builder: (column) => column);

  GeneratedColumn<bool> get allDay =>
      $composableBuilder(column: $table.allDay, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteEventId => $composableBuilder(
    column: $table.remoteEventId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get sourcePresetId => $composableBuilder(
    column: $table.sourcePresetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$RecurringRulesTableAnnotationComposer get recurringRuleId {
    final $$RecurringRulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recurringRuleId,
      referencedTable: $db.recurringRules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecurringRulesTableAnnotationComposer(
            $db: $db,
            $table: $db.recurringRules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, $$TasksTableReferences),
          Task,
          PrefetchHooks Function({bool categoryId, bool recurringRuleId})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> dueAt = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String?> recurringRuleId = const Value.absent(),
                Value<String?> remoteEventId = const Value.absent(),
                Value<String?> remoteEtag = const Value.absent(),
                Value<String?> syncState = const Value.absent(),
                Value<String?> sourcePresetId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                notes: notes,
                categoryId: categoryId,
                dueAt: dueAt,
                allDay: allDay,
                isCompleted: isCompleted,
                completedAt: completedAt,
                recurringRuleId: recurringRuleId,
                remoteEventId: remoteEventId,
                remoteEtag: remoteEtag,
                syncState: syncState,
                sourcePresetId: sourcePresetId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String?> dueAt = const Value.absent(),
                Value<bool> allDay = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String?> completedAt = const Value.absent(),
                Value<String?> recurringRuleId = const Value.absent(),
                Value<String?> remoteEventId = const Value.absent(),
                Value<String?> remoteEtag = const Value.absent(),
                Value<String?> syncState = const Value.absent(),
                Value<String?> sourcePresetId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                notes: notes,
                categoryId: categoryId,
                dueAt: dueAt,
                allDay: allDay,
                isCompleted: isCompleted,
                completedAt: completedAt,
                recurringRuleId: recurringRuleId,
                remoteEventId: remoteEventId,
                remoteEtag: remoteEtag,
                syncState: syncState,
                sourcePresetId: sourcePresetId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, Task>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoryId = false, recurringRuleId = false}) {
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
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $$TasksTableReferences
                                ._categoryIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (recurringRuleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.recurringRuleId,
                            referencedTable: $$TasksTableReferences
                                ._recurringRuleIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._recurringRuleIdTable(db)
                                .id,
                          ) as T;
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

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, $$TasksTableReferences),
      Task,
      PrefetchHooks Function({bool categoryId, bool recurringRuleId})
    >;
typedef $$RecipesTableCreateCompanionBuilder = RecipesCompanion Function({
  required String id,
  required String title,
  Value<String?> instructions,
  Value<int?> prepMinutes,
  Value<int> servings,
  Value<String?> photoPath,
  Value<bool> isFavorite,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$RecipesTableUpdateCompanionBuilder = RecipesCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String?> instructions,
  Value<int?> prepMinutes,
  Value<int> servings,
  Value<String?> photoPath,
  Value<bool> isFavorite,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});

final class $$RecipesTableReferences
    extends BaseReferences<_$AppDatabase, $RecipesTable, Recipe> {
  $$RecipesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RecipeIngredientsTable, List<RecipeIngredient>>
  _recipeIngredientsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.recipeIngredients,
        aliasName: 'recipes__id__recipe_ingredients__recipe_id',
      );

  $$RecipeIngredientsTableProcessedTableManager get recipeIngredientsRefs {
    final manager = $$RecipeIngredientsTableTableManager(
      $_db,
      $_db.recipeIngredients,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _recipeIngredientsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$RecipesTableFilterComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableFilterComposer({
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

  ColumnFilters<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> recipeIngredientsRefs(
    Expression<bool> Function($$RecipeIngredientsTableFilterComposer f) f,
  ) {
    final $$RecipeIngredientsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeIngredients,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipeIngredientsTableFilterComposer(
            $db: $db,
            $table: $db.recipeIngredients,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RecipesTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableOrderingComposer({
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

  ColumnOrderings<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get servings => $composableBuilder(
    column: $table.servings,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipesTable> {
  $$RecipesTableAnnotationComposer({
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

  GeneratedColumn<String> get instructions => $composableBuilder(
    column: $table.instructions,
    builder: (column) => column,
  );

  GeneratedColumn<int> get prepMinutes => $composableBuilder(
    column: $table.prepMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get servings =>
      $composableBuilder(column: $table.servings, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> recipeIngredientsRefs<T extends Object>(
    Expression<T> Function($$RecipeIngredientsTableAnnotationComposer a) f,
  ) {
    final $$RecipeIngredientsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.recipeIngredients,
          getReferencedColumn: (t) => t.recipeId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$RecipeIngredientsTableAnnotationComposer(
                $db: $db,
                $table: $db.recipeIngredients,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$RecipesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipesTable,
          Recipe,
          $$RecipesTableFilterComposer,
          $$RecipesTableOrderingComposer,
          $$RecipesTableAnnotationComposer,
          $$RecipesTableCreateCompanionBuilder,
          $$RecipesTableUpdateCompanionBuilder,
          (Recipe, $$RecipesTableReferences),
          Recipe,
          PrefetchHooks Function({bool recipeIngredientsRefs})
        > {
  $$RecipesTableTableManager(_$AppDatabase db, $RecipesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> instructions = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<int> servings = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion(
                id: id,
                title: title,
                instructions: instructions,
                prepMinutes: prepMinutes,
                servings: servings,
                photoPath: photoPath,
                isFavorite: isFavorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> instructions = const Value.absent(),
                Value<int?> prepMinutes = const Value.absent(),
                Value<int> servings = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipesCompanion.insert(
                id: id,
                title: title,
                instructions: instructions,
                prepMinutes: prepMinutes,
                servings: servings,
                photoPath: photoPath,
                isFavorite: isFavorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipesTable, Recipe>(table),
                  $$RecipesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeIngredientsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (recipeIngredientsRefs) db.recipeIngredients,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (recipeIngredientsRefs)
                    await $_getPrefetchedData<
                      Recipe,
                      $RecipesTable,
                      RecipeIngredient
                    >(
                      currentTable: table,
                      referencedTable: $$RecipesTableReferences
                          ._recipeIngredientsRefsTable(db),
                      managerFromTypedResult: (p0) => $$RecipesTableReferences(
                        db,
                        table,
                        p0,
                      ).recipeIngredientsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.recipeId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RecipesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipesTable,
      Recipe,
      $$RecipesTableFilterComposer,
      $$RecipesTableOrderingComposer,
      $$RecipesTableAnnotationComposer,
      $$RecipesTableCreateCompanionBuilder,
      $$RecipesTableUpdateCompanionBuilder,
      (Recipe, $$RecipesTableReferences),
      Recipe,
      PrefetchHooks Function({bool recipeIngredientsRefs})
    >;
typedef $$RecipeIngredientsTableCreateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      required String id,
      Value<String?> recipeId,
      Value<String?> productId,
      required String rawText,
      Value<int?> quantityMilli,
      Value<String?> unit,
      required int position,
      Value<int> rowid,
    });
typedef $$RecipeIngredientsTableUpdateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<String> id,
      Value<String?> recipeId,
      Value<String?> productId,
      Value<String> rawText,
      Value<int?> quantityMilli,
      Value<String?> unit,
      Value<int> position,
      Value<int> rowid,
    });

final class $$RecipeIngredientsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredient
        > {
  $$RecipeIngredientsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $RecipesTable _recipeIdTable(_$AppDatabase db) =>
      db.recipes.createAlias('recipe_ingredients__recipe_id__recipes__id');

  $$RecipesTableProcessedTableManager? get recipeId {
    final $_column = $_itemColumn<String>('recipe_id');
    if ($_column == null) return null;
    final manager = $$RecipesTableTableManager(
      $_db,
      $_db.recipes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('recipe_ingredients__product_id__products__id');

  $$ProductsTableProcessedTableManager? get productId {
    final $_column = $_itemColumn<String>('product_id');
    if ($_column == null) return null;
    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RecipeIngredientsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableFilterComposer({
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

  ColumnFilters<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$RecipesTableFilterComposer get recipeId {
    final $$RecipesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableFilterComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeIngredientsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableOrderingComposer({
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

  ColumnOrderings<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$RecipesTableOrderingComposer get recipeId {
    final $$RecipesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableOrderingComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeIngredientsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeIngredientsTable> {
  $$RecipeIngredientsTableAnnotationComposer({
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

  GeneratedColumn<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$RecipesTableAnnotationComposer get recipeId {
    final $$RecipesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.recipes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RecipesTableAnnotationComposer(
            $db: $db,
            $table: $db.recipes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RecipeIngredientsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeIngredientsTable,
          RecipeIngredient,
          $$RecipeIngredientsTableFilterComposer,
          $$RecipeIngredientsTableOrderingComposer,
          $$RecipeIngredientsTableAnnotationComposer,
          $$RecipeIngredientsTableCreateCompanionBuilder,
          $$RecipeIngredientsTableUpdateCompanionBuilder,
          (RecipeIngredient, $$RecipeIngredientsTableReferences),
          RecipeIngredient,
          PrefetchHooks Function({bool recipeId, bool productId})
        > {
  $$RecipeIngredientsTableTableManager(
    _$AppDatabase db,
    $RecipeIngredientsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeIngredientsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeIngredientsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeIngredientsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> recipeId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                Value<String> rawText = const Value.absent(),
                Value<int?> quantityMilli = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecipeIngredientsCompanion(
                id: id,
                recipeId: recipeId,
                productId: productId,
                rawText: rawText,
                quantityMilli: quantityMilli,
                unit: unit,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> recipeId = const Value.absent(),
                Value<String?> productId = const Value.absent(),
                required String rawText,
                Value<int?> quantityMilli = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => RecipeIngredientsCompanion.insert(
                id: id,
                recipeId: recipeId,
                productId: productId,
                rawText: rawText,
                quantityMilli: quantityMilli,
                unit: unit,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipeIngredientsTable, RecipeIngredient>(table),
                  $$RecipeIngredientsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false, productId = false}) {
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
                    if (recipeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.recipeId,
                        referencedTable: $$RecipeIngredientsTableReferences
                            ._recipeIdTable(db),
                        referencedColumn: $$RecipeIngredientsTableReferences
                            ._recipeIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$RecipeIngredientsTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$RecipeIngredientsTableReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
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

typedef $$RecipeIngredientsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeIngredientsTable,
      RecipeIngredient,
      $$RecipeIngredientsTableFilterComposer,
      $$RecipeIngredientsTableOrderingComposer,
      $$RecipeIngredientsTableAnnotationComposer,
      $$RecipeIngredientsTableCreateCompanionBuilder,
      $$RecipeIngredientsTableUpdateCompanionBuilder,
      (RecipeIngredient, $$RecipeIngredientsTableReferences),
      RecipeIngredient,
      PrefetchHooks Function({bool recipeId, bool productId})
    >;
typedef $$RecipeTagsTableCreateCompanionBuilder = RecipeTagsCompanion Function({
  required String recipeId,
  required String tag,
  Value<int> rowid,
});
typedef $$RecipeTagsTableUpdateCompanionBuilder = RecipeTagsCompanion Function({
  Value<String> recipeId,
  Value<String> tag,
  Value<int> rowid,
});

class $$RecipeTagsTableFilterComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecipeTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tag => $composableBuilder(
    column: $table.tag,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecipeTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecipeTagsTable> {
  $$RecipeTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<String> get tag =>
      $composableBuilder(column: $table.tag, builder: (column) => column);
}

class $$RecipeTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecipeTagsTable,
          RecipeTag,
          $$RecipeTagsTableFilterComposer,
          $$RecipeTagsTableOrderingComposer,
          $$RecipeTagsTableAnnotationComposer,
          $$RecipeTagsTableCreateCompanionBuilder,
          $$RecipeTagsTableUpdateCompanionBuilder,
          (
            RecipeTag,
            BaseReferences<_$AppDatabase, $RecipeTagsTable, RecipeTag>,
          ),
          RecipeTag,
          PrefetchHooks Function()
        > {
  $$RecipeTagsTableTableManager(_$AppDatabase db, $RecipeTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecipeTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecipeTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecipeTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> recipeId = const Value.absent(),
            Value<String> tag = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => RecipeTagsCompanion(recipeId: recipeId, tag: tag, rowid: rowid),
          createCompanionCallback:
              ({
                required String recipeId,
                required String tag,
                Value<int> rowid = const Value.absent(),
              }) => RecipeTagsCompanion.insert(
                recipeId: recipeId,
                tag: tag,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecipeTagsTable, RecipeTag>(table),
                  BaseReferences<_$AppDatabase, $RecipeTagsTable, RecipeTag>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecipeTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecipeTagsTable,
      RecipeTag,
      $$RecipeTagsTableFilterComposer,
      $$RecipeTagsTableOrderingComposer,
      $$RecipeTagsTableAnnotationComposer,
      $$RecipeTagsTableCreateCompanionBuilder,
      $$RecipeTagsTableUpdateCompanionBuilder,
      (RecipeTag, BaseReferences<_$AppDatabase, $RecipeTagsTable, RecipeTag>),
      RecipeTag,
      PrefetchHooks Function()
    >;
typedef $$StockItemsTableCreateCompanionBuilder = StockItemsCompanion Function({
  required String id,
  required String productId,
  Value<int> quantityMilli,
  Value<String> unit,
  Value<int?> lowStockThresholdMilli,
  Value<String?> lastRestockedAt,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});
typedef $$StockItemsTableUpdateCompanionBuilder = StockItemsCompanion Function({
  Value<String> id,
  Value<String> productId,
  Value<int> quantityMilli,
  Value<String> unit,
  Value<int?> lowStockThresholdMilli,
  Value<String?> lastRestockedAt,
  Value<String?> createdAt,
  Value<String?> updatedAt,
  Value<int> rowid,
});

final class $$StockItemsTableReferences
    extends BaseReferences<_$AppDatabase, $StockItemsTable, StockItem> {
  $$StockItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProductsTable _productIdTable(_$AppDatabase db) =>
      db.products.createAlias('stock_items__product_id__products__id');

  $$ProductsTableProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $$ProductsTableTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StockItemsTableFilterComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableFilterComposer({
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

  ColumnFilters<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lowStockThresholdMilli => $composableBuilder(
    column: $table.lowStockThresholdMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastRestockedAt => $composableBuilder(
    column: $table.lastRestockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProductsTableFilterComposer get productId {
    final $$ProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableOrderingComposer({
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

  ColumnOrderings<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lowStockThresholdMilli => $composableBuilder(
    column: $table.lowStockThresholdMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastRestockedAt => $composableBuilder(
    column: $table.lastRestockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProductsTableOrderingComposer get productId {
    final $$ProductsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StockItemsTable> {
  $$StockItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get quantityMilli => $composableBuilder(
    column: $table.quantityMilli,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get lowStockThresholdMilli => $composableBuilder(
    column: $table.lowStockThresholdMilli,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastRestockedAt => $composableBuilder(
    column: $table.lastRestockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProductsTableAnnotationComposer get productId {
    final $$ProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StockItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StockItemsTable,
          StockItem,
          $$StockItemsTableFilterComposer,
          $$StockItemsTableOrderingComposer,
          $$StockItemsTableAnnotationComposer,
          $$StockItemsTableCreateCompanionBuilder,
          $$StockItemsTableUpdateCompanionBuilder,
          (StockItem, $$StockItemsTableReferences),
          StockItem,
          PrefetchHooks Function({bool productId})
        > {
  $$StockItemsTableTableManager(_$AppDatabase db, $StockItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StockItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StockItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StockItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<int> quantityMilli = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int?> lowStockThresholdMilli = const Value.absent(),
                Value<String?> lastRestockedAt = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockItemsCompanion(
                id: id,
                productId: productId,
                quantityMilli: quantityMilli,
                unit: unit,
                lowStockThresholdMilli: lowStockThresholdMilli,
                lastRestockedAt: lastRestockedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                Value<int> quantityMilli = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<int?> lowStockThresholdMilli = const Value.absent(),
                Value<String?> lastRestockedAt = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StockItemsCompanion.insert(
                id: id,
                productId: productId,
                quantityMilli: quantityMilli,
                unit: unit,
                lowStockThresholdMilli: lowStockThresholdMilli,
                lastRestockedAt: lastRestockedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$StockItemsTable, StockItem>(table),
                  $$StockItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false}) {
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
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $$StockItemsTableReferences
                            ._productIdTable(db),
                        referencedColumn: $$StockItemsTableReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
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

typedef $$StockItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StockItemsTable,
      StockItem,
      $$StockItemsTableFilterComposer,
      $$StockItemsTableOrderingComposer,
      $$StockItemsTableAnnotationComposer,
      $$StockItemsTableCreateCompanionBuilder,
      $$StockItemsTableUpdateCompanionBuilder,
      (StockItem, $$StockItemsTableReferences),
      StockItem,
      PrefetchHooks Function({bool productId})
    >;
typedef $$ChecklistItemsTableCreateCompanionBuilder =
    ChecklistItemsCompanion Function({
      required String id,
      required String roomCategory,
      required String title,
      Value<bool> isMarked,
      Value<int> position,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$ChecklistItemsTableUpdateCompanionBuilder =
    ChecklistItemsCompanion Function({
      Value<String> id,
      Value<String> roomCategory,
      Value<String> title,
      Value<bool> isMarked,
      Value<int> position,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$ChecklistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableFilterComposer({
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

  ColumnFilters<String> get roomCategory => $composableBuilder(
    column: $table.roomCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMarked => $composableBuilder(
    column: $table.isMarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChecklistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableOrderingComposer({
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

  ColumnOrderings<String> get roomCategory => $composableBuilder(
    column: $table.roomCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMarked => $composableBuilder(
    column: $table.isMarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChecklistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChecklistItemsTable> {
  $$ChecklistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get roomCategory => $composableBuilder(
    column: $table.roomCategory,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isMarked =>
      $composableBuilder(column: $table.isMarked, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChecklistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChecklistItemsTable,
          ChecklistItem,
          $$ChecklistItemsTableFilterComposer,
          $$ChecklistItemsTableOrderingComposer,
          $$ChecklistItemsTableAnnotationComposer,
          $$ChecklistItemsTableCreateCompanionBuilder,
          $$ChecklistItemsTableUpdateCompanionBuilder,
          (
            ChecklistItem,
            BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItem>,
          ),
          ChecklistItem,
          PrefetchHooks Function()
        > {
  $$ChecklistItemsTableTableManager(
    _$AppDatabase db,
    $ChecklistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChecklistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChecklistItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChecklistItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> roomCategory = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isMarked = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistItemsCompanion(
                id: id,
                roomCategory: roomCategory,
                title: title,
                isMarked: isMarked,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String roomCategory,
                required String title,
                Value<bool> isMarked = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChecklistItemsCompanion.insert(
                id: id,
                roomCategory: roomCategory,
                title: title,
                isMarked: isMarked,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChecklistItemsTable, ChecklistItem>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ChecklistItemsTable,
                    ChecklistItem
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChecklistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChecklistItemsTable,
      ChecklistItem,
      $$ChecklistItemsTableFilterComposer,
      $$ChecklistItemsTableOrderingComposer,
      $$ChecklistItemsTableAnnotationComposer,
      $$ChecklistItemsTableCreateCompanionBuilder,
      $$ChecklistItemsTableUpdateCompanionBuilder,
      (
        ChecklistItem,
        BaseReferences<_$AppDatabase, $ChecklistItemsTable, ChecklistItem>,
      ),
      ChecklistItem,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<String?> updatedAt,
  Value<String?> testColumn,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<String?> updatedAt,
  Value<String?> testColumn,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get testColumn => $composableBuilder(
    column: $table.testColumn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get testColumn => $composableBuilder(
    column: $table.testColumn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get testColumn => $composableBuilder(
    column: $table.testColumn,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> testColumn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                testColumn: testColumn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<String?> updatedAt = const Value.absent(),
                Value<String?> testColumn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                testColumn: testColumn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$ConsentsTableCreateCompanionBuilder = ConsentsCompanion Function({
  required String key,
  required bool granted,
  Value<String?> grantedAt,
  Value<String?> revokedAt,
  Value<int> rowid,
});
typedef $$ConsentsTableUpdateCompanionBuilder = ConsentsCompanion Function({
  Value<String> key,
  Value<bool> granted,
  Value<String?> grantedAt,
  Value<String?> revokedAt,
  Value<int> rowid,
});

class $$ConsentsTableFilterComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get granted => $composableBuilder(
    column: $table.granted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grantedAt => $composableBuilder(
    column: $table.grantedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConsentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get granted => $composableBuilder(
    column: $table.granted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grantedAt => $composableBuilder(
    column: $table.grantedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get revokedAt => $composableBuilder(
    column: $table.revokedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConsentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConsentsTable> {
  $$ConsentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<bool> get granted =>
      $composableBuilder(column: $table.granted, builder: (column) => column);

  GeneratedColumn<String> get grantedAt =>
      $composableBuilder(column: $table.grantedAt, builder: (column) => column);

  GeneratedColumn<String> get revokedAt =>
      $composableBuilder(column: $table.revokedAt, builder: (column) => column);
}

class $$ConsentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConsentsTable,
          Consent,
          $$ConsentsTableFilterComposer,
          $$ConsentsTableOrderingComposer,
          $$ConsentsTableAnnotationComposer,
          $$ConsentsTableCreateCompanionBuilder,
          $$ConsentsTableUpdateCompanionBuilder,
          (Consent, BaseReferences<_$AppDatabase, $ConsentsTable, Consent>),
          Consent,
          PrefetchHooks Function()
        > {
  $$ConsentsTableTableManager(_$AppDatabase db, $ConsentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConsentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConsentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConsentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<bool> granted = const Value.absent(),
                Value<String?> grantedAt = const Value.absent(),
                Value<String?> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsentsCompanion(
                key: key,
                granted: granted,
                grantedAt: grantedAt,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required bool granted,
                Value<String?> grantedAt = const Value.absent(),
                Value<String?> revokedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConsentsCompanion.insert(
                key: key,
                granted: granted,
                grantedAt: grantedAt,
                revokedAt: revokedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ConsentsTable, Consent>(table),
                  BaseReferences<_$AppDatabase, $ConsentsTable, Consent>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConsentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConsentsTable,
      Consent,
      $$ConsentsTableFilterComposer,
      $$ConsentsTableOrderingComposer,
      $$ConsentsTableAnnotationComposer,
      $$ConsentsTableCreateCompanionBuilder,
      $$ConsentsTableUpdateCompanionBuilder,
      (Consent, BaseReferences<_$AppDatabase, $ConsentsTable, Consent>),
      Consent,
      PrefetchHooks Function()
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String id,
      required String path,
      Value<String?> kind,
      Value<String?> ownerType,
      Value<String?> ownerId,
      Value<String?> createdAt,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> id,
      Value<String> path,
      Value<String?> kind,
      Value<String?> ownerType,
      Value<String?> ownerId,
      Value<String?> createdAt,
      Value<int> rowid,
    });

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
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

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
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

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerType => $composableBuilder(
    column: $table.ownerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get ownerType =>
      $composableBuilder(column: $table.ownerType, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          Attachment,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (
            Attachment,
            BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>,
          ),
          Attachment,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<String?> ownerType = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                id: id,
                path: path,
                kind: kind,
                ownerType: ownerType,
                ownerId: ownerId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String path,
                Value<String?> kind = const Value.absent(),
                Value<String?> ownerType = const Value.absent(),
                Value<String?> ownerId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                id: id,
                path: path,
                kind: kind,
                ownerType: ownerType,
                ownerId: ownerId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttachmentsTable, Attachment>(table),
                  BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      Attachment,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (
        Attachment,
        BaseReferences<_$AppDatabase, $AttachmentsTable, Attachment>,
      ),
      Attachment,
      PrefetchHooks Function()
    >;
typedef $$SyncHouseholdsTableCreateCompanionBuilder =
    SyncHouseholdsCompanion Function({
      required String id,
      required String name,
      required String localSiteId,
      required String sharedAreas,
      required String createdAt,
      required String joinedAt,
      Value<bool> active,
      Value<int> rowid,
    });
typedef $$SyncHouseholdsTableUpdateCompanionBuilder =
    SyncHouseholdsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> localSiteId,
      Value<String> sharedAreas,
      Value<String> createdAt,
      Value<String> joinedAt,
      Value<bool> active,
      Value<int> rowid,
    });

final class $$SyncHouseholdsTableReferences
    extends BaseReferences<_$AppDatabase, $SyncHouseholdsTable, SyncHousehold> {
  $$SyncHouseholdsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SyncMembersTable, List<SyncMember>>
  _syncMembersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.syncMembers,
    aliasName: 'sync_household__id__sync_members__household_id',
  );

  $$SyncMembersTableProcessedTableManager get syncMembersRefs {
    final manager = $$SyncMembersTableTableManager(
      $_db,
      $_db.syncMembers,
    ).filter((f) => f.householdId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_syncMembersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyncHouseholdsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncHouseholdsTable> {
  $$SyncHouseholdsTableFilterComposer({
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

  ColumnFilters<String> get localSiteId => $composableBuilder(
    column: $table.localSiteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sharedAreas => $composableBuilder(
    column: $table.sharedAreas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> syncMembersRefs(
    Expression<bool> Function($$SyncMembersTableFilterComposer f) f,
  ) {
    final $$SyncMembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncMembers,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncMembersTableFilterComposer(
            $db: $db,
            $table: $db.syncMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyncHouseholdsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncHouseholdsTable> {
  $$SyncHouseholdsTableOrderingComposer({
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

  ColumnOrderings<String> get localSiteId => $composableBuilder(
    column: $table.localSiteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sharedAreas => $composableBuilder(
    column: $table.sharedAreas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncHouseholdsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncHouseholdsTable> {
  $$SyncHouseholdsTableAnnotationComposer({
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

  GeneratedColumn<String> get localSiteId => $composableBuilder(
    column: $table.localSiteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sharedAreas => $composableBuilder(
    column: $table.sharedAreas,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  Expression<T> syncMembersRefs<T extends Object>(
    Expression<T> Function($$SyncMembersTableAnnotationComposer a) f,
  ) {
    final $$SyncMembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.syncMembers,
      getReferencedColumn: (t) => t.householdId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncMembersTableAnnotationComposer(
            $db: $db,
            $table: $db.syncMembers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SyncHouseholdsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncHouseholdsTable,
          SyncHousehold,
          $$SyncHouseholdsTableFilterComposer,
          $$SyncHouseholdsTableOrderingComposer,
          $$SyncHouseholdsTableAnnotationComposer,
          $$SyncHouseholdsTableCreateCompanionBuilder,
          $$SyncHouseholdsTableUpdateCompanionBuilder,
          (SyncHousehold, $$SyncHouseholdsTableReferences),
          SyncHousehold,
          PrefetchHooks Function({bool syncMembersRefs})
        > {
  $$SyncHouseholdsTableTableManager(
    _$AppDatabase db,
    $SyncHouseholdsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncHouseholdsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncHouseholdsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncHouseholdsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> localSiteId = const Value.absent(),
                Value<String> sharedAreas = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> joinedAt = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncHouseholdsCompanion(
                id: id,
                name: name,
                localSiteId: localSiteId,
                sharedAreas: sharedAreas,
                createdAt: createdAt,
                joinedAt: joinedAt,
                active: active,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String localSiteId,
                required String sharedAreas,
                required String createdAt,
                required String joinedAt,
                Value<bool> active = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncHouseholdsCompanion.insert(
                id: id,
                name: name,
                localSiteId: localSiteId,
                sharedAreas: sharedAreas,
                createdAt: createdAt,
                joinedAt: joinedAt,
                active: active,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncHouseholdsTable, SyncHousehold>(table),
                  $$SyncHouseholdsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({syncMembersRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (syncMembersRefs) db.syncMembers],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (syncMembersRefs)
                    await $_getPrefetchedData<
                      SyncHousehold,
                      $SyncHouseholdsTable,
                      SyncMember
                    >(
                      currentTable: table,
                      referencedTable: $$SyncHouseholdsTableReferences
                          ._syncMembersRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SyncHouseholdsTableReferences(
                            db,
                            table,
                            p0,
                          ).syncMembersRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.householdId == item.id,
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

typedef $$SyncHouseholdsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncHouseholdsTable,
      SyncHousehold,
      $$SyncHouseholdsTableFilterComposer,
      $$SyncHouseholdsTableOrderingComposer,
      $$SyncHouseholdsTableAnnotationComposer,
      $$SyncHouseholdsTableCreateCompanionBuilder,
      $$SyncHouseholdsTableUpdateCompanionBuilder,
      (SyncHousehold, $$SyncHouseholdsTableReferences),
      SyncHousehold,
      PrefetchHooks Function({bool syncMembersRefs})
    >;
typedef $$SyncMembersTableCreateCompanionBuilder =
    SyncMembersCompanion Function({
      required String id,
      required String householdId,
      required String siteId,
      required String name,
      required String joinedAt,
      Value<String?> lastSeenAt,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$SyncMembersTableUpdateCompanionBuilder =
    SyncMembersCompanion Function({
      Value<String> id,
      Value<String> householdId,
      Value<String> siteId,
      Value<String> name,
      Value<String> joinedAt,
      Value<String?> lastSeenAt,
      Value<bool> isActive,
      Value<int> rowid,
    });

final class $$SyncMembersTableReferences
    extends BaseReferences<_$AppDatabase, $SyncMembersTable, SyncMember> {
  $$SyncMembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SyncHouseholdsTable _householdIdTable(_$AppDatabase db) => db
      .syncHouseholds
      .createAlias('sync_members__household_id__sync_household__id');

  $$SyncHouseholdsTableProcessedTableManager get householdId {
    final $_column = $_itemColumn<String>('household_id')!;

    final manager = $$SyncHouseholdsTableTableManager(
      $_db,
      $_db.syncHouseholds,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_householdIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncMembersTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMembersTable> {
  $$SyncMembersTableFilterComposer({
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

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  $$SyncHouseholdsTableFilterComposer get householdId {
    final $$SyncHouseholdsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.syncHouseholds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncHouseholdsTableFilterComposer(
            $db: $db,
            $table: $db.syncHouseholds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncMembersTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMembersTable> {
  $$SyncMembersTableOrderingComposer({
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

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get joinedAt => $composableBuilder(
    column: $table.joinedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyncHouseholdsTableOrderingComposer get householdId {
    final $$SyncHouseholdsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.syncHouseholds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncHouseholdsTableOrderingComposer(
            $db: $db,
            $table: $db.syncHouseholds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncMembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMembersTable> {
  $$SyncMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get joinedAt =>
      $composableBuilder(column: $table.joinedAt, builder: (column) => column);

  GeneratedColumn<String> get lastSeenAt => $composableBuilder(
    column: $table.lastSeenAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  $$SyncHouseholdsTableAnnotationComposer get householdId {
    final $$SyncHouseholdsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.householdId,
      referencedTable: $db.syncHouseholds,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncHouseholdsTableAnnotationComposer(
            $db: $db,
            $table: $db.syncHouseholds,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncMembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMembersTable,
          SyncMember,
          $$SyncMembersTableFilterComposer,
          $$SyncMembersTableOrderingComposer,
          $$SyncMembersTableAnnotationComposer,
          $$SyncMembersTableCreateCompanionBuilder,
          $$SyncMembersTableUpdateCompanionBuilder,
          (SyncMember, $$SyncMembersTableReferences),
          SyncMember,
          PrefetchHooks Function({bool householdId})
        > {
  $$SyncMembersTableTableManager(_$AppDatabase db, $SyncMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> householdId = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> joinedAt = const Value.absent(),
                Value<String?> lastSeenAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMembersCompanion(
                id: id,
                householdId: householdId,
                siteId: siteId,
                name: name,
                joinedAt: joinedAt,
                lastSeenAt: lastSeenAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String householdId,
                required String siteId,
                required String name,
                required String joinedAt,
                Value<String?> lastSeenAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMembersCompanion.insert(
                id: id,
                householdId: householdId,
                siteId: siteId,
                name: name,
                joinedAt: joinedAt,
                lastSeenAt: lastSeenAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMembersTable, SyncMember>(table),
                  $$SyncMembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({householdId = false}) {
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
                    if (householdId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.householdId,
                        referencedTable: $$SyncMembersTableReferences
                            ._householdIdTable(db),
                        referencedColumn: $$SyncMembersTableReferences
                            ._householdIdTable(db)
                            .id,
                      ) as T;
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

typedef $$SyncMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMembersTable,
      SyncMember,
      $$SyncMembersTableFilterComposer,
      $$SyncMembersTableOrderingComposer,
      $$SyncMembersTableAnnotationComposer,
      $$SyncMembersTableCreateCompanionBuilder,
      $$SyncMembersTableUpdateCompanionBuilder,
      (SyncMember, $$SyncMembersTableReferences),
      SyncMember,
      PrefetchHooks Function({bool householdId})
    >;
typedef $$SyncColumnVersionsTableCreateCompanionBuilder =
    SyncColumnVersionsCompanion Function({
      required String tableNameCol,
      required String rowId,
      required String columnName,
      required String hlc,
      required String siteId,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$SyncColumnVersionsTableUpdateCompanionBuilder =
    SyncColumnVersionsCompanion Function({
      Value<String> tableNameCol,
      Value<String> rowId,
      Value<String> columnName,
      Value<String> hlc,
      Value<String> siteId,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$SyncColumnVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncColumnVersionsTable> {
  $$SyncColumnVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tableNameCol => $composableBuilder(
    column: $table.tableNameCol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get columnName => $composableBuilder(
    column: $table.columnName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncColumnVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncColumnVersionsTable> {
  $$SyncColumnVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tableNameCol => $composableBuilder(
    column: $table.tableNameCol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get columnName => $composableBuilder(
    column: $table.columnName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncColumnVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncColumnVersionsTable> {
  $$SyncColumnVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tableNameCol => $composableBuilder(
    column: $table.tableNameCol,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get columnName => $composableBuilder(
    column: $table.columnName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncColumnVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncColumnVersionsTable,
          SyncColumnVersion,
          $$SyncColumnVersionsTableFilterComposer,
          $$SyncColumnVersionsTableOrderingComposer,
          $$SyncColumnVersionsTableAnnotationComposer,
          $$SyncColumnVersionsTableCreateCompanionBuilder,
          $$SyncColumnVersionsTableUpdateCompanionBuilder,
          (
            SyncColumnVersion,
            BaseReferences<
              _$AppDatabase,
              $SyncColumnVersionsTable,
              SyncColumnVersion
            >,
          ),
          SyncColumnVersion,
          PrefetchHooks Function()
        > {
  $$SyncColumnVersionsTableTableManager(
    _$AppDatabase db,
    $SyncColumnVersionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncColumnVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncColumnVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncColumnVersionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> tableNameCol = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> columnName = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncColumnVersionsCompanion(
                tableNameCol: tableNameCol,
                rowId: rowId,
                columnName: columnName,
                hlc: hlc,
                siteId: siteId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tableNameCol,
                required String rowId,
                required String columnName,
                required String hlc,
                required String siteId,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncColumnVersionsCompanion.insert(
                tableNameCol: tableNameCol,
                rowId: rowId,
                columnName: columnName,
                hlc: hlc,
                siteId: siteId,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncColumnVersionsTable, SyncColumnVersion>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncColumnVersionsTable,
                    SyncColumnVersion
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncColumnVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncColumnVersionsTable,
      SyncColumnVersion,
      $$SyncColumnVersionsTableFilterComposer,
      $$SyncColumnVersionsTableOrderingComposer,
      $$SyncColumnVersionsTableAnnotationComposer,
      $$SyncColumnVersionsTableCreateCompanionBuilder,
      $$SyncColumnVersionsTableUpdateCompanionBuilder,
      (
        SyncColumnVersion,
        BaseReferences<
          _$AppDatabase,
          $SyncColumnVersionsTable,
          SyncColumnVersion
        >,
      ),
      SyncColumnVersion,
      PrefetchHooks Function()
    >;
typedef $$SyncRowTombstonesTableCreateCompanionBuilder =
    SyncRowTombstonesCompanion Function({
      required String id,
      required String tableNameCol,
      required String rowId,
      required String hlc,
      required String purgedAt,
      Value<int> rowid,
    });
typedef $$SyncRowTombstonesTableUpdateCompanionBuilder =
    SyncRowTombstonesCompanion Function({
      Value<String> id,
      Value<String> tableNameCol,
      Value<String> rowId,
      Value<String> hlc,
      Value<String> purgedAt,
      Value<int> rowid,
    });

class $$SyncRowTombstonesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncRowTombstonesTable> {
  $$SyncRowTombstonesTableFilterComposer({
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

  ColumnFilters<String> get tableNameCol => $composableBuilder(
    column: $table.tableNameCol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purgedAt => $composableBuilder(
    column: $table.purgedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncRowTombstonesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncRowTombstonesTable> {
  $$SyncRowTombstonesTableOrderingComposer({
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

  ColumnOrderings<String> get tableNameCol => $composableBuilder(
    column: $table.tableNameCol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rowId => $composableBuilder(
    column: $table.rowId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purgedAt => $composableBuilder(
    column: $table.purgedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncRowTombstonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncRowTombstonesTable> {
  $$SyncRowTombstonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tableNameCol => $composableBuilder(
    column: $table.tableNameCol,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rowId =>
      $composableBuilder(column: $table.rowId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get purgedAt =>
      $composableBuilder(column: $table.purgedAt, builder: (column) => column);
}

class $$SyncRowTombstonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncRowTombstonesTable,
          SyncRowTombstone,
          $$SyncRowTombstonesTableFilterComposer,
          $$SyncRowTombstonesTableOrderingComposer,
          $$SyncRowTombstonesTableAnnotationComposer,
          $$SyncRowTombstonesTableCreateCompanionBuilder,
          $$SyncRowTombstonesTableUpdateCompanionBuilder,
          (
            SyncRowTombstone,
            BaseReferences<
              _$AppDatabase,
              $SyncRowTombstonesTable,
              SyncRowTombstone
            >,
          ),
          SyncRowTombstone,
          PrefetchHooks Function()
        > {
  $$SyncRowTombstonesTableTableManager(
    _$AppDatabase db,
    $SyncRowTombstonesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRowTombstonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRowTombstonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRowTombstonesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> tableNameCol = const Value.absent(),
                Value<String> rowId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<String> purgedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRowTombstonesCompanion(
                id: id,
                tableNameCol: tableNameCol,
                rowId: rowId,
                hlc: hlc,
                purgedAt: purgedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String tableNameCol,
                required String rowId,
                required String hlc,
                required String purgedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncRowTombstonesCompanion.insert(
                id: id,
                tableNameCol: tableNameCol,
                rowId: rowId,
                hlc: hlc,
                purgedAt: purgedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncRowTombstonesTable, SyncRowTombstone>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncRowTombstonesTable,
                    SyncRowTombstone
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncRowTombstonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncRowTombstonesTable,
      SyncRowTombstone,
      $$SyncRowTombstonesTableFilterComposer,
      $$SyncRowTombstonesTableOrderingComposer,
      $$SyncRowTombstonesTableAnnotationComposer,
      $$SyncRowTombstonesTableCreateCompanionBuilder,
      $$SyncRowTombstonesTableUpdateCompanionBuilder,
      (
        SyncRowTombstone,
        BaseReferences<
          _$AppDatabase,
          $SyncRowTombstonesTable,
          SyncRowTombstone
        >,
      ),
      SyncRowTombstone,
      PrefetchHooks Function()
    >;
typedef $$SyncPeerVectorsTableCreateCompanionBuilder =
    SyncPeerVectorsCompanion Function({
      required String householdId,
      required String siteId,
      required String hlc,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$SyncPeerVectorsTableUpdateCompanionBuilder =
    SyncPeerVectorsCompanion Function({
      Value<String> householdId,
      Value<String> siteId,
      Value<String> hlc,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$SyncPeerVectorsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncPeerVectorsTable> {
  $$SyncPeerVectorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncPeerVectorsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncPeerVectorsTable> {
  $$SyncPeerVectorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get siteId => $composableBuilder(
    column: $table.siteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncPeerVectorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncPeerVectorsTable> {
  $$SyncPeerVectorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get siteId =>
      $composableBuilder(column: $table.siteId, builder: (column) => column);

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncPeerVectorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncPeerVectorsTable,
          SyncPeerVector,
          $$SyncPeerVectorsTableFilterComposer,
          $$SyncPeerVectorsTableOrderingComposer,
          $$SyncPeerVectorsTableAnnotationComposer,
          $$SyncPeerVectorsTableCreateCompanionBuilder,
          $$SyncPeerVectorsTableUpdateCompanionBuilder,
          (
            SyncPeerVector,
            BaseReferences<
              _$AppDatabase,
              $SyncPeerVectorsTable,
              SyncPeerVector
            >,
          ),
          SyncPeerVector,
          PrefetchHooks Function()
        > {
  $$SyncPeerVectorsTableTableManager(
    _$AppDatabase db,
    $SyncPeerVectorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPeerVectorsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPeerVectorsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPeerVectorsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> householdId = const Value.absent(),
                Value<String> siteId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPeerVectorsCompanion(
                householdId: householdId,
                siteId: siteId,
                hlc: hlc,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String householdId,
                required String siteId,
                required String hlc,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncPeerVectorsCompanion.insert(
                householdId: householdId,
                siteId: siteId,
                hlc: hlc,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncPeerVectorsTable, SyncPeerVector>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncPeerVectorsTable,
                    SyncPeerVector
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncPeerVectorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncPeerVectorsTable,
      SyncPeerVector,
      $$SyncPeerVectorsTableFilterComposer,
      $$SyncPeerVectorsTableOrderingComposer,
      $$SyncPeerVectorsTableAnnotationComposer,
      $$SyncPeerVectorsTableCreateCompanionBuilder,
      $$SyncPeerVectorsTableUpdateCompanionBuilder,
      (
        SyncPeerVector,
        BaseReferences<_$AppDatabase, $SyncPeerVectorsTable, SyncPeerVector>,
      ),
      SyncPeerVector,
      PrefetchHooks Function()
    >;
typedef $$SyncMemberAcksTableCreateCompanionBuilder =
    SyncMemberAcksCompanion Function({
      required String householdId,
      required String memberSiteId,
      required String originSiteId,
      required String hlc,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$SyncMemberAcksTableUpdateCompanionBuilder =
    SyncMemberAcksCompanion Function({
      Value<String> householdId,
      Value<String> memberSiteId,
      Value<String> originSiteId,
      Value<String> hlc,
      Value<String> updatedAt,
      Value<int> rowid,
    });

class $$SyncMemberAcksTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMemberAcksTable> {
  $$SyncMemberAcksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberSiteId => $composableBuilder(
    column: $table.memberSiteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originSiteId => $composableBuilder(
    column: $table.originSiteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMemberAcksTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMemberAcksTable> {
  $$SyncMemberAcksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberSiteId => $composableBuilder(
    column: $table.memberSiteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originSiteId => $composableBuilder(
    column: $table.originSiteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMemberAcksTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMemberAcksTable> {
  $$SyncMemberAcksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get memberSiteId => $composableBuilder(
    column: $table.memberSiteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originSiteId => $composableBuilder(
    column: $table.originSiteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SyncMemberAcksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMemberAcksTable,
          SyncMemberAck,
          $$SyncMemberAcksTableFilterComposer,
          $$SyncMemberAcksTableOrderingComposer,
          $$SyncMemberAcksTableAnnotationComposer,
          $$SyncMemberAcksTableCreateCompanionBuilder,
          $$SyncMemberAcksTableUpdateCompanionBuilder,
          (
            SyncMemberAck,
            BaseReferences<_$AppDatabase, $SyncMemberAcksTable, SyncMemberAck>,
          ),
          SyncMemberAck,
          PrefetchHooks Function()
        > {
  $$SyncMemberAcksTableTableManager(
    _$AppDatabase db,
    $SyncMemberAcksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMemberAcksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMemberAcksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMemberAcksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> householdId = const Value.absent(),
                Value<String> memberSiteId = const Value.absent(),
                Value<String> originSiteId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMemberAcksCompanion(
                householdId: householdId,
                memberSiteId: memberSiteId,
                originSiteId: originSiteId,
                hlc: hlc,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String householdId,
                required String memberSiteId,
                required String originSiteId,
                required String hlc,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncMemberAcksCompanion.insert(
                householdId: householdId,
                memberSiteId: memberSiteId,
                originSiteId: originSiteId,
                hlc: hlc,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncMemberAcksTable, SyncMemberAck>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncMemberAcksTable,
                    SyncMemberAck
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMemberAcksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMemberAcksTable,
      SyncMemberAck,
      $$SyncMemberAcksTableFilterComposer,
      $$SyncMemberAcksTableOrderingComposer,
      $$SyncMemberAcksTableAnnotationComposer,
      $$SyncMemberAcksTableCreateCompanionBuilder,
      $$SyncMemberAcksTableUpdateCompanionBuilder,
      (
        SyncMemberAck,
        BaseReferences<_$AppDatabase, $SyncMemberAcksTable, SyncMemberAck>,
      ),
      SyncMemberAck,
      PrefetchHooks Function()
    >;
typedef $$SyncAppliedBundlesTableCreateCompanionBuilder =
    SyncAppliedBundlesCompanion Function({
      required String digest,
      required String appliedAt,
      Value<int> rowid,
    });
typedef $$SyncAppliedBundlesTableUpdateCompanionBuilder =
    SyncAppliedBundlesCompanion Function({
      Value<String> digest,
      Value<String> appliedAt,
      Value<int> rowid,
    });

class $$SyncAppliedBundlesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncAppliedBundlesTable> {
  $$SyncAppliedBundlesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncAppliedBundlesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncAppliedBundlesTable> {
  $$SyncAppliedBundlesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appliedAt => $composableBuilder(
    column: $table.appliedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncAppliedBundlesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncAppliedBundlesTable> {
  $$SyncAppliedBundlesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get digest =>
      $composableBuilder(column: $table.digest, builder: (column) => column);

  GeneratedColumn<String> get appliedAt =>
      $composableBuilder(column: $table.appliedAt, builder: (column) => column);
}

class $$SyncAppliedBundlesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncAppliedBundlesTable,
          SyncAppliedBundle,
          $$SyncAppliedBundlesTableFilterComposer,
          $$SyncAppliedBundlesTableOrderingComposer,
          $$SyncAppliedBundlesTableAnnotationComposer,
          $$SyncAppliedBundlesTableCreateCompanionBuilder,
          $$SyncAppliedBundlesTableUpdateCompanionBuilder,
          (
            SyncAppliedBundle,
            BaseReferences<
              _$AppDatabase,
              $SyncAppliedBundlesTable,
              SyncAppliedBundle
            >,
          ),
          SyncAppliedBundle,
          PrefetchHooks Function()
        > {
  $$SyncAppliedBundlesTableTableManager(
    _$AppDatabase db,
    $SyncAppliedBundlesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncAppliedBundlesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncAppliedBundlesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncAppliedBundlesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> digest = const Value.absent(),
                Value<String> appliedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncAppliedBundlesCompanion(
                digest: digest,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String digest,
                required String appliedAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncAppliedBundlesCompanion.insert(
                digest: digest,
                appliedAt: appliedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncAppliedBundlesTable, SyncAppliedBundle>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncAppliedBundlesTable,
                    SyncAppliedBundle
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncAppliedBundlesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncAppliedBundlesTable,
      SyncAppliedBundle,
      $$SyncAppliedBundlesTableFilterComposer,
      $$SyncAppliedBundlesTableOrderingComposer,
      $$SyncAppliedBundlesTableAnnotationComposer,
      $$SyncAppliedBundlesTableCreateCompanionBuilder,
      $$SyncAppliedBundlesTableUpdateCompanionBuilder,
      (
        SyncAppliedBundle,
        BaseReferences<
          _$AppDatabase,
          $SyncAppliedBundlesTable,
          SyncAppliedBundle
        >,
      ),
      SyncAppliedBundle,
      PrefetchHooks Function()
    >;
typedef $$SyncCompactionHorizonTableCreateCompanionBuilder =
    SyncCompactionHorizonCompanion Function({
      required String householdId,
      required String originSiteId,
      required String hlc,
      Value<int> rowid,
    });
typedef $$SyncCompactionHorizonTableUpdateCompanionBuilder =
    SyncCompactionHorizonCompanion Function({
      Value<String> householdId,
      Value<String> originSiteId,
      Value<String> hlc,
      Value<int> rowid,
    });

class $$SyncCompactionHorizonTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCompactionHorizonTable> {
  $$SyncCompactionHorizonTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originSiteId => $composableBuilder(
    column: $table.originSiteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCompactionHorizonTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCompactionHorizonTable> {
  $$SyncCompactionHorizonTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originSiteId => $composableBuilder(
    column: $table.originSiteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hlc => $composableBuilder(
    column: $table.hlc,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCompactionHorizonTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCompactionHorizonTable> {
  $$SyncCompactionHorizonTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get householdId => $composableBuilder(
    column: $table.householdId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get originSiteId => $composableBuilder(
    column: $table.originSiteId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get hlc =>
      $composableBuilder(column: $table.hlc, builder: (column) => column);
}

class $$SyncCompactionHorizonTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCompactionHorizonTable,
          SyncCompactionHorizonData,
          $$SyncCompactionHorizonTableFilterComposer,
          $$SyncCompactionHorizonTableOrderingComposer,
          $$SyncCompactionHorizonTableAnnotationComposer,
          $$SyncCompactionHorizonTableCreateCompanionBuilder,
          $$SyncCompactionHorizonTableUpdateCompanionBuilder,
          (
            SyncCompactionHorizonData,
            BaseReferences<
              _$AppDatabase,
              $SyncCompactionHorizonTable,
              SyncCompactionHorizonData
            >,
          ),
          SyncCompactionHorizonData,
          PrefetchHooks Function()
        > {
  $$SyncCompactionHorizonTableTableManager(
    _$AppDatabase db,
    $SyncCompactionHorizonTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCompactionHorizonTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SyncCompactionHorizonTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncCompactionHorizonTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> householdId = const Value.absent(),
                Value<String> originSiteId = const Value.absent(),
                Value<String> hlc = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCompactionHorizonCompanion(
                householdId: householdId,
                originSiteId: originSiteId,
                hlc: hlc,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String householdId,
                required String originSiteId,
                required String hlc,
                Value<int> rowid = const Value.absent(),
              }) => SyncCompactionHorizonCompanion.insert(
                householdId: householdId,
                originSiteId: originSiteId,
                hlc: hlc,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SyncCompactionHorizonTable,
                    SyncCompactionHorizonData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncCompactionHorizonTable,
                    SyncCompactionHorizonData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCompactionHorizonTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCompactionHorizonTable,
      SyncCompactionHorizonData,
      $$SyncCompactionHorizonTableFilterComposer,
      $$SyncCompactionHorizonTableOrderingComposer,
      $$SyncCompactionHorizonTableAnnotationComposer,
      $$SyncCompactionHorizonTableCreateCompanionBuilder,
      $$SyncCompactionHorizonTableUpdateCompanionBuilder,
      (
        SyncCompactionHorizonData,
        BaseReferences<
          _$AppDatabase,
          $SyncCompactionHorizonTable,
          SyncCompactionHorizonData
        >,
      ),
      SyncCompactionHorizonData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
  $$ProductAliasesTableTableManager get productAliases =>
      $$ProductAliasesTableTableManager(_db, _db.productAliases);
  $$ProductDenialsTableTableManager get productDenials =>
      $$ProductDenialsTableTableManager(_db, _db.productDenials);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db, _db.stores);
  $$RecurringRulesTableTableManager get recurringRules =>
      $$RecurringRulesTableTableManager(_db, _db.recurringRules);
  $$BillsTableTableManager get bills =>
      $$BillsTableTableManager(_db, _db.bills);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db, _db.purchases);
  $$PurchaseItemsTableTableManager get purchaseItems =>
      $$PurchaseItemsTableTableManager(_db, _db.purchaseItems);
  $$PricePointsTableTableManager get pricePoints =>
      $$PricePointsTableTableManager(_db, _db.pricePoints);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$BillPaymentsTableTableManager get billPayments =>
      $$BillPaymentsTableTableManager(_db, _db.billPayments);
  $$ShoppingListsTableTableManager get shoppingLists =>
      $$ShoppingListsTableTableManager(_db, _db.shoppingLists);
  $$ShoppingItemsTableTableManager get shoppingItems =>
      $$ShoppingItemsTableTableManager(_db, _db.shoppingItems);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$RecipesTableTableManager get recipes =>
      $$RecipesTableTableManager(_db, _db.recipes);
  $$RecipeIngredientsTableTableManager get recipeIngredients =>
      $$RecipeIngredientsTableTableManager(_db, _db.recipeIngredients);
  $$RecipeTagsTableTableManager get recipeTags =>
      $$RecipeTagsTableTableManager(_db, _db.recipeTags);
  $$StockItemsTableTableManager get stockItems =>
      $$StockItemsTableTableManager(_db, _db.stockItems);
  $$ChecklistItemsTableTableManager get checklistItems =>
      $$ChecklistItemsTableTableManager(_db, _db.checklistItems);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$ConsentsTableTableManager get consents =>
      $$ConsentsTableTableManager(_db, _db.consents);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$SyncHouseholdsTableTableManager get syncHouseholds =>
      $$SyncHouseholdsTableTableManager(_db, _db.syncHouseholds);
  $$SyncMembersTableTableManager get syncMembers =>
      $$SyncMembersTableTableManager(_db, _db.syncMembers);
  $$SyncColumnVersionsTableTableManager get syncColumnVersions =>
      $$SyncColumnVersionsTableTableManager(_db, _db.syncColumnVersions);
  $$SyncRowTombstonesTableTableManager get syncRowTombstones =>
      $$SyncRowTombstonesTableTableManager(_db, _db.syncRowTombstones);
  $$SyncPeerVectorsTableTableManager get syncPeerVectors =>
      $$SyncPeerVectorsTableTableManager(_db, _db.syncPeerVectors);
  $$SyncMemberAcksTableTableManager get syncMemberAcks =>
      $$SyncMemberAcksTableTableManager(_db, _db.syncMemberAcks);
  $$SyncAppliedBundlesTableTableManager get syncAppliedBundles =>
      $$SyncAppliedBundlesTableTableManager(_db, _db.syncAppliedBundles);
  $$SyncCompactionHorizonTableTableManager get syncCompactionHorizon =>
      $$SyncCompactionHorizonTableTableManager(_db, _db.syncCompactionHorizon);
}
