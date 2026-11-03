import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/prayer_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/providers.dart';

void main() {
  testWidgets('app starts on home', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(PrayerPage), findsNothing);
    await unmount(tester);
  });

  testWidgets('arabic shows the arabic strings', (tester) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('tapping a tab shows its page and hides the old one', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Prayer'));
    await tester.pumpAndSettle();

    expect(find.byType(PrayerPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);
    await unmount(tester);
  });

  testWidgets('the in-app reduce motion switch reaches every widget below the router (R4)', (
    tester,
  ) async {
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();
    bool disabled() => MediaQuery.disableAnimationsOf(tester.element(find.byType(HomePage)));

    expect(disabled(), isFalse);

    await ProviderScope.containerOf(tester.element(find.byType(HomePage)))
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(reduceMotion: Value(true)));
    await tester.pumpAndSettle();

    expect(disabled(), isTrue);
    await unmount(tester);
  });

  testWidgets('the text size multiplies the phone scale and keeps the 2.0 cap', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(ProviderScope(overrides: testOverrides(), child: const App()));
    await tester.pumpAndSettle();
    double scale() => MediaQuery.textScalerOf(tester.element(find.byType(HomePage))).scale(1);
    final db = ProviderScope.containerOf(tester.element(find.byType(HomePage)))
        .read(databaseProvider);

    expect(scale(), 1.5);

    await db.updateSettings(const SettingsCompanion(textSize: Value(TextSize.large)));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1.725, 0.001));

    await db.updateSettings(const SettingsCompanion(textSize: Value(TextSize.largest)));
    await tester.pumpAndSettle();
    expect(scale(), 2.0);
    await unmount(tester);
  });
}
