import 'dart:io';
import 'dart:typed_data';

import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/system/share.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:better_muslim/features/duas/model/dua_clips.dart';
import 'package:better_muslim/features/duas/view/dua_category_page.dart';
import 'package:better_muslim/features/duas/view/widgets/dua_card.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/azkar.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);
  setUp(recordPhone);

  /// the save action's label, the chip says "Saved" too
  Finder action(String label) =>
      find.descendant(of: find.byType(DuaCard), matching: find.text(label));

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

  Future<void> chip(WidgetTester tester, String label) async {
    final target = find.text(label).first;
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('find the dua for this moment (US3)', () {
    testWidgets('the 4.14 copy and order with no tab bar', (tester) async {
      await pumpDuas(tester, await designOverrides());

      for (final text in [
        'Duas',
        'Search in English or Arabic',
        'All',
        'Morning and evening',
        'Home',
        'Travel',
        'Sleep',
        'Saved',
        'Leaving the home',
        'Abu Dawud 4/325, at-Tirmidhi 5/490',
        'بِسْمِ اللَّهِ، تَوَكَّلْتُ عَلَى اللَّهِ، وَلَاَ حَوْلَ وَلَا قُوَّةَ إِلاَّ بِاللَّهِ',
        'Save',
        'Share',
        'Waking up',
        'Before sleeping',
        'Entering and leaving the mosque',
        'Before and after eating',
        '4 duas',
        '13 duas',
        '3 duas',
        '2 duas',
      ]) {
        expect(find.text(text), findsWidgets, reason: text);
      }
      expect(
        tester.getTopLeft(find.text('Waking up')).dy,
        lessThan(tester.getTopLeft(find.text('Before and after eating')).dy),
      );
      expect(find.byType(NavBar), findsNothing);
      await unmount(tester);
    });

    testWidgets('a chip shows only its categories', (tester) async {
      await pumpDuas(tester, await designOverrides());
      await chip(tester, 'Home');

      expect(find.text('Leaving the home'), findsNWidgets(2));
      expect(find.text('Entering and leaving the mosque'), findsOneWidget);
      expect(find.text('Waking up'), findsNothing);
      expect(find.text('Before sleeping'), findsNothing);
      await unmount(tester);
    });

    testWidgets('search shows cards as I type, clearing returns to the chip', (tester) async {
      await pumpDuas(tester, await designOverrides());
      await chip(tester, 'Sleep');
      await search(tester, '4/325');

      expect(find.byType(DuaCard), findsWidgets);
      expect(find.text('Leaving the home'), findsWidgets);
      expect(find.text('9 duas'), findsNothing);

      await search(tester, 'توكلت');
      expect(find.text('Leaving the home'), findsWidgets);

      await search(tester, '');
      expect(find.text('Before sleeping'), findsWidgets);
      expect(find.text('Leaving the home'), findsNothing);
      await unmount(tester);
    });

    testWidgets('no match shows the empty state with its hint', (tester) async {
      await pumpDuas(tester, await designOverrides());
      await search(tester, 'zzz');

      expect(find.text('No duas found'), findsOneWidget);
      expect(find.text('Try another word in English or Arabic.'), findsOneWidget);
      expect(find.byType(DuaCard), findsNothing);
      await unmount(tester);
    });

    testWidgets('the hisn al-muslim chips each show their chapters', (tester) async {
      await pumpDuas(tester, await designOverrides());
      for (final (label, category) in [
        ('Prayer', 'Before ablution'),
        ('Travel', 'When mounting an animal or any means of transport'),
        ('Food', 'Before and after eating'),
        ('Distress', 'For anxiety and sorrow'),
        ('Illness', 'When visiting the sick'),
        ('Weather', 'During a wind storm'),
      ]) {
        await chip(tester, label);
        expect(find.text(category), findsWidgets, reason: label);
        expect(find.text('No duas found'), findsNothing, reason: label);
      }
      await unmount(tester);
    });

    testWidgets('quran shows the rabbana duas, sahih english, listen in my reciter', (
      tester,
    ) async {
      final clips = FakeClipPlayer();
      final root = Directory.systemTemp.createTempSync('recitations');
      File('${root.path}/recitations/husary/002127.mp3')
        ..createSync(recursive: true)
        ..writeAsBytesSync([0x49, 0x44, 0x33]);
      final overrides = await designOverrides(
        recitationFiles: recitationFilesProvider.overrideWith(
          (ref) => RecitationFiles(
            root: () async => root,
            fetch: (_, {from = 0}) async => throw const SocketException('offline'),
            exclude: (_) async {},
          ),
        ),
      );
      await pumpDuas(tester, [...overrides, clipPlayerProvider.overrideWithValue(clips)]);
      await containerOf(tester)
          .read(databaseProvider)
          .updateSettings(const SettingsCompanion(reciter: Value(Reciter.husary)));
      await chip(tester, 'Quran');

      final card = tester.widget<DuaCard>(find.byType(DuaCard));
      expect(card.dua.id, 'q2-127');
      expect(find.text('Al-Baqarah 2:127'), findsOneWidget);
      expect(find.textContaining('Our Lord, accept [this] from us.'), findsOneWidget);
      expect(find.text('Rabbana duas from the Quran'), findsWidgets);
      expect(find.text('38 duas'), findsOneWidget);
      expect(find.text('Leaving the home'), findsNothing);

      await tester.tap(action('Listen'));
      await tester.pumpAndSettle();
      expect(clips.played, ['${root.path}/recitations/husary/002127.mp3']);
      expect(action('Stop'), findsOneWidget);

      await tester.tap(action('Save'));
      await tester.pumpAndSettle();
      expect(action('Saved'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a row opens its page with its duas as cards', (tester) async {
      await pumpDuas(tester, await designOverrides());
      await tester.ensureVisible(find.text('Before sleeping'));
      await tester.tap(find.text('Before sleeping'));
      await tester.pumpAndSettle();

      expect(find.byType(DuaCategoryPage), findsOneWidget);
      expect(
        find.descendant(of: find.byType(CompactAppBar), matching: find.text('Before sleeping')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<DuaCard>(
              find
                  .descendant(of: find.byType(DuaCategoryPage), matching: find.byType(DuaCard))
                  .first,
            )
            .dua
            .id,
        'd022',
      );
      await unmount(tester);
    });

    testWidgets('arabic shows the arabic and the source only, arabic plural forms', (tester) async {
      await pumpDuas(tester, await designOverrides(), locale: const Locale('ar'));

      expect(find.text('أبو داود ٤/٣٢٥، الترمذي ٥/٤٩٠'), findsOneWidget);
      expect(find.text('مغادرة المنزل'), findsNWidgets(2));
      expect(find.text('١٣ دعاءً'), findsOneWidget);
      expect(find.text('٣ أدعية'), findsWidgets);
      expect(find.text('٤ أدعية'), findsWidgets);
      expect(find.text('دعاءان'), findsWidgets);
      await unmount(tester);
    });
  });

  group('keep the duas I use (US4)', () {
    testWidgets('save fills the bookmark, the saved chip lists it', (tester) async {
      await pumpDuas(tester, await designOverrides());
      await tester.tap(action('Save'));
      await tester.pumpAndSettle();

      expect(action('Saved'), findsOneWidget);
      await chip(tester, 'Saved');
      expect(find.byType(DuaCard), findsOneWidget);
      expect(find.text('Leaving the home'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('newest first, a removal toasts and undo puts it back in place', (tester) async {
      await pumpDuas(tester, await designOverrides());
      final db = dbOf(tester);
      await db.saveDua('d001', at: DateTime(2026, 10, 1));
      await db.saveDua('d003', at: DateTime(2026, 10, 2));
      await chip(tester, 'Saved');

      List<String> shown() => [
        for (final card in tester.widgetList<DuaCard>(find.byType(DuaCard))) card.dua.id,
      ];
      expect(shown(), ['d003', 'd001']);

      await tester.tap(action('Saved').first);
      await tester.pumpAndSettle();
      expect(shown(), ['d001']);
      expect(find.text('Removed from saved'), findsOneWidget);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(shown(), ['d003', 'd001']);
      await unmount(tester);
    });

    testWidgets('nothing saved shows the empty state', (tester) async {
      await pumpDuas(tester, await designOverrides());
      await chip(tester, 'Saved');

      expect(find.text('No duas saved yet'), findsOneWidget);
      expect(find.text('Tap Save on any dua to keep it here.'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a save on a category page shows on duas', (tester) async {
      await pumpDuas(tester, await designOverrides());
      containerOf(tester).read(routerProvider).push(Routes.duaCategory('mosque'));
      await tester.pumpAndSettle();
      await tester.tap(action('Save').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BarBackButton));
      await tester.pumpAndSettle();
      await chip(tester, 'Saved');

      expect(find.text('Entering and leaving the mosque'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a new app start on the same store keeps it', (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = await designScenarioStore();
      addTearDown(db.close);
      final overrides = [
        databaseProvider.overrideWithValue(db),
        flavorProvider.overrideWithValue(
          const FlavorConfig(
            flavor: Flavor.dev,
            appName: 'Better Muslim',
            sentryDsn: '',
            scenario: 'design',
          ),
        ),
        ...designScenarioOverrides(),
        onboardingProvider.overrideWith(() => OnboardingNotifier(done: true)),
      ];
      await pumpDuas(tester, overrides);
      await tester.tap(action('Save'));
      await tester.pumpAndSettle();
      await unmount(tester);

      await pumpDuas(tester, overrides);
      expect(action('Saved'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('listen and share (US5)', () {
    testWidgets('a clip plays and reads stop, a page on top or leaving stops it', (tester) async {
      final clips = FakeClipPlayer();
      final root = Directory.systemTemp.createTempSync('duas');
      File('${root.path}/duas/16.mp3').createSync(recursive: true);
      await pumpDuas(tester, [
        ...await designOverrides(),
        clipPlayerProvider.overrideWithValue(clips),
        duaClipsProvider.overrideWithValue(
          DuaClips(
            root: () async => root,
            fetch: (_, {from = 0}) async => throw const SocketException('offline'),
            exclude: (_) async {},
          ),
        ),
      ]);
      await tester.tap(action('Listen'));
      await tester.pumpAndSettle();
      expect(action('Stop'), findsOneWidget);
      expect(clips.played, ['${root.path}/duas/16.mp3']);

      containerOf(tester).read(routerProvider).push(Routes.duaCategory('mosque'));
      await tester.pumpAndSettle();
      expect(clips.stops, 1);

      await tester.tap(find.byType(BarBackButton));
      await tester.pumpAndSettle();
      await tester.tap(action('Listen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BarBackButton));
      await tester.pumpAndSettle();
      expect(clips.stops, greaterThanOrEqualTo(2));
      await unmount(tester);
    });

    for (final locale in [const Locale('en'), const Locale('ar')]) {
      testWidgets(
        'share opens the sheet, its share sends one 1080 px wide png (${locale.languageCode})',
        (tester) async {
          final shared = <ShareParams>[];
          await pumpDuas(tester, [
            ...await designOverrides(),
            shareProvider.overrideWithValue((params) async => shared.add(params)),
          ], locale: locale);
          final share = locale.languageCode == 'ar' ? 'مشاركة' : 'Share';
          await tester.tap(action(share));
          await tester.pumpAndSettle();

          /// the dua's own share sheet, then its Share button
          final button = find.descendant(of: find.byType(ShareSheet), matching: find.text(share));
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pump();
          await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
          await tester.pump();

          expect(shared, hasLength(1));
          final [file] = shared.single.files!;
          expect(file.mimeType, 'image/png');
          final png = await tester.runAsync(file.readAsBytes) ?? Uint8List(0);
          expect(ByteData.sublistView(png).getUint32(16), 360 * 3);
          await unmount(tester);
        },
      );
    }
  });
}
