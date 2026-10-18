import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  /// testWidgets for its fake time, so the midnight timer can be run forward
  testWidgets('today, its times and the hijri date move at local midnight and follow the zone', (
    tester,
  ) async {
    var phoneZone = 'Asia/Riyadh';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_timezone'),
      (_) async => phoneZone,
    );

    /// 23:59 in riyadh
    var now = DateTime.utc(2026, 10, 15, 20, 59);
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        clockProvider.overrideWithValue(() => now),
        phoneZoneProvider.overrideWith(() => PhoneZone(phoneZone)),
      ],
    );
    final today = container.listen(todayProvider, (_, _) {});
    final times = container.listen(todayTimesProvider, (_, _) {});
    int hijriDay() => container.read(hijriDateProvider(today.read())).day;
    await container
        .read(databaseProvider)
        .updateSettings(
          const SettingsCompanion(
            latitude: Value(21.4266),
            longitude: Value(39.8256),
            placeName: Value('Makkah'),
            countryCode: Value('SA'),
            timeZone: Value('Asia/Riyadh'),
            locationMode: Value(LocationMode.auto),
          ),
        );
    await tester.pump();

    expect(today.read(), DateTime(2026, 10, 15));
    expect(times.read()!.date, DateTime(2026, 10, 15));
    expect(hijriDay(), 4);

    now = DateTime.utc(2026, 10, 15, 21, 0, 30);
    await tester.pump(const Duration(minutes: 1));

    expect(today.read(), DateTime(2026, 10, 16));
    expect(times.read()!.date, DateTime(2026, 10, 16));
    expect(hijriDay(), 5);

    /// 17:00 the day before in new york
    phoneZone = 'America/New_York';
    await container.read(phoneZoneProvider.notifier).refresh();
    await tester.pump();

    expect(today.read(), DateTime(2026, 10, 15));
    expect(times.read()!.dhuhr!.location.name, 'America/New_York');

    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
  });
}
