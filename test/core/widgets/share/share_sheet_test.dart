import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/widgets/share/share_frame.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fonts.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/widgets.dart';

/// records every layout call, the card is one plain box
class _Content extends ShareContent {
  _Content({this.note});

  final String? note;
  final asked = <ShareOptions>[];

  @override
  String get title => 'shareAyah';

  @override
  String get file => 'test.png';

  @override
  String footer(BuildContext context) => 'Al-Fatiha · 5';

  @override
  ShareLayout layout(BuildContext context, ShareOptions options) {
    asked.add(options);
    return (size: options.size, scale: 1, fits: true, note: note);
  }

  @override
  Widget build(BuildContext context, ShareOptions options, ShareLayout layout) =>
      const SizedBox.square(key: Key('card'), dimension: 100);
}

void main() {
  setUpAll(loadAppFonts);

  Future<void> pumpSheet(
    WidgetTester tester,
    _Content content, {
    List<Widget> rows = const [],
    double textScale = 1,
  }) => pumpCoreWidget(
    tester,
    ProviderScope(
      overrides: testOverrides(),
      child: ShareSheet(content: content, rows: rows),
    ),
    textScale: textScale,
  );

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).first);
    await tester.pumpAndSettle();
  }

  Finder inFrame(Finder finder) => find.descendant(of: find.byType(ShareFrame), matching: finder);

  /// the footer draws the app mark as an svg too
  final pattern = inFrame(
    find.byWidgetPredicate(
      (widget) =>
          widget is SvgPicture &&
          (widget.bytesLoader as SvgAssetLoader).assetName.startsWith('assets/ornaments/'),
    ),
  );

  testWidgets('solid color shows only on a gradient', (tester) async {
    await pumpSheet(tester, _Content());
    expect(find.text('Solid color'), findsNothing, reason: 'paper');
    await tap(tester, 'Ocean');
    expect(find.text('Solid color'), findsOneWidget);
    await tap(tester, 'Deep Sea');
    expect(find.text('Solid color'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a size tap locks the size', (tester) async {
    final content = _Content();
    await pumpSheet(tester, content);
    expect(content.asked.last.sizeLocked, isFalse);
    await tap(tester, 'Story');
    expect((content.asked.last.size, content.asked.last.sizeLocked), (ShareSize.story, true));
    await unmount(tester);
  });

  testWidgets("the layout's note shows under the preview, the rows come last", (tester) async {
    await pumpSheet(
      tester,
      _Content(note: 'Tafsir hidden for 1 ayah'),
      rows: const [SizedBox(key: Key('row'), height: 10)],
    );
    expect(find.text('Tafsir hidden for 1 ayah'), findsOneWidget);
    expect(find.byKey(const Key('row')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('row'))).dy,
      greaterThan(tester.getTopLeft(find.text('Show app name')).dy),
    );
    await unmount(tester);
  });

  testWidgets('text scale 2.0 never reaches the card', (tester) async {
    await pumpSheet(tester, _Content(), textScale: 2);
    final card = tester.element(find.byKey(const Key('card')));
    expect(MediaQuery.textScalerOf(card), TextScaler.noScaling);
    await unmount(tester);
  });

  testWidgets('a font pick lays the card out again with it', (tester) async {
    final content = _Content();
    await pumpSheet(tester, content);
    expect(content.asked.last.font, QuranFont.kfgqpc);
    await tap(tester, 'Scheherazade');
    expect(content.asked.last.font, QuranFont.scheherazade);
    await unmount(tester);
  });

  testWidgets('ornament on draws one pattern under the text, off none', (tester) async {
    await pumpSheet(tester, _Content());
    expect(pattern, findsNothing);
    await tap(tester, 'Ornament');
    expect(pattern, findsOneWidget);
    expect(find.text('Khatam'), findsOneWidget);
    await tap(tester, 'Star and cross');
    expect(pattern, findsOneWidget);
    await tap(tester, 'Ornament');
    expect(pattern, findsNothing);
    await unmount(tester);
  });

  testWidgets('solid on a gradient fills with its middle color', (tester) async {
    await pumpSheet(tester, _Content());
    await tap(tester, 'Ocean');
    await tap(tester, 'Solid color');
    final fill = inFrame(find.byType(ShareBackgroundFill));
    expect(
      tester.widget<ColoredBox>(find.descendant(of: fill, matching: find.byType(ColoredBox))).color,
      ShareBackground.ocean.solidOf(),
    );
    await unmount(tester);
  });

  testWidgets('each ornament svg still draws after its metadata was stripped', (tester) async {
    for (final ornament in ShareOrnament.values) {
      await pumpCoreWidget(
        tester,
        SizedBox.square(dimension: 200, child: SvgPicture.asset(ornament.asset)),
      );
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: ornament.name);
      expect(find.byType(SvgPicture), findsOneWidget);
    }
  });
}
