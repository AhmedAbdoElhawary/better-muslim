import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/motion/container_transform.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/widgets.dart';

const _ms = Duration(milliseconds: 1);

Widget _transform() => BmContainerTransform(
  closedBuilder: (context, open) => GestureDetector(
    onTap: open,
    child: const SizedBox(height: 60, child: Text('row')),
  ),
  openBuilder: (context) => const Scaffold(body: Text('page')),
);

void main() {
  testWidgets('it opens in 520 ms and closes back to the row', (tester) async {
    await pumpCoreWidget(tester, _transform());
    await tester.tap(find.text('row'));
    await tester.pump();
    await tester.pump(BmMotion.containerOpen - _ms);
    final route = ModalRoute.of(tester.element(find.text('page')))!;
    expect(route.animation!.isCompleted, isFalse);
    await tester.pump(_ms * 2);
    expect(route.animation!.isCompleted, isTrue);

    Navigator.of(tester.element(find.text('page'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('page'), findsNothing);
    expect(find.text('row'), findsOneWidget);
  });

  testWidgets('reduce motion is a 150 ms crossfade', (tester) async {
    await pumpCoreWidget(tester, _transform(), reduceMotion: true);
    await tester.tap(find.text('row'));
    await tester.pump();
    await tester.pump(BmMotion.micro + _ms);
    final route = ModalRoute.of(tester.element(find.text('page')))!;
    expect(route.transitionDuration, BmMotion.micro);
    expect(route.animation!.isCompleted, isTrue);
  });
}
