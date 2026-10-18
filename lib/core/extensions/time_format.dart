import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart';

extension TimeFormatExtension on BuildContext {
  /// the phone's 12 or 24 hour setting, the app stores none (FR-017a)
  String formatTime(TZDateTime time, Digits digits) {
    final locale = Localizations.localeOf(this).languageCode;
    final format = MediaQuery.alwaysUse24HourFormatOf(this)
        ? DateFormat.Hm(locale)
        : DateFormat.jm(locale);
    return formatDigits((format..useNativeDigits = false).format(time), digits);
  }

  /// eastern arabic digits only in arabic, and only when the digits setting says so
  String formatDigits(String text, Digits digits) {
    final isArabic = Localizations.localeOf(this).languageCode == 'ar';
    if (!isArabic || digits == Digits.western) return text;
    return text.replaceAllMapped(
      RegExp('[0-9]'),
      (match) => String.fromCharCode(0x0660 + int.parse(match[0]!)),
    );
  }
}
