import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/next_prayer.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the notifications' 6 days, ios 26 schedules no countdown further than they go
const _windowDays = 6;
const _windowLength = Duration(hours: 2);

/// the file the widgets, the live activity and the android countdown read
/// (contracts/surface-data.md). the prayer rules stay in dart, the native side only picks the
/// entry in force and counts
Map<String, Object?> buildSurfaceData({
  required DateTime now,
  required Location? location,
  required AppSettings settings,
  required Set<Prayer> prayed,
  required AppLocalizations l10n,
  required String language,
  required bool use24h,
}) {
  final digits = settings.digits;
  String tr(String key, [Map<String, String> args = const {}]) => l10n.tr(key, args);
  String number(String text) => formatDigitsIn(text, language: language, digits: digits);
  final city = location?.nameIn(language) ?? '';
  final method =
      settings.method ?? PrayerMethod.forCountry(location?.countryCode ?? settings.countryCode);
  final data = <String, Object?>{
    'version': 1,
    'place': location != null,
    'language': language,
    'eastern': language == 'ar' && digits == Digits.eastern,
    'countdown': settings.prayerCountdown,
    'until': 0,
    'texts': {
      'noPlace': tr(StringsManager.openToSetPlace),
      'outdated': tr(StringsManager.openToUpdateTimes),
      'open': tr(StringsManager.openApp),
      'now': tr(StringsManager.nowShort),
      'inDuration': tr(StringsManager.inDuration),
      'timeLeft': tr(StringsManager.timeLeftSemantics),
      'next': tr(StringsManager.surfaceNext),
      'nextPrayer': tr(StringsManager.nextPrayer),
      'nextCity': tr(StringsManager.surfaceNextCity, {
        'city': language == 'en' ? city.toUpperCase() : city,
      }),
      'nextCityShort': tr(StringsManager.surfaceNextShort, {'city': city}),
      'liveNext': tr(StringsManager.liveNextPrayer, {'city': city}),
      'methodLine': '$city · ${tr(method.nameKey)}',
      'channel': tr(StringsManager.countdownChannel),
    },
    'entries': const <Map<String, Object?>>[],
    'countdowns': const <Map<String, Object?>>[],
  };
  if (location == null) return data;

  final zone = location.zone;
  final cache = <DateTime, DayTimes>{};
  DateTime plus(DateTime date, int days) => DateTime(date.year, date.month, date.day + days);
  DayTimes timesOn(DateTime date) => cache.putIfAbsent(
    date,
    () => dayTimesAt(
      location,
      date,
      method: settings.method,
      asrMethod: settings.asrMethod,
      hijriAdjust: settings.hijriAdjust,
    ),
  );
  String clock(DateTime time) =>
      formatTimeIn(TZDateTime.from(time, zone), language: language, use24h: use24h, digits: digits);

  final local = TZDateTime.from(now, zone);
  final today = DateTime(local.year, local.month, local.day);
  final first = prayerDayOf(now, today, timesOn(today).fajr);

  /// a prayer day without fajr lasts until midnight, as prayerDayOf counts it
  final until =
      timesOn(plus(first, 7)).fajr ?? TZDateTime(zone, first.year, first.month, first.day + 8);

  /// home changes only at these, so one entry holds from one to the next
  final boundaries = {
    for (var i = -1; i <= 8; i++)
      for (final time in [
        TZDateTime(zone, first.year, first.month, first.day + i),
        ...Period.values.map(timesOn(plus(first, i)).startOf),
      ])
        ?time?.millisecondsSinceEpoch,
  }.toList()..sort();

  /// from the start of the stretch now is in, so a second write in it is equal and skipped
  final start = boundaries.lastWhere((ms) => ms <= now.millisecondsSinceEpoch);
  final froms = [
    for (final ms in boundaries)
      if (ms >= start && ms < until.millisecondsSinceEpoch) ms,
  ];

  Map<String, Object?> entryAt(int from) {
    final moment = TZDateTime.fromMillisecondsSinceEpoch(zone, from);
    final date = DateTime(moment.year, moment.month, moment.day);
    final times = timesOn(date);
    final (prayer, at) = times.next(moment, timesOn(plus(date, 1)))!;
    final day = prayerDayOf(moment, date, times.fajr);
    final shown = timesOn(day);
    final marks = day == first ? prayed : const <Prayer>{};

    /// after isha the next fajr is the next day's, nothing in this day is highlighted
    final next = shown.timeOf(prayer)?.isAtSameMomentAs(at) ?? false ? prayer.index : null;
    final period = times.periodAt(moment);
    final barFrom = period == null
        ? null
        : periodStart(period, moment, times, timesOn(plus(date, -1)));
    final hijri = HijriDate.of(date, settings.hijriAdjust);
    final month = tr(hijri.monthKey);
    final hijriLine = number(hijriLineIn(hijri, month));
    final name = tr(prayer.nameKey);
    final time = clock(at);
    final minutes = settings.reminderMinutes;

    String? barFromLabel;
    if (period != null && barFrom != null) {
      final started = Prayer.values.asNameMap()[period.name];
      barFromLabel = started == null
          ? tr(StringsManager.sunriseLabel, {'time': clock(barFrom)})
          : tr(marks.contains(started) ? StringsManager.nameTimePrayed : StringsManager.nameTime, {
              'prayer': tr(started.nameKey),
              'time': clock(barFrom),
            });
    }

    return {
      'from': from,
      'prayer': prayer.name,
      'day': const CivilDate().toSql(day),
      'at': at.millisecondsSinceEpoch,
      'name': name,
      'time': time,
      'atTime': tr(StringsManager.atTime, {'time': time}),
      'timeCity': tr(StringsManager.notifReminderBody, {'time': time, 'city': city}),
      'nameTime': tr(StringsManager.nameTime, {'prayer': name, 'time': time}),
      'barFrom': barFrom?.millisecondsSinceEpoch,
      'barFromLabel': barFromLabel,
      'sunrise': times.sunrise?.millisecondsSinceEpoch,
      'maghrib': times.maghrib?.millisecondsSinceEpoch,
      'hijri': hijriLine,
      'hijriCity': '$hijriLine · $city',
      'dateLine': number(dateLineIn(date, hijriLineIn(hijri, month, year: false), language)),
      'prayedLine': tr(StringsManager.prayedToday, {'count': number('${marks.length}')}),
      'reminder': minutes == 0
          ? null
          : tr(StringsManager.reminderChip, {
              'time': clock(at.subtract(Duration(minutes: minutes))),
            }),
      'next': next,
      'strip': [
        for (final cell in Prayer.values)
          {
            'prayer': cell.name,
            'name': tr(cell.nameKey),
            'time': switch (shown.timeOf(cell)) {
              final time? => clock(time),
              null => '—',
            },
            'logged': marks.contains(cell),
            'past': next == null || cell.index < next,
          },
      ],
    };
  }

  int entryIndexAt(int ms) => froms.lastIndexWhere((from) => from <= ms);

  /// a prayer with no time (polar) has no window and isn't the previous one of the next
  final prayerTimes = [
    for (var i = -1; i < _windowDays; i++)
      for (final prayer in Prayer.values)
        if (timesOn(plus(first, i)).timeOf(prayer) case final time?) (day: i, time: time),
  ]..sort((a, b) => a.time.compareTo(b.time));
  final countdowns = <Map<String, Object?>>[];
  if (settings.prayerCountdown) {
    for (var i = 1; i < prayerTimes.length; i++) {
      final (:day, :time) = prayerTimes[i];
      final previous = prayerTimes[i - 1].time;
      final twoHours = time.subtract(_windowLength);
      final windowStart = previous.isAfter(twoHours) ? previous : twoHours;
      if (day < 0 || !time.isAfter(now) || !windowStart.isBefore(time)) continue;
      final shown = windowStart.isAfter(now) ? windowStart : now;
      countdowns.add({
        'start': windowStart.millisecondsSinceEpoch,
        'end': time.millisecondsSinceEpoch,
        'entry': entryIndexAt(shown.millisecondsSinceEpoch),
      });
    }
  }

  return {
    ...data,
    'until': until.millisecondsSinceEpoch,
    'entries': [for (final from in froms) entryAt(from)],
    'countdowns': countdowns,
  };
}
