import 'package:drift/drift.dart';
import '../app_database.dart';

part 'payments_dao.g.dart';

/// 16.2.4 — Local Payment DAO
@DriftAccessor(tables: [LocalPayments])
class PaymentsDao extends DatabaseAccessor<AppDatabase>
    with _$PaymentsDaoMixin {
  PaymentsDao(super.db);

  Future<void> insertPayment(LocalPaymentsCompanion payment) =>
      into(localPayments)
          .insert(payment, mode: InsertMode.insertOrReplace);

  Future<List<LocalPaymentRow>> getPaymentsByOrder(String orderId) =>
      (select(localPayments)
            ..where((p) => p.orderId.equals(orderId)))
          .get();

  Future<List<LocalPaymentRow>> getUnsyncedPayments() =>
      (select(localPayments)..where((p) => p.isSynced.equals(false)))
          .get();

  Future<void> markPaymentSynced(String id) =>
      (update(localPayments)..where((p) => p.id.equals(id))).write(
        const LocalPaymentsCompanion(isSynced: Value(true)),
      );
}
