import 'dart:io';

import 'package:better_muslim/core/backup/backup_file.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/widgets/backup/pick_and_restore.dart';
import 'package:better_muslim/core/widgets/backup/restore_sheet.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/backup.dart';
import '../../helpers/fonts.dart';
import '../../helpers/more.dart';
import '../../helpers/phone_storage.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  late Directory phone;
  late List<ShareParams> shared;
  late List<bool> sharedFileExisted;
  File? picked;
  var picks = 0;
  setUp(() {
    phone = usePhoneStorage();
    mockSystemChannel();
    shared = [];
    sharedFileExisted = [];
    picked = null;
    picks = 0;
  });

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double scale = 1,
  }) async => pumpMore(
    tester,
    <Override>[
      ...await designOverrides(),
      shareProvider.overrideWithValue((params) async {
        shared.add(params);
        sharedFileExisted.add(File(params.files!.single.path).existsSync());
      }),
      backupPickerProvider.overrideWithValue(() async {
        picks++;
        return picked;
      }),
    ],
    locale: locale,
    textScale: scale,
  );

  /// drift's background store and the files run on the real clock
  Future<void> work(WidgetTester tester, [int ms = 2500]) async {
    for (var i = 0; i < ms ~/ 250; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 250)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
  }

  /// a tap whose work runs on drift's background store: started on the real clock, or it never
  /// gets past the fake one
  Future<void> realTap(WidgetTester tester, Finder finder, [int ms = 2500]) async {
    await tester.runAsync(() async {
      await tester.tap(finder);
      await Future<void>.delayed(Duration(milliseconds: ms));
    });
    await tester.pumpAndSettle();
  }

  bool off(WidgetTester tester, String label) =>
      tester.widget<BmButton>(find.widgetWithText(BmButton, label)).busy;

  Future<File> backupFile(WidgetTester tester, {String password = 'test1234'}) async {
    final file = await tester.runAsync(() async {
      final from = await seededStore();
      final file = await writeBackup(from, password, now: DateTime(2026, 10, 1));
      await from.close();
      return file.rename('${phone.path}/picked.bmbackup');
    });
    return file!;
  }

  testWidgets('save is off until both match with 6, each line at its time, one file shared', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, 'Back up');
    expect(
      find.text("Keep this password safe. Without it the backup can't be opened."),
      findsOneWidget,
    );
    final fields = find.byType(TextField);

    await tester.enterText(fields.at(0), 'abc');
    await tester.pump();
    expect(find.text('Use at least 6 characters.'), findsNothing);
    await tester.enterText(fields.at(1), 'a');
    await tester.pump();
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(off(tester, 'Save backup'), isTrue);

    await tester.enterText(fields.at(0), 'test1234');
    await tester.enterText(fields.at(1), 'test12');
    await tester.pump();
    expect(find.text('Use at least 6 characters.'), findsNothing);
    expect(find.text("The passwords don't match."), findsNothing);
    await tester.enterText(fields.at(1), 'test1235');
    await tester.pump();
    expect(find.text("The passwords don't match."), findsOneWidget);
    expect(off(tester, 'Save backup'), isTrue);

    await tester.enterText(fields.at(1), 'test1234');
    await tester.pump();
    expect(off(tester, 'Save backup'), isFalse);
    await realTap(tester, find.text('Save backup'));

    expect(shared, hasLength(1));
    expect(shared.single.files!.single.path, endsWith('better-muslim-2026-10-15.bmbackup'));
    expect(sharedFileExisted.single, isTrue);
    expect(File(shared.single.files!.single.path).existsSync(), isFalse);
    expect(find.text('Save backup'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a file that is no backup says so at once, restore stays off', (tester) async {
    picked = File('${phone.path}/photo.jpg')..writeAsStringSync('not a backup at all');
    await open(tester);
    await tapText(tester, 'Restore from backup');
    await work(tester, 500);

    expect(find.byType(RestoreSheet), findsOneWidget);
    expect(find.text("This file isn't a Better Muslim backup."), findsOneWidget);
    expect(off(tester, 'Restore'), isTrue);
    await unmount(tester);
  });

  testWidgets('a wrong password says so and nothing changes', (tester) async {
    picked = await backupFile(tester);
    await open(tester);
    await tapText(tester, 'Restore from backup');
    await work(tester, 500);
    await tester.enterText(find.byType(TextField), 'wrong one');
    await tester.pump();
    await realTap(tester, find.text('Restore'));

    expect(find.text('Wrong password. Check it and try again.'), findsOneWidget);
    expect((await settingsOf(tester)).subhanallahCount, 16);
    await unmount(tester);
  });

  testWidgets('from more the dialog asks first: cancel changes nothing, restore restores', (
    tester,
  ) async {
    picked = await backupFile(tester);
    await open(tester);
    await tapText(tester, 'Restore from backup');
    await work(tester, 500);
    await tester.enterText(find.byType(TextField), 'test1234');
    await tester.pump();
    await realTap(tester, find.text('Restore'));

    expect(find.text('Restore this backup?'), findsOneWidget);
    await realTap(tester, find.text('Cancel'), 500);
    expect(find.byType(RestoreSheet), findsNothing);
    expect((await settingsOf(tester)).subhanallahCount, 16);

    await tapText(tester, 'Restore from backup');
    await work(tester, 500);
    await tester.enterText(find.byType(TextField), 'test1234');
    await tester.pump();
    await realTap(tester, find.text('Restore'));
    await realTap(tester, find.widgetWithText(GestureDetector, 'Restore').last);

    final settings = await settingsOf(tester);
    expect((settings.subhanallahCount, settings.placeName), (21, 'Makkah'));
    expect(find.text('Backup restored'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a cancelled picker opens nothing', (tester) async {
    await open(tester);
    await tapText(tester, 'Restore from backup');
    await work(tester, 250);
    expect(picks, 1);
    expect(find.byType(RestoreSheet), findsNothing);
    await unmount(tester);
  });

  for (final (name, locale, scale) in [
    ('arabic', const Locale('ar'), 1.0),
    ('text scale 2.0', const Locale('en'), 2.0),
  ]) {
    testWidgets('$name: both sheets fit', (tester) async {
      picked = File('${phone.path}/photo.jpg')..writeAsStringSync('nope');
      await open(tester, locale: locale, scale: scale);
      await tapText(tester, locale.languageCode == 'ar' ? 'نسخ احتياطي' : 'Back up');
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(196, 30));
      await tester.pumpAndSettle();
      await tapText(
        tester,
        locale.languageCode == 'ar' ? 'استعادة من نسخة احتياطية' : 'Restore from backup',
      );
      await work(tester, 500);
      expect(tester.takeException(), isNull);
      expect(find.byType(RestoreSheet), findsOneWidget);
      await unmount(tester);
    });
  }
}
