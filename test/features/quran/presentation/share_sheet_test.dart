import 'dart:async';
import 'dart:typed_data';

import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/share_card.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    await tester.tapAt(mushaf.localToGlobal(mushaf.washBounds(ayah)!.center));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();
  }

  ShareCard cardOf(WidgetTester tester) => tester.widget<ShareCard>(find.byType(ShareCard));

  Finder onCard(String text) =>
      find.descendant(of: find.byType(ShareCard), matching: find.text(text));

  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the preview shows the ayah, its marker, the reference and the app', (tester) async {
    await openShare(tester, const AyahKey(1, 5), 1);

    expect(find.text('Share ayah'), findsOneWidget);
    final card = cardOf(tester);
    expect(card.text.arabic, isNotEmpty);
    expect(card.text.marker, '﴿٥﴾');
    expect(card.text.translation, 'It is You we worship and You we ask for help.');
    expect(card.reference, 'Al-Fatiha · 5');
    expect(onCard('Al-Fatiha · 5'), findsOneWidget);
    expect(onCard('Better Muslim'), findsOneWidget);
    expect((card.background, card.size, card.scale), (ShareBackground.paper, ShareSize.square, 1));
    await unmount(tester);
  });

  testWidgets('backgrounds, size and the two switches change the preview', (tester) async {
    await openShare(tester, const AyahKey(1, 5), 1);

    for (final (label, background) in [
      ('Night', ShareBackground.night),
      ('Emerald', ShareBackground.emerald),
      ('Sky', ShareBackground.sky),
      ('Paper', ShareBackground.paper),
    ]) {
      await tapInSheet(tester, find.text(label));
      expect(cardOf(tester).background, background, reason: label);
    }

    await tapInSheet(tester, find.text('Story'));
    expect(cardOf(tester).size, ShareSize.story);
    await tapInSheet(tester, find.text('Square'));
    expect(cardOf(tester).size, ShareSize.square);

    await tapInSheet(tester, find.text('Include translation'));
    expect(cardOf(tester).text.translation, isNull);
    await tapInSheet(tester, find.text('Show app name'));
    expect(onCard('Better Muslim'), findsNothing);
    await unmount(tester);
  });

  testWidgets('al-baqarah 282 shrinks and moves to story, square muted', (tester) async {
    /// only page 1 ships laid out, so the sheet opens straight from the reader
    await openShare(tester, const AyahKey(1, 5), 1);
    Navigator.of(tester.element(find.byType(ShareCard))).pop();
    await tester.pumpAndSettle();
    unawaited(showShareSheet(tester.element(find.byType(ReaderPage)), const AyahKey(2, 282)));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pumpAndSettle();

    expect(cardOf(tester).size, ShareSize.story);
    expect(cardOf(tester).scale, lessThan(1));
    final segmented = tester.widget<Segmented<ShareSize>>(find.byType(Segmented<ShareSize>));
    expect(segmented.muted, {ShareSize.square});

    await tapInSheet(tester, find.text('Square'));
    expect(cardOf(tester).size, ShareSize.story, reason: 'square never crops it');
    await unmount(tester);
  });

  for (final (size, height) in [(ShareSize.square, 1080), (ShareSize.story, 1920)]) {
    testWidgets('share sends a 1080 x $height png', (tester) async {
      await openShare(tester, const AyahKey(1, 5), 1);
      if (size == ShareSize.story) await tapInSheet(tester, find.text('Story'));

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
