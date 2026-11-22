import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/surah_index.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('index opens over the reader at its surah, a tap turns this reader there', (
    tester,
  ) async {
    await pumpHome(tester, await designOverrides(), settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(50));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(find.text('Index'), findsOneWidget);
    await tester.tap(find.text('Index'));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderPage), findsOneWidget, reason: 'the reader stays open');
    for (final tab in ['Surah', 'Juz', 'Page']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }

    /// the top bar names the surah too
    final row = find.descendant(of: find.byType(SurahIndex), matching: find.text("Aal-'Imran"));
    expect(row, findsOneWidget, reason: 'page 50 is in its surah, in view');

    await tester.tap(find.descendant(of: find.byType(SurahIndex), matching: find.text("An-Nisa'")));
    await tester.pumpAndSettle();
    expect(find.text('Juz'), findsNothing, reason: 'the sheet closed');
    expect(find.byType(ReaderPage), findsOneWidget);
    expect(
      tester.widgetList<MushafPageView>(find.byType(MushafPageView)).map((view) => view.number),
      contains(77),
    );
    await unmount(tester);
  });
}
