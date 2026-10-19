import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/more/view/licenses_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/more.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  late List<MethodCall> system;
  setUp(() => system = mockSystemChannel(version: '1.0.0 (12)'));

  Future<(int, int, int)> counts(WidgetTester tester) async {
    final db = dbOf(tester);
    return (await tester.runAsync(
      () async => (
        (await db.select(db.prayerLog).get()).length,
        (await db.select(db.qadaEntries).get()).length,
        (await db.select(db.savedDuas).get()).length,
      ),
    ))!;
  }

  group('reset prayer journey', () {
    testWidgets('cancel keeps the log', (tester) async {
      await pumpMore(tester, await designOverrides());
      final before = await counts(tester);
      await tapText(tester, 'Reset prayer journey');
      expect(find.text('Reset prayer journey?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(await counts(tester), before);
      await unmount(tester);
    });

    testWidgets('reset clears the log and qada only, and the toast with its undo', (tester) async {
      await pumpMore(tester, await designOverrides());
      final db = dbOf(tester);
      await tester.runAsync(() async {
        await db.saveDua('travel-1');
        await db.updateSettings(const SettingsCompanion(tasbihCount: Value(16)));
      });
      expect((await counts(tester)).$1, greaterThan(0));
      showToast(
        tester.element(find.text('Reset prayer journey')),
        StringsManager.prayerUnmarked,
        args: {'prayer': 'Asr'},
        onUndo: () {},
      );
      await tester.pump();

      await tapText(tester, 'Reset prayer journey');
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      expect(await counts(tester), (0, 0, 1));
      final settings = await settingsOf(tester);
      expect(settings.tasbihCount, 16);
      expect(settings.firstUse, DateTime(2026, 10, 1));
      expect(find.text('Undo'), findsNothing);
      await unmount(tester);
    });
  });

  group('about', () {
    testWidgets('the version shows and does nothing on tap', (tester) async {
      await pumpMore(tester, await designOverrides());
      await scrollTo(tester, 'Version');
      expect(find.text('1.0.0 (12)'), findsOneWidget);
      await tester.tap(find.text('Version'));
      await tester.pumpAndSettle();
      expect(find.text('Version'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('credits: each source with its use, license and link', (tester) async {
      await pumpMore(tester, await designOverrides());
      await tapText(tester, 'Credits');

      expect(find.text('GeoNames'), findsOneWidget);
      expect(find.text('Place names · CC BY 4.0'), findsOneWidget);
      for (final font in [
        'Marcellus',
        'Schibsted Grotesk',
        'Reem Kufi',
        'Noto Sans Arabic',
        'Amiri',
      ]) {
        expect(find.text(font), findsOneWidget, reason: font);
      }
      expect(find.text('Fonts · SIL OFL 1.1'), findsNWidgets(5));
      expect(find.text('Azkar and duas'), findsOneWidget);
      expect(find.text('Adhan recordings'), findsOneWidget);

      await tester.tap(find.text('GeoNames'));
      await tester.pumpAndSettle();
      expect(system.last.method, 'openUrl');
      expect(system.last.arguments, {'url': 'https://www.geonames.org'});
      await unmount(tester);
    });

    testWidgets('the licenses page lists packages and opens one', (tester) async {
      LicenseRegistry.addLicense(
        () => Stream.value(const LicenseEntryWithLineBreaks(['better_test_package'], 'The text.')),
      );
      await pumpMore(tester, await designOverrides());
      await tapText(tester, 'Credits');
      await tapText(tester, 'Open source licenses');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.byType(LicensesPage), findsOneWidget);

      await tapText(tester, 'better_test_package');
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(find.text('The text.'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('arabic', (tester) async {
      await pumpMore(tester, await designOverrides(), locale: const Locale('ar'));
      await tapText(tester, 'المصادر والشكر');
      expect(find.text('أسماء الأماكن · CC BY 4.0'), findsOneWidget);
      await unmount(tester);
    });
  });
}
