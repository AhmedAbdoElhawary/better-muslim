import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/core/widgets/step/step_dots.dart';
import 'package:better_muslim/features/notifications/presentation/view/notifications_step_page.dart';
import 'package:better_muslim/features/onboarding/view/location_step_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/onboarding.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

const _kaaba = (latitude: 21.4225, longitude: 39.8262);

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  /// loaded once outside fake time, the real list reads an asset in an isolate
  late PlaceList places;
  setUpAll(() async => places = await PlaceList.load());

  Future<void> open(
    WidgetTester tester,
    FakePositionSource source, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) => pumpStep(
    tester,
    Routes.onboardingLocation,
    overrides: [
      ...testOverrides(positionSource: source, onboarded: false),
      placeListProvider.overrideWith((ref) async => places),
    ],
    locale: locale,
    textScale: textScale,
  );

  AppSettings saved(WidgetTester tester) => containerOf(tester).read(settingsProvider).value!;

  testWidgets('4.11 with the first dot wide', (tester) async {
    await open(tester, FakePositionSource());

    expect(find.text('Prayer times for where you are'), findsOneWidget);
    expect(find.text('Accurate prayer times'), findsOneWidget);
    expect(find.text('Qibla direction'), findsOneWidget);
    expect(find.text('Stays on this phone'), findsOneWidget);
    expect(find.text('Change it anytime in More › Location'), findsOneWidget);
    expect(tester.widget<StepDots>(find.byType(StepDots)).step, 1);
    for (final button in find.byType(BmButton).evaluate()) {
      expect(button.size!.height, greaterThanOrEqualTo(44));
    }
    await unmount(tester);
  });

  testWidgets('use my location, allowed: the place is kept in auto and 4.12 builds', (
    tester,
  ) async {
    final source = FakePositionSource(answer: LocationPermission.whileInUse, position: _kaaba);
    await open(tester, source);

    await tester.tap(find.text('Use my location'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await frames(tester, const Duration(milliseconds: 1000));

    expect(source.requests, 1);
    expect(saved(tester).placeName, 'Makkah');
    expect(saved(tester).locationMode, LocationMode.auto);
    expect(find.byType(NotificationsStepPage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('refused: the city search opens at once saying why, a city goes on', (tester) async {
    final source = FakePositionSource(answer: LocationPermission.denied);
    await open(tester, source);

    await tester.tap(find.text('Use my location'));
    await tester.pump();
    await frames(tester, const Duration(milliseconds: 800));
    expect(find.byType(LocationSheet), findsOneWidget);
    expect(find.textContaining("Couldn't get your location"), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tanta');
    await frames(tester, const Duration(milliseconds: 200));
    await tester.tap(find.text('Gharbia · Egypt'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await frames(tester, const Duration(milliseconds: 1200));

    expect(saved(tester).placeName, 'Tanta');
    expect(saved(tester).locationMode, LocationMode.manual);
    expect(find.byType(NotificationsStepPage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the search closed without a city stays on 4.11', (tester) async {
    await open(tester, FakePositionSource(answer: LocationPermission.deniedForever));

    await tester.tap(find.text('Use my location'));
    await frames(tester, const Duration(milliseconds: 800));
    expect(find.byType(LocationSheet), findsOneWidget);

    await tester.tapAt(const Offset(196, 40));
    await frames(tester, const Duration(milliseconds: 800));
    expect(find.byType(LocationSheet), findsNothing);
    expect(find.byType(NotificationsStepPage), findsNothing);
    expect(find.byType(LocationStepPage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('choose a city instead opens the search without the line', (tester) async {
    final source = FakePositionSource();
    await open(tester, source);

    await tester.tap(find.text('Choose a city instead'));
    await frames(tester, const Duration(milliseconds: 800));
    expect(find.byType(LocationSheet), findsOneWidget);
    expect(find.textContaining("Couldn't get your location"), findsNothing);
    expect(source.requests, 0);
    await unmount(tester);
  });

  for (final (name, locale, scale) in [
    ('arabic', const Locale('ar'), 1.0),
    ('text scale 2.0', const Locale('en'), 2.0),
    ('arabic at 2.0', const Locale('ar'), 2.0),
  ]) {
    testWidgets('$name: nothing cut, the buttons stay at the bottom', (tester) async {
      await open(tester, FakePositionSource(), locale: locale, textScale: scale);
      expect(tester.takeException(), isNull);
      final buttons = tester.getRect(find.byType(BmButton).first);
      expect(buttons.bottom, lessThan(852));
      await unmount(tester);
    });
  }
}
