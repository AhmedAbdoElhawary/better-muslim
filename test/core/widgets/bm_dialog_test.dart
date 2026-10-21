import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widgets.dart';

void main() {
  Future<Future<bool>> open(
    WidgetTester tester, {
    String cancel = StringsManager.cancel,
    bool destructive = true,
  }) async {
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
            cancel: cancel,
            destructive: destructive,
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

  Color? actionFill(WidgetTester tester, String text) {
    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text(text), matching: find.byType(DecoratedBox)).first,
    );
    return (box.decoration as BoxDecoration).color;
  }

  testWidgets('the action is tinted red by default', (tester) async {
    await open(tester);
    final error = bmThemes[BmThemeId.qiyamEmerald]!.dark.error;
    expect(actionFill(tester, 'Reset'), error.withValues(alpha: .16));
  });

  testWidgets('a plain action and its own cancel, for the reset notice', (tester) async {
    final answer = await open(tester, cancel: StringsManager.startFresh, destructive: false);
    expect(find.text('Start fresh'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
    expect(actionFill(tester, 'Reset'), isNull);
    await tester.tap(find.text('Start fresh'));
    await tester.pumpAndSettle();
    expect(await answer, isFalse);
  });

  group('the way in (FR-034)', () {
    Future<void> tapOpen(WidgetTester tester, {bool reduceMotion = false}) async {
      await pumpCoreWidget(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showBmDialog(
              context,
              title: StringsManager.resetJourneyTitle,
              body: StringsManager.resetJourneyBody,
              action: StringsManager.reset,
            ),
            child: const SizedBox.square(dimension: 44),
          ),
        ),
        reduceMotion: reduceMotion,
      );
      await tester.tap(find.byType(TextButton));
      await tester.pump();
    }

    Finder scale() => find.ancestor(
      of: find.text('Reset prayer journey?'),
      matching: find.byType(ScaleTransition),
    );

    double opacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('Reset prayer journey?'),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    testWidgets('scales from a little larger to its size while it fades in', (tester) async {
      await tapOpen(tester);
      expect(tester.widget<ScaleTransition>(scale()).scale.value, BmMotion.dialogFrom);
      expect(opacity(tester), 0);

      await tester.pump(BmMotion.standard);
      expect(tester.widget<ScaleTransition>(scale()).scale.value, 1);
      expect(opacity(tester), 1);

      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(BmMotion.micro);
      expect(opacity(tester), 0, reason: 'out in 150 ms');
      expect(tester.widget<ScaleTransition>(scale()).scale.value, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('reduce motion fades in 150 ms with no scale', (tester) async {
      await tapOpen(tester, reduceMotion: true);
      expect(scale(), findsNothing);
      await tester.pump(BmMotion.micro);
      expect(opacity(tester), 1);
    });
  });
}
