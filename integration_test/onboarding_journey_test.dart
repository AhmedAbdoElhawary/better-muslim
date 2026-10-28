import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// milestone 10 on a real engine and a real router: the replay from the dev page to home
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  /// pumpAndSettle never ends on a real engine, the welcome's sky keeps drawing
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// the store answers on a real clock, so wait for what should show
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
  }

  /// a real phone can be shorter than the design, centered so nothing covers it
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder.first), alignment: .5);
    await tester.pump();
    await tester.tap(finder.first);
    await settle(tester);
  }

  testWidgets('replay, the sun, a city, not now, iznik, home', (tester) async {
    /// the checks read english, whatever the phone's language
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    final db = await designScenarioStore();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          onboardingProvider.overrideWith(() => OnboardingNotifier(done: true)),
          flavorProvider.overrideWithValue(
            const FlavorConfig(
              flavor: Flavor.dev,
              appName: 'Better Muslim',
              apiBaseUrl: '',
              sentryDsn: '',
              scenario: 'design',
            ),
          ),
          ...designScenarioOverrides(),
        ],
        child: const App(),
      ),
    );
    await settle(tester);

    await tap(tester, find.text('More'));
    await tap(tester, find.text('Notifications (dev)'));
    await tap(tester, find.text('Replay onboarding'));

    /// the sun's own action, what a screen reader gives instead of the drag
    final semantics = tester.ensureSemantics();
    final sun = find.semantics.byLabel(RegExp('^Sun. Drag it up past the horizon'));
    await waitFor(tester, find.bySemanticsLabel(RegExp('^Sun. Drag it up past the horizon')));
    tester.semantics.tap(sun);
    semantics.dispose();

    /// the buttons are there from the start, they take taps once the welcome has built
    await waitFor(tester, find.text('Get started').hitTestable());
    await tap(tester, find.text('Get started'));

    await waitFor(tester, find.text('Choose a city instead'));
    await tap(tester, find.text('Choose a city instead'));
    await waitFor(tester, find.byType(LocationSheet));
    await tester.enterText(find.byType(TextField), 'makkah');
    await waitFor(tester, find.textContaining('Saudi Arabia'));
    await tap(tester, find.textContaining('Saudi Arabia'));
    expect((await db.select(db.settings).getSingle()).placeName, 'Makkah');

    /// the phone's own clock decides 24 or 12 hours
    await waitFor(tester, find.text('How should each prayer reach you?'));
    expect(find.textContaining(RegExp(r'^(17:56|5:56\sPM)$')), findsOneWidget);
    await tap(tester, find.text('Not now'));

    await waitFor(tester, find.text('Iznik'));
    await tap(tester, find.text('Iznik'));
    await tap(tester, find.text('Apply theme'));

    await waitFor(tester, find.byType(HomePage));
    final saved = await db.select(db.settings).getSingle();
    expect(saved.theme, BmThemeId.iznik);
    expect(saved.onboarded, isTrue);
    expect(saved.notificationsAsked, isFalse);
  });
}
