import 'package:better_muslim/core/database/app_database.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';

/// drift_dev make-migrations writes migration_test.dart next to this once schema v2 exists
void main() {
  final verifier = SchemaVerifier(GeneratedHelper());

  test('the tables in code are exactly schema v1, a change needs a new version (FR-022)', () async {
    final schema = await verifier.schemaAt(1);
    final db = AppDatabase.forTesting(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });
}
