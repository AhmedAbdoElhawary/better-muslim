import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

final hijriDateProvider = Provider.family<HijriDate, DateTime>(
  (ref, date) => HijriDate.of(
    date,
    ref.watch(settingsProvider.select((settings) => settings.value?.hijriAdjust ?? 0)),
  ),
);

/// Umm al-Qura date, month names come from the arb files, not the package
class HijriDate {
  const HijriDate({required this.day, required this.month, required this.year});

  /// utc and day arithmetic, so a daylight saving night never shifts the day
  factory HijriDate.of(DateTime localDate, int adjust) {
    final date = DateTime.utc(localDate.year, localDate.month, localDate.day + adjust);
    final hijri = HijriCalendar.fromDate(date);
    return HijriDate(day: hijri.hDay, month: hijri.hMonth, year: hijri.hYear);
  }

  final int day;
  final int month;
  final int year;

  String get monthKey => const [
    StringsManager.hijriMonth1,
    StringsManager.hijriMonth2,
    StringsManager.hijriMonth3,
    StringsManager.hijriMonth4,
    StringsManager.hijriMonth5,
    StringsManager.hijriMonth6,
    StringsManager.hijriMonth7,
    StringsManager.hijriMonth8,
    StringsManager.hijriMonth9,
    StringsManager.hijriMonth10,
    StringsManager.hijriMonth11,
    StringsManager.hijriMonth12,
  ][month - 1];
}
