import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';

import '../../helpers/home.dart';
import '../../helpers/providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tz.initializeTimeZones);

  TZDateTime at(int day, int hour, int minute) =>
      TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, day, hour, minute);

  /// the store and content loaded, with listeners kept so the streams stay up
  Future<ProviderContainer> containerAt(DateTime now, {bool located = true}) async {
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        clockProvider.overrideWithValue(() => now),
        if (located) locationProvider.overrideWithValue(makkah()),
      ],
    );
    addTearDown(container.dispose);
    for (final set in AzkarSet.values) {
      container.listen(azkarProgressProvider(set), (_, _) {});
    }
    container.listen(azkarBadgeProvider, (_, _) {});
    await container.read(settingsProvider.future);
    await container.read(azkarContentProvider.future);
    await pumpEventQueue();
    return container;
  }

  test('0 of 20 at 16:32, 1 of 20 once an item reaches its count', () async {
    final container = await containerAt(at(15, 16, 32));
    final db = container.read(databaseProvider);
    expect(container.read(currentAzkarSetProvider), AzkarSet.evening);
    expect(container.read(azkarProgressProvider(AzkarSet.evening)), (done: 0, total: 20));

    await db.setZikrCount(AzkarSet.evening, DateTime(2026, 10, 15), 'e17', 99);
    await pumpEventQueue();
    expect(container.read(azkarProgressProvider(AzkarSet.evening)).done, 0);

    await db.setZikrCount(AzkarSet.evening, DateTime(2026, 10, 15), 'e17', 100);
    await pumpEventQueue();
    expect(container.read(azkarProgressProvider(AzkarSet.evening)), (done: 1, total: 20));
    expect(container.read(azkarProgressProvider(AzkarSet.morning)), (done: 0, total: 23));
  });

  test('an id no longer in the content is ignored', () async {
    final container = await containerAt(at(15, 16, 32));
    await container
        .read(databaseProvider)
        .setZikrCount(AzkarSet.evening, DateTime(2026, 10, 15), 'gone', 5);
    await pumpEventQueue();

    expect(container.read(azkarProgressProvider(AzkarSet.evening)), (done: 0, total: 20));
  });

  test('at 10:00 the evening shows last night\'s counts', () async {
    final container = await containerAt(at(15, 10, 0));
    await container
        .read(databaseProvider)
        .setZikrCount(AzkarSet.evening, DateTime(2026, 10, 14), 'e01', 1);
    await pumpEventQueue();

    expect(container.read(currentAzkarSetProvider), AzkarSet.morning);
    expect(container.read(azkarWindowDayProvider(AzkarSet.evening)), DateTime(2026, 10, 14));
    expect(container.read(azkarProgressProvider(AzkarSet.evening)).done, 1);
  });

  test('a count in a new window drops the older days of that set only', () async {
    final container = await containerAt(at(15, 16, 32));
    final db = container.read(databaseProvider);
    await db.setZikrCount(AzkarSet.evening, DateTime(2026, 10, 14), 'e01', 3);
    await db.setZikrCount(AzkarSet.morning, DateTime(2026, 10, 14), 'm01', 3);
    await db.setZikrCount(AzkarSet.evening, DateTime(2026, 10, 15), 'e02', 1);

    expect(await db.zikrCounts(AzkarSet.evening, DateTime(2026, 10, 14)), isEmpty);
    expect(await db.zikrCounts(AzkarSet.evening, DateTime(2026, 10, 15)), {'e02': 1});
    expect(await db.zikrCounts(AzkarSet.morning, DateTime(2026, 10, 14)), {'m01': 3});
  });

  test('the badge shows until the current window is opened', () async {
    final container = await containerAt(at(15, 16, 32));
    expect(container.read(azkarBadgeProvider), isTrue);

    await container
        .read(databaseProvider)
        .updateSettings(SettingsCompanion(eveningOpenedOn: Value(DateTime(2026, 10, 15))));
    await pumpEventQueue();
    expect(container.read(azkarBadgeProvider), isFalse);
  });

  test('last night\'s opened day doesn\'t clear tonight\'s badge', () async {
    final container = await containerAt(at(15, 16, 32));
    await container
        .read(databaseProvider)
        .updateSettings(SettingsCompanion(eveningOpenedOn: Value(DateTime(2026, 10, 14))));
    await pumpEventQueue();

    expect(container.read(azkarBadgeProvider), isTrue);
  });

  test('no badge without a location', () async {
    final container = await containerAt(at(15, 16, 32), located: false);

    expect(container.read(azkarBadgeProvider), isFalse);
  });
}
