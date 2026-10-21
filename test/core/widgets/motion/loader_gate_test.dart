import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/motion/loader_gate.dart';
import 'package:better_muslim/core/widgets/motion/oil_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widgets.dart';

const _ms = Duration(milliseconds: 1);

Future<void> _gate(WidgetTester tester, {required bool loading, bool second = false}) =>
    pumpCoreWidget(
      tester,
      Column(
        children: [
          BmLoaderGate(loading: loading, child: const Text('ready')),
          if (second) BmLoaderGate(loading: loading, child: const Text('second')),
        ],
      ),
      settle: false,
    );

void main() {
  tearDown(() => expect(BmLoaderGate.showing, 0));

  testWidgets('a wait under 400 ms shows no loader', (tester) async {
    await _gate(tester, loading: true);
    await tester.pump(BmMotion.loaderDelay - _ms);
    await _gate(tester, loading: false);
    await tester.pump(BmMotion.loaderDelay);

    expect(find.byType(BmOilDrop), findsNothing);
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('the loader shows at 400 ms and ends with its cycle', (tester) async {
    await _gate(tester, loading: true);
    await tester.pump(BmMotion.loaderDelay);
    expect(find.byType(BmOilDrop), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 100));
    await _gate(tester, loading: false);
    await tester.pump(BmMotion.loaderMinimum);
    expect(find.byType(BmOilDrop), findsOneWidget, reason: 'no sooner than 600 ms');

    await tester.pump(
      BmMotion.oilCycle - BmMotion.loaderMinimum - const Duration(milliseconds: 101),
    );
    expect(find.byType(BmOilDrop), findsOneWidget, reason: 'only at the end of a cycle');
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.byType(BmOilDrop), findsNothing);
    expect(find.text('ready'), findsOneWidget);
  });

  testWidgets('a second gate never shows its own loader', (tester) async {
    await _gate(tester, loading: true, second: true);
    await tester.pump(BmMotion.loaderDelay);
    expect(find.byType(BmOilDrop), findsOneWidget);

    await _gate(tester, loading: false, second: true);
    await tester.pump(BmMotion.oilCycle);
    expect(find.text('second'), findsOneWidget);
  });
}
