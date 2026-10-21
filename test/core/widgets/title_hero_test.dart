import 'package:better_muslim/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/more.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUp(mockSystemChannel);

  /// the flight's two texts sit in the shuttle's FittedBoxes, the heroes themselves have none
  Finder shuttle(String text) =>
      find.ancestor(of: find.text(text), matching: find.byType(FittedBox));

  testWidgets('the qibla tile\'s label flies into the bar, growing on the way', (tester) async {
    await pumpMore(tester, await designOverrides());
    final from = tester.getSize(find.text('Qibla'));

    await tester.tap(find.text('Qibla'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(shuttle('Qibla'), findsNWidgets(2));
    final mid = tester.getSize(shuttle('Qibla').first);

    await tester.pumpAndSettle();
    expect(shuttle('Qibla'), findsNothing);
    final to = tester.getSize(find.text('Qibla'));
    expect(to.height, greaterThan(from.height));
    expect(mid.height, inExclusiveRange(from.height, to.height));

    containerOf(tester).read(routerProvider).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(shuttle('Qibla'), findsNWidgets(2), reason: 'the way back flies too');
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('a row and its page share one tag, so theme flies from more', (tester) async {
    await pumpMore(tester, await designOverrides());
    await scrollTo(tester, 'Theme');
    await tester.tap(find.text('Theme'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(shuttle('Theme'), findsNWidgets(2));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((w) => w is Hero && w.tag == Routes.theme), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('reduce motion: no flight, the heroes are off', (tester) async {
    await pumpMore(tester, await designOverrides(), reduceMotion: true);
    expect(
      tester.widget<HeroMode>(
        find.ancestor(of: find.byType(Hero).first, matching: find.byType(HeroMode)).first,
      ),
      isA<HeroMode>().having((mode) => mode.enabled, 'enabled', false),
    );

    await tester.tap(find.text('Qibla'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(shuttle('Qibla'), findsNothing);
    await tester.pumpAndSettle();
    await unmount(tester);
  });

  testWidgets('a source scrolled off screen gives no flight, the title waits in the bar', (
    tester,
  ) async {
    await pumpMore(tester, await designOverrides());
    await scrollTo(tester, 'Version');
    final tile = find.byWidgetPredicate((w) => w is Hero && w.tag == Routes.qibla);
    expect(tester.getRect(tile).bottom, lessThan(0), reason: 'still built, above the screen');

    containerOf(tester).read(routerProvider).push(Routes.qibla);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final mid = tester.getRect(shuttle('Qibla').last);
    await tester.pumpAndSettle();
    expect(mid, tester.getRect(find.text('Qibla')));
    await unmount(tester);
  });
}
