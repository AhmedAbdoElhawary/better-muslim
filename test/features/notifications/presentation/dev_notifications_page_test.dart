import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_page.dart';
import 'package:better_muslim/features/notifications/presentation/view/dev_notifications_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/notifications.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  setUp(muteAdhanChannel);

  Future<void> openMore(WidgetTester tester) async {
    containerOf(tester).read(routerProvider).go(Routes.more);
    await tester.pumpAndSettle();
  }

  bool hasDevRoute(WidgetTester tester) =>
      containerOf(tester)
          .read(routerProvider)
          .configuration
          .routes
          .whereType<GoRoute>()
          .any((route) => route.path == Routes.devNotifications);

  testWidgets('dev builds reach both buttons from more', (tester) async {
    await pumpHome(tester, testOverrides());
    await openMore(tester);

    await tapText(tester, 'Notifications (dev)');

    expect(find.byType(DevNotificationsPage), findsOneWidget);
    expect(find.text('Open adhan screen'), findsOneWidget);
    expect(find.text('Test notification in 1 min'), findsOneWidget);
    await unmount(tester);
  });

  for (final flavor in [Flavor.staging, Flavor.production]) {
    testWidgets('${flavor.name} has neither the row nor the route', (tester) async {
      await pumpHome(
        tester,
        testOverrides(
          flavor: FlavorConfig(
            flavor: flavor,
            appName: 'Better Muslim',
            apiBaseUrl: '',
            sentryDsn: '',
          ),
        ),
      );
      await openMore(tester);

      expect(find.text('Notifications (dev)'), findsNothing);
      expect(hasDevRoute(tester), isFalse);
      await unmount(tester);
    });
  }

  testWidgets('the design scenario opens 4.03 with its fixed progress and never schedules', (
    tester,
  ) async {
    await pumpHome(tester, await designOverrides());
    containerOf(tester).read(routerProvider).push(Routes.devNotifications);
    await tester.pumpAndSettle();
    expect(find.text('Test notification in 1 min'), findsNothing);

    await tester.tap(find.text('Open adhan screen'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(AdhanPage), findsOneWidget);
    for (final text in ['ADHAN · MAKKAH', 'Maghrib', '17:56', '0:42', '2:56']) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    await unmount(tester);
  });
}
