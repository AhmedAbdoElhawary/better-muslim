import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

extension TimeFormatExtension on BuildContext {
  /// the phone's 12 or 24 hour setting, the app stores none (FR-017a)
  String formatTime(TZDateTime time, Digits digits) => formatTimeIn(
    time,
    language: Localizations.localeOf(this).languageCode,
    use24h: MediaQuery.alwaysUse24HourFormatOf(this),
    digits: digits,
  );

  String formatDigits(String text, Digits digits) =>
      formatDigitsIn(text, language: Localizations.localeOf(this).languageCode, digits: digits);
}

/// the same as the context extension, for notifications built with no context
String formatTimeIn(
  TZDateTime time, {
  required String language,
  required bool use24h,
  required Digits digits,
}) {
  final format = use24h ? DateFormat.Hm(language) : DateFormat.jm(language);
  return formatDigitsIn(
    (format..useNativeDigits = false).format(time),
    language: language,
    digits: digits,
  );
}

/// eastern arabic digits only in arabic, and only when the digits setting says so
String formatDigitsIn(String text, {required String language, required Digits digits}) {
  if (language != 'ar' || digits == Digits.western) return text;
  return text.replaceAllMapped(
    RegExp('[0-9]'),
    (match) => String.fromCharCode(0x0660 + int.parse(match[0]!)),
  );
}

/// "4 Jumada I 1448", the month already translated. digits are left to the caller
String hijriLineIn(HijriDate hijri, String month, {bool year = true}) =>
    year ? '${hijri.day} $month ${hijri.year}' : '${hijri.day} $month';

/// english "Thu 15 Oct · {hijri}", arabic the full weekday and the hijri line (4.16)
String dateLineIn(DateTime date, String hijriLine, String language) {
  final day = language == 'ar'
      ? DateFormat.EEEE(language).format(date)
      : DateFormat('EEE d MMM', language).format(date);
  return '$day · $hijriLine';
}
