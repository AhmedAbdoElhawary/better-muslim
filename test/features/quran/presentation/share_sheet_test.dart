import 'dart:async';
import 'dart:typed_data';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/widgets/share/share_frame.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_share.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/share_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  late List<ShareParams> shared;

  /// the reader at the ayah's page, its sheet open, then Share
  Future<void> openShare(WidgetTester tester, AyahKey ayah, int page) async {
    shared = [];
    await pumpHome(tester, [
      ...await designOverrides(),
      shareProvider.overrideWithValue((params) async => shared.add(params)),
    ], settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(page));
    await tester.pumpAndSettle();
    final mushaf = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
      (mushaf) => mushaf.washBounds(ayah) != null,
    );
    await tester.longPressAt(mushaf.localToGlobal(mushaf.washBounds(ayah)!.center));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    /// the sheet's Share starts choosing with the ayah checked, the bar makes the card
    await tester.tap(find.text('Share (1)'));
    await tester.pumpAndSettle();
  }

  AyahShare shareOf(WidgetTester tester) =>
      tester.widget<ShareSheet>(find.byType(ShareSheet)).content as AyahShare;

  Finder onCard(String text) =>
      find.descendant(of: find.byType(ShareFrame), matching: find.text(text));

  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the preview shows the ayah with its translation, the reference and the app', (
    tester,
  ) async {
    await openShare(tester, const AyahKey(1, 5), 1);

    expect(find.text('Share ayah'), findsOneWidget);
    final share = shareOf(tester);
    expect(share.keys, [const AyahKey(1, 5)]);
    expect(share.arabic.values.single, isNotEmpty);
    expect(share.source, ShareTextSource.translation);
    expect(share.texts.values.single, 'It is You we worship and You we ask for help.');
    expect(onCard('Al-Fatiha 5'), findsOneWidget);
    expect(onCard('Better Muslim'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the text row picks what goes under the ayah', (tester) async {
    await openShare(tester, const AyahKey(1, 5), 1);

    await tapInSheet(tester, find.text('Ayah only'));
    expect(shareOf(tester).source, ShareTextSource.none);
    expect(shareOf(tester).texts, isEmpty);
    await tapInSheet(tester, find.text('Al-Muyassar').last);
    expect(shareOf(tester).source, ShareTextSource.muyassar);
    expect(shareOf(tester).texts.values.single, isNotEmpty);
    await unmount(tester);
  });

  testWidgets('a tafsir not on the phone needs internet once, the card keeps its text', (
    tester,
  ) async {
    await openShare(tester, const AyahKey(1, 5), 1);

    /// the chip spins while it downloads, so this tap can't settle
    final chip = find.text('Ibn Kathir').last;
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    expect(find.text('Needs internet once'), findsOneWidget);
    expect(shareOf(tester).source, ShareTextSource.translation);
    await tester.pump(const Duration(seconds: 5));
    await unmount(tester);
  });

  testWidgets('al-baqarah 282 moves to story with its translation hidden', (tester) async {
    /// only the sheet matters here, so it opens straight from the reader
    await openShare(tester, const AyahKey(1, 5), 1);
    Navigator.of(tester.element(find.byType(ShareSheet))).pop();
    await tester.pumpAndSettle();
    unawaited(showAyahShare(tester.element(find.byType(ReaderPage)), [const AyahKey(2, 282)]));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();

    expect(tester.widget<ShareFrame>(find.byType(ShareFrame)).size, ShareSize.story);
    expect(find.text('Tafsir hidden for 1 ayah'), findsOneWidget);
    await unmount(tester);
  });

  for (final (label, height) in [(null, 1080), ('Portrait', 1350), ('Story', 1920)]) {
    testWidgets('share sends a 1080 x $height png', (tester) async {
      await openShare(tester, const AyahKey(1, 5), 1);
      if (label != null) await tapInSheet(tester, find.text(label));

      final button = find.text('Share').last;
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await tester.pump();

      expect(shared, hasLength(1));
      final [file] = shared.single.files!;
      expect(file.mimeType, 'image/png');
      final png = ByteData.sublistView(await tester.runAsync(file.readAsBytes) ?? Uint8List(0));
      expect((png.getUint32(16), png.getUint32(20)), (1080, height));
      await unmount(tester);
    });
  }
}
