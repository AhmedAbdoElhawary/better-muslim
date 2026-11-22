import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/prayer/presentation/view/prayer_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/fonts.dart';
import '../../helpers/home.dart';
import '../../helpers/notifications.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

/// what a tap on a widget or the live activity hands flutter (research R11)
void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  setUp(muteAdhanChannel);

  Future<void> open(WidgetTester tester, String link) async {
    await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
      SystemChannels.navigation.name,
      SystemChannels.navigation.codec.encodeMethodCall(
        MethodCall('pushRouteInformation', {'location': link, 'state': null}),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();
  }

  String path(WidgetTester tester) =>
      containerOf(tester).read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  testWidgets('a prayer cell opens the prayer tab on its day at its prayer', (tester) async {
    await pumpHome(tester, await designOverrides());

    await open(tester, 'bettermuslim://open/prayer?day=2026-10-15&prayer=maghrib');

    expect(path(tester), Routes.prayer);
    final page = tester.widget<PrayerPage>(find.byType(PrayerPage));
    expect(page.day, DateTime(2026, 10, 15));
    expect(page.prayer, Prayer.maghrib);
    await unmount(tester);
  });

  testWidgets('the rest of a surface opens home', (tester) async {
    await pumpHome(tester, await designOverrides());
    await open(tester, 'bettermuslim://open/prayer?day=2026-10-15&prayer=maghrib');

    await open(tester, 'bettermuslim://open/');

    expect(path(tester), Routes.home);
    await unmount(tester);
  });

  testWidgets('before onboarding ends both still go to onboarding', (tester) async {
    await pumpHome(tester, testOverrides(onboarded: false));

    await open(tester, 'bettermuslim://open/prayer?day=2026-10-15&prayer=maghrib');
    expect(path(tester), Routes.onboarding);

    await open(tester, 'bettermuslim://open/');
    expect(path(tester), Routes.onboarding);
    await unmount(tester);
  });
}
