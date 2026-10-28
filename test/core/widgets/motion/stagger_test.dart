import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/motion/skeleton.dart';
import 'package:better_muslim/core/widgets/motion/stagger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widgets.dart';

double _opacity(WidgetTester tester, String text) => tester
    .widget<FadeTransition>(
      find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)).first,
    )
    .opacity
    .value;

Widget _rows(int count) => Column(
  children: [for (var i = 0; i < count; i++) BmStagger(index: i, child: Text('row $i'))],
);

void main() {
  testWidgets('rows start 30 ms apart, past the eighth with the eighth', (tester) async {
    await pumpCoreWidget(tester, _rows(10), settle: false);
    await tester.pump(BmMotion.staggerStep * 2 + const Duration(milliseconds: 15));

    expect(_opacity(tester, 'row 0'), greaterThan(0));
    expect(_opacity(tester, 'row 2'), greaterThan(0));
    expect(_opacity(tester, 'row 3'), 0);

    await tester.pump(BmMotion.staggerStep * 5);
    expect(_opacity(tester, 'row 7'), greaterThan(0));
    expect(_opacity(tester, 'row 9'), _opacity(tester, 'row 7'));

    await tester.pumpAndSettle();
    expect(_opacity(tester, 'row 9'), 1);
  });

  testWidgets('it runs once per screen, a row built later just shows', (tester) async {
    await pumpCoreWidget(tester, _rows(2), settle: false);
    await tester.pumpAndSettle();
    await pumpCoreWidget(tester, _rows(3), settle: false);

    expect(_opacity(tester, 'row 2'), 1);
  });

  testWidgets('reduce motion shows every row at once', (tester) async {
    await pumpCoreWidget(tester, _rows(3), reduceMotion: true, settle: false);
    expect(_opacity(tester, 'row 2'), 1);
  });

  testWidgets('the skeleton hands over in one 150 ms crossfade', (tester) async {
    Widget box(bool loading) => BmSkeletonSwitch(
      loading: loading,
      skeleton: const BmSkeleton(height: 20),
      child: const Text('content'),
    );
    await pumpCoreWidget(tester, box(true), settle: false);
    await pumpCoreWidget(tester, box(false), settle: false);
    await tester.pump(BmMotion.micro ~/ 2);
    expect(find.byType(BmSkeleton), findsOneWidget);
    expect(find.text('content'), findsOneWidget);

    await tester.pump(BmMotion.micro ~/ 2 + const Duration(milliseconds: 1));
    expect(find.byType(BmSkeleton), findsNothing);
  });
}
