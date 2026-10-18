import 'package:better_muslim/core/power/power_saving.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

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
    expect(same(painter(tester).stops, bmSkyQiyamEmerald[BmSkyState.asr]!), isTrue);
    expect(painter(tester).starsStrength, 0);
    expect(painter(tester).sunFraction, isNotNull);
    await unmount(tester);

    await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 18)));
    expect(same(painter(tester).stops, bmSkyQiyamEmerald[BmSkyState.isha]!), isTrue);
    expect(painter(tester).starsStrength, 1);
    expect(painter(tester).sunFraction, isNull);
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
      final asr = bmSkyQiyamEmerald[BmSkyState.asr]!;
      final maghrib = bmSkyQiyamEmerald[BmSkyState.maghrib]!;
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
}
