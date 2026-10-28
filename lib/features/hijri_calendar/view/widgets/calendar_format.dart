import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

const hijriShortMonths = [
  StringsManager.hijriShort1,
  StringsManager.hijriShort2,
  StringsManager.hijriShort3,
  StringsManager.hijriShort4,
  StringsManager.hijriShort5,
  StringsManager.hijriShort6,
  StringsManager.hijriShort7,
  StringsManager.hijriShort8,
  StringsManager.hijriShort9,
  StringsManager.hijriShort10,
  StringsManager.hijriShort11,
  StringsManager.hijriShort12,
];

/// the calendar's dates as text, in the app's language and digits
extension CalendarFormat on BuildContext {
  String get _locale => Localizations.localeOf(this).languageCode;

  String dayMonth(DateTime day, Digits digits) =>
      formatDigits(DateFormat('d MMM', _locale).format(day), digits);

  /// "24–26 Oct", "30 Oct – 1 Nov", or one day alone
  String dayRange(DateTime start, DateTime end, Digits digits) {
    if (start == end) return dayMonth(start, digits);
    if (start.month == end.month) {
      return formatDigits('${start.day}–${DateFormat('d MMM', _locale).format(end)}', digits);
    }
    return '${dayMonth(start, digits)} – ${dayMonth(end, digits)}';
  }

  /// "October – November 2026", or both years when it crosses one
  String monthSpan(DateTime first, DateTime last, Digits digits) {
    final month = DateFormat.MMMM(_locale);
    if (first.month == last.month) {
      return formatDigits(DateFormat.yMMMM(_locale).format(first), digits);
    }
    if (first.year == last.year) {
      return formatDigits(
        tr(StringsManager.monthSpan, {
          'first': month.format(first),
          'last': month.format(last),
          'year': '${first.year}',
        }),
        digits,
      );
    }
    return formatDigits(
      tr(StringsManager.monthSpanYears, {
        'first': month.format(first),
        'firstYear': '${first.year}',
        'last': month.format(last),
        'lastYear': '${last.year}',
      }),
      digits,
    );
  }

  /// "October 2026"
  String gregorianMonth(int year, int month, Digits digits) =>
      formatDigits(DateFormat.yMMMM(_locale).format(DateTime(year, month)), digits);

  String gregorianMonthName(int month) => DateFormat.MMMM(_locale).format(DateTime(2026, month));

  /// "Rabi II – Jumada I 1448", or both years when it crosses one
  String hijriSpan(HijriDate first, HijriDate last, Digits digits) {
    if (first.month == last.month) {
      return formatDigits('${tr(first.monthKey)} ${first.year}', digits);
    }
    if (first.year == last.year) {
      return formatDigits(
        tr(StringsManager.monthSpan, {
          'first': tr(first.monthKey),
          'last': tr(last.monthKey),
          'year': '${first.year}',
        }),
        digits,
      );
    }
    return formatDigits(
      tr(StringsManager.monthSpanYears, {
        'first': tr(first.monthKey),
        'firstYear': '${first.year}',
        'last': tr(last.monthKey),
        'lastYear': '${last.year}',
      }),
      digits,
    );
  }

  /// "20 Rab II"
  String hijriDayMonth(HijriDate date, Digits digits) =>
      formatDigits('${date.day} ${tr(hijriShortMonths[date.month - 1])}', digits);

  /// "13–15 Jum I", "29 Ram – 1 Shaw", or one day alone
  String hijriRange(HijriDate start, HijriDate end, Digits digits) {
    if (start.day == end.day && start.month == end.month) return hijriDayMonth(start, digits);
    if (start.month == end.month) {
      return formatDigits('${start.day}–${end.day} ${tr(hijriShortMonths[end.month - 1])}', digits);
    }
    return '${hijriDayMonth(start, digits)} – ${hijriDayMonth(end, digits)}';
  }

  /// "1 day", "12 days"
  String daysAway(int days, Digits digits) =>
      tr(StringsManager.days, {'sign': '', 'n': formatDigits('$days', digits)});
}
