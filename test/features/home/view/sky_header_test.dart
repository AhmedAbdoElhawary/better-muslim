import 'package:better_muslim/core/power/power_saving.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/theme_sky.dart';
import 'package:better_muslim/features/home/model/home_moment.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  SkyHeaderPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<SkyHeaderPainter>()
      .single;

  /// Color.lerp at 1 can be off in the last bit
  bool close(Color a, Color b) =>
      (a.r - b.r).abs() < 1e-6 && (a.g - b.g).abs() < 1e-6 && (a.b - b.b).abs() < 1e-6;
  bool same(BmSkyStops a, BmSkyStops b) =>
      close(a.top, b.top) && close(a.mid, b.mid) && close(a.bottom, b.bottom);

  /// the channel never answers under fake time, so tests that want the loop say what it is
  Override powerSaving(bool saving) => powerSavingProvider.overrideWith((ref) async => saving);

  testWidgets('16:32 has the asr sky with no stars, 21:00 the isha sky with stars and no sun', (
    tester,
  ) async {
    await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32)));
    expect(same(painter(tester).stops, themeSky(BmThemeId.qiyamEmerald)[BmSkyState.asr]!), isTrue);
    expect(painter(tester).starsStrength, 0);
    expect(painter(tester).points!.kind, ArcKind.day);
    expect(painter(tester).markerShare, isNotNull);
    await unmount(tester);

    await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 18)));
    expect(same(painter(tester).stops, themeSky(BmThemeId.qiyamEmerald)[BmSkyState.isha]!), isTrue);
    expect(painter(tester).starsStrength, 1);
    expect(painter(tester).points!.kind, ArcKind.night);
    await unmount(tester);
  });

  testWidgets('another theme paints its own sky for the state', (tester) async {
    await pumpHome(
      tester,
      makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32), theme: BmThemeId.andalus),
    );
    expect(same(painter(tester).stops, themeSky(BmThemeId.andalus)[BmSkyState.asr]!), isTrue);
    await unmount(tester);
  });

  for (final (reduceMotion, change) in [
    (false, const Duration(milliseconds: 1800)),
    (true, const Duration(milliseconds: 300)),
  ]) {
    testWidgets('maghrib changes the sky over ${change.inMilliseconds} ms '
        '(reduce motion ${reduceMotion ? 'on' : 'off'})', (tester) async {
      await pumpHome(
        tester,
        makkahAt(tester, DateTime.utc(2026, 10, 15, 14, 55, 59)),
        reduceMotion: reduceMotion,

        /// the glow breathes this close to maghrib, settling would run past it
        settle: false,
      );
      await tester.pump();
      final asr = themeSky(BmThemeId.qiyamEmerald)[BmSkyState.asr]!;
      final maghrib = themeSky(BmThemeId.qiyamEmerald)[BmSkyState.maghrib]!;
      expect(same(painter(tester).stops, asr), isTrue);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(change ~/ 2);
      final halfway = painter(tester).stops;
      expect(same(halfway, asr) || same(halfway, maghrib), isFalse);

      await tester.pump(change ~/ 2);
      expect(same(painter(tester).stops, maghrib), isTrue);
      expect(painter(tester).starsStrength, 1);
      await unmount(tester);
    });
  }

  group('the ambient loop', () {
    testWidgets('runs while home is visible', (tester) async {
      await pumpHome(
        tester,
        makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32), extra: [powerSaving(false)]),
        settle: false,
      );

      /// the power check answers after the first frame
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(painter(tester).elapsed, isNotNull);
      expect(tester.binding.transientCallbackCount, greaterThan(0));

      /// another tab: TickerMode turns it off
      await tester.tap(find.text('Prayer'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.binding.transientCallbackCount, 0);
      await unmount(tester);
    });

    testWidgets('stops with reduce motion', (tester) async {
      await pumpHome(
        tester,
        makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32), extra: [powerSaving(false)]),
        reduceMotion: true,
      );

      expect(painter(tester).elapsed, isNull);
      expect(tester.binding.transientCallbackCount, 0);
      await unmount(tester);
    });

    testWidgets('stops in low power mode or battery saver', (tester) async {
      await pumpHome(
        tester,
        makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32), extra: [powerSaving(true)]),
      );

      expect(painter(tester).elapsed, isNull);
      expect(tester.binding.transientCallbackCount, 0);
      await unmount(tester);
    });
  });

  testWidgets('the design scenario paints the theme base sky (FR-013)', (tester) async {
    await pumpHome(tester, await designOverrides());
    final dark = bmThemes[BmThemeId.qiyamEmerald]!.dark;

    expect(same(painter(tester).stops, BmSkyStops(dark.sky1, dark.sky2, dark.sky3)), isTrue);
    expect(painter(tester).starsStrength, 1);
    await unmount(tester);
  });

  group('the arc labels (US9)', () {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      for (final scale in [1.0, 2.0]) {
        for (final (name, utc) in [
          ('16:32', DateTime.utc(2026, 10, 15, 13, 32)),
          ('23:00', DateTime.utc(2026, 10, 15, 20)),
        ]) {
          testWidgets('${locale.languageCode} at $scale at $name: none overlap, all inside', (
            tester,
          ) async {
            await pumpHome(tester, makkahAt(tester, utc), locale: locale, textScale: scale);
            final labels = skyLabels(tester);

            expect(labels, hasLength(name == '16:32' ? 4 : 5));
            for (final (i, label) in labels.indexed) {
              expect(label.rect.left, greaterThanOrEqualTo(14), reason: label.text);
              expect(label.rect.right, lessThanOrEqualTo(393 - 14), reason: label.text);
              expect(label.rect.top, greaterThanOrEqualTo(0), reason: label.text);
              for (final other in labels.skip(i + 1)) {
                expect(
                  label.rect.overlaps(other.rect),
                  isFalse,
                  reason: '${label.text} and ${other.text}',
                );
              }
            }

            /// the feet always keep their name, the middle ones only above 1.4
            expect(labels.first.short, isFalse);
            expect(labels.last.short, isFalse);
            if (scale > 1.4) {
              expect(labels.sublist(1, labels.length - 1).every((label) => label.short), isTrue);
            }
            await unmount(tester);
          });
        }
      }
    }

    testWidgets('the night shows its five names with their times', (tester) async {
      await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 20)));

      expect(
        [for (final label in skyLabels(tester)) label.text],
        ['Maghrib 17:56', 'Isha 19:26', 'Last third 01:18', 'Fajr 05:00', 'Sunrise 06:17'],
      );
      await unmount(tester);
    });

    testWidgets('arabic keeps sunrise at the left foot by day', (tester) async {
      await pumpHome(
        tester,
        makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32)),
        locale: const Locale('ar'),
      );
      final labels = skyLabels(tester);

      expect(labels.first.text, 'الشروق ٠٦:١٦');
      expect(labels.first.rect.left, lessThan(labels.last.rect.left));
      await unmount(tester);
    });
  });

  group('day turns into night (US10)', () {
    for (final (reduceMotion, change) in [(false, BmMotion.skyChange), (true, BmMotion.standard)]) {
      testWidgets('maghrib turns the arc over ${change.inMilliseconds} ms '
          '(reduce motion ${reduceMotion ? 'on' : 'off'})', (tester) async {
        await pumpHome(
          tester,
          makkahAt(tester, DateTime.utc(2026, 10, 15, 14, 55, 59)),
          reduceMotion: reduceMotion,
          settle: false,
        );
        await tester.pump();
        expect(painter(tester).points!.kind, ArcKind.day);
        expect(painter(tester).turn, 1);

        /// the frame maghrib comes still shows the day arc where it was
        await tester.pump(const Duration(seconds: 1));
        expect(painter(tester).points!.kind, ArcKind.night);
        expect(painter(tester).outgoing!.kind, ArcKind.day);
        expect(painter(tester).turn, 0);
        expect(painter(tester).wheel, !reduceMotion);

        await tester.pump(change ~/ 2);
        expect(painter(tester).turn, inExclusiveRange(0, 1));

        await tester.pump(change ~/ 2);
        expect(painter(tester).turn, 1);
        await unmount(tester);
      });
    }

    testWidgets('home offscreen at maghrib comes back to the night arc with no turn', (
      tester,
    ) async {
      await pumpHome(
        tester,
        makkahAt(tester, DateTime.utc(2026, 10, 15, 14, 55, 30)),
        settle: false,
      );
      await tester.pump();
      await tester.tap(find.text('Prayer'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 30));
      await tester.pump();

      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(painter(tester).points!.kind, ArcKind.night);
      expect(painter(tester).turn, 1);
      await unmount(tester);
    });

    SkyHeaderPainter still(ArcKind kind, ValueNotifier<Duration>? elapsed) {
      final zone = tz.getLocation('Asia/Riyadh');
      final start = tz.TZDateTime(zone, 2026, 10, 15, 6);
      final end = tz.TZDateTime(zone, 2026, 10, 15, 18);
      return SkyHeaderPainter(
        stops: themeSky(BmThemeId.qiyamEmerald)[BmSkyState.asr]!,
        starsStrength: 0,
        points: ArcPoints(
          kind: kind,
          start: start,
          end: end,
          points: [(name: 'a', time: start, share: 0), (name: 'b', time: end, share: 1)],
        ),
        markerShare: .5,
        onSky: const Color(0xFFFFFFFF),
        sun: const Color(0xFFFFD27A),
        starOpacity: 1,
        unit: 1,
        horizonAboveBottom: 80,
        elapsed: elapsed,
      );
    }

    List<RecordedInvocation> drawn(SkyHeaderPainter painter, Symbol call) {
      final canvas = TestRecordingCanvas();
      painter.paint(canvas, const Size(393, 380));
      return canvas.invocations.where((i) => i.invocation.memberName == call).toList();
    }

    test('the sun has twelve rays only while the loop runs', () {
      final lines = drawn(still(ArcKind.day, null), #drawLine).length;

      expect(
        drawn(still(ArcKind.day, ValueNotifier(const Duration(seconds: 2))), #drawLine),
        hasLength(lines + 12),
      );
    });

    test('the night stars twinkle only while the loop runs', () {
      List<double> alphas(ValueNotifier<Duration>? elapsed) => [
        for (final call in drawn(still(ArcKind.night, elapsed), #drawPath))
          (call.invocation.positionalArguments[1] as Paint).color.a,
      ];

      expect(alphas(null), [1.0, 1.0, 1.0]);
      final a = alphas(ValueNotifier(const Duration(milliseconds: 1000)));
      final b = alphas(ValueNotifier(const Duration(milliseconds: 1900)));
      expect(a, hasLength(3));
      expect(a, isNot(b));
    });
  });
}
