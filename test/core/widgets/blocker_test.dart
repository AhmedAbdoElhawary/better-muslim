import 'dart:async';

import 'package:better_muslim/core/widgets/blocker.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/widgets.dart';

void main() {
  testWidgets('the loader covers the screen, taps and back wait until the task is done', (
    tester,
  ) async {
    final task = Completer<bool>();
    var taps = 0;
    bool? result;
    await pumpCoreWidget(
      tester,
      Builder(
        builder: (context) => Column(
          children: [
            TextButton(onPressed: () => taps++, child: const Text('behind')),
            TextButton(
              onPressed: () async => result = await whileBlocked(context, () => task.future),
              child: const Text('start'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('start'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BmStarLoader), findsOneWidget);

    await tester.tap(find.text('behind'), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 200));
    expect(taps, 0);
    expect(find.byType(BmStarLoader), findsOneWidget);

    task.complete(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(BmStarLoader), findsNothing);
    expect(result, isTrue);

    await tester.tap(find.text('behind'));
    expect(taps, 1);
  });
}
