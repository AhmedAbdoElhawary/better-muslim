import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the notification texts, built with no context so the background top-up writes the same ones
class AlertTexts {
  const AlertTexts({
    required this.l10n,
    required this.language,
    required this.use24h,
    required this.digits,
    required this.location,
    this.azkar,
  });

  /// flutter_localizations loads the date symbols only inside the app, the background needs them
  static Future<AlertTexts> load({
    required Locale locale,
    required bool use24h,
    required Digits digits,
    required Location location,
  }) async {
    await initializeDateFormatting();
    return AlertTexts(
      l10n: await AppLocalizations.load(locale),
      language: locale.languageCode,
      use24h: use24h,
      digits: digits,
      location: location,
      azkar: await loadAzkarContent(),
    );
  }

  final AppLocalizations l10n;
  final String language;
  final bool use24h;
  final Digits digits;
  final Location location;

  /// the nudges' count and minutes come from the sets
  final AzkarContent? azkar;

  String get city => (language == 'ar' ? location.placeNameAr : null) ?? location.placeName ?? '';

  String titleOf(Alert alert) => switch (alert.kind) {
    AlertKind.adhan => l10n.tr(StringsManager.notifAdhanTitle, {
      'prayer': tr(alert.prayer.nameKey),
      'time': timeOf(alert),
    }),
    AlertKind.reminder => l10n.tr(StringsManager.notifReminderTitle, {
      'prayer': tr(alert.prayer.nameKey),
      'minutes': formatDigitsIn('${alert.before.inMinutes}', language: language, digits: digits),
    }),
    AlertKind.azkar => tr(azkarSetOf(alert.prayer).titleKey),
  };

  String bodyOf(Alert alert) => switch (alert.kind) {
    AlertKind.adhan => l10n.tr(StringsManager.notifAdhanBody, {
      'prayer': tr(alert.prayer.nameKey),
      'city': city,
    }),
    AlertKind.reminder => l10n.tr(StringsManager.notifReminderBody, {
      'time': timeOf(alert),
      'city': city,
    }),
    AlertKind.azkar => _azkarBody(azkarSetOf(alert.prayer)),
  };

  String _azkarBody(AzkarSet set) {
    final content = azkar?.setOf(set);
    String digitsOf(int value) => formatDigitsIn('$value', language: language, digits: digits);
    return l10n.tr(
      set == AzkarSet.morning
          ? StringsManager.notifAzkarMorningBody
          : StringsManager.notifAzkarBody,
      {'count': digitsOf(content?.total ?? 0), 'minutes': digitsOf(content?.minutes ?? 0)},
    );
  }

  /// the prayer's time, also on a reminder. the place's own clock, the same time the app shows
  /// for a manual city in another zone
  String timeOf(Alert alert) => formatTimeIn(
    TZDateTime.from(alert.prayerTime, location.zone),
    language: language,
    use24h: use24h,
    digits: digits,
  );

  String tr(String key) => l10n.tr(key, const {});
}
