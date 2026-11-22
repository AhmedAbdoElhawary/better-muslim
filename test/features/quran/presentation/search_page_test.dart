import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/quran/data/search_text.dart';
import 'package:better_muslim/features/quran/domain/quran_search.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/search_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/more.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

/// the page searches after a pause in typing
const typingPause = Duration(milliseconds: 200);

void main() {
  late List<SearchAyah> ayahs;
  late QuranAssets assets;
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    ayahs = await loadSearchAyahs();
    assets = await QuranAssets.load();
  });
  setUp(mockSystemChannel);

  testWidgets(
    '4.27 from quran home: jump card, grouped hits, rows that open, a hit opens the reader',
    (tester) async {
      await pumpHome(tester, [
        ...await designOverrides(),
        searchAyahsProvider.overrideWith((ref) async => ayahs),
      ], settle: false);
      await tester.pump();
      containerOf(tester).read(routerProvider).go(Routes.quran);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Search the Quran'));
      await tester.pumpAndSettle();
      expect(find.byType(SearchPage), findsOneWidget);
      expect(
        find.text('Search is smart enough to ignore diacritics and hamza forms.'),
        findsOneWidget,
      );
      expect(find.text('No ayahs found'), findsNothing);

      await tester.enterText(find.byType(TextField), 'الرحمن');
      await tester.pump(typingPause);
      await tester.pumpAndSettle();
      expect(find.text('JUMP TO SURAH'), findsOneWidget);
      expect(find.text('55 · Ar-Rahman'), findsOneWidget);
      expect(find.text('Medinan · 78 ayahs · p. 531'), findsOneWidget);
      final count = searchQuran('الرحمن', ayahs, assets).groups;
      expect(
        find.text(
          '${count.values.expand((hits) => hits).fold(0, (sum, hit) => sum + hit.count)} times in '
          '${count.values.fold(0, (sum, hits) => sum + hits.length)} ayahs in ${count.length} surahs',
        ),
        findsOneWidget,
      );

      /// every surah starts folded, a tap opens its hits and a second folds them
      expect(find.text('1:1'), findsNothing);
      await tester.tap(find.text('Al-Fatiha'));
      await tester.pumpAndSettle();
      expect(find.text('AL-FATIHA'), findsOneWidget);
      expect(find.text('1:1'), findsOneWidget);
      expect(find.text('1:3'), findsOneWidget);
      await tester.tap(find.text('AL-FATIHA'));
      await tester.pumpAndSettle();
      expect(find.text('1:1'), findsNothing);

      await tester.tap(find.text('Expand all'));
      await tester.pumpAndSettle();
      expect(find.text('1:1'), findsOneWidget);
      expect(find.text('AL-BAQARAH'), findsOneWidget);
      await tester.tap(find.text('Fold all'));
      await tester.pumpAndSettle();
      expect(find.text('AL-BAQARAH'), findsNothing);
      expect(find.text('Expand all'), findsOneWidget);

      /// a search I submit is kept, the empty field lists it
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(typingPause);
      await tester.pumpAndSettle();
      expect(find.text('Recent searches'), findsOneWidget);
      await tester.tap(find.text('الرحمن'));
      await tester.pumpAndSettle();
      expect(find.text('Expand all'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.pump(typingPause);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Recent searches'), findsNothing);

      await tester.enterText(find.byType(TextField), 'p 700');
      await tester.pump(typingPause);
      await tester.pumpAndSettle();
      expect(find.text('No ayahs found'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'الحمد لله رب العالمين');
      await tester.pump(typingPause);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Al-Fatiha'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1:2'));
      await tester.pumpAndSettle();
      expect(tester.widget<ReaderPage>(find.byType(ReaderPage)).page, 1);
      await unmount(tester);
    },
  );

  testWidgets('from the reader a hit turns that reader and opens the ayah', (tester) async {
    await pumpHome(tester, [
      ...await designOverrides(),
      searchAyahsProvider.overrideWith((ref) async => ayahs),
    ], settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(3));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Search the Quran'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchPage), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'الحمد لله رب العالمين');
    await tester.pump(typingPause);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Al-Fatiha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1:2'));
    await tester.pumpAndSettle();

    expect(find.byType(SearchPage), findsNothing);
    expect(find.byType(ReaderPage), findsOneWidget);
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(1, 2));
    await unmount(tester);
  });
}
