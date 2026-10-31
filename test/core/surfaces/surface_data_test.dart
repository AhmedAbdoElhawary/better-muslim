import 'dart:convert';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/next_prayer.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/surfaces/surface_data.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

typedef Json = Map<String, Object?>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// the places below are made before setUpAll runs
  tz.initializeTimeZones();
  late AppSettings defaults;
  final l10n = <String, AppLocalizations>{};

  setUpAll(() async {
    await initializeDateFormatting();
    for (final language in ['en', 'ar']) {
      l10n[language] = await AppLocalizations.load(Locale(language));
    }
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    defaults = await db.watchSettings(now: DateTime(2026, 10, 1)).first;
    await db.close();
  });

  Location place(
    String name,
    double latitude,
    double longitude,
    String country,
    String zone, {
    String? nameAr,
  }) => Location(
    latitude: latitude,
    longitude: longitude,
    placeName: name,
    placeNameAr: nameAr,
    countryCode: country,
    zone: tz.getLocation(zone),
    mode: LocationMode.manual,
  );

  final makkah = place('Makkah', 21.4225, 39.8262, 'SA', 'Asia/Riyadh', nameAr: 'مكة المكرمة');
  final istanbul = place('Istanbul', 41.0082, 28.9784, 'TR', 'Europe/Istanbul');

  /// istanbul has kept one offset since 2016, london's clocks go back on 25 oct
  final london = place('London', 51.5074, -0.1278, 'GB', 'Europe/London');
  final tromso = place('Tromsø', 69.6489, 18.9551, 'NO', 'Europe/Oslo');

  tz.TZDateTime at(Location location, int month, int day, int hour, int minute) =>
      tz.TZDateTime(location.zone, 2026, month, day, hour, minute);

  Json build(
    Location? location,
    DateTime now, {
    Set<Prayer> prayed = const {},
    String language = 'en',
    bool use24h = true,
    AppSettings? settings,
  }) => jsonDecode(
    jsonEncode(
      buildSurfaceData(
        now: now,
        location: location,
        settings: settings ?? defaults,
        prayed: prayed,
        l10n: l10n[language]!,
        language: language,
        use24h: use24h,
      ),
    ),
  ) as Json;

  List<Json> entriesOf(Json data) => (data['entries']! as List).cast<Json>();
  List<Json> windowsOf(Json data) => (data['countdowns']! as List).cast<Json>();
  List<Json> stripOf(Json entry) => (entry['strip']! as List).cast<Json>();

  /// the rule of contracts/native-surfaces.md
  Json inForce(Json data, int ms) =>
      entriesOf(data).lastWhere((entry) => (entry['from']! as int) <= ms);

  DayTimes timesOn(Location location, DateTime date) =>
      dayTimesAt(location, date, method: null, asrMethod: null, hijriAdjust: 0);

  ProviderContainer homeAt(DateTime moment, Location location, DateTime first, Set<Prayer> prayed) {
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => moment),
        tickerProvider.overrideWithValue(const AsyncLoading()),
        locationProvider.overrideWithValue(location),
        settingsProvider.overrideWithValue(AsyncData(defaults)),
        prayedProvider.overrideWith((ref, day) => day == first ? prayed : const <Prayer>{}),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  String clock(DateTime time, Location location) => formatTimeIn(
    tz.TZDateTime.from(time, location.zone),
    language: 'en',
    use24h: true,
    digits: Digits.eastern,
  );

  group('SC-001, the entry in force is what home shows, every 5 minutes', () {
    final cases = [
      (location: makkah, now: at(makkah, 10, 15, 16, 32)),
      (location: istanbul, now: at(istanbul, 10, 24, 9, 0)),
      (location: london, now: at(london, 10, 24, 9, 0)),
      (location: tromso, now: at(tromso, 6, 20, 9, 0)),
    ];
    for (final (:location, :now) in cases) {
      test(location.placeName!, () {
        const prayed = {Prayer.fajr, Prayer.dhuhr};
        final first = homeAt(now, location, DateTime(0), prayed).read(prayerDayProvider);
        final data = build(location, now, prayed: prayed);
        final until = data['until']! as int;
        final froms = [for (final entry in entriesOf(data)) entry['from']! as int];
        expect(froms.first, lessThanOrEqualTo(now.millisecondsSinceEpoch));
        expect(froms, [...froms]..sort());

        var checked = 0;
        for (var ms = now.millisecondsSinceEpoch; ms < until; ms += 5 * 60 * 1000) {
          final moment = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
          final reason = tz.TZDateTime.from(moment, location.zone).toString();
          final entry = inForce(data, ms);
          final home = homeAt(moment, location, first, prayed);

          final (prayer, time) = home.read(nextPrayerProvider)!;
          expect(entry['prayer'], prayer.name, reason: reason);
          expect(entry['at'], time.millisecondsSinceEpoch, reason: reason);
          final minutes = ((entry['at']! as int) - ms) ~/ 60000;
          expect(minutes, home.read(timeLeftProvider)!.inMinutes, reason: reason);

          final day = home.read(prayerDayProvider);
          expect(entry['day'], const CivilDate().toSql(day), reason: reason);
          final strip = home.read(stripProvider);
          expect(
            [for (final cell in stripOf(entry)) cell['time']],
            [for (final cell in strip) cell.time == null ? '—' : clock(cell.time!, location)],
            reason: reason,
          );
          expect(
            [for (final cell in stripOf(entry)) cell['logged']],
            [for (final cell in strip) cell.logged],
            reason: reason,
          );

          final today = home.read(todayProvider);
          final todayTimes = home.read(todayTimesProvider)!;
          final period = home.read(periodProvider);
          final start = period == null
              ? null
              : periodStart(
                  period,
                  moment,
                  todayTimes,
                  home.read(dayTimesProvider(DateTime(today.year, today.month, today.day - 1))),
                );
          expect(entry['barFrom'], start?.millisecondsSinceEpoch, reason: reason);
          final barFrom = entry['barFrom'] as int?;
          final share = barFrom == null
              ? null
              : barShare(
                  moment,
                  DateTime.fromMillisecondsSinceEpoch(barFrom),
                  DateTime.fromMillisecondsSinceEpoch(entry['at']! as int),
                );
          expect(
            share == null ? null : (share * 1000).round() / 1000,
            home.read(barShareProvider),
            reason: reason,
          );
          expect(entry['sunrise'], todayTimes.sunrise?.millisecondsSinceEpoch, reason: reason);
          expect(entry['maghrib'], todayTimes.maghrib?.millisecondsSinceEpoch, reason: reason);

          final hijri = home.read(hijriDateProvider(today));
          final month = l10n['en']!.tr(hijri.monthKey, const {});
          expect(entry['hijri'], hijriLineIn(hijri, month), reason: reason);
          expect(
            entry['dateLine'],
            dateLineIn(today, hijriLineIn(hijri, month, year: false), 'en'),
            reason: reason,
          );
          checked++;
        }
        expect(checked, greaterThan(7 * 24 * 12 - 12 * 24));
      });
    }
  });

  group('the countdown windows', () {
    final now = at(makkah, 10, 15, 16, 32);
    late Json data;
    setUp(() => data = build(makkah, now, prayed: {Prayer.asr}));

    DateTime timeOf(int day, Prayer prayer) =>
        timesOn(makkah, DateTime(2026, 10, 15 + day)).timeOf(prayer)!;
    Json windowEnding(DateTime end) =>
        windowsOf(data).singleWhere((window) => window['end'] == end.millisecondsSinceEpoch);
    int ms(DateTime time) => time.millisecondsSinceEpoch;

    test('2 hours before, or from the previous prayer when that is later', () {
      final maghrib = windowEnding(timeOf(0, Prayer.maghrib));
      expect(maghrib['start'], ms(timeOf(0, Prayer.maghrib).subtract(const Duration(hours: 2))));
      expect(maghrib['entry'], 0);

      /// umm al-qura's isha is 90 minutes after maghrib
      final isha = windowEnding(timeOf(0, Prayer.isha));
      expect(isha['start'], ms(timeOf(0, Prayer.maghrib)));
    });

    test("fajr's starts in the night, its bar from last night's isha", () {
      final fajr = windowEnding(timeOf(1, Prayer.fajr));
      expect(fajr['start'], ms(timeOf(1, Prayer.fajr).subtract(const Duration(hours: 2))));
      final entry = entriesOf(data)[fajr['entry']! as int];
      expect(entry['prayer'], 'fajr');
      expect(entry['barFrom'], ms(timeOf(0, Prayer.isha)));
      expect(entry['barFromLabel'], 'Isha ${clock(timeOf(0, Prayer.isha), makkah)}');
    });

    test("dhuhr's bar starts at sunrise, never prayed", () {
      final dhuhr = windowEnding(timeOf(1, Prayer.dhuhr));
      final entry = entriesOf(data)[dhuhr['entry']! as int];
      final sunrise = timesOn(makkah, DateTime(2026, 10, 16)).sunrise!;
      expect(entry['barFrom'], ms(sunrise));
      expect(entry['barFromLabel'], 'Sunrise ${clock(sunrise, makkah)}');
    });

    test('a logged start prayer ends its label in prayed', () {
      final entry = entriesOf(data)[windowEnding(timeOf(0, Prayer.maghrib))['entry']! as int];
      expect(entry['barFromLabel'], 'Asr ${clock(timeOf(0, Prayer.asr), makkah)} · prayed');
    });

    test('only the first 6 prayer days, each entry the one in force at its start', () {
      final windows = windowsOf(data);
      expect(windows, hasLength(6 * 5 - 3));
      expect(windows.last['end'], ms(timeOf(5, Prayer.isha)));
      for (final window in windows) {
        final start = window['start']! as int;
        final entry = entriesOf(data).indexOf(inForce(data, start < ms(now) ? ms(now) : start));
        expect(window['entry'], entry);
      }
    });

    test('never overlapping, in order', () {
      final windows = windowsOf(data);
      for (var i = 1; i < windows.length; i++) {
        expect(windows[i]['start']! as int, greaterThanOrEqualTo(windows[i - 1]['end']! as int));
      }
      expect(windows.first['start'], lessThan(ms(now)));
    });

    test('a prayer with no time has no window and is no one\'s previous', () {
      final polar = build(tromso, at(tromso, 6, 20, 9, 0));
      final days = [for (var i = -1; i < 6; i++) timesOn(tromso, DateTime(2026, 6, 19 + i))];
      final ends = {
        for (final day in days) ...[ms(day.dhuhr!), ms(day.asr!)],
      };
      for (final window in windowsOf(polar)) {
        expect(ends, contains(window['end']));
        final end = window['end']! as int;
        final previous = ends.where((time) => time < end).lastOrNull;
        final twoHours = end - const Duration(hours: 2).inMilliseconds;
        expect(window['start'], previous != null && previous > twoHours ? previous : twoHours);
      }
      expect(windowsOf(polar), hasLength(lessThanOrEqualTo(6 * 2)));
    });

    test('none with the switch off, none without a place', () {
      final off = build(makkah, now, settings: defaults.copyWith(prayerCountdown: false));
      expect(off['countdown'], false);
      expect(windowsOf(off), isEmpty);
      expect(entriesOf(off), isNotEmpty);
      expect(windowsOf(build(null, now)), isEmpty);
    });
  });

  group('after isha', () {
    test('fajr next, no cell highlighted, every cell past', () {
      for (final now in [at(makkah, 10, 15, 21, 0), at(makkah, 10, 16, 2, 0)]) {
        final entry = inForce(build(makkah, now), now.millisecondsSinceEpoch);
        expect(entry['prayer'], 'fajr');
        expect(entry['next'], isNull);
        expect(entry['day'], '2026-10-15');
        expect([for (final cell in stripOf(entry)) cell['past']], everyElement(true));
      }
    });

    test('before, the next prayer is highlighted and only the earlier ones are past', () {
      final now = at(makkah, 10, 15, 16, 32);
      final entry = inForce(build(makkah, now), now.millisecondsSinceEpoch);
      expect(entry['next'], 3);
      expect([for (final cell in stripOf(entry)) cell['past']], [true, true, true, false, false]);
    });
  });

  group('the texts', () {
    final now = at(makkah, 10, 15, 16, 32);
    const prayed = {Prayer.fajr, Prayer.dhuhr, Prayer.asr};
    Json first(Json data) => entriesOf(data).first;
    Json texts(Json data) => data['texts']! as Json;

    test('english, 24 hour', () {
      final data = build(makkah, now, prayed: prayed);
      final entry = first(data);
      expect(data['eastern'], false);
      expect(texts(data), {
        'noPlace': 'Open Better Muslim to set your place',
        'outdated': 'Open Better Muslim to update the times',
        'open': 'Open Better Muslim',
        'now': 'Now',
        'inDuration': 'in {duration}',
        'timeLeft': '{hours} h {minutes} min until {prayer}',
        'next': 'NEXT',
        'nextPrayer': 'Next prayer',
        'nextCity': 'NEXT · MAKKAH',
        'nextCityShort': 'Next · Makkah',
        'liveNext': 'Next prayer · Makkah',
        'methodLine': 'Makkah · Umm al-Qura',
        'channel': 'Prayer countdown',
      });
      expect(entry['name'], 'Maghrib');
      expect(entry['time'], '17:56');
      expect(entry['atTime'], 'at 17:56');
      expect(entry['timeCity'], '17:56 · Makkah');
      expect(entry['nameTime'], 'Maghrib 17:56');
      expect(entry['reminder'], 'Reminder 17:46');
      expect(entry['prayedLine'], '3 of 5 prayed today');
      expect(entry['hijriCity'], '${entry['hijri']} · Makkah');
      expect(entry['barFromLabel'], endsWith(' · prayed'));
      expect(stripOf(entry)[3], {
        'prayer': 'maghrib',
        'name': 'Maghrib',
        'time': '17:56',
        'logged': false,
        'past': false,
      });
    });

    test('12 hour', () {
      final entry = first(build(makkah, now, use24h: false));
      expect(entry['time'], matches(r'^5:56\sPM$'));
      expect(stripOf(entry)[3]['time'], matches(r'^5:56\sPM$'));
    });

    test('arabic with eastern digits', () {
      final data = build(makkah, now, prayed: prayed, language: 'ar');
      final entry = first(data);
      expect(data['eastern'], true);
      expect(data['language'], 'ar');
      expect(texts(data)['nextCity'], 'التالية · مكة المكرمة');
      expect(texts(data)['liveNext'], 'الصلاة القادمة · مكة المكرمة');
      expect(entry['name'], 'المغرب');
      expect(entry['time'], '١٧:٥٦');
      expect(entry['nameTime'], 'المغرب ١٧:٥٦');
      expect(entry['barFromLabel'], endsWith(' · صلّيت'));
      expect(entry['prayedLine'], contains('٣'));
      expect(entry['hijri'], isNot(matches(RegExp('[0-9]'))));
    });

    test('arabic with western digits', () {
      final settings = defaults.copyWith(digits: Digits.western);
      final data = build(makkah, now, language: 'ar', settings: settings);
      expect(data['eastern'], false);
      expect(first(data)['time'], '17:56');
    });

    test('no reminder at 0 minutes, no prayed when not logged', () {
      final settings = defaults.copyWith(reminderMinutes: 0);
      final entry = first(build(makkah, now, settings: settings));
      expect(entry['reminder'], isNull);
      expect(entry['barFromLabel'], isNot(contains('prayed')));
      expect(entry['prayedLine'], '0 of 5 prayed today');
    });

    test('marks only on the first prayer day', () {
      final data = build(makkah, now, prayed: prayed);
      final later = entriesOf(data).where((entry) => entry['day'] != '2026-10-15');
      expect(later, isNotEmpty);
      for (final entry in later) {
        expect([for (final cell in stripOf(entry)) cell['logged']], everyElement(false));
      }
    });
  });

  group('the theme', () {
    final now = at(makkah, 10, 15, 16, 32);
    Json colorsOf(Json data, String mode) => (data['colors']! as Json)[mode]! as Json;

    test("emerald's dark is the 5.6 tree's", () {
      expect(colorsOf(build(makkah, now), 'dark'), {
        'top': 0xFF000000,
        'middle': 0xFF04100C,
        'bottom': 0xFF173328,

        /// the large widget's #0B1E17, one step off from the lerp
        'deep': 0xFF0C1E17,
        'text': 0xFFD9D3C2,
        'label': 0xD9D9D3C2,
        'dim': 0xFF878C82,
        'gold': 0xFFD9C08A,
        'live': colorsOf(build(makkah, now), 'dark')['live'],
        'primary': 0xFFA88A52,
        'container': 0xFF221C10,
        'success': 0xFF5FB389,
        'ring': 0xFF4C5E57,
        'sun': 0xFFCDB27A,
        'outline': 0xFF1C2C26,
      });
    });

    test('the chosen theme, light from its surfaces', () {
      final theme = bmThemes[BmThemeId.andalus]!;
      final data = build(makkah, now, settings: defaults.copyWith(theme: BmThemeId.andalus));
      expect(colorsOf(data, 'dark')['text'], theme.dark.text.toARGB32());
      expect(colorsOf(data, 'dark')['top'], theme.dark.sky1.toARGB32());
      expect(colorsOf(data, 'light')['text'], theme.light.text.toARGB32());
      expect(colorsOf(data, 'light')['top'], theme.light.surface.toARGB32());
      expect(colorsOf(data, 'light')['gold'], theme.light.onPrimaryContainer.toARGB32());
    });

    test('follow sky is light from sunrise until maghrib, each entry on its own', () {
      final data = build(makkah, now);
      expect(data['mode'], 'followSky');
      final today = timesOn(makkah, DateTime(2026, 10, 15));
      final tomorrow = timesOn(makkah, DateTime(2026, 10, 16));
      bool lightAt(DateTime time) => inForce(data, time.millisecondsSinceEpoch)['light']! as bool;
      expect(lightAt(now), true);
      expect(lightAt(today.maghrib!), false);
      expect(lightAt(tomorrow.fajr!), false);
      expect(lightAt(tomorrow.sunrise!), true);
      expect(lightAt(tomorrow.maghrib!.subtract(const Duration(minutes: 1))), true);
    });

    test('dark and light hold all day', () {
      for (final mode in [BmThemeMode.dark, BmThemeMode.light]) {
        final data = build(makkah, now, settings: defaults.copyWith(themeMode: mode));
        expect(data['mode'], mode.name);
        expect(entriesOf(data).map((entry) => entry['light']).toSet(), {mode == BmThemeMode.light});
      }
    });

    test('no place still sends the mode and the colors', () {
      final data = build(null, now, settings: defaults.copyWith(themeMode: BmThemeMode.light));
      expect(data['mode'], 'light');
      expect(
        colorsOf(data, 'light')['text'],
        bmThemes[BmThemeId.qiyamEmerald]!.light.text.toARGB32(),
      );
    });
  });

  group('SC-006, only the listed fields', () {
    const top = [
      'version',
      'place',
      'language',
      'eastern',
      'countdown',
      'mode',
      'colors',
      'until',
      'texts',
      'entries',
      'countdowns',
    ];
    const texts = [
      'noPlace',
      'outdated',
      'open',
      'now',
      'inDuration',
      'timeLeft',
      'next',
      'nextPrayer',
      'nextCity',
      'nextCityShort',
      'liveNext',
      'methodLine',
      'channel',
    ];
    const entry = [
      'from',
      'prayer',
      'day',
      'at',
      'name',
      'time',
      'atTime',
      'timeCity',
      'nameTime',
      'barFrom',
      'barFromLabel',
      'sunrise',
      'maghrib',
      'hijri',
      'hijriCity',
      'dateLine',
      'prayedLine',
      'reminder',
      'next',
      'light',
      'strip',
    ];
    const cell = ['prayer', 'name', 'time', 'logged', 'past'];
    const window = ['start', 'end', 'entry'];

    test('the key sets', () {
      final data = build(makkah, at(makkah, 10, 15, 16, 32));
      expect(data.keys.toSet(), top.toSet());
      expect(data['version'], 2);
      expect((data['texts']! as Json).keys.toSet(), texts.toSet());
      for (final item in entriesOf(data)) {
        expect(item.keys.toSet(), entry.toSet());
        expect(stripOf(item), hasLength(5));
        for (final strip in stripOf(item)) {
          expect(strip.keys.toSet(), cell.toSet());
        }
      }
      for (final item in windowsOf(data)) {
        expect(item.keys.toSet(), window.toSet());
      }
    });

    test('no place', () {
      final data = build(null, at(makkah, 10, 15, 16, 32));
      expect(data.keys.toSet(), top.toSet());
      expect(data['place'], false);
      expect(data['until'], 0);
      expect(entriesOf(data), isEmpty);
      expect(windowsOf(data), isEmpty);
      expect((data['texts']! as Json).keys.toSet(), texts.toSet());
    });
  });

  test('two builds in the same stretch are equal, one after a prayer time is not', () {
    String json(int hour, int minute) =>
        jsonEncode(build(makkah, at(makkah, 10, 15, hour, minute)));
    expect(json(16, 32), json(16, 50));
    expect(json(16, 32), isNot(json(18, 0)));
  });

  test('until is the 8th prayer day\'s fajr, or its midnight without one', () {
    final makkahData = build(makkah, at(makkah, 10, 15, 16, 32));
    expect(
      makkahData['until'],
      timesOn(makkah, DateTime(2026, 10, 22)).fajr!.millisecondsSinceEpoch,
    );
    final polar = build(tromso, at(tromso, 6, 20, 9, 0));
    expect(polar['until'], tz.TZDateTime(tromso.zone, 2026, 6, 27).millisecondsSinceEpoch);
  });

  test('the hijri adjustment moves the hijri line', () {
    final now = at(makkah, 10, 15, 16, 32);
    final plain = entriesOf(build(makkah, now)).first;
    final moved = entriesOf(build(makkah, now, settings: defaults.copyWith(hijriAdjust: 1))).first;
    final hijri = HijriDate.of(DateTime(2026, 10, 15), 1);
    expect(moved['hijri'], hijriLineIn(hijri, l10n['en']!.tr(hijri.monthKey, const {})));
    expect(moved['hijri'], isNot(plain['hijri']));
  });

  test('the method line names the picked method, or the country\'s', () {
    String line(AppSettings settings) =>
        (build(istanbul, at(istanbul, 10, 24, 9, 0), settings: settings)['texts']!
                as Json)['methodLine']!
            as String;
    String name(PrayerMethod method) => l10n['en']!.tr(method.nameKey, const {});
    expect(line(defaults), 'Istanbul · ${name(PrayerMethod.turkiye)}');
    final picked = defaults.copyWith(method: const Value(PrayerMethod.muslimWorldLeague));
    expect(line(picked), 'Istanbul · ${name(PrayerMethod.muslimWorldLeague)}');
  });
}
