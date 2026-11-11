library;

// coverage:ignore-file
import 'package:drift/drift.dart';

// ---------------------------------------------------------------------------
// F002: Products and synonyms
// ---------------------------------------------------------------------------

class Products extends Table {
  TextColumn get id => text()(); // PK: UUID v7
  TextColumn get canonicalName => text()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get defaultUnit => text()(); // un | kg | g | l | ml | pack
  IntColumn get packageSizeMilli => integer().nullable()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProductAliases extends Table {
  TextColumn get id => text()();
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get alias => text()();
  TextColumn get normalizedAlias => text()();
  TextColumn get source => text()(); // seed | user | ocr
  TextColumn get createdAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {normalizedAlias, productId},
  ];
}

class ProductDenials extends Table {
  TextColumn get id => text()();
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.cascade)();
  TextColumn get rawText => text()();
  TextColumn get normalizedText => text()();
  TextColumn get createdAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {normalizedText, productId},
  ];
}

// ---------------------------------------------------------------------------
// F003: Establishments, purchases, and prices
// ---------------------------------------------------------------------------

class Stores extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get cnpj => text().nullable().unique()();
  TextColumn get address => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Purchases extends Table {
  TextColumn get id => text()();
  TextColumn get storeId => text().nullable().references(Stores, #id)();
  TextColumn get purchasedAt => text()();
  IntColumn get totalCents => integer()();
  IntColumn get discountCents => integer().withDefault(const Constant(0))();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get receiptImagePath => text().nullable()();
  TextColumn get receiptKey => text().nullable()();
  TextColumn get source => text()(); // manual | ocr
  TextColumn get expenseId => text().nullable().references(Expenses, #id)();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PurchaseItems extends Table {
  TextColumn get id => text()();
  TextColumn get purchaseId =>
      text().references(Purchases, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get rawDescription => text()();
  IntColumn get quantityMilli => integer()();
  TextColumn get unit => text()();
  IntColumn get unitPriceCents => integer()();
  IntColumn get totalPriceCents => integer()();
  TextColumn get ean => text().nullable()();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class PricePoints extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get storeId => text().nullable().references(Stores, #id)();
  TextColumn get observedAt => text()();
  IntColumn get unitPriceCents => integer()();
  IntColumn get normalizedPriceCents => integer()();
  IntColumn get quantityMilli => integer()();
  TextColumn get unit => text()();
  TextColumn get purchaseItemId =>
      text().nullable().references(PurchaseItems, #id)();
  TextColumn get source => text()(); // manual | ocr
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// F005: Expenses and budget
// ---------------------------------------------------------------------------

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()(); // expense | product | task | recipe
  TextColumn get iconKey => text()();
  TextColumn get colorHex => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get amountCents => integer()();
  TextColumn get occurredOn => text()(); // ISO yyyy-MM-dd
  TextColumn get description => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get recurringRuleId =>
      text().nullable().references(RecurringRules, #id)();
  TextColumn get billId => text().nullable().references(Bills, #id)();
  TextColumn get purchaseId => text().nullable().references(Purchases, #id)();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get yearMonth => text()(); // 2026-09
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  IntColumn get limitCents => integer()();
  IntColumn get baseIncomeCents => integer().withDefault(const Constant(0))();
  IntColumn get extraIncomeCents => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {yearMonth, categoryId},
  ];
}

class RecurringRules extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()(); // expense | task | bill
  TextColumn get rrule => text()();
  TextColumn get startsOn => text()();
  TextColumn get endsOn => text().nullable()();
  IntColumn get amountCents => integer().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get lastMaterializedOn => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// F006: Recurring bills
// ---------------------------------------------------------------------------

class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get amountCents => integer().nullable()();
  BoolColumn get isAmountVariable => boolean()();
  IntColumn get dueDay => integer()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get paymentMethod => text().nullable()();
  IntColumn get reminderDaysBefore =>
      integer().withDefault(const Constant(3))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class BillPayments extends Table {
  TextColumn get id => text()();
  TextColumn get billId => text().nullable().references(Bills, #id)();
  TextColumn get dueOn => text()();
  TextColumn get paidOn => text().nullable()();
  IntColumn get amountCents => integer().nullable()();
  TextColumn get status => text()(); // pending|paid|late|skipped
  TextColumn get expenseId => text().nullable().references(Expenses, #id)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {billId, dueOn},
  ];
}

// ---------------------------------------------------------------------------
// F004: Shopping list
// ---------------------------------------------------------------------------

class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get storeId => text().nullable().references(Stores, #id)();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text().nullable().references(
    ShoppingLists,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get freeText => text().nullable()();
  IntColumn get quantityMilli => integer().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get estimatedPriceCents => integer().nullable()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  TextColumn get checkedAt => text().nullable()();
  TextColumn get source => text()(); // manual | recipe | suggestion
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// F007: Tasks
// ---------------------------------------------------------------------------

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get dueAt => text().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(true))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  TextColumn get completedAt => text().nullable()();
  TextColumn get recurringRuleId =>
      text().nullable().references(RecurringRules, #id)();
  TextColumn get remoteEventId => text().nullable()();
  TextColumn get remoteEtag => text().nullable()();
  TextColumn get syncState => text().nullable()(); // synced|dirty|conflict
  TextColumn get sourcePresetId => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get deletedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// F008: Receitas
// ---------------------------------------------------------------------------

class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get instructions => text().nullable()();
  IntColumn get prepMinutes => integer().nullable()();
  IntColumn get servings => integer().withDefault(const Constant(2))();
  TextColumn get photoPath => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecipeIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId =>
      text().nullable().references(Recipes, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text().nullable().references(Products, #id)();
  TextColumn get rawText => text()();
  IntColumn get quantityMilli => integer().nullable()();
  TextColumn get unit => text().nullable()();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class RecipeTags extends Table {
  TextColumn get recipeId => text()();
  TextColumn get tag => text()();

  @override
  Set<Column> get primaryKey => {recipeId, tag};
}

// ---------------------------------------------------------------------------
// F011: Extras (Inventory and Checklist)
// ---------------------------------------------------------------------------

class StockItems extends Table {
  TextColumn get id => text()();
  TextColumn get productId =>
      text().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get quantityMilli => integer().withDefault(const Constant(0))();
  TextColumn get unit => text().withDefault(const Constant('un'))();
  IntColumn get lowStockThresholdMilli => integer().nullable()();
  TextColumn get lastRestockedAt => text().nullable()();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistItems extends Table {
  TextColumn get id => text()();
  TextColumn get roomCategory => text()();
  TextColumn get title => text()();
  BoolColumn get isMarked => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text().nullable()();
  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// Cross-cutting
// ---------------------------------------------------------------------------

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  TextColumn get updatedAt => text().nullable()();
  TextColumn get testColumn =>
      text().nullable()(); // Only for v1->v2 migration testing

  @override
  Set<Column> get primaryKey => {key};
}

class Consents extends Table {
  TextColumn get key => text()();
  BoolColumn get granted => boolean()();
  TextColumn get grantedAt => text().nullable()();
  TextColumn get revokedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get path => text()();
  TextColumn get kind => text().nullable()();
  TextColumn get ownerType => text().nullable()();
  TextColumn get ownerId => text().nullable()();
  TextColumn get createdAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
