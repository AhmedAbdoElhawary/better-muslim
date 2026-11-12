import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/home/view/widgets/location_pill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/providers.dart';

const _kaaba = (latitude: 21.4225, longitude: 39.8262);

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  /// loaded once outside fake time, the real list reads an asset in an isolate
  late PlaceList places;
  setUpAll(() async => places = await PlaceList.load());

  Future<FakePositionSource> openSheet(
    WidgetTester tester, {
    LocationPermission answer = LocationPermission.denied,
    LatLng? position,
  }) async {
    final source = FakePositionSource(answer: answer, position: position);
    await pumpHome(tester, [
      ...testOverrides(positionSource: source),
      placeListProvider.overrideWith((ref) async => places),

      /// a fixed hour, so the glow never breathes and the page always settles
      clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 13, 32)),
    ]);
    await tester.tap(find.byType(LocationPill));
    await tester.pumpAndSettle();
    return source;
  }

  Finder inSheet(Finder finder) =>
      find.descendant(of: find.byType(LocationSheet), matching: finder);

  /// the list has more than one tanta, the one in egypt is the test's
  final egypt = find.text('Gharbia · Egypt');

  /// the app watches the settings already, so their latest value is there after a pump
  AppSettings saved(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(HomePage)))
          .read(settingsProvider)
          .value!;

  testWidgets('the pill opens the sheet, its tap area is at least 44 x 44', (tester) async {
    await openSheet(tester);

    expect(find.byType(LocationSheet), findsOneWidget);
    final pill = tester.getSize(find.byType(LocationPill));
    expect(pill.width, greaterThanOrEqualTo(44));
    expect(pill.height, greaterThanOrEqualTo(44));
    await unmount(tester);
  });

  testWidgets('english and arabic queries find tanta with its region and country', (tester) async {
    await openSheet(tester);

    for (final query in ['tanta', 'طنطا']) {
      await tester.enterText(find.byType(TextField), query);
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Tanta')), findsWidgets, reason: query);
      expect(egypt, findsOneWidget, reason: query);
    }
    await unmount(tester);
  });

  testWidgets('a query with no match says so', (tester) async {
    await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No places found'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('picking a result saves it as manual and closes the sheet', (tester) async {
    await openSheet(tester);

    await tester.enterText(find.byType(TextField), 'tanta');
    await tester.pumpAndSettle();
    await tester.tap(egypt);
    await tester.pumpAndSettle();

    expect(find.byType(LocationSheet), findsNothing);
    expect(saved(tester).locationMode, LocationMode.manual);
    expect(find.text('Tanta'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('use my location denied says so and keeps the sheet open', (tester) async {
    await openSheet(tester);

    await tester.tap(inSheet(find.text('Use my location')));
    await tester.pumpAndSettle();

    expect(find.byType(LocationSheet), findsOneWidget);
    expect(
      find.text("Couldn't get your location. Check that location is on, or choose a city."),
      findsOneWidget,
    );
    expect(saved(tester).latitude, isNull);
    await unmount(tester);
  });

  testWidgets('use my location allowed closes the sheet', (tester) async {
    await openSheet(tester, answer: LocationPermission.whileInUse, position: _kaaba);

    await tester.tap(inSheet(find.text('Use my location')));
    await tester.pumpAndSettle();

    expect(find.byType(LocationSheet), findsNothing);
    expect(saved(tester).locationMode, LocationMode.auto);
    expect(find.text('Makkah'), findsOneWidget);
    await unmount(tester);
  });
}
