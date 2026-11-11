import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/quran/data/mushaf_files.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/translation_view.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart' show Color, Scrollable, TextPainter;
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/quran.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('qcf');
    Directory('${root.path}/mushaf').createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  Override files() => mushafFilesProvider.overrideWith(
    (ref) => MushafFiles(root: () async => root, exclude: (_) async {}),
  );

  /// the font is read and loaded off the fake clock
  Future<RenderMushafPage> waitFor(WidgetTester tester, String family) async {
    RenderMushafPage? page() => tester.allRenderObjects
        .whereType<RenderMushafPage>()
        .where((page) => page.glyphs?.family == family)
        .firstOrNull;
    for (var i = 0; i < 20 && page() == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    return page()!;
  }

  /// a phone reads a page over a platform channel, frames after a font already loaded is there
  final slowPages = mushafPageProvider.overrideWith((ref, n) async {
    final json = await (await ref.watch(quranAssetsProvider.future)).page(n);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return json == null ? null : MushafPage.fromJson(n, json);
  });

  /// a new style lays the pages beside the shown one out again, one a frame, each slow page 50 ms
  Future<void> settleNeighbours(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<RenderMushafPage> pumpPage(
    WidgetTester tester,
    int n, {
    MushafStyle style = MushafStyle.qcfV2,
    List<Override> overrides = const [],
  }) async {
    await pumpHome(tester, [
      ...await designOverrides(mushafFiles: files()),
      ...overrides,
    ], settle: false);
    await tester.pump();
    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(
          SettingsCompanion(mushafStyle: Value(style), pageColor: const Value(PageColor.paper)),
        );
    containerOf(tester).read(routerProvider).push(Routes.quranPage(n));
    return waitFor(tester, 'qcf_${style.name}_${n}_0');
  }

  testWidgets(
    'a page in QCF V2 lays out its glyphs in their lines, right to left',
    (tester) async {
      File('${root.path}/mushaf/qcf_v2.bin').writeAsBytesSync(packStyle('v2', {2, 3, 4}));
      final page = await pumpPage(tester, 3);
      expect(page.glyphs!.ink, MushafStyle.qcfV2.ink);
      expect(page.tajweed, isNull);

      final lines =
          (jsonDecode(File('assets/quran/pages/003.json').readAsStringSync()) as Map)['lines']
              as List;
      final bounds = {
        for (final line in lines.cast<Map>())
          for (final word in (line['w'] as List).cast<List>())
            AyahKey(word[0] as int, word[1] as int): null,
      }.keys.map((key) => (key, page.washBounds(key)!)).toList();

      /// each ayah sits below or beside the one before, never above
      for (var i = 1; i < bounds.length; i++) {
        expect(
          bounds[i].$2.top,
          greaterThanOrEqualTo(bounds[i - 1].$2.top - 1),
          reason: '${bounds[i].$1}',
        );
      }

      /// a line's first word is at its right end, its last at its left end
      for (final line in lines.cast<Map>()) {
        final words = (line['w'] as List).cast<List>();
        if (words.isEmpty) continue;
        final first = AyahKey(words.first[0] as int, words.first[1] as int);
        final last = AyahKey(words.last[0] as int, words.last[1] as int);
        final rect = page.washBounds(first)!;
        expect(page.washBounds(last)!.left, lessThanOrEqualTo(rect.right));
      }
      await unmount(tester);
    },

    /// no QCF fonts in tool/quran/.cache without a run of tool/quran/build_quran.dart
    skip: !File('${qcfFonts('v2')}/p3.ttf').existsSync(),
  );

  testWidgets('a V4 page loads again in the palette of its page color and keeps the font colors', (
    tester,
  ) async {
    File('${root.path}/mushaf/qcf_v4.bin').writeAsBytesSync(packStyle('v4', {2, 3, 4}));
    final page = await pumpPage(tester, 3, style: MushafStyle.qcfV4);
    expect(page.glyphs!.colored, isTrue);

    /// the key reads the font's palette off the fake clock, mudd lazim is its dark red
    for (var i = 0; i < 20 && page.tajweed == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(page.tajweed, hasLength(8));
    expect(page.tajweed!.first, (color: const Color(0xFFB50000), label: 'مد لازم ٦'));
    expect(page.tajweed!.last.label, 'قلقلة');
    for (final (color, palette) in [
      (PageColor.night, 1),
      (PageColor.sepia, 2),
      (PageColor.navy, 1),
    ]) {
      await containerOf(tester)
          .read(databaseProvider)
          .updateSettings(SettingsCompanion(pageColor: Value(color)));
      await waitFor(tester, 'qcf_qcfV4_3_$palette');
    }
    await unmount(tester);
  }, skip: !File('${qcfFonts('v4')}/p3.ttf').existsSync());

  testWidgets('the tajweed key grows with the mushaf size, its eight names in one size', (
    tester,
  ) async {
    File('${root.path}/mushaf/qcf_v4.bin').writeAsBytesSync(packStyle('v4', {2, 3, 4}));
    await pumpPage(tester, 3, style: MushafStyle.qcfV4);
    final sizes = <int, double>{};
    for (final step in [0, mushafSizeSteps.max, mushafSizeSteps.min]) {
      await containerOf(tester)
          .read(databaseProvider)
          .updateSettings(SettingsCompanion(mushafSize: Value(step)));
      await tester.pumpAndSettle();
      List<TextPainter>? labels() => tester.allRenderObjects
          .whereType<RenderMushafPage>()
          .map((page) => page.tajweedLabels)
          .nonNulls
          .firstOrNull;
      for (var i = 0; i < 20 && labels() == null; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pump();
      }
      final shown = labels()!;
      expect({for (final label in shown) label.text!.style!.fontSize}, hasLength(1));
      sizes[step] = shown.first.text!.style!.fontSize!;
    }
    expect(sizes[mushafSizeSteps.max], greaterThan(sizes[0]!));
    expect(sizes[mushafSizeSteps.min], lessThan(sizes[0]!));
    expect(sizes[mushafSizeSteps.max]! / sizes[0]!, lessThanOrEqualTo(1.25 + 1e-9));
    await unmount(tester);
  }, skip: !File('${qcfFonts('v4')}/p3.ttf').existsSync());

  testWidgets('a cell under QCF V2 draws its ayah in the page glyphs, the end marker last', (
    tester,
  ) async {
    File('${root.path}/mushaf/qcf_v2.bin').writeAsBytesSync(packStyle('v2', {2, 3, 4}));
    await pumpHome(tester, await designOverrides(mushafFiles: files()), settle: false);
    await tester.pump();
    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(
          const SettingsCompanion(
            mushafStyle: Value(MushafStyle.qcfV2),
            pageColor: Value(PageColor.paper),
            quranLayout: Value(QuranLayout.translation),
          ),
        );
    containerOf(tester).read(routerProvider).push(Routes.quranPage(3));
    await waitFor(tester, 'qcf_qcfV2_3_0');

    /// 2:6 opens page 3, its sahih line is under it
    final surah = jsonDecode(File('assets/quran/surahs/002.json').readAsStringSync()) as Map;
    final view = find.byType(TranslationView).first;
    await tester.scrollUntilVisible(
      find.descendant(of: view, matching: find.text((surah['tr'] as List)[5] as String)),
      200,
      scrollable: find.descendant(of: view, matching: find.byType(Scrollable)),
    );
    await tester.pumpAndSettle();

    final page = MushafPage.fromJson(
      3,
      jsonDecode(File('assets/quran/pages/003.json').readAsStringSync()) as Map<String, dynamic>,
    );
    final words = [
      for (final line in page.lines)
        for (final word in line.words)
          if (word.key == const AyahKey(2, 6) && word.glyph.isNotEmpty) word,
    ];
    expect(words.last.end, isTrue);
    final drawn = tester
        .widgetList<RegularText>(
          find.descendant(
            of: view,
            matching: find.byWidgetPredicate(
              (widget) => widget is RegularText && widget.family == 'qcf_qcfV2_3_0',
            ),
          ),
        )
        .map((text) => text.text)
        .toList();
    expect(drawn.take(words.length), words.map((word) => word.glyph));
    await unmount(tester);
  }, skip: !File('${qcfFonts('v2')}/p3.ttf').existsSync());

  testWidgets('QCF V2 picked but not on the phone draws the page as text', (tester) async {
    await pumpHome(tester, await designOverrides(mushafFiles: files()), settle: false);
    await tester.pump();
    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.qcfV2)));
    containerOf(tester).read(routerProvider).push(Routes.quranPage(3));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    final pages = tester.allRenderObjects.whereType<RenderMushafPage>().toList();
    expect(pages, isNotEmpty);
    expect(pages.every((page) => page.glyphs == null), isTrue);
    expect(pages.any((page) => page.washBounds(const AyahKey(2, 6)) != null), isTrue);
    await unmount(tester);
  });

  testWidgets('switching to QCF V1 and back keeps the page\'s first ayah on screen', (
    tester,
  ) async {
    await pumpHome(tester, await designOverrides(mushafFiles: files()), settle: false);
    await tester.pump();
    final db = containerOf(tester).read(databaseProvider);
    AppSettings settings() => containerOf(tester).read(settingsProvider).value!;
    containerOf(tester).read(routerProvider).push(Routes.quranPage(586));
    await tester.pumpAndSettle();

    /// 1421H 586 starts at 80:41, which is on 1405H 585. its turn saves last read
    await db.updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.qcfV1)));
    await tester.pumpAndSettle();
    expect((settings().lastReadSurah, settings().lastReadAyah), (80, 1));
    expect(settings().lastReadPage, 585, reason: 'kept as the 1421H page');
    expect(containerOf(tester).read(quranAssetsProvider).value!.folder, 'pages_v1');

    await db.updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.text)));
    await tester.pumpAndSettle();
    expect((settings().lastReadSurah, settings().lastReadAyah), (80, 1));
    expect(containerOf(tester).read(quranAssetsProvider).value!.folder, 'pages');
    await unmount(tester);
  });

  /// 1421H 120 has 5:77, 1405H 120 doesn't. a frame comes while the new print's page loads
  testWidgets(
    'switching between QCF V2 and V1 never lays one print\'s words out in the other\'s font',
    (tester) async {
      File('${root.path}/mushaf/qcf_v2.bin').writeAsBytesSync(packStyle('v2', {119, 120, 121}));
      File('${root.path}/mushaf/qcf_v1.bin').writeAsBytesSync(packStyle('v1', {119, 120, 121}));
      final first = await pumpPage(tester, 120, overrides: [slowPages]);
      expect(first.washBounds(const AyahKey(5, 77)), isNotNull);
      final db = containerOf(tester).read(databaseProvider);

      await db.updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.qcfV1)));
      await tester.pump();
      expect((await waitFor(tester, 'qcf_qcfV1_120_0')).washBounds(const AyahKey(5, 77)), isNull);

      /// the V2 font is loaded already, the 1421H page isn't
      await db.updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.qcfV2)));
      await tester.pump();
      expect(
        (await waitFor(tester, 'qcf_qcfV2_120_0')).washBounds(const AyahKey(5, 77)),
        isNotNull,
      );
      await settleNeighbours(tester);
      await unmount(tester);
    },
    skip:
        !File('${qcfFonts('v2')}/p120.ttf').existsSync() ||
        !File('${qcfFonts('v1')}/p120.ttf').existsSync(),
  );

  testWidgets('text after QCF V1 lays out the 1421H words', (tester) async {
    File('${root.path}/mushaf/qcf_v1.bin').writeAsBytesSync(packStyle('v1', {119, 120, 121}));
    await pumpPage(tester, 120, style: MushafStyle.qcfV1, overrides: [slowPages]);

    await containerOf(tester)
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(mushafStyle: Value(MushafStyle.text)));

    /// the new style reaches the page off the fake clock, before the slow page is there
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pumpAndSettle();
    final pages = tester.allRenderObjects.whereType<RenderMushafPage>().toList();
    expect(pages.every((page) => page.glyphs == null), isTrue);

    /// 120 starts at 5:71 in both prints, 1405H 121 has 5:77 too
    final shown = pages.where((page) => page.washBounds(const AyahKey(5, 71)) != null);
    expect(shown, isNotEmpty);
    expect(shown.every((page) => page.washBounds(const AyahKey(5, 77)) != null), isTrue);
    await settleNeighbours(tester);
    await unmount(tester);
  }, skip: !File('${qcfFonts('v1')}/p120.ttf').existsSync());
}
