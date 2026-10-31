import 'dart:io';

import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/quran/data/recitation_files.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/more.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('downloads'));
  tearDown(() => root.deleteSync(recursive: true));

  /// al-ikhlas in al-husary's voice, 2 MB with its bismillah beside it
  void seed() {
    final folder = Directory('${root.path}/recitations/husary')..createSync(recursive: true);
    for (final name in ['001001', '112001', '112002', '112003', '112004']) {
      File('${folder.path}/$name.mp3').writeAsBytesSync(List.filled(500000, 7));
    }
  }

  Future<void> pumpDownloads(WidgetTester tester) async {
    await pumpMore(
      tester,
      await designOverrides(
        recitationFiles: recitationFilesProvider.overrideWithValue(
          RecitationFiles(root: () async => root, exclude: (_) async {}),
        ),
      ),
      push: Routes.downloads,
    );
  }

  testWidgets('empty until a surah is downloaded', (tester) async {
    await pumpDownloads(tester);
    expect(find.text('No downloads yet'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('lists a surah under its reciter with its size, delete asks and takes it', (
    tester,
  ) async {
    seed();
    await pumpDownloads(tester);

    expect(find.text('Al-Husary'), findsOneWidget);
    expect(find.text('Al-Ikhlas'), findsOneWidget);
    expect(find.text('2.0 MB'), findsOneWidget);
    expect(find.text('Al-Fatiha'), findsNothing, reason: 'only its first ayah is here');

    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == 'Delete',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delete this download?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(find.text('No downloads yet'), findsOneWidget);
    expect(File('${root.path}/recitations/husary/112001.mp3').existsSync(), isFalse);
    expect(File('${root.path}/recitations/husary/001001.mp3').existsSync(), isTrue);
    await unmount(tester);
  });
}
