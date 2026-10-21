import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/azkar.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  late ({List<String> haptics, List<String> announcements}) phone;
  setUp(() => phone = recordPhone());

  final today = DateTime(2026, 10, 15);

  /// the azkar tab first, so counts can be written before the set opens
  Future<void> openEvening(
    WidgetTester tester, {
    Map<String, int> counts = const {},
    bool reduceMotion = false,
  }) async {
    await pumpAzkar(tester, [...await designOverrides(), shortAzkar()], reduceMotion: reduceMotion);
    for (final MapEntry(:key, :value) in counts.entries) {
      await dbOf(tester).setZikrCount(AzkarSet.evening, today, key, value);
    }
    containerOf(tester).read(routerProvider).push(Routes.azkarSet(AzkarSet.evening));
    await tester.pumpAndSettle();
  }

  Future<void> tapCard(WidgetTester tester) async {
    await tester.tap(find.text('Tap anywhere to count'));
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh set opens at card 1, counts, and the tap after done moves on', (
    tester,
  ) async {
    await openEvening(tester);
    expect(find.text('Evening azkar · 1 of 3'), findsOneWidget);
    expect(find.text('0 / 1'), findsOneWidget);

    await tapCard(tester);
    expect(find.text('1 / 1'), findsOneWidget);
    expect(phone.haptics, [complete, complete]);

    await tapCard(tester);
    expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(phone.haptics, hasLength(2));

    await tapCard(tester);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(phone.haptics.last, bead);
    await unmount(tester);
  });

  testWidgets('opens at the first card not done', (tester) async {
    await openEvening(tester, counts: {'e1': 1});

    expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a swipe moves without counting', (tester) async {
    await openEvening(tester);
    await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(phone.haptics, isEmpty);
    await unmount(tester);
  });

  testWidgets('the last card done says set complete with one haptic, then taps do nothing', (
    tester,
  ) async {
    await openEvening(tester, counts: {'e1': 1, 'e2': 3});
    await tapCard(tester);

    expect(find.text('Set complete'), findsOneWidget);
    expect(phone.haptics, [complete, complete]);

    await tapCard(tester);
    expect(phone.haptics, hasLength(2));
    expect(find.text('1 / 1'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('leaving and opening again continues where I stopped (FR-009)', (tester) async {
    await openEvening(tester);
    await tapCard(tester);
    await tapCard(tester);
    await tapCard(tester);
    await tester.tap(find.byType(BarBackButton));
    await tester.pumpAndSettle();
    expect(find.text('After Asr · 1 of 3'), findsOneWidget);

    await tester.tap(find.text('Evening azkar'));
    await tester.pumpAndSettle();
    expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a verse keeps the quran font and doesn\'t move on a tap', (tester) async {
    await openEvening(tester, counts: {'e1': 1, 'e2': 3});
    final verse = find.text('قُلْ هُوَ اللَّهُ أَحَدٌ');
    final before = tester.getRect(verse);

    expect(
      tester.widget<RegularText>(find.ancestor(of: verse, matching: find.byType(RegularText))).font,
      FontEnum.quran,
    );
    await tapCard(tester);
    expect(tester.getRect(verse), before);
    await unmount(tester);
  });

  group('the move after a done card (FR-024)', () {
    Future<void> wait(WidgetTester tester, Duration time) async {
      await tester.pump(time);
      await tester.pumpAndSettle();
    }

    testWidgets('moves on by itself after the completion moment', (tester) async {
      await openEvening(tester);
      await tester.tap(find.text('Tap anywhere to count'));
      await tester.pump(BmMotion.completionPause - const Duration(milliseconds: 100));
      expect(find.text('Evening azkar · 1 of 3'), findsOneWidget);

      await wait(tester, const Duration(milliseconds: 100));
      expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a tap in the wait moves at once and counts nothing, nothing moves after', (
      tester,
    ) async {
      await openEvening(tester);
      await tapCard(tester);
      await tapCard(tester);
      expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);

      await wait(tester, BmMotion.completionPause);
      expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a swipe back in the wait cancels the move', (tester) async {
      await openEvening(tester, counts: {'e1': 1});
      for (var i = 0; i < 3; i++) {
        await tapCard(tester);
      }
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Evening azkar · 1 of 3'), findsOneWidget);

      await wait(tester, BmMotion.completionPause);
      expect(find.text('Evening azkar · 1 of 3'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a done card swiped back to moves on at the first tap', (tester) async {
      await openEvening(tester, counts: {'e1': 1});
      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Evening azkar · 1 of 3'), findsOneWidget);

      await tapCard(tester);
      expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the last card stays and shows complete', (tester) async {
      await openEvening(tester, counts: {'e1': 1, 'e2': 3});
      await tapCard(tester);
      await wait(tester, BmMotion.completionPause * 2);
      expect(find.text('Set complete'), findsOneWidget);
      expect(find.text('1 / 1'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('leaving in the wait throws nothing and moves nothing', (tester) async {
      await openEvening(tester);
      await tapCard(tester);
      await tester.tap(find.byType(BarBackButton));
      await tester.pumpAndSettle();
      await wait(tester, BmMotion.completionPause);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Evening azkar'));
      await tester.pumpAndSettle();
      expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
      expect(find.text('0 / 3'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('reduce motion jumps and fades in', (tester) async {
      await openEvening(tester, reduceMotion: true);
      await tapCard(tester);
      await tester.pump(BmMotion.completionPause);
      await tester.pump();
      expect(find.text('Evening azkar · 2 of 3'), findsOneWidget);
      await tester.pumpAndSettle();
      await unmount(tester);
    });
  });
}
