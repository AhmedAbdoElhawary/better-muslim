import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/phone_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(usePhoneStorage);

  Future<AppDatabase> open() async {
    final db = await AppDatabase.open();
    addTearDown(db.close);
    return db;
  }

  test('a new store has the FR-020 defaults', () async {
    final settings = await (await open()).watchSettings().first;

    expect(settings.latitude, isNull);
    expect(settings.locationMode, isNull);
    expect(settings.method, isNull);
    expect(settings.asrMethod, isNull);
    expect(settings.hijriAdjust, 0);
    expect(settings.digits, Digits.eastern);
    expect(settings.theme, BmThemeId.moonlight);
    expect(settings.themeMode, BmThemeMode.followPhone);
    expect(settings.reduceMotion, isFalse);
    expect(settings.haptics, isTrue);
    expect(settings.uiSounds, isFalse);
  });

  test('watching the settings again never adds a row', () async {
    final db = await open();
    await db.watchSettings().first;
    await db.watchSettings().first;
    expect(await db.select(db.settings).get(), hasLength(1));
  });

  test('reset prayer journey clears the log and qada only', () async {
    final db = await open();
    final day = DateTime(2026, 10, 15);
    await db.watchSettings().first;
    await db.updateSettings(const SettingsCompanion(haptics: Value(false)));
    await db.markPrayed(day, Prayer.asr);
    await db.into(db.qadaEntries).insert(QadaEntriesCompanion.insert(prayer: Prayer.fajr));
    await db.saveDua('travel-1');

    await db.resetPrayerJourney();

    expect(await db.select(db.prayerLog).get(), isEmpty);
    expect(await db.select(db.qadaEntries).get(), isEmpty);
    expect(await db.select(db.savedDuas).get(), hasLength(1));
    expect((await db.watchSettings().first).haptics, isFalse);
  });

  test('every column survives closing and opening again', () async {
    final first = await AppDatabase.open();
    await first.updateSettings(
      const SettingsCompanion(
        latitude: Value(30.0626),
        longitude: Value(31.2497),
        placeName: Value('Cairo'),
        placeNameAr: Value('القاهرة'),
        regionName: Value('Cairo Governorate'),
        regionNameAr: Value('محافظة القاهرة'),
        countryCode: Value('EG'),
        timeZone: Value('Africa/Cairo'),
        locationMode: Value(LocationMode.manual),
        method: Value(PrayerMethod.muslimWorldLeague),
        asrMethod: Value(AsrMethod.hanafi),
        hijriAdjust: Value(-1),
        digits: Value(Digits.western),
        theme: Value(BmThemeId.andalus),
        themeMode: Value(BmThemeMode.light),
        reduceMotion: Value(true),
        haptics: Value(false),
        uiSounds: Value(true),
      ),
    );
    final written = await first.watchSettings().first;
    await first.close();

    expect(await (await open()).watchSettings().first, written);
  });

  test('a hijri adjustment outside -2 to 2 is never stored', () async {
    final db = await open();
    final rejected = throwsA(predicate((error) => '$error'.contains('CHECK constraint failed')));

    await expectLater(db.updateSettings(const SettingsCompanion(hijriAdjust: Value(3))), rejected);
    await expectLater(db.updateSettings(const SettingsCompanion(hijriAdjust: Value(-3))), rejected);
    expect((await db.watchSettings().first).hijriAdjust, 0);
  });

  test('Value(null) on method goes back to by country', () async {
    final db = await open();
    await db.updateSettings(const SettingsCompanion(method: Value(PrayerMethod.egyptian)));
    await db.updateSettings(const SettingsCompanion(method: Value(null)));

    expect((await db.watchSettings().first).method, isNull);
  });

  test('a new store has "Bookmarks" in the primary color', () async {
    final db = await open();
    final [category] = await db.select(db.quranCategories).get();

    expect(
      (category.id, category.name, category.color, category.position),
      (AppDatabase.defaultCategory, null, CategoryColor.primary, 0),
    );
  });
}
