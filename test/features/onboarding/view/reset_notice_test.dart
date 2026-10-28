import 'dart:io';

import 'package:better_muslim/core/backup/backup_file.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/backup/pick_and_restore.dart';
import 'package:better_muslim/core/widgets/backup/restore_sheet.dart';
import 'package:better_muslim/features/onboarding/view/location_step_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/backup.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/onboarding.dart';
import '../../../helpers/phone_storage.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  late Directory phone;
  File? picked;
  var picks = 0;
  setUp(() {
    phone = usePhoneStorage();
    picked = null;
    picks = 0;
  });

  Future<void> open(WidgetTester tester, {bool reset = true}) async {
    await pumpWelcome(
      tester,
      overrides: [
        ...testOverrides(onboarded: false),
        backupPickerProvider.overrideWithValue(() async {
          picks++;
          return picked;
        }),
      ],
    );
    if (reset) {
      await containerOf(tester)
          .read(databaseProvider)
          .updateSettings(const SettingsCompanion(storeResetPending: Value(true)));
      await frames(tester, const Duration(milliseconds: 100));
    }
  }

  Future<void> begin(WidgetTester tester) async {
    await tester.tap(find.text('Swipe up to begin'));
    await frames(tester, const Duration(milliseconds: 2200));
  }

  bool pending(WidgetTester tester) =>
      containerOf(tester).read(settingsProvider).value!.storeResetPending;

  /// a tap whose work runs on drift's background store, started on the real clock
  Future<void> realTap(WidgetTester tester, Finder finder) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(const Duration(milliseconds: 2500));
    });
    await frames(tester, const Duration(milliseconds: 1200));
  }

  testWidgets('once the welcome has built: the notice with start fresh and restore', (
    tester,
  ) async {
    await open(tester);
    expect(find.text("Your saved data couldn't be opened"), findsNothing);
    await begin(tester);

    expect(find.text("Your saved data couldn't be opened"), findsOneWidget);
    expect(find.textContaining('The app started fresh on this phone.'), findsOneWidget);
    expect(find.text('Start fresh'), findsOneWidget);

    /// the welcome's button and the dialog's action, which isn't tinted as destructive
    expect(find.text('Restore from backup'), findsNWidgets(2));
    final action = tester.widget<DecoratedBox>(
      find
          .ancestor(of: find.text('Restore from backup').last, matching: find.byType(DecoratedBox))
          .first,
    );
    expect((action.decoration as BoxDecoration).color, isNull);
    await unmount(tester);
  });

  testWidgets('start fresh clears it, it never shows again', (tester) async {
    await open(tester);
    await begin(tester);
    await tester.tap(find.text('Start fresh'));
    await frames(tester, const Duration(milliseconds: 400));
    expect(find.text("Your saved data couldn't be opened"), findsNothing);
    expect(pending(tester), isFalse);

    await tester.binding.handlePopRoute();
    await frames(tester, const Duration(milliseconds: 1800));
    await begin(tester);
    expect(find.text("Your saved data couldn't be opened"), findsNothing);
    await unmount(tester);
  });

  testWidgets('restore from backup clears it first, then picks', (tester) async {
    await open(tester);
    await begin(tester);
    await tester.tap(find.text('Restore from backup').last);
    await frames(tester, const Duration(milliseconds: 400));
    expect(pending(tester), isFalse);
    expect(picks, 1);
    await unmount(tester);
  });

  testWidgets('no reset, no notice', (tester) async {
    await open(tester, reset: false);
    await begin(tester);
    expect(find.text("Your saved data couldn't be opened"), findsNothing);
    await unmount(tester);
  });

  testWidgets('restore on 4.10: no dialog, the steps follow with the backup', (tester) async {
    picked = await tester.runAsync(() async {
      final from = await seededStore();
      final file = await writeBackup(from, 'test1234', now: DateTime(2026, 10, 1));
      await from.close();
      return file.rename('${phone.path}/picked.bmbackup');
    });
    await open(tester, reset: false);
    await begin(tester);
    await tester.tap(find.text('Restore from backup'));
    await frames(tester, const Duration(milliseconds: 700));
    expect(find.byType(RestoreSheet), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'test1234');
    await tester.pump();
    await realTap(tester, find.text('Restore'));

    expect(find.text('Restore this backup?'), findsNothing);
    expect(find.byType(LocationStepPage), findsOneWidget);
    final settings = containerOf(tester).read(settingsProvider).value!;
    expect((settings.placeName, settings.dhuhrSound), ('Makkah', PrayerSound.silent));
    expect(settings.onboarded, isFalse);
    await unmount(tester);
  });
}
