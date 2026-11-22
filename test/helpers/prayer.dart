import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/day_dots.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_cell.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/prayer_row.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'home.dart';

/// the app at 393 x 852 on the prayer tab, or at a deep link
Future<void> pumpPrayer(
  WidgetTester tester,
  List<Override> overrides, {
  String location = Routes.prayer,
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  bool use24 = true,
  bool reduceMotion = false,
}) async {
  await pumpHome(
    tester,
    overrides,
    locale: locale,
    brightness: brightness,
    textScale: textScale,
    use24: use24,
    reduceMotion: reduceMotion,
    settle: false,
  );
  await tester.pump();
  containerOf(tester).read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

ProviderContainer containerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(App)));

AppDatabase dbOf(WidgetTester tester) => containerOf(tester).read(databaseProvider);

Finder rowOf(Prayer prayer) =>
    find.byWidgetPredicate((widget) => widget is PrayerRow && widget.prayer == prayer);

Finder inRow(Prayer prayer, Finder matching) =>
    find.descendant(of: rowOf(prayer), matching: matching);

Finder cellOf(DateTime day) =>
    find.byWidgetPredicate((widget) => widget is DayCell && widget.day == day);

/// the logged prayers the strip shows for a day
Set<Prayer> dotsOf(WidgetTester tester, DateTime day) =>
    tester.widget<DayDots>(find.descendant(of: cellOf(day), matching: find.byType(DayDots))).prayed;
