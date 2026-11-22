import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/more/view/credits_page.dart';
import 'package:better_muslim/features/more/view/feedback_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/crash_reporter.dart';
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
    testWidgets('downloads, then reset prayer journey', (tester) async {
      await pumpMore(tester, await designOverrides());
      await scrollTo(tester, 'Reset prayer journey');
      final downloads = tester.getRect(find.text('Downloads')).top;
      final reset = tester.getRect(find.text('Reset prayer journey')).top;
      expect(downloads, lessThan(reset));
      expect(tester.getRect(find.text('YOUR DATA')).top, lessThan(downloads));
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
    testWidgets('the version, and credits with the four sources as text', (tester) async {
      mockSystemChannel();
      await pumpMore(tester, await designOverrides());
      await scrollTo(tester, 'Version');
      expect(find.text('1.0.0 (12)'), findsOneWidget);
      await tapText(tester, 'Credits');
      expect(find.byType(CreditsPage), findsOneWidget);
      expect(find.text('GeoNames'), findsOneWidget);
      expect(find.text('Place names · CC BY 4.0'), findsOneWidget);
      expect(find.text('King Fahd Glorious Quran Printing Complex'), findsOneWidget);
      expect(find.text('Tanzil'), findsOneWidget);
      expect(find.text('Quranic Arabic Corpus'), findsOneWidget);
      expect(find.text('Word roots · GNU GPL'), findsOneWidget);
      expect(find.text('Open source licenses'), findsNothing);
      await unmount(tester);
    });
  });

  group('feedback', () {
    late FakeCrashReporter reporter;
    setUp(() => CrashReporter.instance = reporter = FakeCrashReporter());
    tearDown(() => CrashReporter.instance = const DebugCrashReporter());

    testWidgets('send waits for text, a wrong email stops it, then it goes with the details', (
      tester,
    ) async {
      mockSystemChannel();
      await pumpMore(tester, await designOverrides());
      await tapText(tester, 'Send feedback');
      expect(find.byType(FeedbackPage), findsOneWidget);

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(reporter.feedback, isEmpty);

      final fields = find.byType(TextField);
      await tester.enterText(fields.first, '  The qibla is great  ');
      await tester.enterText(fields.last, 'me@example');
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(find.text("This email doesn't look right"), findsOneWidget);
      expect(reporter.feedback, isEmpty);

      await tester.enterText(fields.last, ' me@example.com ');
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      expect(reporter.feedback.single, (
        message: 'The qibla is great\n\nVersion 1.0.0 (12) · Google Pixel 8 · Android 16',
        email: 'me@example.com',
      ));
      expect(find.text('Sent, thank you'), findsOneWidget);
      expect(find.byType(FeedbackPage), findsNothing);
      hideToast();
      await unmount(tester);
    });

    testWidgets('the message stops at 1,000 and the email is left out when empty', (tester) async {
      mockSystemChannel();
      await pumpMore(tester, await designOverrides(), push: Routes.feedback);
      await tester.enterText(find.byType(TextField).first, 'a' * 1200);
      await tester.pump();
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();
      final sent = reporter.feedback.single;
      expect(sent.message.split('\n').first.length, 1000);
      expect(sent.email, isNull);
      hideToast();
      await unmount(tester);
    });
  });
}
