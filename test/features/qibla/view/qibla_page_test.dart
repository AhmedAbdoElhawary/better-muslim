import 'dart:math' as math;

import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/qibla/declination.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/core/widgets/sheet/location_choices.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/features/qibla/view/qibla_page.dart';
import 'package:better_muslim/features/qibla/view/widgets/aligned_pulse.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_cards.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_dial.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_dot.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_needle.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/qibla.dart';
import '../../../helpers/sounds.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  /// the real fonts, the square test font is far wider and would overflow where the app doesn't
  setUpAll(loadAppFonts);

  final haptics = <String>[];
  final announcements = <String>[];
  setUp(() {
    haptics.clear();
    announcements.clear();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
      return null;
    });
    messenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (message) async {
      final data = (message! as Map)['data'] as Map;
      if (data['message'] case final String text) announcements.add(text);
      return null;
    });
  });

  const approach = 'HapticFeedbackType.selectionClick';
  const aligned = 'HapticFeedbackType.mediumImpact';
  final start = DateTime.utc(2026, 10, 15, 13, 32);
  final offset = declination(51.5074, -0.1278, decimalYear: decimalYear(start));

  late FakeCompassSource compass;
  setUp(() => compass = FakeCompassSource());

  /// london by hand, a fake compass and a clock that moves with the test's fake time
  List<Override> londonWith(WidgetTester tester, {bool location = true}) {
    final origin = tester.binding.clock.now();
    return [
      ...testOverrides(compass: compass),
      clockProvider.overrideWithValue(
        () => start.add(tester.binding.clock.now().difference(origin)),
      ),
      if (location)
        locationProvider.overrideWithValue(london())
      else
        locationProvider.overrideWithValue(null),
    ];
  }

  /// the top of the phone to a true heading, then long enough for the smoothing to arrive
  Future<void> face(WidgetTester tester, double heading, {double accuracy = 10}) async {
    compass.send(heading - offset, accuracy: accuracy);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  double degreesOf(Transform transform) {
    final matrix = transform.transform;
    return math.atan2(matrix.entry(1, 0), matrix.entry(0, 0)) * 180 / math.pi;
  }

  /// the face's turn, in (−180, 180]
  double dialAngle(WidgetTester tester) => degreesOf(
    tester.widget<Transform>(
      find
          .ancestor(
            of: find.byWidgetPredicate(
              (widget) => widget is CustomPaint && widget.painter is DialPainter,
            ),
            matching: find.byType(Transform),
          )
          .first,
    ),
  );

  DialPainter painter(WidgetTester tester) =>
      tester
              .widget<CustomPaint>(
                find.byWidgetPredicate(
                  (widget) => widget is CustomPaint && widget.painter is DialPainter,
                ),
              )
              .painter!
          as DialPainter;

  Finder needleTurn() =>
      find.descendant(of: find.byType(QiblaNeedle), matching: find.byType(Transform));

  double needleAngle(WidgetTester tester) =>
      degreesOf(tester.widget<Transform>(needleTurn().first));

  Finder accuracyDot() =>
      find.descendant(of: find.byType(QiblaCards), matching: find.byType(QiblaDot));

  ThemeEnum dotColor(WidgetTester tester) => tester.widget<QiblaDot>(accuracyDot()).color;

  Color colorOf(WidgetTester tester, ThemeEnum role) =>
      tester.element(find.byType(QiblaPage)).getColor(role);

  Color ringColor(WidgetTester tester) {
    final ring = tester.widget<AnimatedContainer>(
      find.descendant(of: find.byType(QiblaDial), matching: find.byType(AnimatedContainer)).first,
    );
    final decoration =
        tester
                .renderObject<RenderDecoratedBox>(
                  find
                      .descendant(of: find.byWidget(ring), matching: find.byType(DecoratedBox))
                      .first,
                )
                .decoration
            as BoxDecoration;
    return (decoration.border! as Border).top.color;
  }

  Color topTickColor(WidgetTester tester) {
    final decoration =
        tester
                .renderObject<RenderDecoratedBox>(
                  find
                      .descendant(
                        of: find
                            .descendant(
                              of: find.byType(QiblaDial),
                              matching: find.byType(AnimatedContainer),
                            )
                            .last,
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    return decoration.color!;
  }

  bool pulsing(WidgetTester tester) => find
      .descendant(of: find.byType(AlignedPulse), matching: find.byType(CustomOpacity))
      .evaluate()
      .isNotEmpty;

  bool inGlow(Element element) => find
      .ancestor(
        of: find.byElementPredicate((e) => e == element),
        matching: find.byType(AlignedGlow),
      )
      .evaluate()
      .isNotEmpty;

  group('turning (4.05)', () {
    testWidgets('the design scenario in english', (tester) async {
      await pumpQibla(tester, await designOverrides());

      expect(find.text('Qibla'), findsOneWidget);
      expect(find.text('Turn 14° right'), findsOneWidget);
      expect(find.text('London · Qibla at 119° from north'), findsOneWidget);
      expect(find.text('4,790 km'), findsOneWidget);
      expect(find.text('to the Kaaba'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('compass accuracy'), findsOneWidget);
      expect(find.text('Hold your phone flat, away from metal and magnets.'), findsOneWidget);
      expect(find.text('N'), findsOneWidget);
      expect(dotColor(tester), ThemeEnum.success);

      expect(dialAngle(tester), closeTo(-105, 1e-6));
      expect(needleAngle(tester), closeTo(14, .05));
      await unmount(tester);
    });

    testWidgets('arabic: eastern digits, the arabic letters, the dial never mirrored', (
      tester,
    ) async {
      await pumpQibla(tester, await designOverrides(), locale: const Locale('ar'));

      expect(find.text('استدر ١٤° يمينًا'), findsOneWidget);
      expect(find.text('لندن · القبلة على ١١٩° من الشمال'), findsOneWidget);
      expect(find.text('٤٬٧٩٠ كم'), findsOneWidget);
      expect(find.text('عالية'), findsOneWidget);
      for (final letter in ['ش', 'ق', 'ج', 'غ']) {
        expect(find.text(letter), findsOneWidget);
      }
      expect(dialAngle(tester), closeTo(-105, 1e-6));
      expect(needleAngle(tester), closeTo(14, .05));
      final dial = find.byType(QiblaDial);
      expect(
        tester
            .widget<Directionality>(
              find.descendant(of: dial, matching: find.byType(Directionality)).first,
            )
            .textDirection,
        TextDirection.ltr,
      );

      /// east sits right of the center, whatever the language
      final center = tester.getCenter(dial);
      final north = tester.getCenter(find.text('ش'));
      final east = tester.getCenter(find.text('ق'));
      final angle = math.atan2(east.dx - center.dx, center.dy - east.dy) * 180 / math.pi;
      expect(angle, closeTo(-15, .5));
      expect(north.dy, greaterThan(center.dy));

      final back = tester.widget<Transform>(
        find.descendant(of: find.byType(BarBackButton), matching: find.byType(Transform)),
      );
      expect(back.transform.entry(0, 0), -1);
      await unmount(tester);
    });

    testWidgets('letters stay upright as the face turns', (tester) async {
      await pumpQibla(tester, await designOverrides());
      for (final letter in ['N', 'E', 'S', 'W']) {
        final turns = tester.widgetList<Transform>(
          find.ancestor(of: find.text(letter), matching: find.byType(Transform)),
        );
        expect(turns.map(degreesOf), everyElement(0), reason: letter);
      }
      await unmount(tester);
    });

    testWidgets('across north the needle takes the short way', (tester) async {
      await pumpQibla(tester, londonWith(tester));
      await face(tester, 350);
      await tester.pumpAndSettle();
      final from = needleAngle(tester);
      expect(from, closeTo(129, .1));
      expect(dialAngle(tester), closeTo(10, .1));

      compass.send(10 - offset);
      final seen = <double>[];
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        seen.add(needleAngle(tester));
      }
      expect(seen, everyElement(inInclusiveRange(100, 135)));
      expect(dialAngle(tester), closeTo(-10, .5));
      await unmount(tester);
    });

    testWidgets('reduce motion: the needle arrives in 300 ms with no overshoot', (tester) async {
      await pumpQibla(tester, londonWith(tester), reduceMotion: true);
      await face(tester, 105);
      await tester.pumpAndSettle();
      expect(needleAngle(tester), closeTo(14, .1));

      compass.send(139 - offset);
      await tester.pump();
      final seen = <double>[];
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 30));
        seen.add(needleAngle(tester));
      }

      /// the first reading after a second weighs almost fully, the rest is smoothing
      expect(seen.last, closeTo(-20, .2));
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], lessThanOrEqualTo(seen[i - 1] + 1e-9));
      }
      expect(seen, everyElement(greaterThanOrEqualTo(-20.2)));
      await unmount(tester);
    });

    testWidgets('the approach haptic fires once on the way in', (tester) async {
      await pumpQibla(tester, londonWith(tester));
      await face(tester, 99);
      expect(haptics, isEmpty);
      await face(tester, 110);
      await face(tester, 107.5);
      await face(tester, 111);
      expect(haptics, [approach]);
      await unmount(tester);
    });

    testWidgets('the gear opens the location sheet, back pops the page', (tester) async {
      await pumpQibla(tester, await designOverrides());
      await tester.tap(find.bySemanticsLabel('Location'));
      await tester.pumpAndSettle();
      expect(find.byType(LocationSheet), findsOneWidget);
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();
      expect(find.byType(LocationSheet), findsNothing);

      await tester.tap(find.byType(BarBackButton));
      await tester.pumpAndSettle();
      expect(find.byType(QiblaPage), findsNothing);
      await unmount(tester);
    });

    testWidgets('screen readers hear the dial as one node, and every action is 44 x 44', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpQibla(tester, await designOverrides());
      expect(
        tester.getSemantics(find.byType(QiblaDial)),
        isSemantics(
          label: 'Qibla compass',
          value: 'Turn 14° right, 119°, 4,790 km, compass accuracy High',
        ),
      );
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      semantics.dispose();
      await unmount(tester);
    });
  });

  group('aligned (4.06)', () {
    testWidgets('a tap on the dial aligns after 400 ms, once, and back', (tester) async {
      await pumpQibla(tester, await designOverrides());
      await tester.tap(find.byType(QiblaDial));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 399));
      expect(find.text('Facing the Qibla'), findsNothing);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Facing the Qibla'), findsOneWidget);
      expect(find.text('Hold steady'), findsOneWidget);
      expect(
        tester.widget<RegularText>(find.widgetWithText(RegularText, 'Facing the Qibla')).color,
        ThemeEnum.onAccentContainer,
      );
      final accent = colorOf(tester, ThemeEnum.accent);
      expect(ringColor(tester), accent);
      expect(topTickColor(tester), accent);
      expect(haptics, [approach, aligned]);
      expect(announcements, ['Facing the Qibla']);
      expect(pulsing(tester), isTrue);
      expect(find.byType(DecoratedBox).evaluate().where(inGlow), isNotEmpty);

      await tester.pump(const Duration(seconds: 3));
      expect(haptics, [approach, aligned]);
      expect(announcements, hasLength(1));

      await tester.tap(find.byType(QiblaDial));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Turn 14° right'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(ringColor(tester), colorOf(tester, ThemeEnum.outline));
      await unmount(tester);
    });

    testWidgets('with ui sounds on aligning plays the aligned sound once', (tester) async {
      final sounds = FakeSoundOutput();
      BmSounds.output = sounds;
      addTearDown(() => BmSounds.enabled = false);
      await pumpQibla(tester, await designOverrides());
      await dbOf(tester).updateSettings(const SettingsCompanion(uiSounds: Value(true)));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(QiblaDial));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump(const Duration(seconds: 3));
      expect(sounds.played, ['assets/audio/ui_aligned.m4a']);
      await unmount(tester);
    });

    testWidgets('inside 5° stays aligned, past it turns back', (tester) async {
      await pumpQibla(tester, londonWith(tester));
      await face(tester, 119);
      expect(find.text('Facing the Qibla'), findsOneWidget);
      await face(tester, 123.9);
      expect(find.text('Facing the Qibla'), findsOneWidget);
      await face(tester, 124.1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Turn 5° left'), findsOneWidget);
      expect(haptics, [aligned]);
      await unmount(tester);
    });

    testWidgets('reduce motion: colors only, the haptic still fires', (tester) async {
      await pumpQibla(tester, await designOverrides(), reduceMotion: true);
      await tester.tap(find.byType(QiblaDial));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(find.text('Facing the Qibla'), findsOneWidget);
      expect(ringColor(tester), colorOf(tester, ThemeEnum.accent));
      expect(pulsing(tester), isFalse);
      expect(find.byType(DecoratedBox).evaluate().where(inGlow), isEmpty);
      expect(haptics, [approach, aligned]);
      await tester.pumpAndSettle();
      await unmount(tester);
    });
  });

  group('accuracy', () {
    testWidgets('high, medium and low, the figure 8 at low', (tester) async {
      await pumpQibla(tester, londonWith(tester));
      await face(tester, 100);
      expect(find.text('High'), findsOneWidget);
      expect(dotColor(tester), ThemeEnum.success);
      final paints = DialPainter.paints;

      await face(tester, 100, accuracy: 25);
      expect(find.text('Medium'), findsOneWidget);
      expect(dotColor(tester), ThemeEnum.warning);

      await face(tester, 100, accuracy: 40);
      expect(find.text('Low'), findsOneWidget);
      expect(dotColor(tester), ThemeEnum.error);
      expect(find.text('Move your phone in a figure 8 to calibrate the compass.'), findsOneWidget);

      await face(tester, 100, accuracy: -1);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Move your phone in a figure 8 to calibrate the compass.'), findsOneWidget);

      await face(tester, 100);
      expect(find.text('High'), findsOneWidget);
      expect(find.text('Hold your phone flat, away from metal and magnets.'), findsOneWidget);
      expect(DialPainter.paints, paints);
      await unmount(tester);
    });
  });

  group('no compass, no location', () {
    testWidgets('no compass: a still dial, the needle at the bearing, no haptics', (tester) async {
      await pumpQibla(tester, londonWith(tester));
      compass.none();
      await tester.pumpAndSettle();

      expect(find.text('No compass on this phone'), findsOneWidget);
      expect(find.text('London · Qibla at 119° from north'), findsOneWidget);
      expect(find.text('4,790 km'), findsOneWidget);
      expect(find.text('Not available'), findsOneWidget);
      expect(accuracyDot(), findsNothing);
      expect(find.text('Turn the N on the dial to north to see the Qibla.'), findsOneWidget);
      expect(dialAngle(tester), 0);
      expect(needleAngle(tester), closeTo(118.99, .05));
      expect(painter(tester).bearing, closeTo(118.99, .05));

      await tester.pump(const Duration(seconds: 2));
      expect(dialAngle(tester), 0);
      expect(haptics, isEmpty);
      await unmount(tester);
    });

    testWidgets('no location: the dial turns, no marker or needle, the two ways in', (
      tester,
    ) async {
      await pumpQibla(tester, londonWith(tester, location: false));
      compass.send(100);
      await tester.pumpAndSettle();

      expect(find.text('No location yet'), findsOneWidget);
      expect(find.text('The Qibla needs your location or a city.'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.byType(LocationChoices), findsOneWidget);
      expect(dialAngle(tester), closeTo(-100, .01));
      expect(needleTurn(), findsNothing);
      expect(painter(tester).bearing, isNull);

      await tester.tap(find.text('Use my location'));
      await tester.pumpAndSettle();
      expect(tester.widget<LocationSheet>(find.byType(LocationSheet)).useMyLocation, isTrue);
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose a city instead'));
      await tester.pumpAndSettle();
      expect(tester.widget<LocationSheet>(find.byType(LocationSheet)).useMyLocation, isFalse);
      await unmount(tester);
    });

    testWidgets('a location saved while the page is open shows at once', (tester) async {
      final origin = tester.binding.clock.now();
      await pumpQibla(tester, [
        ...testOverrides(compass: compass),
        clockProvider.overrideWithValue(
          () => start.add(tester.binding.clock.now().difference(origin)),
        ),
      ]);
      await face(tester, 105);
      expect(find.text('No location yet'), findsOneWidget);

      await tester.runAsync(
        () => dbOf(tester).updateSettings(
          const SettingsCompanion(
            latitude: Value(51.5074),
            longitude: Value(-0.1278),
            placeName: Value('London'),
            placeNameAr: Value('لندن'),
            countryCode: Value('GB'),
            timeZone: Value('Europe/London'),
            locationMode: Value(LocationMode.manual),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('London · Qibla at 119° from north'), findsOneWidget);
      expect(find.text('4,790 km'), findsOneWidget);
      expect(needleTurn(), findsWidgets);
      expect(painter(tester).bearing, closeTo(118.99, .05));
      await unmount(tester);
    });
  });

  group('languages, text size, modes, tablets', () {
    testWidgets('arabic aligned', (tester) async {
      await pumpQibla(tester, await designOverrides(), locale: const Locale('ar'));
      await tester.tap(find.byType(QiblaDial));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('أنت تواجه القبلة'), findsOneWidget);
      expect(find.text('ثبّت هاتفك'), findsOneWidget);
      expect(announcements, ['أنت تواجه القبلة']);
      await tester.tap(find.byType(QiblaDial));
      await tester.pumpAndSettle();
      await unmount(tester);
    });

    for (final brightness in Brightness.values) {
      testWidgets('text scale 2.0 scrolls with nothing cut, $brightness', (tester) async {
        await pumpQibla(tester, await designOverrides(), textScale: 2, brightness: brightness);
        expect(tester.takeException(), isNull);
        expect(find.text('Turn 14° right'), findsOneWidget);
        await tester.dragUntilVisible(
          find.text('Hold your phone flat, away from metal and magnets.'),
          find.byType(SingleChildScrollView),
          const Offset(0, -200),
        );
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }

    testWidgets('a tablet gets the phone layout stretched to 480 pt, the dial scaled', (
      tester,
    ) async {
      await pumpQibla(tester, await designOverrides(), size: const Size(1024, 1366));
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(QiblaPage)).width, closeTo(480 * 1.3, .01));
      expect(tester.getSize(find.byType(QiblaDial)).width, closeTo(300 * 1.3, .01));
      await unmount(tester);
    });
  });
}
