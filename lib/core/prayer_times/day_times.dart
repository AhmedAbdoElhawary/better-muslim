import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:timezone/timezone.dart';

/// the five prayers, sunrise is a time but not a prayer
enum Prayer {
  fajr(StringsManager.fajr),
  dhuhr(StringsManager.dhuhr),
  asr(StringsManager.asr),
  maghrib(StringsManager.maghrib),
  isha(StringsManager.isha);

  const Prayer(this.nameKey);
  final String nameKey;
}

enum Period {
  fajr(StringsManager.fajr),
  duha(StringsManager.duha),
  dhuhr(StringsManager.dhuhr),
  asr(StringsManager.asr),
  maghrib(StringsManager.maghrib),
  isha(StringsManager.isha);

  const Period(this.nameKey);
  final String nameKey;
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

  /// before today's fajr it is still yesterday's isha
  Period? periodAt(DateTime now) {
    final starts = {
      Period.fajr: fajr,
      Period.duha: sunrise,
      Period.dhuhr: dhuhr,
      Period.asr: asr,
      Period.maghrib: maghrib,
      Period.isha: isha,
    };
    if (starts.values.every((start) => start == null)) return null;
    var period = Period.isha;
    for (final MapEntry(key: candidate, value: start) in starts.entries) {
      if (start != null && !now.isBefore(start)) period = candidate;
    }
    return period;
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
}
