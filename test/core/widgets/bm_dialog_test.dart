import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widgets.dart';

void main() {
  Future<Future<bool>> open(WidgetTester tester) async {
    late Future<bool> answer;
    await pumpCoreWidget(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => answer = showBmDialog(
            context,
            title: StringsManager.resetJourneyTitle,
            body: StringsManager.resetJourneyBody,
            action: StringsManager.reset,
          ),
          child: const SizedBox.square(dimension: 44),
        ),
      ),
    );
    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();
    return answer;
  }

  testWidgets('title, body, cancel returns false', (tester) async {
    final answer = await open(tester);
    expect(find.text('Reset prayer journey?'), findsOneWidget);
    expect(
      find.text("This clears your private log on this phone. It can't be undone."),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(await answer, isFalse);
  });

  testWidgets('the destructive action returns true, both are 44 tall', (tester) async {
    final answer = await open(tester);
    for (final text in ['Cancel', 'Reset']) {
      final hit = find.ancestor(of: find.text(text), matching: find.byType(GestureDetector));
      expect(tester.getSize(hit.first).height, greaterThanOrEqualTo(44));
    }
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(await answer, isTrue);
  });
}
