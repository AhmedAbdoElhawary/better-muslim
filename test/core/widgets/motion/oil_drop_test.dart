import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/widgets/motion/oil_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widgets.dart';

BmOilDropPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byWidgetPredicate((w) => w is CustomPaint && w.painter is BmOilDropPainter),
            )
            .painter!
        as BmOilDropPainter;

void main() {
  testWidgets('the drop falls at 48 pt and not at 16 pt', (tester) async {
    await pumpCoreWidget(tester, const BmOilDrop(), settle: false);
    expect(_painter(tester).showDrop, isTrue);

    await pumpCoreWidget(tester, const BmOilDrop(size: SizeManager.oilDropSmall), settle: false);
    expect(_painter(tester).showDrop, isFalse);
  });

  testWidgets('reduce motion has no drop and no wave, the sun pulses on the cycle', (tester) async {
    await pumpCoreWidget(tester, const BmOilDrop(), reduceMotion: true, settle: false);
    final painter = _painter(tester);
    expect(painter.showDrop, isFalse);
    expect(painter.reduce, isTrue);
    final wave = painter.wave.value;
    await tester.pump(BmMotion.oilCycle ~/ 3);
    expect(painter.wave.value, wave);

    expect(BmOilDropPainter.sunOpacity(0), 1);
    expect(BmOilDropPainter.sunOpacity(.5), closeTo(.45, .001));
    expect(BmOilDropPainter.sunOpacity(1), 1);
    for (var t = 0.0; t <= 1; t += .05) {
      expect(BmOilDropPainter.sunOpacity(t), inInclusiveRange(.45 - 1e-9, 1));
    }
  });

  testWidgets('a new progress springs the pool toward it', (tester) async {
    await pumpCoreWidget(tester, const BmOilDrop(progress: .2), settle: false);
    final painter = _painter(tester);
    expect(painter.level.value, .2);

    await pumpCoreWidget(tester, const BmOilDrop(progress: .8), settle: false);
    await tester.pump(const Duration(milliseconds: 100));
    expect(painter.level.value, inExclusiveRange(.2, .8));
    await tester.pump(const Duration(seconds: 2));
    expect(painter.level.value, closeTo(.8, .01));
  });

  testWidgets('it reads as Loading, with the percent when it has one', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpCoreWidget(tester, const BmOilDrop(progress: .36), settle: false);
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(tester.getSemantics(find.bySemanticsLabel('Loading')).value, '36%');
    semantics.dispose();
  });
}
