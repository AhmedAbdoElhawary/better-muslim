import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/continue_card.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
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

  LastRead lastRead(WidgetTester tester) => containerOf(tester).read(lastReadProvider);

  Future<QuranAssets> assets(WidgetTester tester) =>
      containerOf(tester).read(quranAssetsProvider.future);

  /// the mushaf reads right to left, the next page is a drag to the right
  Future<void> turn(WidgetTester tester) async {
    await tester.timedDrag(
      find.byType(PageTurner),
      const Offset(393 * .6, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();
  }

  Future<void> leave(WidgetTester tester) async {
    containerOf(tester).read(routerProvider).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('a page settling without audio is last read, from its first ayah', (tester) async {
    await pumpReciting(tester, FakeRecitation());
    await turn(tester);

    final start = (await assets(tester)).pageInfo(2).start;
    expect(lastRead(tester).ayah, start);
    expect(lastRead(tester).page, 2);
    await unmount(tester);
  });

  testWidgets('leaving the reader saves the page shown', (tester) async {
    await pumpReciting(tester, FakeRecitation(), page: 3);
    expect(lastRead(tester).page, 1);

    await leave(tester);
    expect(lastRead(tester).ayah, (await assets(tester)).pageInfo(3).start);
    expect(lastRead(tester).page, 3);
    await unmount(tester);
  });

  testWidgets('while it plays only the playing ayah is saved', (tester) async {
    final recitation = FakeRecitation();
    await pumpReciting(tester, recitation);
    await recitation.play(const AyahKey(1, 6), to: const AyahKey(1, 7));
    await tester.pumpAndSettle();
    expect(lastRead(tester).ayah, const AyahKey(1, 6));

    await turn(tester);
    expect(lastRead(tester).ayah, const AyahKey(1, 6));
    await leave(tester);
    expect(lastRead(tester).ayah, const AyahKey(1, 6));
    expect(lastRead(tester).page, 1);
    await unmount(tester);
  });

  testWidgets('continue reading on the quran tab and on home open the last read page', (
    tester,
  ) async {
    final reads = [
      (Routes.quran, find.byType(ContinueCard)),
      (Routes.home, find.text('Continue reading')),
    ];
    for (final (tab, card) in reads) {
      await pumpHome(tester, await designOverrides());
      final container = containerOf(tester);
      await container.read(saveLastReadProvider)(const AyahKey(2, 255), 42);
      container.read(routerProvider).go(tab);
      await tester.pumpAndSettle();
      await tester.ensureVisible(card);
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(tester.widget<ReaderPage>(find.byType(ReaderPage)).page, 42, reason: tab);
      await unmount(tester);
    }
  });

  testWidgets('a fresh install starts at al-fatiha, ayah 1, page 1', (tester) async {
    await pumpHome(tester, testOverrides());
    expect(find.text('Al-Fatiha · ayah 1 of 7'), findsOneWidget);

    containerOf(tester).read(routerProvider).go(Routes.quran);
    await tester.pumpAndSettle();
    expect(find.text('Al-Fatiha · Ayah 1'), findsOneWidget);
    expect(find.text('Page 1 · Juz 1'), findsOneWidget);
    await unmount(tester);
  });
}
