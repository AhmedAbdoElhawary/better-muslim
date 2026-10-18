import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:timezone/timezone.dart' show TZDateTime;

/// the notification texts, built with no context so the background top-up writes the same ones
class AlertTexts {
  const AlertTexts({
    required this.l10n,
    required this.language,
    required this.use24h,
    required this.digits,
    required this.location,
  });

  final AppLocalizations l10n;
  final String language;
  final bool use24h;
  final Digits digits;
  final Location location;

  String get city => (language == 'ar' ? location.placeNameAr : null) ?? location.placeName ?? '';

  String titleOf(Alert alert) => l10n.tr(StringsManager.notifAdhanTitle, {
    'prayer': l10n.tr(alert.prayer.nameKey, const {}),
    'time': timeOf(alert),
  });

  String bodyOf(Alert alert) => l10n.tr(StringsManager.notifAdhanBody, {
    'prayer': l10n.tr(alert.prayer.nameKey, const {}),
    'city': city,
  });

  /// the place's own clock, the same time the app shows for a manual city in another zone
  String timeOf(Alert alert) => formatTimeIn(
    TZDateTime.from(alert.at, location.zone),
    language: language,
    use24h: use24h,
    digits: digits,
  );

  String tr(String key) => l10n.tr(key, const {});
}
