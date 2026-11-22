import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/widgets.dart';

void main() {
  late ValueNotifier<int> shown;
  setUp(() => shown = ValueNotifier(0));

  Future<void> pump(
    WidgetTester tester, {
    AxisDirection from = AxisDirection.down,
    Locale locale = const Locale('en'),
    bool reduceMotion = false,
  }) => pumpCoreWidget(
    tester,
    ValueListenableBuilder(
      valueListenable: shown,
      builder: (context, id, _) => BmSwitcher(
        from: from,
        child: SizedBox(key: ValueKey(id), width: 100, height: 40.0 * (id + 1), child: Text('$id')),
      ),
    ),
    locale: locale,
    reduceMotion: reduceMotion,
  );

  Offset offsetOf(WidgetTester tester, String text) {
    final transform = tester.widget<Transform>(
      find.ancestor(of: find.text(text), matching: find.byType(Transform)).first,
    );
    final translation = transform.transform.getTranslation();
    return Offset(translation.x, translation.y);
  }

  double opacityOf(WidgetTester tester, String text) => tester
      .widget<FadeTransition>(
        find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)).first,
      )
      .opacity
      .value;

  double heightOf(WidgetTester tester) => tester.getSize(find.byType(AnimatedSize)).height;

  testWidgets('a new child slides in from below while the old one fades, the box grows', (
    tester,
  ) async {
    await pump(tester);
    shown.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(offsetOf(tester, '1').dy, moreOrLessEquals((BmMotion.shift * 2).r, epsilon: .5));

    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(offsetOf(tester, '1').dy, inExclusiveRange(0, (BmMotion.shift * 2).r));
    expect(heightOf(tester), inExclusiveRange(40, 80));

    await tester.pumpAndSettle();
    expect(find.text('0'), findsNothing);
    expect(offsetOf(tester, '1'), Offset.zero);
    expect(heightOf(tester), 80);
  });

  testWidgets('a third child mid swap takes over from where the second is', (tester) async {
    await pump(tester);
    shown.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final mid = opacityOf(tester, '1');
    expect(mid, inExclusiveRange(0, 1));

    shown.value = 2;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(opacityOf(tester, '1'), inExclusiveRange(0, mid));
    expect(find.text('2'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNothing);
  });

  testWidgets('reduce motion: a 150 ms fade, no slide, the size jumps', (tester) async {
    await pump(tester, reduceMotion: true);
    shown.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      find.descendant(of: find.byType(BmSwitcher), matching: find.byType(Transform)),
      findsNothing,
    );
    expect(find.byType(AnimatedSize), findsNothing);
    expect(tester.getSize(find.byType(AnimatedSwitcher)).height, 80);

    await tester.pump(BmMotion.micro);
    expect(find.text('0'), findsNothing);
    expect(opacityOf(tester, '1'), 1);
  });

  for (final (locale, sign) in [(const Locale('en'), -1), (const Locale('ar'), 1)]) {
    testWidgets('from the start side in ${locale.languageCode} comes from x $sign', (tester) async {
      await pump(tester, from: AxisDirection.left, locale: locale);
      shown.value = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      final offset = offsetOf(tester, '1');
      expect(offset.dx.sign, sign);
      expect(offset.dy, 0);
    });
  }
}
