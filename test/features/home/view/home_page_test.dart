import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/core/location/place_list.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/azkar/view/azkar_page.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/home/view/widgets/countdown.dart';
import 'package:better_muslim/features/home/view/widgets/countdown_digit.dart';
import 'package:better_muslim/features/home/view/widgets/next_prayer_card.dart';
import 'package:better_muslim/features/home/view/widgets/no_location_card.dart';
import 'package:better_muslim/features/home/view/widgets/now_block.dart';
import 'package:better_muslim/features/home/view/widgets/prayer_strip.dart';
import 'package:better_muslim/features/home/view/widgets/shortcuts_card.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header_painter.dart';
import 'package:better_muslim/features/home/view/widgets/sky_labels.dart';
import 'package:better_muslim/features/home/view/widgets/strip_cell.dart';
import 'package:better_muslim/features/home/view/widgets/strip_row.dart';
import 'package:better_muslim/features/home/view/widgets/verse_card.dart';
import 'package:better_muslim/features/prayer/presentation/view/prayer_page.dart';
import 'package:better_muslim/features/quran/presentation/view/quran_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  late PlaceList places;
  setUpAll(() async => places = await PlaceList.load());

  /// the real fonts, the square test font is far wider and would overflow where the app doesn't
  setUpAll(loadAppFonts);

  String countdown(WidgetTester tester) => tester
      .widgetList<CountdownDigit>(find.byType(CountdownDigit))
      .map((digit) => digit.digit)
      .join();

  Finder checkIn(int cell) => find.descendant(
    of: find.byWidgetPredicate((widget) => widget is StripCell && widget.index == cell),
    matching: find.byWidgetPredicate(
      (widget) => widget is BmIcon && widget.asset.endsWith('ui/check.svg'),
    ),
  );

  /// the current cell's name is the only semibold text on home
  Finder currentCell() =>
      find.descendant(of: find.byType(PrayerStrip), matching: find.byType(SemiBoldText));

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(HomePage)));

  group('the design scenario (4.01, 4.02, 4.16)', () {
    testWidgets('english', (tester) async {
      await pumpHome(tester, designOverrides());

      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('Asr'), findsNWidgets(2));
      expect(find.text('العصر'), findsOneWidget);
      expect(find.text('Until Maghrib at 17:56'), findsOneWidget);
      expect(find.text('Next prayer'), findsOneWidget);
      expect(find.text('Maghrib'), findsNWidgets(2));
      expect(countdown(tester), '1:24:00');
      expect(find.text('Adhan at 17:56 · reminder 10 min before'), findsOneWidget);
      for (final time in ['04:58', '12:05', '15:27', '17:56', '19:26']) {
        expect(find.text(time), findsOneWidget, reason: time);
      }
      expect(find.text('Sunrise 06:15'), findsOneWidget);
      expect(find.text('Maghrib 17:56'), findsOneWidget);
      expect(find.text('Thu 15 Oct · 4 Jumada I 1448'), findsOneWidget);
      expect(find.text('Makkah'), findsOneWidget);
      expect(checkIn(0), findsOneWidget);
      expect(checkIn(1), findsOneWidget);
      for (final cell in [2, 3, 4]) {
        expect(checkIn(cell), findsNothing);
      }
      expect(tester.widget<SemiBoldText>(currentCell()).text, Prayer.asr.nameKey);
      await unmount(tester);
    });

    testWidgets('arabic, with eastern digits and no second name', (tester) async {
      await pumpHome(tester, designOverrides(), locale: const Locale('ar'));

      expect(find.text('الآن'), findsOneWidget);
      expect(find.text('العصر'), findsNWidgets(2));
      expect(find.text('حتى المغرب الساعة ١٧:٥٦'), findsOneWidget);
      expect(find.text('الصلاة القادمة'), findsOneWidget);
      expect(countdown(tester), '١:٢٤:٠٠');
      expect(find.text('الأذان ١٧:٥٦ · تذكير قبل ١٠ دقائق'), findsOneWidget);
      for (final time in ['٠٤:٥٨', '١٢:٠٥', '١٥:٢٧', '١٧:٥٦', '١٩:٢٦']) {
        expect(find.text(time), findsOneWidget, reason: time);
      }
      expect(find.text('الخميس · ٤ جمادى الأولى ١٤٤٨'), findsOneWidget);
      expect(find.text('مكة المكرمة'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('dark and light both build', (tester) async {
      await pumpHome(tester, designOverrides(), brightness: Brightness.light);
      expect(find.byType(NextPrayerCard), findsOneWidget);
      await unmount(tester);

      await pumpHome(tester, designOverrides());
      expect(find.byType(NextPrayerCard), findsOneWidget);
      await unmount(tester);
    });
  });

  group('live values', () {
    testWidgets('the countdown ticks with the clock, and maghrib takes over at 17:56', (
      tester,
    ) async {
      await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32)));
      expect(countdown(tester), '1:24:00');

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(countdown(tester), '1:23:59');

      await tester.pump(const Duration(hours: 1, minutes: 23, seconds: 59));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: find.byType(NowBlock), matching: find.text('Maghrib')),
        findsOneWidget,
      );
      expect(find.text('Until Isha at 19:26'), findsOneWidget);
      expect(tester.widget<SemiBoldText>(currentCell()).text, Prayer.maghrib.nameKey);
      await unmount(tester);
    });

    testWidgets('during duha no cell is current', (tester) async {
      await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 6)));

      expect(
        find.descendant(of: find.byType(NowBlock), matching: find.text('Duha')),
        findsOneWidget,
      );
      expect(find.text('Until Dhuhr at 12:06'), findsOneWidget);
      expect(currentCell(), findsNothing);
      await unmount(tester);
    });

    testWidgets('after isha the next prayer is tomorrow\'s fajr', (tester) async {
      await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 18)));

      expect(find.text('Until Fajr at 05:00'), findsOneWidget);
      expect(find.text('Isha 19:26'), findsOneWidget);
      expect(find.text('Fajr 05:00'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a polar day with no isha shows a dash', (tester) async {
      final zone = tz.getLocation('Asia/Riyadh');
      await pumpHome(
        tester,
        makkahAt(
          tester,
          DateTime.utc(2026, 10, 15, 13, 32),
          extra: [
            dayTimesProvider.overrideWith(
              (ref, date) => DayTimes(
                date: date,
                fajr: tz.TZDateTime(zone, date.year, date.month, date.day, 4, 58),
                sunrise: tz.TZDateTime(zone, date.year, date.month, date.day, 6, 15),
                dhuhr: tz.TZDateTime(zone, date.year, date.month, date.day, 12, 5),
                asr: tz.TZDateTime(zone, date.year, date.month, date.day, 15, 27),
                maghrib: tz.TZDateTime(zone, date.year, date.month, date.day, 17, 56),
                isha: null,
                method: PrayerMethod.ummAlQura,
                asrMethod: AsrMethod.standard,
              ),
            ),
          ],
        ),
      );

      expect(
        find.descendant(
          of: find.byWidgetPredicate((widget) => widget is StripCell && widget.index == 4),
          matching: find.text('—'),
        ),
        findsOneWidget,
      );
      await unmount(tester);
    });

    testWidgets('location, method, hijri and digits changes show without leaving home (FR-007)', (
      tester,
    ) async {
      await pumpHome(tester, [
        ...testOverrides(),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 10, 15, 13, 32)),
      ]);
      final container = containerOf(tester);
      final db = container.read(databaseProvider);
      await tester.runAsync(
        () => db.updateSettings(
          const SettingsCompanion(
            latitude: Value(21.4225),
            longitude: Value(39.8262),
            placeName: Value('Makkah'),
            countryCode: Value('SA'),
            timeZone: Value('Asia/Riyadh'),
            locationMode: Value(LocationMode.manual),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('15:27'), findsOneWidget);
      expect(find.text('05:00'), findsOneWidget);

      await tester.runAsync(
        () => db.updateSettings(const SettingsCompanion(method: Value(PrayerMethod.egyptian))),
      );
      await tester.pumpAndSettle();
      expect(find.text('05:00'), findsNothing);

      await tester.runAsync(
        () => container.read(locationControllerProvider).choose(places.search('tanta').first),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tanta'), findsOneWidget);
      expect(find.text('15:27'), findsNothing);

      await tester.runAsync(
        () => db.updateSettings(const SettingsCompanion(hijriAdjust: Value(1))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('5 Jumada I 1448'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('arabic follows the digits setting', (tester) async {
      await pumpHome(tester, designOverrides(), locale: const Locale('ar'));
      expect(find.text('١٥:٢٧'), findsOneWidget);

      await tester.runAsync(
        () =>
            containerOf(tester)
                .read(databaseProvider)
                .updateSettings(const SettingsCompanion(digits: Value(Digits.western))),
      );
      await tester.pumpAndSettle();

      expect(find.text('15:27'), findsOneWidget);
      expect(countdown(tester), '1:24:00');
      await unmount(tester);
    });
  });

  group('one tap to what I need (US3)', () {
    testWidgets('the verse, continue reading and the evening azkar in english', (tester) async {
      await pumpHome(tester, designOverrides());

      expect(find.text('Al-Fatiha 1:5'), findsOneWidget);
      expect(find.text('إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ'), findsOneWidget);
      expect(find.text('It is You we worship and You we ask for help.'), findsOneWidget);
      expect(find.text('Continue reading'), findsOneWidget);
      expect(find.text('Al-Fatiha · ayah 3 of 7'), findsOneWidget);
      expect(find.text('Evening azkar'), findsOneWidget);
      expect(find.text('After Asr · 0 of 24'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('morning azkar from fajr until asr', (tester) async {
      await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 5)));

      expect(find.text('Morning azkar'), findsOneWidget);
      expect(find.text('After Fajr · 0 of 12'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('arabic has no translation and no azkar row', (tester) async {
      await pumpHome(tester, designOverrides(), locale: const Locale('ar'));

      expect(find.text('الفاتحة ٥'), findsOneWidget);
      expect(find.text('It is You we worship and You we ask for help.'), findsNothing);
      expect(find.text('متابعة القراءة'), findsOneWidget);
      expect(find.text('أذكار المساء'), findsNothing);
      await unmount(tester);
    });

    testWidgets('each card and row opens its tab', (tester) async {
      final taps = <(Finder, Type)>[
        (find.byType(NextPrayerCard), PrayerPage),
        (find.byWidgetPredicate((widget) => widget is StripCell && widget.index == 0), PrayerPage),
        (find.byType(VerseCard), QuranPage),
        (find.text('Continue reading'), QuranPage),
        (find.text('Evening azkar'), AzkarPage),
      ];
      for (final (target, page) in taps) {
        await pumpHome(tester, designOverrides());
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();

        expect(find.byType(page), findsOneWidget, reason: '$target');
        expect(find.byType(HomePage), findsNothing);
        await unmount(tester);
      }
    });
  });

  testWidgets('with no location: no sun, no labels, no NOW, no strip, the two choices (US4)', (
    tester,
  ) async {
    await pumpHome(tester, testOverrides());

    expect(find.text('No location yet'), findsOneWidget);
    expect(find.byType(NoLocationCard), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Choose a city instead'), findsOneWidget);
    expect(find.byType(NowBlock), findsNothing);
    expect(find.byType(PrayerStrip), findsNothing);
    expect(find.byType(SkyLabels), findsNothing);
    expect(find.byType(VerseCard), findsOneWidget);
    expect(find.byType(ShortcutsCard), findsOneWidget);
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((paint) => paint.painter)
        .whereType<SkyHeaderPainter>()
        .single;
    expect(painter.sunFraction, isNull);
    await unmount(tester);
  });

  group('readable for everyone (US5)', () {
    for (final locale in [const Locale('en'), const Locale('ar')]) {
      for (final scale in [1.5, 2.0]) {
        testWidgets('${locale.languageCode} at $scale stacks the card and the strip', (
          tester,
        ) async {
          await pumpHome(tester, designOverrides(), locale: locale, textScale: scale);

          final name = find.descendant(
            of: find.byType(NextPrayerCard),
            matching: find.byWidgetPredicate(
              (widget) => widget is RegularText && widget.text == Prayer.maghrib.nameKey,
            ),
          );
          expect(
            tester.getTopLeft(find.byType(Countdown)).dy,
            greaterThanOrEqualTo(tester.getBottomLeft(name).dy),
          );
          expect(find.byType(StripRow), findsNWidgets(5));

          /// the arc and its labels move under the text instead of crossing it (SC-005)
          final text = tester.getRect(find.byType(NowBlock));
          for (final label
              in find
                  .descendant(of: find.byType(SkyLabels), matching: find.byType(Text))
                  .evaluate()) {
            expect(tester.getRect(find.byWidget(label.widget)).top, greaterThan(text.bottom));
          }
          await unmount(tester);
        });
      }
    }

    testWidgets('24 hour times fit the strip cells, 12 hour phones get rows', (tester) async {
      bool cut(Finder text) => tester.renderObject<RenderParagraph>(text).didExceedMaxLines;

      await pumpHome(tester, designOverrides());
      expect(find.byType(StripCell), findsNWidgets(5));
      for (final time in ['04:58', '12:05', '15:27', '17:56', '19:26']) {
        expect(cut(find.text(time)), isFalse, reason: time);
      }
      await unmount(tester);

      await pumpHome(tester, designOverrides(), use24: false);
      expect(find.byType(StripRow), findsNWidgets(5));

      /// intl puts a narrow no-break space before PM
      expect(cut(find.text('12:05\u202fPM')), isFalse);
      expect(find.text('5:56\u202fPM'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('a screen reader hears hours and minutes, not every tick', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpHome(tester, designOverrides());

      /// the card is one button, so the countdown's label is read as part of it
      final card = find.bySemanticsLabel(RegExp('1 h 24 min until Maghrib'));
      expect(card, findsOneWidget);
      expect(tester.getSemantics(card).label, isNot(contains('1:24:00')));
      expect(tester.getSemantics(card).flagsCollection.isLiveRegion, isFalse);
      semantics.dispose();
      await unmount(tester);
    });

    testWidgets('with reduce motion the digits change with no animation', (tester) async {
      await pumpHome(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32)));
      await tester.runAsync(
        () =>
            containerOf(tester)
                .read(databaseProvider)
                .updateSettings(const SettingsCompanion(reduceMotion: Value(true))),
      );
      await tester.pumpAndSettle();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(countdown(tester), isNot('1:24:00'));
      expect(tester.hasRunningAnimations, isFalse);
      await unmount(tester);
    });
  });
}
