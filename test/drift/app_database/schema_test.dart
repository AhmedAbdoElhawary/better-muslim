import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  test('the tables in code are exactly schema v2, a change needs a new version (FR-022)', () async {
    final schema = await verifier.schemaAt(2);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 2);
  });
}
