import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' show TZDateTime, getLocation;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    tz.initializeTimeZones();
    await initializeDateFormatting();
  });

  Future<AlertTexts> texts(String language, {bool use24h = true}) async => AlertTexts(
    l10n: await AppLocalizations.load(Locale(language)),
    language: language,
    use24h: use24h,
    digits: Digits.eastern,
    location: Location(
      latitude: 21.4225,
      longitude: 39.8262,
      placeName: 'Makkah',
      placeNameAr: 'مكة المكرمة',
      zone: getLocation('Asia/Riyadh'),
      mode: LocationMode.auto,
    ),
  );

  Alert maghrib() => Alert(
    day: DateTime(2026, 10, 15),
    prayer: Prayer.maghrib,
    kind: AlertKind.adhan,
    at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 17, 56),
    sound: PrayerSound.adhan,
  );

  test('english', () async {
    final english = await texts('en');

    expect(english.titleOf(maghrib()), 'Maghrib · 17:56');
    expect(english.bodyOf(maghrib()), 'It is time for Maghrib in Makkah. Tap to mark it prayed.');
  });

  test('arabic with eastern digits and the arabic place name', () async {
    final arabic = await texts('ar');

    expect(arabic.titleOf(maghrib()), 'المغرب · ١٧:٥٦');
    expect(arabic.bodyOf(maghrib()), 'حان وقت المغرب في مكة المكرمة. اضغط لتسجيل الصلاة.');
  });

  test('a 12 hour phone', () async {
    final english = await texts('en', use24h: false);

    expect(english.titleOf(maghrib()), matches(r'^Maghrib · 5:56\sPM$'));
  });

  test('the place\'s clock, not the phone\'s', () async {
    final english = await texts('en');
    final alert = Alert(
      day: DateTime(2026, 10, 15),
      prayer: Prayer.maghrib,
      kind: AlertKind.adhan,
      at: TZDateTime.from(maghrib().at, getLocation('Europe/London')),
      sound: PrayerSound.adhan,
    );

    expect(english.titleOf(alert), 'Maghrib · 17:56');
  });

  Alert reminder() => Alert(
    day: DateTime(2026, 10, 15),
    prayer: Prayer.maghrib,
    kind: AlertKind.reminder,
    at: TZDateTime(getLocation('Asia/Riyadh'), 2026, 10, 15, 17, 46),
    sound: PrayerSound.adhan,
    before: const Duration(minutes: 10),
  );

  test('a reminder in english', () async {
    final english = await texts('en');

    expect(english.titleOf(reminder()), 'Maghrib in 10 minutes');
    expect(english.bodyOf(reminder()), '17:56 · Makkah');
  });

  test('a reminder in arabic', () async {
    final arabic = await texts('ar');

    expect(arabic.titleOf(reminder()), 'المغرب بعد ١٠ دقائق');
    expect(arabic.bodyOf(reminder()), '١٧:٥٦ · مكة المكرمة');
  });
}
