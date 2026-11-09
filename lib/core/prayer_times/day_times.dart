import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:timezone/timezone.dart';

/// the five prayers, sunrise is a time but not a prayer
enum Prayer {
  fajr(StringsManager.fajr, StringsManager.fajrAr),
  dhuhr(StringsManager.dhuhr, StringsManager.dhuhrAr),
  asr(StringsManager.asr, StringsManager.asrAr),
  maghrib(StringsManager.maghrib, StringsManager.maghribAr),
  isha(StringsManager.isha, StringsManager.ishaAr);

  const Prayer(this.nameKey, this.nameArKey);
  final String nameKey;

  /// the arabic name in both languages, english shows it beside the name
  final String nameArKey;
}

enum Period {
  fajr(StringsManager.fajr, StringsManager.fajrAr),
  duha(StringsManager.duha, StringsManager.duhaAr),
  dhuhr(StringsManager.dhuhr, StringsManager.dhuhrAr),
  asr(StringsManager.asr, StringsManager.asrAr),
  maghrib(StringsManager.maghrib, StringsManager.maghribAr),
  isha(StringsManager.isha, StringsManager.ishaAr);

  const Period(this.nameKey, this.nameArKey);
  final String nameKey;
  final String nameArKey;
}

/// the six times of one local date at one place, null = not available that day (polar)
class DayTimes {
  const DayTimes({
    required this.date,
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.method,
    required this.asrMethod,
  });

  factory DayTimes.compute({
    required double latitude,
    required double longitude,
    required DateTime date,
    required Location zone,
    required PrayerMethod method,
    required AsrMethod asrMethod,
    required bool isRamadan,
  }) {
    final coordinates = adhan.Coordinates(latitude, longitude);
    final parameters = method.parameters
      ..madhab = asrMethod.madhab
      ..highLatitudeRule = adhan.HighLatitudeRule.recommended(coordinates);

    /// adhan's umm al-qura preset has the 90 minutes only, its readme says to add these in ramadan
    if (method == PrayerMethod.ummAlQura && isRamadan) {
      parameters.adjustments[adhan.Prayer.isha] = 30;
    }
    adhan.PrayerTimes calculate(DateTime day) =>
        adhan.PrayerTimes(coordinates: coordinates, date: day, calculationParameters: parameters);

    /// adhan takes the date as the solar day at the longitude, which is the wrong day where the
    /// zone is far from it (samoa, kiribati), so the day is moved until dhuhr lands on the date
    var times = calculate(date);
    final dhuhr = TZDateTime.from(times.dhuhr, zone);
    final shift = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(dhuhr.year, dhuhr.month, dhuhr.day)).inDays;
    if (shift != 0) times = calculate(DateTime(date.year, date.month, date.day + shift));

    /// above the polar circle adhan gives times weeks away instead of none. the window is around
    /// dhuhr, not the calendar day, since isha can rightly fall after local midnight
    TZDateTime? ofThisDay(DateTime time) =>
        time.difference(times.dhuhr).abs() < const Duration(hours: 14)
        ? TZDateTime.from(time, zone)
        : null;

    return DayTimes(
      date: DateTime(date.year, date.month, date.day),
      fajr: ofThisDay(times.fajr),
      sunrise: ofThisDay(times.sunrise),
      dhuhr: TZDateTime.from(times.dhuhr, zone),
      asr: ofThisDay(times.asr),
      maghrib: ofThisDay(times.maghrib),
      isha: ofThisDay(times.isha),
      method: method,
      asrMethod: asrMethod,
    );
  }

  final DateTime date;
  final TZDateTime? fajr;
  final TZDateTime? sunrise;
  final TZDateTime? dhuhr;
  final TZDateTime? asr;
  final TZDateTime? maghrib;
  final TZDateTime? isha;
  final PrayerMethod method;
  final AsrMethod asrMethod;

  TZDateTime? timeOf(Prayer prayer) => switch (prayer) {
    Prayer.fajr => fajr,
    Prayer.dhuhr => dhuhr,
    Prayer.asr => asr,
    Prayer.maghrib => maghrib,
    Prayer.isha => isha,
  };

  TZDateTime? startOf(Period period) => switch (period) {
    Period.fajr => fajr,
    Period.duha => sunrise,
    Period.dhuhr => dhuhr,
    Period.asr => asr,
    Period.maghrib => maghrib,
    Period.isha => isha,
  };

  /// before today's fajr it is still yesterday's isha
  Period? periodAt(DateTime now) {
    if (Period.values.every((period) => startOf(period) == null)) return null;
    var current = Period.isha;
    for (final period in Period.values) {
      final start = startOf(period);
      if (start != null && !now.isBefore(start)) current = period;
    }
    return current;
  }

  /// a prayer is open until the next start that has a time, the same boundaries as periodAt.
  /// null on a polar day with nothing after it
  TZDateTime? endOf(Prayer prayer, DayTimes? tomorrow) {
    final after = switch (prayer) {
      Prayer.fajr => [sunrise, dhuhr, asr, maghrib, isha],
      Prayer.dhuhr => [asr, maghrib, isha],
      Prayer.asr => [maghrib, isha],
      Prayer.maghrib => [isha],
      Prayer.isha => <TZDateTime?>[],
    };
    return [...after, tomorrow?.fajr].nonNulls.firstOrNull;
  }

  /// the night is maghrib to fajr, so the caller passes the next day's fajr
  TZDateTime? lastThird(TZDateTime? nextFajr) {
    final start = maghrib;
    if (start == null || nextFajr == null) return null;
    return nextFajr.subtract(nextFajr.difference(start) ~/ 3);
  }

  /// after isha it is tomorrow's fajr, so the caller passes tomorrow's times
  (Prayer, TZDateTime)? next(DateTime now, DayTimes? tomorrow) {
    for (final day in [this, ?tomorrow]) {
      for (final prayer in Prayer.values) {
        final time = day.timeOf(prayer);
        if (time != null && time.isAfter(now)) return (prayer, time);
      }
    }
    return null;
  }

  static const nowWindow = Duration(minutes: 20);

  /// the prayer in its now window. a next prayer that comes sooner ends it
  (Prayer, TZDateTime)? inWindow(DateTime now) {
    final started = [
      for (final prayer in Prayer.values)
        if (timeOf(prayer) case final time? when !now.isBefore(time)) (prayer, time),
    ].lastOrNull;
    if (started == null || !now.isBefore(started.$2.add(nowWindow))) return null;
    return started;
  }
}
