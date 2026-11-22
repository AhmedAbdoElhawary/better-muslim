import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/widgets.dart';

void main() {
  final palette = bmThemes[BmThemeId.qiyamEmerald]!.dark;

  testWidgets('the text button: no fill, no border, its color, 44 pt and more', (tester) async {
    var taps = 0;
    await pumpCoreWidget(
      tester,
      BmButton.text(StringsManager.notNow, color: ThemeEnum.onSky, onPressed: () => taps++),
    );
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(BmButton), matching: find.byType(Material)),
    );
    expect(material.type, MaterialType.transparency);
    expect((material.shape! as RoundedRectangleBorder).side, BorderSide.none);
    final text = tester.widget<Text>(find.text('Not now'));
    expect(text.style?.color, palette.onSky);
    expect(tester.getSize(find.byType(BmButton)).height, greaterThanOrEqualTo(44));
    await tester.tap(find.byType(BmButton));
    expect(taps, 1);
  });

  testWidgets('primary by default, busy ignores taps', (tester) async {
    var taps = 0;
    await pumpCoreWidget(
      tester,
      BmButton.text(StringsManager.notNow, busy: true, onPressed: () => taps++),
    );
    expect(tester.widget<Text>(find.text('Not now')).style?.color, palette.primary);
    await tester.tap(find.byType(BmButton));
    expect(taps, 0);
  });

  testWidgets('secondary keeps its outline', (tester) async {
    await pumpCoreWidget(tester, BmButton.secondary(StringsManager.chooseCity, onPressed: () {}));
    final material = tester.widget<Material>(
      find.descendant(of: find.byType(BmButton), matching: find.byType(Material)),
    );
    expect((material.shape! as RoundedRectangleBorder).side.color, palette.outlineStrong);
  });
}
