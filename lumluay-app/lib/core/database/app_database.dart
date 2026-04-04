import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database_native.dart'
    if (dart.library.html) 'database_web.dart' as db;

import 'daos/products_dao.dart';
import 'daos/orders_dao.dart';
import 'daos/payments_dao.dart';
import 'daos/shifts_dao.dart';
import 'daos/sync_queue_dao.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Table definitions (16.2.1)
// ─────────────────────────────────────────────────────────────────────────────

@DataClassName('LocalCategoryRow')
class LocalCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalProductRow')
class LocalProducts extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get name => text()();
  RealColumn get basePrice => real().withDefault(const Constant(0.0))();
  TextColumn get sku => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get productType =>
      text().withDefault(const Constant('simple'))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get trackStock =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder =>
      integer().withDefault(const Constant(0))();
  // Serialised JSON for extra / tags
  TextColumn get extraJson =>
      text().withDefault(const Constant('{}'))();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalOrderRow')
class LocalOrders extends Table {
  TextColumn get id => text()();
  TextColumn get receiptNumber => text()();
  TextColumn get status =>
      text().withDefault(const Constant('open'))();
  TextColumn get orderType =>
      text().withDefault(const Constant('dine_in'))();
  TextColumn get tableId => text().nullable()();
  TextColumn get memberId => text().nullable()();
  RealColumn get subtotal =>
      real().withDefault(const Constant(0.0))();
  RealColumn get discountAmount =>
      real().withDefault(const Constant(0.0))();
  RealColumn get taxAmount =>
      real().withDefault(const Constant(0.0))();
  RealColumn get totalAmount =>
      real().withDefault(const Constant(0.0))();
  TextColumn get createdAt => text()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalOrderItemRow')
class LocalOrderItems extends Table {
  TextColumn get id => text()();
  TextColumn get orderId =>
      text().references(LocalOrders, #id, onDelete: KeyAction.cascade)();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  TextColumn get variantId => text().nullable()();
  TextColumn get variantName => text().nullable()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get unitPrice =>
      real().withDefault(const Constant(0.0))();
  RealColumn get lineTotal =>
      real().withDefault(const Constant(0.0))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalPaymentRow')
class LocalPayments extends Table {
  TextColumn get id => text()();
  TextColumn get orderId =>
      text().references(LocalOrders, #id, onDelete: KeyAction.cascade)();
  TextColumn get method => text()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  TextColumn get reference => text().nullable()();
  TextColumn get createdAt => text()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalShiftRow')
class LocalShifts extends Table {
  TextColumn get id => text()();
  TextColumn get status =>
      text().withDefault(const Constant('open'))();
  RealColumn get openingCash =>
      real().withDefault(const Constant(0.0))();
  RealColumn get closingCash => real().nullable()();
  TextColumn get openedAt => text()();
  TextColumn get closedAt => text().nullable()();
  BoolColumn get isSynced =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalSyncQueueRow')
class LocalSyncQueue extends Table {
  TextColumn get id => text()();
  TextColumn get operation => text()(); // create | update | delete
  TextColumn get entityType => text()();
  TextColumn get entityId => text().nullable()();
  TextColumn get payload => text()(); // JSON string
  TextColumn get checksum => text().nullable()();
  // pending | syncing | completed | failed
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  IntColumn get attempts =>
      integer().withDefault(const Constant(0))();
  TextColumn get clientTimestamp => text()();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────────────────────
// Database (16.2.1)
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(
  tables: [
    LocalCategories,
    LocalProducts,
    LocalOrders,
    LocalOrderItems,
    LocalPayments,
    LocalShifts,
    LocalSyncQueue,
  ],
  daos: [
    ProductsDao,
    OrdersDao,
    PaymentsDao,
    ShiftsDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(db.openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
