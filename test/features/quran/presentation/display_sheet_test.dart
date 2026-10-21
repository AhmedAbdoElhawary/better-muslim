import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_turn.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

  late List<MethodCall> calls;
  setUp(() => calls = mockSystemChannel());

  Future<void> pumpReader(WidgetTester tester, {double textScale = 1}) async {
    await pumpHome(tester, await designOverrides(), textScale: textScale, settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    await tester.pumpAndSettle();
  }

  /// a tap past the spine shows the controls, then the dock's Display
  Future<void> openDisplay(WidgetTester tester) async {
    await tester.tapAt(const Offset(385, 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Display'));
    await tester.pumpAndSettle();
  }

  AppSettings settingsOf(WidgetTester tester) => containerOf(tester).read(settingsProvider).value!;

  Finder segment<T>(String label) =>
      find.descendant(of: find.byType(Segmented<T>), matching: find.text(label));

  Future<void> tapInSheet(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('holds page, layout, page turn, keep screen on and the mushaf', (tester) async {
    await pumpReader(tester);
    await openDisplay(tester);

    for (final text in [
      'Display',
      'Applies to every page',
      'PAGE',
      'Paper',
      'Cream',
      'Night',
      'Follow sky',
      'Layout',
      'Page turn',
      'Book',
      'Slide',
      'Keep screen on',
      'Madinah · Hafs',
      'Sahih International',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    for (final label in ['Mushaf', 'Translation', 'Both']) {
      expect(segment<QuranLayout>(label), findsOneWidget, reason: label);
    }

    /// tajweed colors wait for 7b, the sizes only matter in the translation layouts
    expect(find.text('Tajweed colors'), findsNothing);
    expect(find.text('Arabic size'), findsNothing);
    await unmount(tester);
  });

  testWidgets('each choice is kept in settings and the page takes it at once', (tester) async {
    await pumpReader(tester);
    await openDisplay(tester);

    await tapInSheet(tester, find.text('Night'));
    expect(settingsOf(tester).pageColor, PageColor.night);
    expect(containerOf(tester).read(pageColorProvider), PageColor.night);

    await tapInSheet(tester, segment<PageTurn>('Slide'));
    expect(settingsOf(tester).pageTurn, PageTurn.slide);
    expect(tester.widget<PageTurner>(find.byType(PageTurner)).book, isFalse);

    await tapInSheet(tester, segment<QuranLayout>('Both'));
    expect(settingsOf(tester).quranLayout, QuranLayout.both);

    /// the sheet reopens on what was picked
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Display'));
    await tester.pumpAndSettle();
    final picked = tester.widget<Segmented<QuranLayout>>(find.byType(Segmented<QuranLayout>));
    expect(picked.selected, QuranLayout.both);
    await unmount(tester);
  });

  testWidgets('the sizes step within -2 to 3 and show their point size', (tester) async {
    await pumpReader(tester);
    await openDisplay(tester);
    await tapInSheet(tester, segment<QuranLayout>('Translation'));

    expect(find.text('Arabic size'), findsOneWidget);
    expect(find.text('Translation size'), findsOneWidget);
    expect(find.text('26'), findsOneWidget);
    expect(find.text('14'), findsOneWidget);

    final larger = find.bySemanticsLabel('Larger');
    final smaller = find.bySemanticsLabel('Smaller');
    await tapInSheet(tester, larger.first);
    expect(settingsOf(tester).quranArabicSize, 1);
    expect(find.text('28'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tapInSheet(tester, smaller.last);
    }
    expect(settingsOf(tester).quranTranslationSize, -2);
    expect(find.text('12'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('keep screen on holds the screen in the reader and lets go on leaving', (
    tester,
  ) async {
    await pumpReader(tester);
    await openDisplay(tester);
    calls.clear();

    await tapInSheet(tester, find.text('Keep screen on'));
    expect(settingsOf(tester).keepScreenOn, isTrue);
    expect(calls.where((call) => call.method == 'keepScreenOn').last.arguments, {'on': true});

    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    containerOf(tester).read(routerProvider).pop();
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'keepScreenOn').last.arguments, {'on': false});
    await unmount(tester);
  });

  testWidgets('in arabic the translation row names al-muyassar', (tester) async {
    await pumpHome(tester, await designOverrides(), locale: const Locale('ar'), settle: false);
    await tester.pump();
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    await tester.pumpAndSettle();

    /// the margin past the spine is on the left in arabic too, the mushaf never mirrors
    await tester.tapAt(const Offset(385, 400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العرض'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(GroupedSection), matching: find.text('الميسّر')),
      findsOneWidget,
    );
    expect(find.text('المدينة · حفص'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('survives text scale 2.0', (tester) async {
    await pumpReader(tester, textScale: 2);
    await openDisplay(tester);
    await tapInSheet(tester, segment<QuranLayout>('Both'));
    await tester.ensureVisible(find.text('Madinah · Hafs'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await unmount(tester);
  });
}
