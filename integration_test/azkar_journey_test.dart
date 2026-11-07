import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/features/azkar/view/widgets/tasbih_counter.dart';
import 'package:better_muslim/features/duas/view/duas_page.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// milestone 8 on a real engine and a real router: home's row, a set, tasbih, duas
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  /// pumpAndSettle never ends on a real engine, home's sky keeps drawing
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// the content and the store answer on a real clock, so wait for what should show
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
  }

  /// a real phone can be shorter than the design, home's azkar row sits under the fold. centered,
  /// so more's compact bar never covers it
  Future<void> tap(WidgetTester tester, Finder finder, {int times = 1}) async {
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pump();
    for (var i = 0; i < times; i++) {
      await tester.tap(finder);
      await tester.pump(const Duration(milliseconds: 50));
    }
    await settle(tester);
  }

  testWidgets('home, the evening set, tasbih to set complete, duas, save', (tester) async {
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
    await waitFor(tester, find.text('After Asr · 0 of 20'));

    await tap(tester, find.text('Evening azkar'));
    await waitFor(tester, find.text('Evening azkar · 1 of 20'));

    /// card 1 is said once, the next tap moves on
    await tap(tester, find.text('Tap anywhere to count'), times: 2);
    await waitFor(tester, find.text('Evening azkar · 2 of 20'));

    await tap(tester, find.byType(BarBackButton));
    await waitFor(tester, find.text('After Asr · 1 of 20'));

    await tap(tester, find.text('Tasbih'));

    /// the count rolls digit by digit, so it's read off the counter, not one text
    await waitFor(tester, find.byWidgetPredicate((w) => w is TasbihCounter && w.count == 16));

    /// a set is 33, 33 and 34, each done dhikr hands over to the next one at 0
    for (final times in [17, 33, 34]) {
      await tap(tester, find.text('Tap anywhere to count'), times: times);
      if (times == 34) break;
      await waitFor(tester, find.byWidgetPredicate((w) => w is TasbihCounter && w.count == 0));
    }
    await waitFor(tester, find.text('Set complete'));

    await tap(tester, find.text('More'));
    await tap(tester, find.text('Duas'));
    await tester.enterText(find.byType(TextField), 'توكلت');
    await settle(tester);
    await waitFor(tester, find.byType(DuaCard));

    await tap(tester, find.descendant(of: find.byType(DuaCard), matching: find.text('Save')).first);
    expect(find.descendant(of: find.byType(DuaCard), matching: find.text('Saved')), findsWidgets);

    await tap(tester, find.byType(BarBackButton));
    expect(find.byType(DuasPage), findsNothing);
  });
}
