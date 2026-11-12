import 'dart:ui' show Tristate;

import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/widgets.dart';

void main() {
  late List<String> haptics;
  setUp(() => haptics = recordHaptics());

  NavRow row({VoidCallback? onTap, bool? toggled}) => NavRow(
    icon: BmIcon.ui(BmUiIcon.palette, size: 20),
    title: StringsManager.theme,
    value: toggled == null ? StringsManager.themeQiyamEmerald : null,
    toggled: toggled,
    onTap: onTap,
  );

  testWidgets('icon, title, value and chevron, the whole row is the target', (tester) async {
    var taps = 0;
    await pumpCoreWidget(tester, row(onTap: () => taps++));
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Qiyam Emerald'), findsOneWidget);
    expect(find.byType(BmIcon), findsNWidgets(2));
    expect(tester.getSize(find.byType(NavRow)).height, greaterThanOrEqualTo(44));

    await tester.tapAt(tester.getTopLeft(find.byType(NavRow)) + const Offset(4, 4));
    expect(taps, 1);
    expect(haptics, isEmpty);

    final semantics = tester.getSemantics(find.byType(NavRow));
    expect(semantics.label, contains('Theme'));
    expect(semantics.label, contains('Qiyam Emerald'));
  });

  testWidgets('the chevron mirrors in arabic', (tester) async {
    await pumpCoreWidget(tester, row(onTap: () {}), locale: const Locale('ar'));
    final flip = tester.widget<Transform>(
      find.ancestor(of: find.byType(BmIcon).last, matching: find.byType(Transform)).first,
    );
    expect(flip.transform.storage.first, -1);
  });

  testWidgets('above text scale 1.4 the value goes under the title', (tester) async {
    await pumpCoreWidget(tester, row(onTap: () {}), textScale: 2);
    expect(
      tester.getTopLeft(find.text('Qiyam Emerald')).dy,
      greaterThan(tester.getBottomLeft(find.text('Theme')).dy - 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a toggle row flips with the selection haptic and reads as a toggle', (tester) async {
    var taps = 0;
    await pumpCoreWidget(tester, row(onTap: () => taps++, toggled: true));
    await tester.tap(find.byType(NavRow));
    expect(taps, 1);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    expect(
      tester.getSemantics(find.byType(NavRow)).flagsCollection.isToggled,
      isNot(Tristate.none),
    );
  });

  testWidgets('no tap draws the value with no chevron', (tester) async {
    await pumpCoreWidget(tester, row());
    expect(find.byType(BmIcon), findsOneWidget);
  });
}
