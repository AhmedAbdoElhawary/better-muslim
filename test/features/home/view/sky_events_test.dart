import 'dart:math';
import 'dart:ui';

import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:better_muslim/features/home/view/widgets/countdown.dart';
import 'package:better_muslim/features/home/view/widgets/location_pill.dart';
import 'package:better_muslim/features/home/view/widgets/now_block.dart';
import 'package:better_muslim/features/home/view/widgets/sky_events.dart';
import 'package:better_muslim/features/home/view/widgets/sky_events_painter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  /// 21:00 in makkah, the night sky
  final night = DateTime.utc(2026, 10, 15, 18);

  final event = find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is SkyEventsPainter,
    skipOffstage: false,
  );

  /// past the longest gap, in steps so the frames of an event are pumped
  Future<void> wait(WidgetTester tester) async {
    for (var i = 0; i < 24; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  /// the same wait, stopping on the event, which is over long before the wait ends
  Future<void> waitForEvent(WidgetTester tester) async {
    for (var i = 0; i < 24 && event.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Finder tab(String name) => find.descendant(of: find.byType(NavBar), matching: find.text(name));

  test('every kind comes on any sky, the rock the least', () {
    final random = Random(1);
    for (final bright in [true, false]) {
      final kinds = [
        for (var i = 0; i < 1000; i++) SkyEvent.next(random, bright: bright, sunShare: .5).kind,
      ];
      expect(kinds.toSet(), SkyEventKind.values.toSet());
      final rocks = kinds.where((kind) => kind == SkyEventKind.rock).length;
      final bursts = kinds.where((kind) => kind == SkyEventKind.burst).length;
      expect(rocks, lessThan(bursts));
    }
  });

  test('a streak picks its own angle, length and speed', () {
    final random = Random(1);
    final streaks = [
      for (var i = 0; i < 400; i++) SkyEvent.next(random, bright: false, sunShare: .5),
    ].where((event) => event.kind.streak);
    expect(streaks.map((event) => event.fall).toSet().length, greaterThan(20));
    for (final streak in streaks) {
      expect(streak.fall, inInclusiveRange(.26, .87));
      expect(streak.reach, inInclusiveRange(.7, 1));
      final share = streak.duration.inMicroseconds / streak.kind.duration.inMicroseconds;
      expect(share, inInclusiveRange(.85, 1.15));
    }
  });

  test('a tap keeps the event on its spot, a burst lands near it', () {
    final random = Random(1);
    const tap = Offset(.4, .6);
    for (var i = 0; i < 400; i++) {
      final event = SkyEvent.next(random, bright: false, sunShare: .5, tap: tap);
      expect(event.tapped, isTrue);
      if (event.kind == SkyEventKind.burst) {
        expect((event.at.dx - tap.dx).abs(), lessThanOrEqualTo(.06));
        expect((event.at.dy - tap.dy).abs(), lessThanOrEqualTo(.075));
      } else {
        expect(event.at, tap);
      }
    }
  });

  test('every kind paints, by day and by night, on its own and tapped', () {
    final random = Random(1);
    final seen = <SkyEventKind>{};
    for (var i = 0; i < 200; i++) {
      final event = SkyEvent.next(
        random,
        bright: i.isEven,
        sunShare: i % 3 == 0 ? null : .5,
        tap: i % 5 == 0 ? const Offset(.5, .5) : null,
      );
      seen.add(event.kind);
      SkyEventsPainter(
        progress: const AlwaysStoppedAnimation(.5),
        event: event,
        onSky: const Color(0xFFFFFFFF),
        sun: const Color(0xFFFFCC00),
        strength: .6,
        unit: 1,
        horizonAboveBottom: 20,
        rtl: false,
      ).paint(Canvas(PictureRecorder()), const Size(393, 320));
    }
    expect(seen, SkyEventKind.values.toSet());
  });

  testWidgets('an event comes, ends, and leaves nothing running', (tester) async {
    await pumpHome(tester, makkahAt(tester, night));
    expect(event, findsNothing);

    await waitForEvent(tester);
    expect(event, findsOneWidget);

    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await unmount(tester);
  });

  testWidgets('a tap answers after a second, around the spot', (tester) async {
    await pumpHome(tester, makkahAt(tester, night));
    final sky = tester.getRect(find.byType(SkyEvents));
    final spot = sky.topLeft + Offset(sky.width * .3, sky.height * .6);

    await tester.tapAt(spot);
    await tester.pump(const Duration(milliseconds: 900));
    expect(event, findsNothing);

    await tester.pump(const Duration(milliseconds: 200));
    final painter = tester.widget<CustomPaint>(event).painter! as SkyEventsPainter;
    expect(painter.event.tapped, isTrue);
    expect(painter.event.at.dx, closeTo(.3, .06));
    expect(painter.event.at.dy, closeTo(.6, .075));

    await tester.pumpAndSettle();
    expect(event, findsNothing);
    await unmount(tester);
  });

  testWidgets('taps over the text count, the location pill keeps its own', (tester) async {
    await pumpHome(tester, makkahAt(tester, night));
    await tester.tapAt(tester.getCenter(find.byType(NowBlock)));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(event, findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LocationPill));
    await tester.pump(const Duration(milliseconds: 1100));
    expect(event, findsNothing);
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('at most 3 at once, the gap starts again after the last', (tester) async {
    await pumpHome(tester, makkahAt(tester, night));
    final sky = tester.getCenter(find.byType(SkyEvents));
    for (var i = 0; i < 5; i++) {
      await tester.tapAt(sky + Offset(i * 10, 0));
    }
    await tester.pump(const Duration(milliseconds: 1100));
    expect(event, findsNWidgets(3));

    await tester.pumpAndSettle();
    expect(event, findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(event, findsNothing);
    await waitForEvent(tester);
    expect(event, findsOneWidget);
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('a tap is dropped when the sky goes away before its second', (tester) async {
    await pumpHome(tester, makkahAt(tester, night));
    await tester.tapAt(tester.getCenter(find.byType(SkyEvents)));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(tab('Prayer'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(tab('Home'));
    await tester.pumpAndSettle();
    expect(event, findsNothing);
    await unmount(tester);
  });

  testWidgets('reduce motion and the design scenario have none, tapped or not', (tester) async {
    await pumpHome(tester, makkahAt(tester, night), reduceMotion: true);
    await tester.tapAt(tester.getCenter(find.byType(SkyEvents)));
    await wait(tester);
    expect(event, findsNothing);
    await unmount(tester);

    await pumpHome(tester, await designOverrides());
    await tester.tapAt(tester.getCenter(find.byType(SkyEvents)));
    await wait(tester);
    expect(event, findsNothing);
    await unmount(tester);
  });

  testWidgets('another tab pauses home, coming back goes on with the right time', (tester) async {
    await pumpHome(tester, makkahAt(tester, night));
    final digits = find.byType(Countdown, skipOffstage: false);
    String shown() => tester
        .widgetList<Text>(
          find.descendant(of: digits, matching: find.byType(Text), skipOffstage: false),
        )
        .map((text) => text.data)
        .join();

    await tester.tap(tab('Prayer'));
    await tester.pumpAndSettle();
    final before = shown();

    await wait(tester);
    expect(event, findsNothing);
    expect(shown(), before);

    await tester.tap(tab('Home'));
    await tester.pumpAndSettle();
    expect(shown(), isNot(before));

    await waitForEvent(tester);
    expect(event, findsOneWidget);
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('no icon on home takes a layer for its tint', (tester) async {
    await pumpHome(tester, makkahAt(tester, night));
    final icons = tester.widgetList<SvgPicture>(find.byType(SvgPicture));
    expect(icons, isNotEmpty);
    expect(icons.where((icon) => icon.colorFilter != null), isEmpty);
    await unmount(tester);
  });
}
