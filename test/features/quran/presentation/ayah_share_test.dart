import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_share.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fonts.dart';
import '../../../helpers/widgets.dart';

void main() {
  setUpAll(loadAppFonts);

  late QuranAssets assets;

  /// a context with screen util and the language, the layout only measures
  Future<BuildContext> contextIn(WidgetTester tester, {String language = 'en'}) async {
    assets = (await tester.runAsync(QuranAssets.load))!;
    late BuildContext context;
    await pumpCoreWidget(
      tester,
      Builder(
        builder: (inside) {
          context = inside;
          return const SizedBox();
        },
      ),
      locale: Locale(language),
    );
    return context;
  }

  Future<AyahShare> share(
    WidgetTester tester,
    List<AyahKey> keys, {
    ShareTextSource source = ShareTextSource.none,
  }) async {
    final arabic = <AyahKey, String>{};
    final texts = <AyahKey, String>{};
    for (final key in keys) {
      arabic[key] = (await tester.runAsync(() => assets.ayahText(key)))!;
      final surah = (await tester.runAsync(() => assets.surahText(key.surah)))!;
      if (source == ShareTextSource.translation) texts[key] = surah.translation[key.ayah - 1];
      if (source == ShareTextSource.muyassar) texts[key] = surah.tafsir[key.ayah - 1];
    }
    return AyahShare(
      arabic: arabic,
      texts: texts,
      source: source,
      surahs: {for (final key in keys) key.surah: assets.surah(key.surah)},
    );
  }

  const kursi = [AyahKey(2, 255), AyahKey(2, 256), AyahKey(2, 257), AyahKey(3, 18)];

  testWidgets('ayahs in a row are one run, the footer groups them by surah', (tester) async {
    final context = await contextIn(tester);
    final ayahs = await share(tester, kursi.reversed.toList());
    expect(ayahs.keys, kursi, reason: 'mushaf order');
    expect(ayahs.runs, [kursi.sublist(0, 3), kursi.sublist(3)]);
    expect(ayahs.footer(context), "Al-Baqarah 255–257 · Aal-'Imran 18");
  });

  testWidgets('the arabic footer has the arabic names and eastern digits', (tester) async {
    final context = await contextIn(tester, language: 'ar');
    final ayahs = await share(tester, kursi);
    expect(ayahs.footer(context), '${assets.surah(2).ar} ٢٥٥–٢٥٧ · ${assets.surah(3).ar} ١٨');
  });

  testWidgets('a short ayah stays square at full size', (tester) async {
    final context = await contextIn(tester);
    final ayahs = await share(tester, [const AyahKey(1, 1)], source: ShareTextSource.translation);
    expect(ayahs.layout(context, const ShareOptions()), (
      size: ShareSize.square,
      scale: 1.0,
      fits: true,
      note: null,
    ));
  });

  testWidgets('it shrinks to the last step, then goes story unless a size was picked', (
    tester,
  ) async {
    final context = await contextIn(tester);
    final ayahs = await share(tester, [const AyahKey(2, 255)], source: ShareTextSource.translation);
    expect(ayahs.layout(context, const ShareOptions()), (
      size: ShareSize.story,
      scale: .7,
      fits: true,
      note: null,
    ));

    /// square kept, so the translation goes before the ayah gets smaller still
    final square = ayahs.layout(context, const ShareOptions(sizeLocked: true));
    expect((square.size, square.note), (ShareSize.square, 'Tafsir hidden for 1 ayah'));
    expect(square.scale, lessThan(SizeManager.shareFit.last));
  });

  testWidgets('past story the texts go from the last ayah back, with a note', (tester) async {
    final context = await contextIn(tester);
    final ayahs = await share(tester, [
      const AyahKey(2, 281),
      const AyahKey(2, 282),
    ], source: ShareTextSource.translation);
    final layout = ayahs.layout(context, const ShareOptions());
    expect(layout.size, ShareSize.story);
    expect(layout.note, isNotNull);
    expect(layout.note, startsWith('Tafsir hidden for'));
  });

  testWidgets('2:282 alone is accepted: tafsir hidden, story, smaller than the last step', (
    tester,
  ) async {
    final context = await contextIn(tester);
    final ayahs = await share(tester, [const AyahKey(2, 282)], source: ShareTextSource.muyassar);
    final layout = ayahs.layout(context, const ShareOptions());
    expect(layout.size, ShareSize.story);
    expect(layout.note, 'Tafsir hidden for 1 ayah');
    expect(layout.scale, lessThan(SizeManager.shareFit.last));
  });

  testWidgets('the ayah itself is never cut, it only gets smaller', (tester) async {
    final context = await contextIn(tester);
    final ayahs = await share(tester, [const AyahKey(2, 282)]);
    final layout = ayahs.layout(context, const ShareOptions());
    expect(layout.note, isNull);
    expect(layout.scale, lessThan(SizeManager.shareFit.last));
  });

  testWidgets('a long ayah next to 2:282 is refused, a short one is added', (tester) async {
    final context = await contextIn(tester);
    final long = await share(tester, [const AyahKey(2, 282), const AyahKey(2, 283)]);
    expect(AyahShare.canAdd(context, long.arabic), isFalse);
    final short = await share(tester, [const AyahKey(1, 1), const AyahKey(1, 2)]);
    expect(AyahShare.canAdd(context, short.arabic), isTrue);
  });
}
