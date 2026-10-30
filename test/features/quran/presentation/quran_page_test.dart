import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/recitation_boot.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mini_player.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_chrome.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/recitation_sheet.dart';
import 'package:flutter/material.dart';
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

  Future<void> pumpQuran(WidgetTester tester) async {
    await pumpHome(tester, await designOverrides(), settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).go(Routes.quran);
    await tester.pumpAndSettle();
  }

  int? openedPage(WidgetTester tester) {
    final reader = find.byType(ReaderPage);
    return reader.evaluate().isEmpty ? null : tester.widget<ReaderPage>(reader).page;
  }

  testWidgets('4.18 shows the scenario copy and its tools, no khatmah or memorize', (tester) async {
    await pumpQuran(tester);

    for (final text in [
      'Madinah Mushaf · Hafs',
      'CONTINUE READING',
      'Al-Fatiha · Ayah 3',
      'Page 1 · Juz 1 · Today 14:10',
      'Listen',
      'Bookmarks',
      'Notes',
      'Surah',
      'Juz',
      'Page',
      'Al-Fatiha',
      'Meccan · 7 ayahs · p. 1',
      'Al-Baqarah',
      'Medinan · 286 ayahs · p. 2',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.text('Quran'), findsWidgets);
    expect(find.text('Memorize'), findsNothing);
    expect(find.textContaining('Khatmah'), findsNothing);
    await unmount(tester);
  });

  testWidgets('listen opens the last read page reciting from its ayah', (tester) async {
    final recitation = FakeRecitation();
    await pumpHome(
      tester,
      [...await designOverrides(), recitationProvider.overrideWithValue(recitation)],
      settle: false,
      app: const RecitationBoot(child: App()),
    );
    await tester.pump();
    containerOf(tester).read(routerProvider).go(Routes.quran);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Listen'));
    await tester.pumpAndSettle();
    expect(recitation.calls.last, 'play 1:3 1:7');
    expect(openedPage(tester), 1);
    expect(find.byType(MiniPlayer), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('the index switches to juz and to pages', (tester) async {
    await pumpQuran(tester);

    await tapText(tester, 'Juz');
    expect(find.text('Juz 1'), findsOneWidget);
    expect(find.text('Al-Fatiha 1 · p. 1'), findsOneWidget);
    expect(find.text('Juz 2'), findsOneWidget);

    await tapText(tester, 'Page');
    expect(find.text('Page 1'), findsWidgets);
    expect(find.text('Juz 1 · Al-Fatiha'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a surah row opens its first page', (tester) async {
    await pumpQuran(tester);

    await tapText(tester, 'Al-Baqarah');
    expect(openedPage(tester), 2);
    await unmount(tester);
  });

  testWidgets('continue reading opens the last read page in the page palette', (tester) async {
    await pumpQuran(tester);

    await tester.tap(find.text('CONTINUE READING'));
    await tester.pumpAndSettle();
    expect(openedPage(tester), 1);

    /// a mode change crossfades the palette over the sky's 1.8 s
    final theme = tester.widget<AnimatedTheme>(
      find.descendant(of: find.byType(ReaderPage), matching: find.byType(AnimatedTheme)),
    );
    expect(theme.duration, BmMotion.skyChange);
    expect(theme.curve, BmMotion.sacred);
    expect(
      theme.data.brightness,
      Brightness.dark,
      reason: 'follow sky takes the dark app on night',
    );
    await unmount(tester);
  });

  /// the open builds the page alone, the hidden controls and 4.25 wait until it's open
  testWidgets('the reader opens with its page, a tap brings the controls at once', (tester) async {
    await pumpQuran(tester);

    await tester.tap(find.text('CONTINUE READING'));
    for (var i = 0; i < 10 && find.byType(ReaderPage).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(BmMotion.containerOpen ~/ 2);
    expect(find.byType(PageTurner), findsOneWidget);
    expect(find.byType(PageChrome), findsNothing);
    expect(find.byType(RecitationSheet), findsNothing);

    await tester.pump(BmMotion.containerOpen);
    await tester.tapAt(const Offset(385, 400));
    await tester.pump();
    expect(find.byType(PageChrome), findsOneWidget);
    expect(find.byType(RecitationSheet), findsNothing);

    await tester.pumpAndSettle();
    expect(tester.widget<PageChrome>(find.byType(PageChrome)).shown, isTrue);
    expect(find.byType(RecitationSheet), findsOneWidget);
    await unmount(tester);
  });
}
