import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_complete.dart';
import 'package:drift/drift.dart' show Value;
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/sounds.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  final thursday = DateTime(2026, 10, 15);

  /// 20:00 in makkah, isha is open
  Future<void> pumpIsha(
    WidgetTester tester, {
    required int logged,
    bool reduceMotion = false,
  }) async {
    await pumpPrayer(
      tester,
      makkahAt(tester, DateTime.utc(2026, 10, 15, 17)),
      reduceMotion: reduceMotion,
    );
    for (final prayer in Prayer.values.take(logged)) {
      await dbOf(tester).markPrayed(thursday, prayer);
    }
    await tester.pumpAndSettle();
  }

  Finder isha(String text) => inRow(Prayer.isha, find.text(text));

  /// lets Motion 08 run out, its fade ends 2.8 s in
  Future<void> finish(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  testWidgets('marking the fifth plays day complete once, then it goes', (tester) async {
    await pumpIsha(tester, logged: 4);

    await tester.tap(isha('Mark'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(DayComplete), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('All five prayed'), findsOneWidget);

    await finish(tester);
    expect(find.byType(DayComplete), findsNothing);
    await unmount(tester);
  });

  testWidgets('with ui sounds on the fifth mark plays the complete sound once', (tester) async {
    final sounds = FakeSoundOutput();
    BmSounds.output = sounds;
    addTearDown(() => BmSounds.enabled = false);
    await pumpIsha(tester, logged: 4);
    await dbOf(tester).updateSettings(const SettingsCompanion(uiSounds: Value(true)));
    await tester.pumpAndSettle();

    await tester.tap(isha('Mark'));
    await tester.pump();
    expect(sounds.played, ['assets/audio/ui_complete.m4a']);
    await finish(tester);
    await unmount(tester);
  });

  testWidgets('a day already complete never plays it', (tester) async {
    await pumpIsha(tester, logged: 5);

    expect(isha('Prayed'), findsOneWidget);
    expect(find.byType(DayComplete), findsNothing);
    await unmount(tester);
  });

  testWidgets('unmarking the fifth and marking it again plays it again', (tester) async {
    await pumpIsha(tester, logged: 5);

    await tester.tap(isha('Prayed'));
    await tester.pumpAndSettle();
    expect(find.byType(DayComplete), findsNothing);

    await tester.tap(isha('Mark'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(DayComplete), findsOneWidget);
    await finish(tester);
    await unmount(tester);
  });

  testWidgets('any tap dismisses it', (tester) async {
    await pumpIsha(tester, logged: 4);

    await tester.tap(isha('Mark'));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byType(DayComplete));
    await tester.pump();
    expect(find.byType(DayComplete), findsNothing);
    await unmount(tester);
  });

  /// the star fades in from 700 ms over 300 ms, without reduce motion it starts at 950 ms
  testWidgets('with reduce motion the star fades in over 300 ms', (tester) async {
    double starOpacity() => tester
        .widget<CustomOpacity>(
          find
              .ancestor(
                of: find.byWidgetPredicate(
                  (widget) =>
                      widget is CustomPaint &&
                      widget.painter.runtimeType.toString() == '_StarPainter',
                ),
                matching: find.byType(CustomOpacity),
              )
              .first,
        )
        .opacity;

    for (final reduceMotion in [true, false]) {
      await pumpIsha(tester, logged: 4, reduceMotion: reduceMotion);
      await tester.tap(isha('Mark'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 850));
      expect(starOpacity(), reduceMotion ? closeTo(.5, .05) : 0, reason: '$reduceMotion');
      await finish(tester);
      await unmount(tester);
    }
  });
}
