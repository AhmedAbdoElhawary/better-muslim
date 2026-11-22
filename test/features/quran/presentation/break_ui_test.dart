import 'dart:async';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/ayah_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/share_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

/// the reader, the ayah sheet, saved and the index at their worst
void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(mockSystemChannel);

  const phone = Size(393, 852);
  const tablet = Size(820, 1180);
  final cases = [
    for (final locale in const [Locale('en'), Locale('ar')])
      for (final textScale in const [1.0, 2.0])
        for (final size in const [phone, tablet]) (locale, textScale, size),
  ];

  Future<void> pumpApp(WidgetTester tester, (Locale, double, Size) at) async {
    final (locale, textScale, size) = at;
    await pumpHome(
      tester,
      await designOverrides(),
      locale: locale,
      textScale: textScale,
      size: size,
      settle: false,
    );
    await tester.pump();
  }

  Future<void> open(WidgetTester tester, String route) async {
    containerOf(tester).read(routerProvider).push(route);
    await tester.pumpAndSettle();
  }

  String name((Locale, double, Size) at) => '${at.$1.languageCode} ${at.$2}x ${at.$3.width}';

  for (final at in cases) {
    testWidgets('the reader and the ayah sheet, ${name(at)}', (tester) async {
      await pumpApp(tester, at);
      await open(tester, Routes.quranPage(1));
      expect(tester.takeException(), isNull);

      final page = tester.allRenderObjects.whereType<RenderMushafPage>().firstWhere(
        (page) => page.washBounds(const AyahKey(1, 7)) != null,
      );
      await tester.longPressAt(page.localToGlobal(page.washBounds(const AyahKey(1, 7))!.center));
      await tester.pumpAndSettle();
      expect(find.byType(AyahSheet), findsOneWidget);
      expect(tester.takeException(), isNull);

      /// al-baqarah 282, the longest ayah, on a page whose words aren't shipped yet
      await open(tester, Routes.quranPage(48, ayah: const AyahKey(2, 282)));
      expect(tester.widget<ReaderPage>(find.byType(ReaderPage).last).page, 48);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    testWidgets('saved with 0 and 200 bookmarks, ${name(at)}', (tester) async {
      await pumpApp(tester, at);
      await open(tester, Routes.quranSaved);
      expect(tester.takeException(), isNull);

      final db = dbOf(tester);
      await tester.runAsync(
        () => db.batch(
          (batch) => batch.insertAll(db.quranBookmarks, [
            for (var i = 0; i < 200; i++)
              QuranBookmarksCompanion.insert(
                surah: const Value(2),
                ayah: Value(i % 286 + 1),
                page: 2 + i % 48,
                name: const Value('A bookmark with a long name that has to fit on one line'),
                category: AppDatabase.defaultCategory,
                createdAt: DateTime.utc(2026, 10, 1).add(Duration(hours: i)),
              ),
          ]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('A bookmark with a long name that has to fit on one line'), findsWidgets);
      await tester.fling(find.byType(Scrollable).last, const Offset(0, -3000), 3000);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });

    /// 282 alone, four ayahs over two surahs, and 22 short ayahs over four surahs for the longest
    /// footer under the title
    for (final keys in [
      [const AyahKey(2, 282)],
      [for (var ayah = 255; ayah <= 257; ayah++) AyahKey(2, ayah), const AyahKey(3, 18)],
      [
        for (var ayah = 1; ayah <= 7; ayah++) AyahKey(1, ayah),
        for (final (surah, count) in const [(112, 4), (113, 5), (114, 6)])
          for (var ayah = 1; ayah <= count; ayah++) AyahKey(surah, ayah),
      ],
    ]) {
      testWidgets('the share sheet with ${keys.length} ayahs from ${keys.first}, ${name(at)}', (
        tester,
      ) async {
        await pumpApp(tester, at);
        await open(tester, Routes.quranPage(1));
        unawaited(showAyahShare(tester.element(find.byType(ReaderPage)), keys));
        await tester.pump();
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
        await tester.pumpAndSettle();
        expect(find.byType(ShareSheet), findsOneWidget);
        expect(tester.takeException(), isNull);

        /// story and every font, then the share button at the bottom is still reachable
        for (final label in ['Story', 'Square']) {
          final finder = find.text(at.$1.languageCode == 'ar' ? _ar[label]! : label);
          await tester.ensureVisible(finder.last);
          await tester.pumpAndSettle();
          await tester.tap(finder.last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        final share = find.descendant(
          of: find.byType(ShareSheet),
          matching: find.text(at.$1.languageCode == 'ar' ? _ar['Share']! : 'Share'),
        );
        await tester.ensureVisible(share);
        await tester.pumpAndSettle();
        expect(tester.getRect(share).bottom, lessThanOrEqualTo(at.$3.height));
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }

    testWidgets('the index down to its longest names, ${name(at)}', (tester) async {
      await pumpApp(tester, at);
      containerOf(tester).read(routerProvider).go(Routes.quran);
      await tester.pumpAndSettle();
      for (var i = 0; i < 20; i++) {
        await tester.fling(find.byType(Scrollable).first, const Offset(0, -3000), 3000);
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }
}

const _ar = {'Story': 'قصة', 'Square': 'مربع', 'Share': 'مشاركة'};
