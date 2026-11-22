import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/widgets/day_dots.dart';
import 'package:better_muslim/features/prayer/presentation/view/qada_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_cell.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_complete.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/prayer_row.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/qada_row.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/summary_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// the main journey of milestone 4 on a real engine: the store's streams, the shell's toast and
/// real gestures, which widget tests only fake (R16)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  final tuesday = DateTime(2026, 10, 13);
  Finder row(Prayer prayer, String text) => find.descendant(
    of: find.byWidgetPredicate((widget) => widget is PrayerRow && widget.prayer == prayer),
    matching: find.text(text),
  );
  Finder cell(DateTime day) =>
      find.byWidgetPredicate((widget) => widget is DayCell && widget.day == day);

  /// pumpAndSettle never ends on a real engine, home's countdown and sky keep drawing
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('log asr, fix tuesday, make up a fajr', (tester) async {
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
    await tap(tester, find.text('Prayer'));

    await tap(tester, row(Prayer.asr, 'Mark'));
    expect(find.text('3 of 5 prayed today'), findsOneWidget);
    await tap(tester, row(Prayer.asr, 'Prayed'));
    expect(find.text('Asr unmarked'), findsOneWidget);
    await tap(tester, find.text('Undo'));
    expect(find.text('3 of 5 prayed today'), findsOneWidget);

    await tap(tester, cell(tuesday));
    await tap(tester, row(Prayer.isha, 'In qada'));
    await tap(tester, row(Prayer.isha, 'Add to qada'));
    await tap(tester, find.text('I prayed it'));
    expect(row(Prayer.isha, 'Prayed'), findsOneWidget);
    expect(
      tester
          .widget<DayDots>(find.descendant(of: cell(tuesday), matching: find.byType(DayDots)))
          .prayed,
      hasLength(5),
    );

    /// tuesday's fifth, any tap dismisses it
    expect(find.byType(DayComplete), findsOneWidget);
    await tap(tester, find.byType(DayComplete));
    expect(find.byType(DayComplete), findsNothing);

    await tap(tester, find.byType(SummaryCard));
    expect(find.byType(QadaPage), findsOneWidget);
    final fajr = find.byWidgetPredicate(
      (widget) => widget is QadaRow && widget.prayer == Prayer.fajr,
    );
    await tap(tester, find.descendant(of: fajr, matching: find.text('Made one up')));
    expect(find.descendant(of: fajr, matching: find.text('1 left')), findsOneWidget);
    await tap(tester, find.text('Undo'));
    expect(find.descendant(of: fajr, matching: find.text('2 left')), findsOneWidget);
  });
}
