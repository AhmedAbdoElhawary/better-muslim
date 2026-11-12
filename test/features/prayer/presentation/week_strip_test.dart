import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/features/prayer/presentation/providers/selected_day.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  DateTime october(int day) => DateTime(2026, 10, day);

  /// the shown day's cell has the primaryContainer fill
  bool filled(WidgetTester tester, DateTime day) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: cellOf(day), matching: find.byType(DecoratedBox)).first,
    );
    return (box.decoration as BoxDecoration).color != null;
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// a full width swipe, positive goes to the earlier week in english
  Future<void> swipe(WidgetTester tester, double dx) async {
    await tester.drag(find.byType(PageView), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping tuesday shows its log, the card stays on today (FR-012, FR-014)', (
    tester,
  ) async {
    await pumpPrayer(tester, await designOverrides());

    await tapAndSettle(tester, cellOf(october(13)));
    expect(filled(tester, october(13)), isTrue);
    expect(filled(tester, october(15)), isFalse);
    for (final prayer in Prayer.values.take(4)) {
      expect(inRow(prayer, find.text('Prayed')), findsOneWidget, reason: prayer.name);
    }
    expect(inRow(Prayer.isha, find.text('In qada')), findsOneWidget);
    expect(find.text('2 of 5 prayed today'), findsOneWidget);

    /// today again follows the prayer day
    await tapAndSettle(tester, cellOf(october(15)));
    expect(containerOf(tester).read(selectedDayProvider), isNull);
    await unmount(tester);
  });

  testWidgets('a future day shows times only', (tester) async {
    await pumpPrayer(tester, await designOverrides());

    await tapAndSettle(tester, cellOf(october(17)));
    expect(filled(tester, october(17)), isTrue);
    for (final text in ['Mark', 'Prayed', 'Add to qada', 'In qada', 'NOW']) {
      expect(find.text(text), findsNothing, reason: text);
    }
    await unmount(tester);
  });

  testWidgets('swiping back stops at the week of first use, forward at this week (FR-013)', (
    tester,
  ) async {
    await pumpPrayer(tester, await designOverrides());

    await swipe(tester, -400);
    expect(cellOf(october(11)).hitTestable(), findsOneWidget);

    await swipe(tester, 400);
    expect(cellOf(october(4)).hitTestable(), findsOneWidget);
    await swipe(tester, 400);
    expect(cellOf(DateTime(2026, 9, 27)).hitTestable(), findsOneWidget);
    await swipe(tester, 400);
    expect(cellOf(DateTime(2026, 9, 27)).hitTestable(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('in arabic the earlier week comes from the right', (tester) async {
    await pumpPrayer(tester, await designOverrides(), locale: const Locale('ar'));

    await swipe(tester, -400);
    expect(cellOf(october(4)).hitTestable(), findsOneWidget);
    await unmount(tester);
  });

  /// 01:58 utc is 04:58 in makkah, fajr on the 16th is about 05:00
  testWidgets('with no day picked fajr moves the screen on, with one picked it stays', (
    tester,
  ) async {
    for (final picked in [false, true]) {
      await pumpPrayer(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 1, 58)));
      expect(containerOf(tester).read(shownDayProvider), october(14));
      if (picked) await tapAndSettle(tester, cellOf(october(13)));

      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(
        containerOf(tester).read(shownDayProvider),
        picked ? october(13) : october(15),
        reason: 'picked: $picked',
      );
      await unmount(tester);
    }
  });
}
