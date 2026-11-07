import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/continue_card.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// milestone 7a on a real engine: the tab, the reader, a bookmark and a note that outlive the app
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  /// pumpAndSettle never ends on a real engine, the reader's loader and home's sky keep drawing
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// the assets and the store answer on a real clock, so wait for what should show
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 50 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets);
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder.first);
    await settle(tester);
  }

  Future<void> pumpApp(WidgetTester tester, AppDatabase db) async {
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
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(App)));

  testWidgets('continue reading, turn, bookmark and note an ayah, then reopen the app', (
    tester,
  ) async {
    /// the checks read english, whatever the phone's language
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final db = await designScenarioStore();
    addTearDown(db.close);
    await pumpApp(tester, db);

    await tap(tester, find.text('Quran'));
    await waitFor(tester, find.byType(ContinueCard));
    await tap(tester, find.byType(ContinueCard));
    await waitFor(tester, find.byType(ReaderPage));

    /// only al-fatiha's page ships its words, so the ayah is picked there
    final reader = find.byType(ReaderPage);
    if (tester.widget<ReaderPage>(reader).page != 1) {
      containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
      await settle(tester);
    }
    final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 5)) != null,
    );
    await tester.tapAt(page.localToGlobal(page.washBounds(const AyahKey(1, 5))!.center));
    await waitFor(tester, find.byType(AyahSheet));

    await tap(tester, find.text('Bookmark'));
    await waitFor(tester, find.text('Note'));
    await tap(tester, find.text('Note'));
    await tap(tester, find.text('Add note'));
    await tester.enterText(find.byType(TextField), 'Ask for help, then act.');
    await settle(tester);
    await tap(tester, find.text('Save'));
    await waitFor(tester, find.text('Ask for help, then act.'));

    await tap(
      tester,
      find.descendant(
        of: find.byType(AyahSheet),
        matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Close'),
      ),
    );

    /// the mushaf reads right to left, the next page is a drag to the right
    await tester.timedDrag(
      find.byType(PageTurner).last,
      const Offset(393 * .6, 0),
      const Duration(milliseconds: 600),
    );
    await settle(tester);
    expect(containerOf(tester).read(lastReadProvider).page, 2);

    /// killed: the tree goes, the encrypted file stays
    await tester.pumpWidget(const SizedBox.shrink());
    await settle(tester);
    await pumpApp(tester, db);

    final container = containerOf(tester);
    await waitFor(tester, find.text('Quran'));
    await tap(tester, find.text('Quran'));
    await waitFor(tester, find.byType(ContinueCard));
    expect(container.read(lastReadProvider).page, 2);
    expect(
      find.descendant(of: find.byType(ContinueCard), matching: find.textContaining('Al-Baqarah')),
      findsWidgets,
    );

    container.read(routerProvider).push(Routes.quranSaved);
    await waitFor(tester, find.text('Ask for help, then act.'));
    expect(container.read(ayahBookmarkProvider(const AyahKey(1, 5))), isNotNull);
    expect(container.read(noteProvider(const AyahKey(1, 5)))?.text, 'Ask for help, then act.');
  });
}
