import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final azkarContentProvider = FutureProvider<AzkarContent>((ref) => loadAzkarContent());

final currentAzkarSetProvider = Provider<AzkarSet>(
  (ref) => currentAzkarSet(ref.watch(periodProvider)),
);

final azkarWindowDayProvider = Provider.family<DateTime, AzkarSet>(
  (ref, set) => azkarWindowDay(set, ref.watch(prayerDayProvider), ref.watch(periodProvider)),
);

/// the latest window's counts by zikr id
final azkarCountsProvider = StreamProvider.family<Map<String, int>, AzkarSet>((ref, set) {
  final db = ref.watch(databaseProvider);
  final day = ref.watch(azkarWindowDayProvider(set));
  final query = db.select(db.azkarCounts)
    ..where((row) => row.setId.equalsValue(set) & row.day.equalsValue(day));
  return query.watch().map((rows) => {for (final row in rows) row.zikr: row.count});
});

final azkarProgressProvider = Provider.family<({int done, int total}), AzkarSet>((ref, set) {
  final items = ref.watch(azkarContentProvider.select((content) => content.value?.setOf(set)));
  final counts = ref.watch(azkarCountsProvider(set)).value ?? const {};
  if (items == null) return (done: 0, total: 0);
  return (done: items.doneIn(counts), total: items.total);
});

/// from the start of the current set's window until it's opened
final azkarBadgeProvider = Provider<bool>((ref) {
  if (ref.watch(locationProvider.select((location) => location == null))) return false;
  final set = ref.watch(currentAzkarSetProvider);
  final opened = ref.watch(
    settingsProvider.select(
      (settings) => switch (set) {
        AzkarSet.morning => settings.value?.morningOpenedOn,
        AzkarSet.evening => settings.value?.eveningOpenedOn,
      },
    ),
  );
  final loaded = ref.watch(settingsProvider.select((settings) => settings.hasValue));
  return loaded && opened != ref.watch(azkarWindowDayProvider(set));
});
