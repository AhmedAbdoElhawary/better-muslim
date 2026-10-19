import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/more.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUp(mockSystemChannel);

  bool picked(WidgetTester tester, String title) => tester
      .widget<PickerRow>(find.ancestor(of: find.text(title), matching: find.byType(PickerRow)))
      .selected;

  testWidgets('three rows with follow sky picked, a pick saves and closes', (tester) async {
    await pumpMore(tester, await designOverrides());
    await tapText(tester, 'Light and dark');

    expect(find.byType(PickerRow), findsNWidgets(3));
    expect(picked(tester, 'Dark'), isFalse);
    expect(picked(tester, 'Light'), isFalse);
    expect(
      find.text('Follow sky switches to light after sunrise and back to dark at Maghrib.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(find.byType(PickerRow), findsNothing);
    expect((await settingsOf(tester)).themeMode, BmThemeMode.light);
    expect(find.text('Light'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('Light'))).brightness, Brightness.light);
    await unmount(tester);
  });

  testWidgets('arabic', (tester) async {
    await pumpMore(tester, await designOverrides(), locale: const Locale('ar'));
    await tapText(tester, 'الفاتح والداكن');
    expect(find.byType(PickerRow), findsNWidgets(3));
    await unmount(tester);
  });
}
