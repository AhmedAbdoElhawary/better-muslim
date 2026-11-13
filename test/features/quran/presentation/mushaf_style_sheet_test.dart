import 'dart:async';
import 'dart:io';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/features/quran/data/mushaf_files.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

final _body = List.generate(4000, (i) => i % 251);

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  late Directory root;
  late StreamController<List<int>> chunks;

  setUp(() {
    root = Directory.systemTemp.createTempSync('styles');
    Directory('${root.path}/mushaf').createSync();
    chunks = StreamController();
  });

  tearDown(() => root.deleteSync(recursive: true));

  Future<List<Override>> overrides() => designOverrides(
    mushafFiles: mushafFilesProvider.overrideWith(
      (ref) => MushafFiles(
        root: () async => root,
        fetch: (_, {from = 0}) async => (length: _body.length, bytes: chunks.stream),
        exclude: (_) async {},
        sha256: (_) => '${sha256.convert(_body)}',
      ),
    ),
  );

  /// the file is written and hashed off the fake clock
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }

  /// the reader's Display, then its Mushaf row
  Future<void> openStyles(WidgetTester tester) async {
    await pumpHome(tester, await overrides(), settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Display'));
    await tester.pumpAndSettle();
    final row = find.widgetWithText(NavRow, 'Mushaf');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await settle(tester);
    await tester.pumpAndSettle();
  }

  AppSettings settingsOf(WidgetTester tester) => containerOf(tester).read(settingsProvider).value!;

  testWidgets('one row a style, the qcf ones with their size until they are on the phone', (
    tester,
  ) async {
    await openStyles(tester);
    for (final text in [
      'Madinah · Hafs',
      'Text',
      'Your font, on the 1421H lines',
      'Printed page',
      'Every word as the book prints it\nMadinah Mushaf, 1421H print',
      'Tajweed colors',
      'The printed page, color-coded by tajweed rule',
      'Old print',
      'Madinah Mushaf, 1405H print',
      '135 MB',
      '68 MB',
      '54 MB',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(settingsOf(tester).mushafStyle, MushafStyle.text);
    await unmount(tester);
  });

  testWidgets('a style not on the phone downloads in the sheet, then is picked', (tester) async {
    await openStyles(tester);
    await tester.tap(find.text('Old print'));
    await tester.pump();
    await settle(tester);
    expect(find.text('Cancel'), findsOneWidget);
    expect(settingsOf(tester).mushafStyle, MushafStyle.text, reason: 'kept until it is done');

    chunks.add(_body);
    unawaited(chunks.close());

    /// writing and hashing run on real io
    for (var i = 0; i < 20 && settingsOf(tester).mushafStyle == MushafStyle.text; i++) {
      await settle(tester);
    }
    await tester.pumpAndSettle();
    expect(settingsOf(tester).mushafStyle, MushafStyle.qcfV1);
    expect(find.text('54 MB'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
    expect(File('${root.path}/mushaf/qcf_v1.bin').readAsBytesSync(), _body);
    await unmount(tester);
  });

  testWidgets('deleting the picked style in Downloads goes back to Text', (tester) async {
    File('${root.path}/mushaf/qcf_v2.bin').writeAsBytesSync(_body);
    await pumpMore(tester, await overrides(), push: Routes.downloads);
    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.qcfV2)));
    await settle(tester);

    expect(find.text('Printed page'), findsOneWidget);
    expect(find.text('0.0 MB'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Delete',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('It downloads again when you pick it.'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await settle(tester);
    await tester.pumpAndSettle();

    expect(settingsOf(tester).mushafStyle, MushafStyle.text);
    expect(File('${root.path}/mushaf/qcf_v2.bin').existsSync(), isFalse);
    expect(find.text('No downloads yet'), findsOneWidget);
    await unmount(tester);
  });
}
