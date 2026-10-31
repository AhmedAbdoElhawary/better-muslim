import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/more.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

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

  group('your data', () {
    testWidgets('back up, restore from backup, then reset prayer journey', (tester) async {
      await pumpMore(tester, await designOverrides());
      await scrollTo(tester, 'Reset prayer journey');
      final backUp = tester.getRect(find.text('Back up')).top;
      final restore = tester.getRect(find.text('Restore from backup')).top;
      final reset = tester.getRect(find.text('Reset prayer journey')).top;
      expect(backUp, lessThan(restore));
      expect(restore, lessThan(reset));
      expect(tester.getRect(find.text('YOUR DATA')).top, lessThan(backUp));
      await unmount(tester);
    });

    testWidgets('back up opens its sheet', (tester) async {
      await pumpMore(tester, await designOverrides());
      await tapText(tester, 'Back up');
      expect(find.text('Save backup'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);
      await unmount(tester);
    });
  });

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
        await db.updateSettings(const SettingsCompanion(subhanallahCount: Value(16)));
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
      expect(settings.subhanallahCount, 16);
      expect(settings.firstUse, DateTime(2026, 10, 1));
      expect(find.text('Undo'), findsNothing);
      await unmount(tester);
    });
  });

  group('about', () {
    testWidgets('acknowledgements lists every credit, a tap opens its link, then the licenses', (
      tester,
    ) async {
      final system = mockSystemChannel();
      await pumpMore(tester, await designOverrides());
      await tapText(tester, 'Acknowledgements');
      expect(find.text('GeoNames'), findsOneWidget);
      expect(find.text('Place names · CC BY 4.0'), findsOneWidget);

      await tester.tap(find.text('GeoNames'));
      await tester.pumpAndSettle();
      expect(system.where((call) => call.method == 'openUrl').single.arguments, {
        'url': 'https://www.geonames.org',
      });

      await scrollTo(tester, 'Mishary Rashid Alafasy · Adhan and Fajr');
      expect(find.text('Adam Synagda'), findsNothing);
      expect(find.text('Adhan recordings'), findsOneWidget);
      await tapText(tester, 'Open source licenses');
      expect(find.byType(LicensePage), findsOneWidget);
      await unmount(tester);
    });
  });
}
