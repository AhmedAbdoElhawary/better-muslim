import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/features/hijri_calendar/model/hijri_events.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// milestone 9 on a real engine and a real router: theme, light and dark, the calendar, reset
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  /// pumpAndSettle never ends on a real engine, home's sky keeps drawing
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

  /// a real phone can be shorter than the design, centered so the compact bar never covers it
  Future<void> tap(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder.first), alignment: .5);
    await tester.pump();
    await tester.tap(finder.first);
    await settle(tester);
  }

  testWidgets('theme, light and dark, the calendar to ramadan, reset prayer journey', (
    tester,
  ) async {
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
    await waitFor(tester, find.text('Qiyam Emerald'));

    await tap(tester, find.text('Theme'));
    await tap(tester, find.text('Iznik'));
    await tap(tester, find.text('Apply theme'));
    await waitFor(tester, find.text('Iznik'));
    expect((await db.select(db.settings).getSingle()).theme, BmThemeId.iznik);

    await tap(tester, find.text('Light and dark'));
    await tap(tester, find.text('Light'));
    await settle(tester);
    expect(Theme.of(tester.element(find.text('Light and dark'))).brightness, Brightness.light);
    expect((await db.select(db.settings).getSingle()).themeMode, BmThemeMode.light);

    await tap(tester, find.text('Hijri calendar'));
    await waitFor(tester, find.text('Jumada I 1448'));
    for (var i = 0; i < 4; i++) {
      await tap(tester, find.bySemanticsLabel('Next month'));
    }
    await waitFor(tester, find.text('Ramadan 1448'));
    final first = tester.widget<DayCell>(
      find.byWidgetPredicate((widget) => widget is DayCell && widget.hijriDay == '1'),
    );
    expect(first.look, DayLook.event);
    await tap(tester, find.byType(BarBackButton));

    await tap(tester, find.text('Reset prayer journey'));
    await tap(tester, find.text('Reset'));
    await settle(tester);
    expect(await db.select(db.prayerLog).get(), isEmpty);
    expect(await db.select(db.qadaEntries).get(), isEmpty);

    await tap(tester, find.text('Prayer'));
    await waitFor(tester, find.textContaining('0 of 5'));
  });
}
