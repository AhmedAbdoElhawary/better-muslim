import 'dart:io';

import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/quran/data/mushaf_files.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/more.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/quran.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('tajweed');
    Directory('${root.path}/mushaf').createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  Override files() => mushafFilesProvider.overrideWith(
    (ref) => MushafFiles(root: () async => root, exclude: (_) async {}),
  );

  Iterable<CustomPaint> lines(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .where((paint) => paint.painter.runtimeType.toString() == '_LinesPainter');

  testWidgets('without V4 on the phone it offers the download', (tester) async {
    await pumpMore(tester, await designOverrides(mushafFiles: files()), push: Routes.devTajweed);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    expect(find.text('Download QCF V4, 68 MB'), findsOneWidget);
    expect(lines(tester), isEmpty);
    await unmount(tester);
  });

  testWidgets(
    'with V4 on the phone it draws page 3 in the light, dark and sepia palettes',
    (tester) async {
      File('${root.path}/mushaf/qcf_v4.bin').writeAsBytesSync(packStyle('v4', {3}));
      await pumpMore(tester, await designOverrides(mushafFiles: files()), push: Routes.devTajweed);

      /// the fonts load off the fake clock
      for (var i = 0; i < 20 && lines(tester).length < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
      expect(lines(tester), hasLength(3));
      expect(find.text('Download QCF V4, 68 MB'), findsNothing);
      await unmount(tester);
    },

    /// no QCF fonts in tool/quran/.cache without a run of tool/quran/build_quran.dart
    skip: !File('${qcfFonts('v4')}/p3.ttf').existsSync(),
  );
}
