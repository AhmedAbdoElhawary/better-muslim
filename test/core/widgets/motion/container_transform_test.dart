import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/motion/container_transform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

  /// OpenContainer built it on every frame and again where each way ends, the mushaf jank
  testWidgets('the screen is built once, the frames only move it', (tester) async {
    var builds = 0;
    await pumpCoreWidget(
      tester,
      BmContainerTransform(
        closedBuilder: (context, open) => GestureDetector(
          onTap: open,
          child: const SizedBox(height: 60, child: Text('row')),
        ),
        openBuilder: (context) => Builder(
          builder: (context) {
            builds++;
            return const Scaffold(body: Text('page'));
          },
        ),
      ),
    );
    await tester.tap(find.text('row'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('page'))).pop();
    await tester.pumpAndSettle();
    expect(builds, 1);
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
