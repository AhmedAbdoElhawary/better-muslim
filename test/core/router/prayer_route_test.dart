import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/prayer/presentation/providers/selected_day.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/fonts.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  test('a day and a prayer make the prayer link', () {
    expect(
      Routes.prayerAt(DateTime(2026, 10, 13), Prayer.isha),
      '/prayer?day=2026-10-13&prayer=isha',
    );
  });

  testWidgets('the link opens tuesday with isha in view', (tester) async {
    await pumpPrayer(
      tester,
      await designOverrides(),
      location: Routes.prayerAt(DateTime(2026, 10, 13), Prayer.isha),
    );

    expect(containerOf(tester).read(shownDayProvider), DateTime(2026, 10, 13));
    expect(inRow(Prayer.isha, find.text('In qada')).hitTestable(), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('bad params fall back to the prayer day', (tester) async {
    await pumpPrayer(tester, await designOverrides(), location: '/prayer?day=13-10&prayer=noon');

    expect(containerOf(tester).read(selectedDayProvider), isNull);
    expect(containerOf(tester).read(shownDayProvider), DateTime(2026, 10, 15));
    await unmount(tester);
  });
}
