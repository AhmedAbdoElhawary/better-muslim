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

  testWidgets('the label, a 1 pt outline2 ring, at least 44 tall, obscured', (tester) async {
    await pumpCoreWidget(
      tester,
      BmTextField(label: StringsManager.password, obscure: true, onChanged: (_) {}),
    );
    expect(find.text('Password'), findsOneWidget);
    expect(ring(tester).top.color, palette.outlineStrong);
    expect(ring(tester).top.width, 1);
    expect(tester.widget<TextField>(find.byType(TextField)).obscureText, isTrue);
    expect(tester.getSize(find.byType(TextField)).height, greaterThanOrEqualTo(20));
    final box = find.ancestor(of: find.byType(TextField), matching: find.byType(ConstrainedBox));
    expect(tester.getSize(box.first).height, greaterThanOrEqualTo(44));
  });

  testWidgets('focused: a 2 pt primary ring', (tester) async {
    await pumpCoreWidget(tester, BmTextField(label: StringsManager.password, onChanged: (_) {}));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(ring(tester).top.color, palette.primary);
    expect(ring(tester).top.width, 2);
  });

  testWidgets('an error: its line and a 2 pt error ring', (tester) async {
    await pumpCoreWidget(
      tester,
      BmTextField(
        label: StringsManager.password,
        error: StringsManager.passwordTooShort,
        errorArgs: const {'count': '6'},
        onChanged: (_) {},
      ),
    );
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(ring(tester).top.color, palette.error);
    expect(ring(tester).top.width, 2);
  });

  testWidgets('arabic', (tester) async {
    await pumpCoreWidget(
      tester,
      BmTextField(
        label: StringsManager.confirmPassword,
        error: StringsManager.passwordsDontMatch,
        onChanged: (_) {},
      ),
      locale: const Locale('ar'),
      textScale: 2,
    );
    expect(find.text('تأكيد كلمة المرور'), findsOneWidget);
    expect(find.text('كلمتا المرور غير متطابقتين.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
