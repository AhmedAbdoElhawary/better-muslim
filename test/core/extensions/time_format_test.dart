import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
