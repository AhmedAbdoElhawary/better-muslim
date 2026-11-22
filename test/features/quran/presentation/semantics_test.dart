import 'dart:convert';
import 'dart:io';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/display_sheet.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mini_player.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

  late List<String> announced;
  setUp(() {
    mockSystemChannel();

    /// a screen reader is on, the page builds its ayah labels only then
    final dispatcher = TestWidgetsFlutterBinding.instance.platformDispatcher;
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      accessibleNavigation: true,
    );
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    announced = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockDecodedMessageHandler(
      SystemChannels.accessibility,
      (message) async {
        final event = message! as Map;
        if (event['type'] == 'announce') announced.add((event['data'] as Map)['message'] as String);
        return null;
      },
    );
  });

  /// al-fatiha's shipped sahih international and al-muyassar lines
  final fatiha = jsonDecode(File('assets/quran/surahs/001.json').readAsStringSync()) as Map;
  String translation(int ayah) => (fatiha['tr'] as List)[ayah - 1] as String;
  String tafsir(int ayah) => (fatiha['tafsir'] as List)[ayah - 1] as String;

  Future<void> pumpReader(
    WidgetTester tester, {
    QuranLayout layout = QuranLayout.mushaf,
    Locale locale = const Locale('en'),
  }) async {
    await pumpHome(tester, await designOverrides(), locale: locale, settle: false);
    await tester.pump();
    if (layout != QuranLayout.mushaf) {
      await tester.runAsync(
        () =>
            containerOf(tester)
                .read(databaseProvider)
                .updateSettings(SettingsCompanion(quranLayout: Value(layout))),
      );
    }
    containerOf(tester).read(routerProvider).push(Routes.quranPage(1));
    await tester.pumpAndSettle();
  }

  /// the ayah's node reads its surah and number, the arabic, then the translation slot
  SemanticsFinder ayahNode(String title, String translation) => find.semantics.byPredicate(
    (node) =>
        node.label.startsWith('$title\n') &&
        node.label.endsWith('\n$translation') &&
        node.flagsCollection.isButton,
  );

  testWidgets('each ayah on the page reads as surah, number, arabic and translation', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpReader(tester);

    for (var ayah = 1; ayah <= 7; ayah++) {
      expect(ayahNode('Al-Fatiha · Ayah $ayah', translation(ayah)), findsOne, reason: '$ayah');
    }

    /// a screen reader's double tap opens its sheet like a long press
    tester.semantics.tap(ayahNode('Al-Fatiha · Ayah 5', translation(5)));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(1, 5));

    /// while choosing it checks the ayah instead
    containerOf(tester).read(selectionProvider.notifier).startChoosing(const AyahKey(1, 5));
    await tester.pumpAndSettle();
    tester.semantics.tap(ayahNode('Al-Fatiha · Ayah 5', translation(5)));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).chosen, isEmpty);
    expect(containerOf(tester).read(selectionProvider).sheet, isNull);
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('the translation cells read the same way', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpReader(tester, layout: QuranLayout.translation);

    /// the page above the cells reads its ayahs too
    expect(ayahNode('Al-Fatiha · Ayah 1', translation(1)), findsExactly(2));
    tester.semantics.tap(ayahNode('Al-Fatiha · Ayah 2', translation(2)).first);
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(selectionProvider).sheet, const AyahKey(1, 2));
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('the layout switched under the display sheet reads the new page', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpReader(tester, layout: QuranLayout.translation);

    final reader = tester.element(find.byType(ReaderPage));
    showDisplaySheet(reader);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () =>
          containerOf(tester)
              .read(databaseProvider)
              .updateSettings(const SettingsCompanion(quranLayout: Value(QuranLayout.mushaf))),
    );
    await tester.pumpAndSettle();
    Navigator.of(reader, rootNavigator: true).pop();
    await tester.pumpAndSettle();

    expect(ayahNode('Al-Fatiha · Ayah 1', translation(1)), findsOne);
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('in arabic the slot read is al-muyassar', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpReader(tester, locale: const Locale('ar'));

    expect(find.semantics.byPredicate((node) => node.label.endsWith('\n${tafsir(5)}')), findsOne);
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('each page turn is announced with its number', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpReader(tester);

    /// the left Turn strip opens the next page
    await tester.tapAt(const Offset(20, 400));
    await tester.pumpAndSettle();
    expect(announced, contains('Al-Baqarah · Page 2'));
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('play and pause are announced, the player buttons are labelled', (tester) async {
    final handle = tester.ensureSemantics();
    final recitation = FakeRecitation();
    await pumpReciting(tester, recitation);

    await recitation.play(const AyahKey(1, 1), to: const AyahKey(1, 7));
    await tester.pumpAndSettle();
    expect(announced, contains('Playing'));
    await recitation.pause();
    await tester.pumpAndSettle();
    expect(announced, contains('Paused'));

    expect(
      find.descendant(of: find.byType(MiniPlayer), matching: find.bySemanticsLabel('Play')),
      findsOneWidget,
    );
    await unmount(tester);
    handle.dispose();
  });

  testWidgets('every control in the reader, the dock and the ayah sheet is 44 x 44 and labelled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpReader(tester);

    /// the controls over the page
    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    /// the ayah sheet
    tester.semantics.tap(ayahNode('Al-Fatiha · Ayah 5', translation(5)));
    await tester.pumpAndSettle();
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await unmount(tester);
    handle.dispose();
  });
}
