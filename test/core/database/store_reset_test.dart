import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phone_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late String folder;
  late _RecordingReporter reporter;

  setUp(() async {
    folder = usePhoneStorage().path;
    final db = await AppDatabase.open();
    await db.updateSettings(const SettingsCompanion(placeName: Value('Makkah')));
    await db.close();
    CrashReporter.instance = reporter = _RecordingReporter();
    addTearDown(() => CrashReporter.instance = const DebugCrashReporter());
  });

  Future<AppSettings> openAgain() async {
    final db = await AppDatabase.open();
    addTearDown(db.close);
    return db.watchSettings().first;
  }

  void expectOneReportWithReasonOnly() {
    expect(reporter.contexts, hasLength(1));
    expect(reporter.contexts.single.keys, ['reason']);
    final reported = '${reporter.errors.single} ${reporter.contexts.single}';
    expect(reported, isNot(contains(folder)));
    expect(reported, isNot(contains('Makkah')));
  }

  test('a store whose key is gone starts fresh (FR-024)', () async {
    FlutterSecureStorage.setMockInitialValues({});

    final settings = await openAgain();

    expect(settings.placeName, isNull);
    expect(reporter.contexts.single, {'reason': 'no key'});
    expectOneReportWithReasonOnly();
  });

  test('a store with the wrong key starts fresh', () async {
    FlutterSecureStorage.setMockInitialValues({'database_key': 'not the key'});

    final settings = await openAgain();

    expect(settings.placeName, isNull);
    expect(reporter.contexts.single, {'reason': 'cannot open'});
    expect('${reporter.errors.single}', contains('file is not a database'));
    expect(settings.haptics, isTrue);
    expectOneReportWithReasonOnly();
  });
}

class _RecordingReporter implements CrashReporter {
  final errors = <Object>[];
  final contexts = <Map<String, Object?>>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    bool fatal = false,
    Map<String, Object?>? context,
  }) async {
    errors.add(error);
    contexts.add(context ?? {});
  }

  @override
  void addBreadcrumb(String message, {String? category}) {}

  @override
  Future<void> sendFeedback(String message, {String? email}) async {}
}
