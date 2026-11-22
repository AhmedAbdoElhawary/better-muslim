import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/providers.dart';

const _makkah = SettingsCompanion(
  latitude: Value(21.4225),
  longitude: Value(39.8262),
  countryCode: Value('SA'),
  timeZone: Value('Asia/Riyadh'),
  locationMode: Value(LocationMode.manual),
);

const _cairo = SettingsCompanion(
  latitude: Value(30.0444),
  longitude: Value(31.2357),
  countryCode: Value('EG'),
  timeZone: Value('Africa/Cairo'),
  locationMode: Value(LocationMode.manual),
);

const _london = SettingsCompanion(
  latitude: Value(51.5074),
  longitude: Value(-0.1278),
  countryCode: Value('GB'),
  timeZone: Value('Europe/London'),
  locationMode: Value(LocationMode.manual),
);

void main() {
  setUpAll(tz.initializeTimeZones);

  late DateTime clock;
  late ProviderContainer container;

  /// moving the clock and waking the boundary, like the app's boundary timer does
  Future<void> open(DateTime now, {SettingsCompanion? place, BmThemeMode? mode}) async {
    clock = now;
    container = ProviderContainer(
      overrides: [...testOverrides(), clockProvider.overrideWithValue(() => clock)],
    );
    addTearDown(container.dispose);
    container.listen(themeModeProvider, (_, _) {});
    await container.read(settingsProvider.future);
    final db = container.read(databaseProvider);
    if (place != null) await db.updateSettings(place);
    if (mode != null) await db.updateSettings(SettingsCompanion(themeMode: Value(mode)));
    await pumpEventQueue();
  }

  Future<ThemeMode> at(DateTime now) async {
    clock = now;
    container.invalidate(boundaryProvider);
    await pumpEventQueue();
    return container.read(themeModeProvider);
  }

  ({DateTime sunrise, DateTime maghrib}) sky() {
    final times = container.read(todayTimesProvider)!;
    return (sunrise: times.sunrise!, maghrib: times.maghrib!);
  }

  const minute = Duration(minutes: 1);

  test('dark and light hold at any time', () async {
    await open(DateTime.utc(2026, 10, 15, 9), place: _makkah, mode: BmThemeMode.dark);
    expect(await at(DateTime.utc(2026, 10, 15, 9)), ThemeMode.dark);
    await container
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(themeMode: Value(BmThemeMode.light)));
    await pumpEventQueue();
    expect(await at(DateTime.utc(2026, 10, 15, 21)), ThemeMode.light);
  });

  test('follow phone is the default and leaves light and dark to the phone', () async {
    await open(DateTime.utc(2026, 10, 15, 9), place: _makkah);
    final (:sunrise, :maghrib) = sky();
    expect(await at(sunrise.add(minute)), ThemeMode.system);
    expect(await at(maghrib.add(minute)), ThemeMode.system);
  });

  test('follow sky is light from sunrise to maghrib, dark around them (SC-004)', () async {
    await open(DateTime.utc(2026, 10, 15, 9), place: _makkah, mode: BmThemeMode.followSky);
    final (:sunrise, :maghrib) = sky();
    expect(await at(sunrise.subtract(minute)), ThemeMode.dark);
    expect(await at(sunrise.add(minute)), ThemeMode.light);
    expect(await at(maghrib.subtract(minute)), ThemeMode.light);
    expect(await at(maghrib.add(minute)), ThemeMode.dark);
    expect(await at(DateTime.utc(2026, 10, 14, 21, 30)), ThemeMode.dark);
  });

  test('follow sky with no location follows the phone', () async {
    await open(DateTime.utc(2026, 10, 15, 9), mode: BmThemeMode.followSky);
    expect(await at(DateTime.utc(2026, 10, 15, 9)), ThemeMode.system);
  });

  test('follow sky on a daylight saving day keeps to the local sky', () async {
    await open(DateTime.utc(2026, 3, 29, 12), place: _london, mode: BmThemeMode.followSky);
    final (:sunrise, :maghrib) = sky();
    expect(await at(sunrise.subtract(minute)), ThemeMode.dark);
    expect(await at(sunrise.add(minute)), ThemeMode.light);
    expect(await at(maghrib.subtract(minute)), ThemeMode.light);
    expect(await at(maghrib.add(minute)), ThemeMode.dark);
  });

  test('a location change moves the switch to the new place', () async {
    await open(DateTime.utc(2026, 10, 15, 12), place: _makkah, mode: BmThemeMode.followSky);
    final makkahMaghrib = sky().maghrib;
    await container.read(databaseProvider).updateSettings(_cairo);
    await pumpEventQueue();
    final cairoMaghrib = sky().maghrib;
    expect(cairoMaghrib.isAfter(makkahMaghrib), isTrue);
    expect(await at(makkahMaghrib.add(minute)), ThemeMode.light);
    expect(await at(cairoMaghrib.add(minute)), ThemeMode.dark);
  });

  test('the same value between boundaries notifies nobody', () async {
    await open(DateTime.utc(2026, 10, 15, 9), place: _makkah, mode: BmThemeMode.followSky);
    final (:sunrise, :maghrib) = sky();
    await at(sunrise.add(minute));
    var changes = 0;
    container.listen(themeModeProvider, (_, _) => changes++);
    for (
      var time = sunrise.add(const Duration(hours: 1));
      time.isBefore(maghrib);
      time = time.add(const Duration(hours: 1))
    ) {
      await at(time);
    }
    expect(changes, 0);
    await at(maghrib.add(minute));
    expect(changes, 1);
  });

  test('the theme id is the saved one, moonlight before the store answers', () async {
    await open(DateTime.utc(2026, 10, 15, 9));
    expect(container.read(themeIdProvider), BmThemeId.moonlight);
    await container
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(theme: Value(BmThemeId.iznik)));
    await pumpEventQueue();
    expect(container.read(themeIdProvider), BmThemeId.iznik);
  });
}
