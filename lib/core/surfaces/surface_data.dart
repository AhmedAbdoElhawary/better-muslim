import 'dart:math' as math;

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
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/painting.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the file the widgets, the live activity and the android countdown read
/// (contracts/surface-data.md). the prayer rules stay in dart, the native side only picks the
/// entry in force and counts. the countdown shows while the app is off screen, the native side
/// knows when
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
  final theme = bmThemes[settings.theme]!;
  final data = <String, Object?>{
    'version': 2,
    'place': location != null,
    'language': language,
    'eastern': language == 'ar' && digits == Digits.eastern,
    'reminderMinutes': settings.reminderMinutes,
    'mode': settings.themeMode.name,
    'colors': {'light': _colorsOf(theme.light, dark: false), 'dark': _colorsOf(theme.dark)},
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

    /// entries change at sunrise and maghrib, so follow sky holds for a whole entry. no sunrise
    /// or no maghrib as followSkyProvider has it
    final light = switch (settings.themeMode) {
      BmThemeMode.dark => false,
      BmThemeMode.light => true,
      BmThemeMode.followSky => switch ((times.sunrise, times.maghrib)) {
        (null, _) => false,
        (_, null) => true,
        (final sunrise?, final maghrib?) => !moment.isBefore(sunrise) && moment.isBefore(maghrib),
      },
    };

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
      'nameNow': tr(StringsManager.prayerNow, {'prayer': name}),
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
      'light': light,
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

  return {
    ...data,
    'until': until.millisecondsSinceEpoch,
    'entries': [for (final from in froms) entryAt(from)],
  };
}

/// the 5.6 trees' colors as roles: the dark sky behind dark widgets, and light ones on the theme's
/// own surfaces, since its light sky stays dark
Map<String, int> _colorsOf(BmPalette palette, {bool dark = true}) {
  final (top, middle, sky) = dark
      ? (palette.sky1, palette.sky2, palette.sky3)
      : (palette.surface, palette.raised, palette.variant);
  final gold = HSLColor.fromColor(palette.onPrimaryContainer);

  /// the live countdown's digits a step brighter than gold, lighter on dark and darker on light
  final live = gold.withLightness((gold.lightness + (dark ? .1 : -.1)).clamp(0, 1)).toColor();
  final label = palette.text.withValues(alpha: .85);
  final texts = [palette.text, label, palette.onPrimaryContainer, live];

  /// some themes' last sky is too light under the text, it goes toward the middle until aa
  var bottom = sky;
  for (var t = .05; texts.any((text) => _ratio(text, bottom) < 4.5) && t <= 1; t += .05) {
    bottom = Color.lerp(sky, middle, t)!;
  }
  return {
    'top': top.toARGB32(),
    'middle': middle.toARGB32(),
    'bottom': bottom.toARGB32(),
    'deep': Color.lerp(middle, bottom, .4)!.toARGB32(),
    'text': palette.text.toARGB32(),
    'label': label.toARGB32(),
    'dim': palette.text2.toARGB32(),
    'gold': palette.onPrimaryContainer.toARGB32(),
    'live': live.toARGB32(),
    'primary': palette.primary.toARGB32(),
    'container': palette.primaryContainer.toARGB32(),
    'success': palette.success.toARGB32(),
    'ring': palette.outlineStrong.toARGB32(),

    /// a light sun disappears on a light surface
    'sun': (dark ? palette.sun : palette.glow).toARGB32(),
    'outline': palette.outline.toARGB32(),
  };
}

/// wcag's ratio, a see through text laid over what it sits on first
double _ratio(Color text, Color under) {
  final front = Color.alphaBlend(text, under).computeLuminance();
  final back = under.computeLuminance();
  return (math.max(front, back) + .05) / (math.min(front, back) + .05);
}

/// the dev page's rehearsal, the real alarms with no clock to change
const rehearsalReminder = Duration(seconds: 30);
const rehearsalPrayer = Duration(seconds: 90);

/// the entry in force goes on after it, so a killed app leaves nothing to clean up
Map<String, Object?> withRehearsal(Map<String, Object?> data, DateTime now) {
  final entries = (data['entries']! as List).cast<Map<String, Object?>>();
  final from = now.millisecondsSinceEpoch;
  final at = now.add(rehearsalPrayer).millisecondsSinceEpoch;
  int fromOf(Map<String, Object?> entry) => entry['from']! as int;
  final shown = entries.lastWhere((entry) => fromOf(entry) <= from);
  return {
    ...data,
    'entries': [
      ...entries.where((entry) => fromOf(entry) <= from),
      {
        ...shown,
        'from': from,
        'at': at,
        'start': now.add(rehearsalReminder).millisecondsSinceEpoch,
      },
      {...shown, 'from': at},
      ...entries.where((entry) => fromOf(entry) > at),
    ],
  };
}
