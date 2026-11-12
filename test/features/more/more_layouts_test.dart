import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/fonts.dart';
import '../../helpers/more.dart';
import '../../helpers/notifications.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });
  setUp(mockSystemChannel);

  const ways = [
    ('light', Brightness.light, false, Size(393, 852)),
    ('reduce motion', Brightness.dark, true, Size(393, 852)),
    ('a tablet', Brightness.dark, false, Size(800, 1280)),
  ];
  const pages = {
    'more': null,
    'theme': Routes.theme,
    'the hijri calendar': Routes.hijriCalendar,
    'adhan and reminders': Routes.adhanSettings,
    'acknowledgements': Routes.acknowledgements,
    'downloads': Routes.downloads,
  };

  for (final (way, brightness, reduceMotion, size) in ways) {
    for (final MapEntry(key: page, value: path) in pages.entries) {
      testWidgets('$page, $way: nothing cut, every target at least 44', (tester) async {
        await pumpMore(
          tester,
          [
            ...await designOverrides(),
            notificationSchedulerProvider.overrideWithValue(FakeScheduler()),
          ],
          push: path,
          brightness: brightness,
          reduceMotion: reduceMotion,
          size: size,
        );
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        if (size.width > 480) {
          expect(tester.getSize(find.byType(Scaffold).last).width, lessThan(size.width));
        }
        await unmount(tester);
      });
    }
  }
}
