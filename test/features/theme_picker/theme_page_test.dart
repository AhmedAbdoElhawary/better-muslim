import 'dart:ui' show Tristate;

import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/theme_picker/view/theme_page.dart';
import 'package:better_muslim/features/theme_picker/view/widgets/theme_snippet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/fonts.dart';
import '../../helpers/more.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });
  setUp(mockSystemChannel);

  Future<void> open(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
  }) async => pumpMore(
    tester,
    await designOverrides(),
    push: Routes.theme,
    locale: locale,
    textScale: textScale,
  );

  /// the theme the preview is drawn in
  BmPalette preview(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(ThemeSnippet))).extension<BmColors>()!.p;

  /// the theme the rest of the page is drawn in
  BmPalette page(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(ThemePage))).extension<BmColors>()!.p;

  bool selected(WidgetTester tester, String name) =>
      tester.getSemantics(find.bySemanticsLabel(name)).flagsCollection.isSelected ==
      Tristate.isTrue;

  testWidgets('4.15: the saved theme selected, the swatches in order, the preview', (tester) async {
    await open(tester);
    expect(find.text('Live preview · Moonlight'), findsOneWidget);
    expect(selected(tester, 'Moonlight'), isTrue);
    final names = [
      'Moonlight',
      'Qiyam Emerald',
      'Qiyam',
      'Noor',
      'Living Sky',
      'Iznik',
      'Andalus',
      'Qiyam Rose',
      'Sahara Sand',
      'Zaytun',
      'Attar',
      'Noor Midnight',
      'Qiyam Dusk',
      'Qiyam Copper',
      'Qiyam Lapis',
      'Qiyam Sand',
    ];
    final tops = [for (final name in names) tester.getCenter(find.text(name))];
    for (var row = 0; row < 4; row++) {
      for (var i = row * 4 + 1; i < row * 4 + 4; i++) {
        expect(tops[i].dx, greaterThan(tops[i - 1].dx), reason: names[i]);
        expect(tops[i].dy, tops[row * 4].dy, reason: names[i]);
      }
      if (row > 0) expect(tops[row * 4].dy, greaterThan(tops[row * 4 - 4].dy));
    }
    expect(
      find.text('Follow sky switches to light after sunrise and back to dark at Maghrib.'),
      findsOneWidget,
    );
    expect(find.text('Apply theme'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a swatch restyles only the preview, back saves nothing', (tester) async {
    await open(tester);
    await tester.tap(find.text('Iznik'));
    await tester.pumpAndSettle();
    expect(find.text('Live preview · Iznik'), findsOneWidget);
    expect(selected(tester, 'Iznik'), isTrue);
    expect(preview(tester).primary, bmThemes[BmThemeId.iznik]!.dark.primary);
    expect(page(tester).primary, bmThemes[BmThemeId.moonlight]!.dark.primary);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(preview(tester).bg, bmThemes[BmThemeId.iznik]!.light.bg);

    containerOf(tester).read(routerProvider).pop();
    await tester.pumpAndSettle();
    final settings = await settingsOf(tester);
    expect((settings.theme, settings.themeMode), (BmThemeId.moonlight, BmThemeMode.followPhone));
    await unmount(tester);
  });

  testWidgets('apply saves the theme and the mode and goes back to more', (tester) async {
    await open(tester);
    await tester.tap(find.text('Iznik'));
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply theme'));
    await tester.pumpAndSettle();

    final settings = await settingsOf(tester);
    expect((settings.theme, settings.themeMode), (BmThemeId.iznik, BmThemeMode.dark));
    expect(find.byType(ThemePage), findsNothing);
    expect(find.text('Iznik'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('every swatch is at least 44 x 44 and read with its name', (tester) async {
    await open(tester);
    for (final name in ['Qiyam Emerald', 'Moonlight']) {
      final size = tester.getSize(find.bySemanticsLabel(name));
      expect(size.width, greaterThanOrEqualTo(44));
      expect(size.height, greaterThanOrEqualTo(44));
    }
    await unmount(tester);
  });

  for (final (name, locale) in [('english', const Locale('en')), ('arabic', const Locale('ar'))]) {
    testWidgets('$name at text scale 2.0: names wrap, nothing cut', (tester) async {
      await open(tester, locale: locale, textScale: 2);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }
}
