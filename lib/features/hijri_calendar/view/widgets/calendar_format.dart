import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

/// the calendar's dates as text, in the app's language and digits
extension CalendarFormat on BuildContext {
  String get _locale => Localizations.localeOf(this).languageCode;

  String hijriFull(HijriDate date, Digits digits) =>
      formatDigits('${date.day} ${tr(date.monthKey)} ${date.year}', digits);

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

  /// "+1 day", "−2 days", "0 days"
  String adjustment(int adjust, Digits digits) => tr(StringsManager.days, {
    'sign': adjust > 0 ? '+' : (adjust < 0 ? '−' : ''),
    'n': formatDigits('${adjust.abs()}', digits),
  });
}
