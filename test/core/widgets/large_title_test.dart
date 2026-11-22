import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/more.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUp(mockSystemChannel);

  /// the button row and the large title at the design's 393 pt, where ScreenUtil scales by 1
  const collapseAt = SizeManager.hit + FontSizeManager.largeTitle * LineHeightManager.largeTitle;

  Finder title() => find.descendant(of: find.byType(LargeTitle), matching: find.text('More'));

  double pixels(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels;

  double subtitle(WidgetTester tester) => tester
      .widget<CustomOpacity>(
        find.descendant(of: find.byType(LargeTitleSubtitle), matching: find.byType(CustomOpacity)),
      )
      .opacity;

  Offset bar(WidgetTester tester) =>
      Offset(tester.getSize(find.byType(LargeTitleScrollView)).width / 2, SizeManager.appBar / 2);

  testWidgets('the title follows the finger to the bar, shrinking on the way', (tester) async {
    await pumpMore(tester, await designOverrides());
    final rest = tester.getRect(title());

    final gesture = await tester.startGesture(tester.getCenter(find.text('Qibla')));
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
    }
    final progress = pixels(tester) / collapseAt;
    expect(progress, inExclusiveRange(.2, .8));

    final mid = tester.getRect(title());
    final expected = Offset.lerp(rest.center, bar(tester), progress)!;
    expect(mid.center.dx, closeTo(expected.dx, 1));
    expect(mid.center.dy, closeTo(expected.dy, 1));
    final scale = 1 + (FontSizeManager.title / FontSizeManager.largeTitle - 1) * progress;
    expect(mid.width / rest.width, closeTo(scale, .02));
    expect(subtitle(tester), closeTo((1 - progress / .5).clamp(0, 1), .01));

    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(tester.getRect(title()).center.dy, greaterThan(mid.center.dy), reason: 'back reverses');
    await gesture.up();
    await unmount(tester);
  });

  testWidgets('at the bar the flying title becomes the bar title in one frame', (tester) async {
    await pumpMore(tester, await designOverrides());
    final barTitle = find.descendant(of: find.byType(CompactAppBar), matching: find.text('More'));
    double shown(Finder text) => tester
        .widgetList(find.ancestor(of: text, matching: find.byWidgetPredicate((_) => true)))
        .fold(
          1,
          (total, widget) => switch (widget) {
            CustomOpacity(:final opacity) || AnimatedOpacity(:final opacity) => total * opacity,
            _ => total,
          },
        );

    final gesture = await tester.startGesture(tester.getCenter(find.text('Qibla')));

    /// past the touch slop first, it eats the start of a drag
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveBy(Offset(0, -(collapseAt - 1 - pixels(tester))));
    await tester.pump();
    final flying = find.descendant(of: find.byType(LargeTitle), matching: find.text('More')).last;
    final before = tester.getCenter(flying);

    /// a point before the end, so a pt or two of the move is left
    expect(before.dx, closeTo(tester.getCenter(barTitle).dx, 2));
    expect(before.dy, closeTo(tester.getCenter(barTitle).dy, 2));
    expect(shown(barTitle), 0);

    await gesture.moveBy(const Offset(0, -2));
    await tester.pump();
    expect(shown(barTitle), 1, reason: 'no fade, the title never blinks');
    expect(shown(title().first), 0);
    await gesture.up();
    await unmount(tester);
  });

  testWidgets('let go half way, it snaps to the nearer end', (tester) async {
    await pumpMore(tester, await designOverrides());
    await tester.drag(find.text('Qibla'), const Offset(0, -(collapseAt * .7 + 20)));
    await tester.pumpAndSettle();
    expect(pixels(tester), closeTo(collapseAt, .5));
    expect(find.byType(CompactAppBar), findsOneWidget);
    expect(
      tester
          .getCenter(find.descendant(of: find.byType(CompactAppBar), matching: find.text('More')))
          .dy,
      closeTo(bar(tester).dy, 1),
      reason: 'the bar holds the title',
    );

    await tester.drag(find.text('Qibla'), const Offset(0, collapseAt * .8));
    await tester.pumpAndSettle();
    expect(pixels(tester), 0);
    expect(subtitle(tester), 1);
    await unmount(tester);
  });

  testWidgets('after a language switch the title flies from its new side', (tester) async {
    await pumpMore(tester, await designOverrides());
    await writeSettings(tester, const SettingsCompanion(language: Value(Language.arabic)));
    Finder large() =>
        find.descendant(of: find.byType(LargeTitle), matching: find.byType(Text)).first;
    final rest = tester.getRect(large());
    expect(rest.center.dx, greaterThan(bar(tester).dx), reason: 'arabic rests on the right');

    final gesture = await tester.startGesture(tester.getCenter(find.byType(Scrollable).first));
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
    }
    final progress = pixels(tester) / collapseAt;
    final expected = Offset.lerp(rest.center, bar(tester), progress)!;
    expect(tester.getRect(large()).center.dx, closeTo(expected.dx, 1));
    await gesture.up();
    await unmount(tester);
  });

  testWidgets('reduce motion: the title scrolls with the list, no moving layer', (tester) async {
    await pumpMore(tester, await designOverrides(), reduceMotion: true);
    expect(
      find.descendant(of: find.byType(LargeTitle), matching: find.byType(Transform)),
      findsNothing,
    );
    final rest = tester.getRect(title());

    await tester.drag(find.text('Qibla'), const Offset(0, -60));
    await tester.pumpAndSettle();
    expect(pixels(tester), greaterThan(0), reason: 'no snap either');
    expect(tester.getRect(title()).top, closeTo(rest.top - pixels(tester), 1));
    await unmount(tester);
  });
}
