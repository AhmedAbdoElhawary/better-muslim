import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/providers.dart';

void main() {
  /// the page color at a period, with what the reader picked
  Future<PageColor> colorAt(Period? period, {PageColor? picked}) async {
    final container = ProviderContainer(
      overrides: [...testOverrides(), periodProvider.overrideWithValue(period)],
    );
    addTearDown(container.dispose);
    final db = container.read(databaseProvider);
    if (picked != null) await db.updateSettings(SettingsCompanion(pageColor: Value(picked)));
    final settings = container.listen(settingsProvider, (_, _) {});
    addTearDown(settings.close);
    await container.read(settingsProvider.future);
    return container.read(pageColorProvider);
  }

  test('follow sky is paper from fajr to isha and night from isha to fajr', () async {
    for (final period in [Period.fajr, Period.duha, Period.dhuhr, Period.asr, Period.maghrib]) {
      expect(await colorAt(period), PageColor.paper, reason: '$period');
    }

    /// before fajr is still the night's isha
    expect(await colorAt(Period.isha), PageColor.night);
  });

  test('follow sky with no location yet is paper', () async {
    expect(await colorAt(null), PageColor.paper);
  });

  test('a picked paper, cream or night is kept at any hour', () async {
    for (final picked in [PageColor.paper, PageColor.cream, PageColor.night]) {
      expect(await colorAt(Period.isha, picked: picked), picked);
      expect(await colorAt(Period.dhuhr, picked: picked), picked);
    }
  });
}
