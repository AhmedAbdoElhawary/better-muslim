import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/monitoring/monitoring.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/crash_reporter.dart';
import '../../helpers/fonts.dart';
import '../../helpers/home.dart';
import '../../helpers/notifications.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

Iterable<GoRoute> _routesIn(List<RouteBase> routes) sync* {
  for (final route in routes) {
    if (route is GoRoute) yield route;
    yield* _routesIn(route.routes);
  }
}

void main() {
  late FakeCrashReporter reporter;

  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  setUp(() {
    muteAdhanChannel();
    CrashReporter.instance = reporter = FakeCrashReporter();
  });
  tearDown(Monitoring.debugReset);

  GoRouter routerOf(WidgetTester tester) => containerOf(tester).read(routerProvider);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('every route has its own fixed name with no id in it', (tester) async {
    await pumpHome(tester, await designOverrides());

    final names = _routesIn(routerOf(tester).configuration.routes).map((route) => route.name);

    expect(names, everyElement(matches(RegExp(r'^[a-z_]+$'))));
    expect(names.toSet(), hasLength(names.length));
    await unmount(tester);
  });

  testWidgets('a reader link leaves only the route name, not the page or the ayah', (tester) async {
    await pumpHome(tester, await designOverrides());
    reporter.breadcrumbs.clear();

    routerOf(tester).go(Routes.quranPage(5, ayah: const AyahKey(2, 255)));
    await settle(tester);

    expect(reporter.breadcrumbs, isNotEmpty);
    expect(reporter.breadcrumbs.toSet(), {'quran_reader'});
    await unmount(tester);
  });

  testWidgets('a tab switch leaves its name', (tester) async {
    await pumpHome(tester, await designOverrides());
    reporter.breadcrumbs.clear();

    tester.widget<StatefulNavigationShell>(find.byType(StatefulNavigationShell)).goBranch(4);
    await settle(tester);

    expect(reporter.breadcrumbs, contains('more'));
    await unmount(tester);
  });

  testWidgets('a link that matches nothing throws nothing', (tester) async {
    await pumpHome(tester, await designOverrides());
    reporter.breadcrumbs.clear();

    routerOf(tester).go('/nothing/here');
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(reporter.breadcrumbs, isEmpty);
    await unmount(tester);
  });
}
