import 'package:better_muslim/core/widgets/sliding_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widgets.dart';

void main() {
  late ValueNotifier<int> selected;
  setUp(() => selected = ValueNotifier(0));

  const highlight = Key('highlight');

  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool reduceMotion = false,
  }) async {
    await pumpCoreWidget(
      tester,
      ValueListenableBuilder(
        valueListenable: selected,
        builder: (context, index, _) => SlidingSelection(
          selected: index,
          highlight: const ColoredBox(key: highlight, color: Color(0xFF000000)),
          layout: (children) => Row(mainAxisSize: MainAxisSize.min, children: children),
          children: [
            for (final index in [0, 1, 2]) SizedBox(key: ValueKey(index), width: 100, height: 40),
          ],
        ),
      ),
      locale: locale,
      reduceMotion: reduceMotion,
    );
  }

  Rect rectOf(WidgetTester tester) => tester.getRect(find.byKey(highlight));
  Rect itemOf(WidgetTester tester, int index) => tester.getRect(find.byKey(ValueKey(index)));

  testWidgets('the highlight moves over frames from the old item to the new one', (tester) async {
    await pump(tester);
    expect(rectOf(tester), itemOf(tester, 0));

    selected.value = 2;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = rectOf(tester).left;
    expect(mid, inExclusiveRange(itemOf(tester, 0).left, itemOf(tester, 2).left));

    await tester.pumpAndSettle();
    expect(rectOf(tester).left, moreOrLessEquals(itemOf(tester, 2).left, epsilon: .01));
  });

  testWidgets('a new pick mid way turns from where it is', (tester) async {
    await pump(tester);
    selected.value = 2;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final mid = rectOf(tester).left;

    selected.value = 0;
    await tester.pump();
    await tester.pump();
    expect(rectOf(tester).left, moreOrLessEquals(mid, epsilon: 20));
    await tester.pump(const Duration(milliseconds: 16));
    expect(rectOf(tester).left, inExclusiveRange(itemOf(tester, 0).left, itemOf(tester, 2).left));

    await tester.pumpAndSettle();
    expect(rectOf(tester).left, moreOrLessEquals(itemOf(tester, 0).left, epsilon: .01));
  });

  testWidgets('reduce motion: it jumps', (tester) async {
    await pump(tester, reduceMotion: true);
    selected.value = 2;
    await tester.pump();
    await tester.pump();
    expect(rectOf(tester), itemOf(tester, 2));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('in arabic the first item is on the right', (tester) async {
    await pump(tester, locale: const Locale('ar'));
    expect(rectOf(tester), itemOf(tester, 0));
    expect(itemOf(tester, 0).left, greaterThan(itemOf(tester, 2).left));
  });
}
