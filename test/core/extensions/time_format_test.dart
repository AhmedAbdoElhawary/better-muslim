import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tz.initializeTimeZones);

  Future<String> format(
    WidgetTester tester, {
    required String language,
    required bool use24Hour,
    Digits digits = Digits.eastern,
  }) async {
    final maghrib = tz.TZDateTime(tz.getLocation('Asia/Riyadh'), 2026, 10, 15, 17, 56);
    late String text;
    await tester.pumpWidget(
      Localizations(
        locale: Locale(language),
        delegates: AppLocalizations.localizationsDelegates,
        child: MediaQuery(
          data: MediaQueryData(alwaysUse24HourFormat: use24Hour),
          child: Builder(
            builder: (context) {
              text = context.formatTime(maghrib, digits);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return text;
  }

  testWidgets('english 24 hour', (tester) async {
    expect(await format(tester, language: 'en', use24Hour: true), '17:56');
  });

  testWidgets('english 12 hour', (tester) async {
    expect(await format(tester, language: 'en', use24Hour: false), matches(r'^5:56\sPM$'));
  });

  testWidgets('arabic with eastern digits', (tester) async {
    expect(await format(tester, language: 'ar', use24Hour: true), '١٧:٥٦');
  });

  testWidgets('arabic with western digits', (tester) async {
    expect(await format(tester, language: 'ar', use24Hour: true, digits: Digits.western), '17:56');
  });

  group('without a context, for notifications', () {
    setUpAll(initializeDateFormatting);
    tz.TZDateTime maghrib() => tz.TZDateTime(tz.getLocation('Asia/Riyadh'), 2026, 10, 15, 17, 56);

    test('english 24 and 12 hour', () {
      expect(
        formatTimeIn(maghrib(), language: 'en', use24h: true, digits: Digits.eastern),
        '17:56',
      );
      expect(
        formatTimeIn(maghrib(), language: 'en', use24h: false, digits: Digits.eastern),
        matches(r'^5:56\sPM$'),
      );
    });

    test('arabic follows the digits setting', () {
      expect(
        formatTimeIn(maghrib(), language: 'ar', use24h: true, digits: Digits.eastern),
        '١٧:٥٦',
      );
      expect(
        formatTimeIn(maghrib(), language: 'ar', use24h: true, digits: Digits.western),
        '17:56',
      );
    });

    test('digits change only in arabic', () {
      expect(formatDigitsIn('10', language: 'ar', digits: Digits.eastern), '١٠');
      expect(formatDigitsIn('10', language: 'en', digits: Digits.eastern), '10');
    });
  });
}
