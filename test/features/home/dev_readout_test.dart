import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  Future<void> pumpMakkah(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(),
          clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 13, 32)),
          locationProvider.overrideWithValue(
            Location(
              latitude: 21.4266,
              longitude: 39.8256,
              placeName: 'Makkah',
              placeNameAr: 'مكة المكرمة',
              countryCode: 'SA',
              zone: tz.getLocation('Asia/Riyadh'),
              mode: LocationMode.auto,
            ),
          ),
        ],

        /// the PNGs use a 24 hour phone, MaterialApp takes the flag from a parent MediaQuery
        child: MediaQuery(
          data: MediaQueryData.fromView(tester.view).copyWith(alwaysUse24HourFormat: true),
          child: const App(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('english shows the place, the six times and the next prayer', (tester) async {
    await pumpMakkah(tester);

    expect(find.text('Makkah · auto'), findsOneWidget);
    expect(find.text('Umm al-Qura'), findsOneWidget);
    for (final time in ['05:00', '06:16', '12:06', '15:27', '17:56', '19:26']) {
      expect(find.text(time), findsOneWidget, reason: time);
    }
    expect(find.text('Maghrib'), findsNWidgets(2));
    expect(find.text('in 1:24:00'), findsOneWidget);
    expect(find.text('4 Jumada I 1448'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('arabic shows the arabic place name and eastern digits', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await pumpMakkah(tester);

    expect(find.text('مكة المكرمة · تلقائي'), findsOneWidget);
    for (final time in ['٠٥:٠٠', '٠٦:١٦', '١٢:٠٦', '١٥:٢٧', '١٧:٥٦', '١٩:٢٦']) {
      expect(find.text(time), findsOneWidget, reason: time);
    }
    expect(find.text('بعد ١:٢٤:٠٠'), findsOneWidget);
    expect(find.text('٤ جمادى الأولى ١٤٤٨'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('with no location it says so', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();

    expect(find.text('No location yet'), findsOneWidget);
    await unmount(tester);
  });
}
