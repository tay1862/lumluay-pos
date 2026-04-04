import 'package:drift/drift.dart';
import '../app_database.dart';

part 'shifts_dao.g.dart';

/// 16.2.5 — Local Shift DAO
@DriftAccessor(tables: [LocalShifts])
class ShiftsDao extends DatabaseAccessor<AppDatabase>
    with _$ShiftsDaoMixin {
  ShiftsDao(super.db);

  Future<void> upsertShift(LocalShiftsCompanion shift) =>
      into(localShifts).insertOnConflictUpdate(shift);

  Future<LocalShiftRow?> getCurrentOpenShift() =>
      (select(localShifts)..where((s) => s.status.equals('open')))
          .getSingleOrNull();

  Future<List<LocalShiftRow>> getAll() =>
      (select(localShifts)
            ..orderBy([(s) => OrderingTerm.desc(s.openedAt)]))
          .get();

  Future<void> closeShift(
    String id, {
    required double closingCash,
    required String closedAt,
  }) =>
      (update(localShifts)..where((s) => s.id.equals(id))).write(
        LocalShiftsCompanion(
          status: const Value('closed'),
          closingCash: Value(closingCash),
          closedAt: Value(closedAt),
        ),
      );

  Future<List<LocalShiftRow>> getUnsyncedShifts() =>
      (select(localShifts)..where((s) => s.isSynced.equals(false)))
          .get();

  Future<void> markShiftSynced(String id) =>
      (update(localShifts)..where((s) => s.id.equals(id))).write(
        const LocalShiftsCompanion(isSynced: Value(true)),
      );
}
