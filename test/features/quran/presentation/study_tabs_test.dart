import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:better_muslim/features/quran/data/tafsir_files.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/tafsir_chip.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

final _body = gzip.encode(
  utf8.encode(
    jsonEncode({
      '1': [for (var ayah = 1; ayah <= 7; ayah++) 'ibn kathir on al-fatiha $ayah'],
    }),
  ),
);

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  late Directory root;
  late StreamController<List<int>> chunks;

  setUp(() {
    root = Directory.systemTemp.createTempSync('study');
    chunks = StreamController();
  });

  tearDown(() => root.deleteSync(recursive: true));

  /// the reader on al-fatiha 5 with its tafsir pane open
  Future<void> openTafsir(WidgetTester tester, {bool online = true}) async {
    await pumpHome(
      tester,
      await designOverrides(
        tafsirFiles: tafsirFilesProvider.overrideWith(
          (ref) => TafsirFiles(
            assets: () => ref.read(quranAssetsProvider.future),
            root: () async => root,
            fetch: (_, {from = 0}) async => online
                ? (length: _body.length, bytes: chunks.stream)
                : throw const SocketException('offline'),
            exclude: (_) async {},
            sha256: (_) => '${sha256.convert(_body)}',
          ),
        ),
      ),
      settle: false,
    );
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    await tester.pumpAndSettle();
    final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (page) => page.washBounds(const AyahKey(1, 5)) != null,
    );
    await tester.longPressAt(page.localToGlobal(page.washBounds(const AyahKey(1, 5))!.center));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AyahSheet), matching: find.text('Tafsir')));
    await tester.pumpAndSettle();
  }

  Finder inStudy(Finder matching) =>
      find.descendant(of: find.byType(StudySheet), matching: matching);

  Finder chip(String label) =>
      find.ancestor(of: inStudy(find.text(label)), matching: find.byType(TafsirChip));

  /// the file is written and hashed off the fake clock
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }

  testWidgets('the downloadable tafsirs carry a download mark, al-muyassar none', (tester) async {
    await openTafsir(tester);
    await settle(tester);
    Finder mark(String label) => find.descendant(
      of: chip(label),
      matching: find.byWidgetPredicate(
        (w) =>
            w is SvgPicture &&
            (w.bytesLoader as SvgAssetLoader).assetName == 'assets/icons/ui/download.svg',
      ),
    );
    expect(mark('Ibn Kathir'), findsOneWidget);
    expect(mark("As-Sa'di"), findsOneWidget);
    expect(mark('Al-Muyassar'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a tap downloads with progress, then shows its text', (tester) async {
    await openTafsir(tester);
    await tester.tap(chip('Ibn Kathir'));
    await tester.pump();
    await settle(tester);
    chunks.add(_body.sublist(0, _body.length ~/ 2));
    await settle(tester);
    expect(inStudy(find.text('Downloading')), findsOneWidget);
    expect(inStudy(find.byType(BmStarLoader)), findsWidgets);

    chunks.add(_body.sublist(_body.length ~/ 2));
    unawaited(chunks.close());

    /// writing, hashing and decoding run on real io, the oil drop never settles meanwhile
    for (
      var i = 0;
      i < 20 && inStudy(find.text('ibn kathir on al-fatiha 5')).evaluate().isEmpty;
      i++
    ) {
      await settle(tester);
    }
    expect(inStudy(find.text('Downloading')), findsNothing);
    expect(inStudy(find.text('ibn kathir on al-fatiha 5')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('offline shows the toast and stays on al-muyassar', (tester) async {
    await openTafsir(tester, online: false);
    await tester.tap(chip('Ibn Kathir'));
    for (var i = 0; i < 20 && find.text('Needs internet once').evaluate().isEmpty; i++) {
      await settle(tester);
    }
    expect(find.text('Needs internet once'), findsOneWidget);
    expect(inStudy(find.text('Downloading')), findsNothing);
    final muyassar = tester.widget<TafsirChip>(chip('Al-Muyassar'));
    expect(muyassar.selected, isTrue);
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });
}
