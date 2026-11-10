import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'helpers/home.dart';
import 'helpers/providers.dart';

/// a screen at rest draws no frames, the constitution's principle III
void main() {
  setUpAll(tz.initializeTimeZones);

  /// 10:00:00.050 in makkah, more than an hour from any boundary
  final start = DateTime.utc(2026, 10, 15, 7, 0, 0, 50);

  Future<void> openTab(WidgetTester tester, String tab) async {
    await pumpHome(tester, makkahAt(tester, start));
    await tester.tap(find.descendant(of: find.byType(NavBar), matching: find.text(tab)));
    await tester.pumpAndSettle();
  }

  DateTime Function() clockOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(NavBar))).read(clockProvider);

  for (final tab in ['Quran', 'Azkar', 'More']) {
    testWidgets('$tab draws no frame over 2 minutes', (tester) async {
      await openTab(tester, tab);

      await tester.binding.delayed(const Duration(minutes: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
      await unmount(tester);
    });
  }

  /// the next row's "in h:mm"
  testWidgets('prayer draws only on the minute', (tester) async {
    await openTab(tester, 'Prayer');
    final clock = clockOf(tester);

    /// just past the next whole minute
    final now = clock();
    await tester.pump(Duration(seconds: 60 - now.second, milliseconds: 50 - now.millisecond));
    for (var minute = 0; minute < 3; minute++) {
      await tester.binding.delayed(const Duration(seconds: 59, milliseconds: 900));
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'between minutes, minute $minute');
      await tester.pump(const Duration(milliseconds: 100));
    }
    await unmount(tester);
  });

  /// reduce motion, so no sky event and no roll, only the digit that changed
  testWidgets('home draws only on the second', (tester) async {
    await pumpHome(tester, makkahAt(tester, start), reduceMotion: true);
    final clock = clockOf(tester);

    /// just past the next whole second
    await tester.pump(Duration(milliseconds: (1050 - clock().millisecond) % 1000));
    for (var second = 0; second < 120; second++) {
      await tester.binding.delayed(const Duration(milliseconds: 900));
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'between seconds, second $second');
      await tester.pump(const Duration(milliseconds: 100));
    }
    await unmount(tester);
  });
}
