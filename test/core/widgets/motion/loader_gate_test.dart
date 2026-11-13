import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/motion/loader_gate.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/widgets.dart';

const _ms = Duration(milliseconds: 1);

Future<void> _gate(WidgetTester tester, {required bool loading, bool instant = false}) =>
    pumpCoreWidget(
      tester,
      BmLoaderGate(loading: loading, instant: instant, child: const Text('ready')),
      settle: false,
    );

/// the switcher's fade starts on the frame after the change, the old child leaves a frame after it
Future<void> _crossfade(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(BmMotion.micro * 2);
}

BmStarPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byWidgetPredicate((w) => w is CustomPaint && w.painter is BmStarPainter),
            )
            .painter!
        as BmStarPainter;

void main() {
  group('the gate', () {
    testWidgets('a wait under 400 ms keeps the child and shows no loader', (tester) async {
      await _gate(tester, loading: true);
      await tester.pump(BmMotion.loaderDelay - _ms);
      expect(find.text('ready'), findsOneWidget);
      await _gate(tester, loading: false);
      await tester.pump(BmMotion.loaderDelay);

      expect(find.byType(BmStarLoader), findsNothing);
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('the star shows at 400 ms and stays at least 600 ms', (tester) async {
      await _gate(tester, loading: true);
      await tester.pump(BmMotion.loaderDelay);
      expect(find.byType(BmStarLoader), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 100));
      await _gate(tester, loading: false);
      await tester.pump(BmMotion.loaderMinimum - const Duration(milliseconds: 101));
      expect(find.byType(BmStarLoader), findsOneWidget, reason: 'no sooner than 600 ms');

      await tester.pump(const Duration(milliseconds: 2));
      await _crossfade(tester);
      expect(find.byType(BmStarLoader), findsNothing);
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('a wait longer than the minimum ends with the wait', (tester) async {
      await _gate(tester, loading: true);
      await tester.pump(BmMotion.loaderDelay + BmMotion.loaderMinimum * 2);
      expect(find.byType(BmStarLoader), findsOneWidget);

      await _gate(tester, loading: false);
      await _crossfade(tester);
      expect(find.byType(BmStarLoader), findsNothing);
      expect(find.text('ready'), findsOneWidget);
    });

    testWidgets('a first load shows the star at once', (tester) async {
      await _gate(tester, loading: false, instant: true);
      await _gate(tester, loading: true, instant: true);
      await _crossfade(tester);
      expect(find.byType(BmStarLoader), findsOneWidget);
      expect(find.text('ready'), findsNothing);

      await tester.pump(BmMotion.loaderMinimum);
      await _gate(tester, loading: false);
      await _crossfade(tester);
      expect(find.text('ready'), findsOneWidget);
    });
  });

  group('the star', () {
    test('the four strokes start at 0, 400, 900 and 1400 ms and each draws for 3.6 s', () {
      for (final (index, start) in BmMotion.starStarts.indexed) {
        expect(BmStarPainter.drawn(index, start), 0, reason: '$index');
        expect(BmStarPainter.drawn(index, start + BmMotion.starDraw ~/ 2), closeTo(.5, 1e-9));
        expect(BmStarPainter.drawn(index, start + BmMotion.starDraw), 1, reason: '$index');
      }
    });

    test('it rests 800 ms after the last stroke, then fades in 400 ms', () {
      const drawn = Duration(milliseconds: 1400 + 3600);
      expect(BmStarPainter.fade(drawn), 1);
      expect(BmStarPainter.fade(drawn + BmMotion.starRest), 1);
      expect(BmStarPainter.fade(drawn + BmMotion.starRest + BmMotion.starFade ~/ 2), .5);
      expect(BmStarPainter.fade(BmMotion.starCycle), 0);
    });

    testWidgets('it loops the cycle', (tester) async {
      await pumpCoreWidget(tester, const BmStarLoader(), settle: false);
      final painter = _painter(tester);
      expect(painter.level, isNull);
      await tester.pump(BmMotion.starCycle ~/ 2);
      expect(painter.loop.value, closeTo(.5, .01));
      await tester.pump(BmMotion.starCycle ~/ 2);
      expect(painter.loop.value, closeTo(0, .01));
    });

    testWidgets('a progress draws the line up to it and stops the loop', (tester) async {
      await pumpCoreWidget(tester, const BmStarLoader(progress: .2), settle: false);
      final painter = _painter(tester);
      expect(painter.level!.value, .2);
      final loop = painter.loop.value;

      await pumpCoreWidget(tester, const BmStarLoader(progress: .8), settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(painter.level!.value, inExclusiveRange(.2, .8));
      await tester.pump(const Duration(seconds: 2));
      expect(painter.level!.value, closeTo(.8, .01));
      expect(painter.loop.value, loop);
    });

    testWidgets('with reduce motion the whole star breathes', (tester) async {
      await pumpCoreWidget(tester, const BmStarLoader(), reduceMotion: true, settle: false);
      final painter = _painter(tester);
      expect(painter.reduce, isTrue);
      await tester.pump(BmMotion.starBreathe);
      expect(painter.loop.value, closeTo(1, .01));
      await tester.pump(BmMotion.starBreathe);
      expect(painter.loop.value, closeTo(0, .01));
    });

    testWidgets('it reads as Loading, with the percent when it has one', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpCoreWidget(tester, const BmStarLoader(progress: .36), settle: false);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Loading')).value, '36%');
      semantics.dispose();
    });
  });
}
