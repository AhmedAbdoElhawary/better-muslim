import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widgets.dart';

void main() {
  final palette = bmThemes[BmThemeId.qiyamEmerald]!.dark;

  Border ring(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(BmTextField), matching: find.byType(DecoratedBox)).first,
    );
    return (box.decoration as BoxDecoration).border! as Border;
  }

  testWidgets('the label, a 1 pt outline2 ring, at least 44 tall', (tester) async {
    await pumpCoreWidget(tester, BmTextField(label: StringsManager.note, onChanged: (_) {}));
    expect(find.text('Note'), findsOneWidget);
    expect(ring(tester).top.color, palette.outlineStrong);
    expect(ring(tester).top.width, 1);
    expect(tester.getSize(find.byType(TextField)).height, greaterThanOrEqualTo(20));
    final box = find.ancestor(of: find.byType(TextField), matching: find.byType(ConstrainedBox));
    expect(tester.getSize(box.first).height, greaterThanOrEqualTo(44));
  });

  testWidgets('focused: a 2 pt primary ring', (tester) async {
    await pumpCoreWidget(tester, BmTextField(label: StringsManager.note, onChanged: (_) {}));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(ring(tester).top.color, palette.primary);
    expect(ring(tester).top.width, 2);
  });

  testWidgets('an error: its line and a 2 pt error ring', (tester) async {
    await pumpCoreWidget(
      tester,
      BmTextField(
        label: StringsManager.bookmarkName,
        error: StringsManager.categoryHint,
        onChanged: (_) {},
      ),
    );
    expect(find.text('Category name'), findsOneWidget);
    expect(ring(tester).top.color, palette.error);
    expect(ring(tester).top.width, 2);
  });

  testWidgets('arabic', (tester) async {
    await pumpCoreWidget(
      tester,
      BmTextField(label: StringsManager.note, error: StringsManager.noteHint, onChanged: (_) {}),
      locale: const Locale('ar'),
      textScale: 2,
    );
    expect(find.text('ملاحظة'), findsOneWidget);
    expect(find.text('اكتب ملاحظة خاصة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
