import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
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
import '../../../helpers/surfaces.dart';

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
    expect(find.text('Rehearse a prayer: reminder in 30 s, prayer in 90 s'), findsOneWidget);
    expect(find.text('Test adhan in 1 min'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('refresh widgets writes the surfaces past the equal check', (tester) async {
    await pumpHome(tester, testOverrides());
    containerOf(tester).read(routerProvider).push(Routes.devNotifications);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Refresh widgets'));

    /// the store answers on the real event loop, its streams on the test's fake clock
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
    }

    final channel = containerOf(tester).read(surfacesChannelProvider) as FakeSurfacesChannel;
    expect(channel.updates.single.force, isTrue);
    await unmount(tester);
  });

  for (final flavor in [Flavor.staging, Flavor.production]) {
    testWidgets('${flavor.name} has neither the row nor the route', (tester) async {
      await pumpHome(
        tester,
        testOverrides(
          flavor: FlavorConfig(flavor: flavor, appName: 'Better Muslim', sentryDsn: ''),
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
    expect(find.text('Test adhan in 1 min'), findsNothing);
    expect(find.text('Refresh widgets'), findsNothing);
    expect(find.text('Start countdown now'), findsNothing);

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
