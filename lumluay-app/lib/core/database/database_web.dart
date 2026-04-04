import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

LazyDatabase openConnection() {
  // Web platform: use IndexedDB-backed WasmDatabase (no encryption on web).
  return LazyDatabase(() async {
    final db = await WasmDatabase.open(
      databaseName: 'lumluay_pos',
      sqlite3Uri: Uri.parse('sqlite3.wasm'),
      driftWorkerUri: Uri.parse('drift_worker.dart.js'),
    );
    return db.resolvedExecutor;
  });
}
