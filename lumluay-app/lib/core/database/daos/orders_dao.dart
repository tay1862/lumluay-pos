import 'package:drift/drift.dart';
import '../app_database.dart';

part 'orders_dao.g.dart';

/// 16.2.3 — Local Order DAO
@DriftAccessor(tables: [LocalOrders, LocalOrderItems])
class OrdersDao extends DatabaseAccessor<AppDatabase>
    with _$OrdersDaoMixin {
  OrdersDao(super.db);

  // ── Orders ─────────────────────────────────────────────────────────────────

  Future<List<LocalOrderRow>> getOrders({String? status}) {
    final query = select(localOrders)
      ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]);
    if (status != null && status != 'all') {
      query.where((o) => o.status.equals(status));
    }
    return query.get();
  }

  Future<LocalOrderRow?> getOrder(String id) =>
      (select(localOrders)..where((o) => o.id.equals(id)))
          .getSingleOrNull();

  Future<List<LocalOrderRow>> getUnsyncedOrders() =>
      (select(localOrders)..where((o) => o.isSynced.equals(false)))
          .get();

  Future<void> insertOrder(LocalOrdersCompanion order) =>
      into(localOrders).insert(order, mode: InsertMode.insertOrReplace);

  Future<void> updateOrderStatus(String id, String status) =>
      (update(localOrders)..where((o) => o.id.equals(id))).write(
        LocalOrdersCompanion(status: Value(status)),
      );

  Future<void> markOrderSynced(String id) =>
      (update(localOrders)..where((o) => o.id.equals(id))).write(
        const LocalOrdersCompanion(isSynced: Value(true)),
      );

  // ── Order Items ────────────────────────────────────────────────────────────

  Future<List<LocalOrderItemRow>> getOrderItems(String orderId) =>
      (select(localOrderItems)
            ..where((i) => i.orderId.equals(orderId)))
          .get();

  Future<void> insertOrderItem(LocalOrderItemsCompanion item) =>
      into(localOrderItems)
          .insert(item, mode: InsertMode.insertOrReplace);

  Future<void> deleteOrderItems(String orderId) =>
      (delete(localOrderItems)
            ..where((i) => i.orderId.equals(orderId)))
          .go();
}
