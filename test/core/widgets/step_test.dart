import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/core/widgets/step/step_dots.dart';
import 'package:better_muslim/core/widgets/step/step_reveal.dart';
import 'package:better_muslim/core/widgets/step/step_scope.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/widgets.dart';

void main() {
  late AnimationController enter;
  late AnimationController covered;
  setUp(() {
    enter = AnimationController(vsync: const TestVSync());
    covered = AnimationController(vsync: const TestVSync());
  });
  tearDown(() {
    enter.dispose();
    covered.dispose();
  });

  Widget slots() => StepScope(
    animation: enter,
    secondaryAnimation: covered,
    child: Column(
      children: [
        for (final slot in StepSlot.values)
          StepReveal(slot: slot, child: const SizedBox.square(dimension: 10)),
      ],
    ),
  );

  double opacityOf(WidgetTester tester, StepSlot slot) => tester
      .widget<CustomOpacity>(
        find.descendant(
          of: find.byWidgetPredicate((widget) => widget is StepReveal && widget.slot == slot),
          matching: find.byType(CustomOpacity),
        ),
      )
      .opacity;

  double riseOf(WidgetTester tester, StepSlot slot) {
    final transform = find.descendant(
      of: find.byWidgetPredicate((widget) => widget is StepReveal && widget.slot == slot),
      matching: find.byType(Transform),
    );
    if (transform.evaluate().isEmpty) return 0;
    return tester.widget<Transform>(transform).transform.getTranslation().y;
  }

  double at(double t, double start, double end) =>
      BmMotion.decelerate.transform(((t - start) / (end - start)).clamp(0, 1));

  testWidgets('without a scope the child is untouched', (tester) async {
    await pumpCoreWidget(
      tester,
      const StepReveal(slot: StepSlot.title, child: SizedBox.square(dimension: 10)),
    );
    expect(find.byType(CustomOpacity), findsNothing);
  });

  testWidgets('each slot fades on its interval, title and buttons rise 14', (tester) async {
    await pumpCoreWidget(tester, slots());
    for (final t in [0.0, .33, .6, 1.0]) {
      enter.value = t;
      await tester.pump();
      expect(opacityOf(tester, StepSlot.background), closeTo(at(t, 0, .33), 1e-6), reason: '$t');
      expect(opacityOf(tester, StepSlot.title), closeTo(at(t, .33, .60), 1e-6), reason: '$t');
      expect(opacityOf(tester, StepSlot.body), closeTo(at(t, .40, .67), 1e-6), reason: '$t');
      expect(opacityOf(tester, StepSlot.cards), closeTo(at(t, .47, .80), 1e-6), reason: '$t');
      expect(opacityOf(tester, StepSlot.buttons), closeTo(at(t, .60, 1), 1e-6), reason: '$t');
      expect(riseOf(tester, StepSlot.title), closeTo((1 - at(t, .33, .60)) * 14.r, 1e-6));
      expect(riseOf(tester, StepSlot.buttons), closeTo((1 - at(t, .60, 1)) * 14.r, 1e-6));
      expect(riseOf(tester, StepSlot.body), 0);
    }
  });

  testWidgets('covered by the next step the content fades in 150 ms, the background stays', (
    tester,
  ) async {
    await pumpCoreWidget(tester, slots());
    enter.value = 1;
    covered.value = .17;
    await tester.pump();
    expect(opacityOf(tester, StepSlot.title), 0);
    expect(opacityOf(tester, StepSlot.buttons), 0);
    expect(opacityOf(tester, StepSlot.background), 1);

    covered.value = .085;
    await tester.pump();
    expect(opacityOf(tester, StepSlot.title), closeTo(.5, 1e-6));
  });

  testWidgets('with reduce motion every slot is a plain fade over the whole', (tester) async {
    await pumpCoreWidget(
      tester,
      MediaQuery(data: const MediaQueryData(disableAnimations: true), child: slots()),
    );
    enter.value = .5;
    await tester.pump();
    for (final slot in StepSlot.values) {
      expect(opacityOf(tester, slot), .5, reason: '$slot');
      expect(riseOf(tester, slot), 0);
    }
  });

  testWidgets('step 2: a small primary, the wide primary, a small outline2', (tester) async {
    final palette = bmThemes[BmThemeId.qiyamEmerald]!.dark;
    final semantics = tester.ensureSemantics();
    await pumpCoreWidget(tester, const StepDots(step: 2));
    final dots = tester
        .widgetList<DecoratedBox>(
          find.descendant(of: find.byType(StepDots), matching: find.byType(DecoratedBox)),
        )
        .map((box) => (box.decoration as BoxDecoration).color)
        .toList();
    expect(dots, [palette.primary, palette.primary, palette.outlineStrong]);
    final sizes = find
        .descendant(of: find.byType(StepDots), matching: find.byType(DecoratedBox))
        .evaluate()
        .map((element) => element.size!.width)
        .toList();
    expect(sizes, [6.r, 22.r, 6.r]);
    expect(find.bySemanticsLabel('Step 2 of 3'), findsOneWidget);
    semantics.dispose();
  });
}
