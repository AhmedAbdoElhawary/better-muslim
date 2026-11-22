import 'dart:ui';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/azkar.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/dua_text.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:better_muslim/features/azkar/view/widgets/dhikr_text.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/azkar.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  int? badge(WidgetTester tester) => tester.widget<NavBar>(find.byType(NavBar)).badge;

  testWidgets('the large title and the three rows with their progress', (tester) async {
    await pumpAzkar(tester, await designOverrides());

    expect(find.text('Azkar'), findsWidgets);
    for (final text in [
      'Morning azkar',
      'After Fajr · 0 of 23',
      'Evening azkar',
      'After Asr · 0 of 20',
      'Tasbih',
      'After prayer',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    await unmount(tester);
  });

  for (final (row, path) in [
    ('Morning azkar', '/azkar/morning'),
    ('Evening azkar', '/azkar/evening'),
    ('Tasbih', Routes.tasbih),
  ]) {
    testWidgets('$row opens $path in the tab', (tester) async {
      await pumpAzkar(tester, await designOverrides());
      await tester.tap(find.text(row));
      await tester.pumpAndSettle();

      expect(pathOf(tester), path);
      expect(find.byType(NavBar), findsOneWidget);
      await unmount(tester);
    });
  }

  testWidgets('the badge shows until the evening set is opened (FR-002)', (tester) async {
    await pumpAzkar(tester, await designOverrides());
    expect(badge(tester), 3);

    await tester.tap(find.text('Evening azkar'));
    await tester.pumpAndSettle();
    expect(badge(tester), isNull);

    await tester.tap(find.byType(BarBackButton));
    await tester.pumpAndSettle();
    expect(badge(tester), isNull);
    await unmount(tester);
  });

  testWidgets('the badge comes back when fajr opens the morning window', (tester) async {
    /// 04:40 in makkah, before home's glow starts breathing for fajr
    await pumpAzkar(tester, makkahAt(tester, DateTime.utc(2026, 10, 16, 1, 40)));
    await dbOf(tester)
        .updateSettings(SettingsCompanion(eveningOpenedOn: Value(DateTime(2026, 10, 15))));
    await tester.pumpAndSettle();
    expect(badge(tester), isNull);

    await tester.pump(const Duration(minutes: 25));
    await tester.pump();
    expect(badge(tester), 3);
    await unmount(tester);
  });

  testWidgets('the reminders switch is on, a flip writes it with the selection haptic', (
    tester,
  ) async {
    final phone = recordPhone();
    await pumpAzkar(tester, await designOverrides());
    expect(find.text('Azkar reminders'), findsOneWidget);
    expect(find.text('20 min after Fajr and Asr'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(ToggleRow).first).flagsCollection.isToggled,
      Tristate.isTrue,
    );

    await tester.tap(find.text('Azkar reminders'));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(settingsProvider).value!.azkarNudges, isFalse);
    expect(phone.haptics, [selection]);
    await unmount(tester);
  });

  testWidgets('the voice switch is on under the reminders, a flip writes it', (tester) async {
    await pumpAzkar(tester, await designOverrides());
    expect(find.text("Say the azkar's name"), findsOneWidget);
    expect(find.text('A calm voice with the reminder'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(ToggleRow).last).flagsCollection.isToggled,
      Tristate.isTrue,
    );

    await tester.tap(find.text("Say the azkar's name"));
    await tester.pumpAndSettle();
    final settings = containerOf(tester).read(settingsProvider).value!;
    expect(settings.azkarVoice, isFalse);
    expect(settings.azkarNudges, isTrue);
    await unmount(tester);
  });

  testWidgets('azkar and tasbih take the stored azkar font, verses keep the quran font', (
    tester,
  ) async {
    await pumpAzkar(tester, await designOverrides());
    Set<FontEnum> fontsIn(Type owner) => {
      for (final text in tester.widgetList<RegularText>(
        find.descendant(of: find.byType(owner), matching: find.byType(RegularText)),
      ))
        text.font,
    };

    await dbOf(tester).updateSettings(const SettingsCompanion(azkarFont: Value(AzkarFont.naskh)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning azkar'));
    await tester.pumpAndSettle();
    expect(fontsIn(DuaText), contains(FontEnum.kfgqpc));

    /// the third is the first that isn't a verse
    for (var i = 0; i < 2; i++) {
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
    }
    expect(fontsIn(DuaText), contains(FontEnum.naskh));
    expect(fontsIn(DuaText), isNot(contains(FontEnum.dua)));

    containerOf(tester).read(routerProvider).go(Routes.tasbih);
    await tester.pumpAndSettle();
    expect(fontsIn(DhikrText), contains(FontEnum.naskh));
    await unmount(tester);
  });

  testWidgets('no badge without a location', (tester) async {
    await pumpAzkar(tester, testOverrides());

    expect(badge(tester), isNull);
    await unmount(tester);
  });
}
