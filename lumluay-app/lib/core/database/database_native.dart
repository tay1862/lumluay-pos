import 'dart:io';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'lumluay_pos.db'));

    // ── SQLCipher encryption key management (18.3.6) ─────────────────────
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    const keyName = 'lumluay_db_encryption_key';

    String? dbKey = await storage.read(key: keyName);
    if (dbKey == null) {
      // Generate a cryptographically secure 256-bit hex key on first launch.
      final random = Random.secure();
      dbKey = List<int>.generate(32, (_) => random.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      await storage.write(key: keyName, value: dbKey);
    }

    final key = dbKey;
    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        // SQLCipher requires the key in hex literal format ("x'...'") so that
        // it is treated as raw bytes rather than a passphrase string.
        rawDb.execute("PRAGMA key = \"x'$key'\"");
        rawDb.execute("PRAGMA cipher_page_size = 4096");
        rawDb.execute("PRAGMA kdf_iter = 64000");
        rawDb.execute("PRAGMA cipher_hmac_algorithm = HMAC_SHA512");
        rawDb.execute("PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA512");
      },
    );
  });
}
