import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/features/qibla/view/qibla_page.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_dial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

/// milestone 6 on a real engine and a real router: more, qibla, the design scenario's tap
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  /// pumpAndSettle never ends on a real engine, home's sky and the aligned glow keep drawing
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await settle(tester);
  }

  testWidgets('home, more, qibla, aligned, back', (tester) async {
    /// the checks read english, whatever the phone's language
    tester.platformDispatcher.localesTestValue = [const Locale('en')];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    final db = await designScenarioStore();
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
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
    await tap(tester, find.text('Qibla'));
    expect(find.text('Turn 14° right'), findsOneWidget);
    expect(find.text('4,790 km'), findsOneWidget);

    await tap(tester, find.byType(QiblaDial));
    expect(find.text('Facing the Qibla'), findsOneWidget);
    expect(find.text('Hold steady'), findsOneWidget);

    await tap(tester, find.byType(BarBackButton));
    expect(find.byType(QiblaPage), findsNothing);
  });
}
