import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/fonts.dart';
import '../../helpers/more.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });
  setUp(mockSystemChannel);

  Future<void> open(WidgetTester tester, {Locale locale = const Locale('en')}) async =>
      pumpMore(tester, await designOverrides(), locale: locale);

  Future<void> openSheet(WidgetTester tester) async {
    await tapText(tester, 'Hijri date adjustment');
    expect(
      find.text('Move the Hijri date to match the moon sighting where you live.'),
      findsOneWidget,
    );
  }

  Finder plus() => find.bySemanticsLabel('+');
  Finder minus() => find.bySemanticsLabel('−');

  testWidgets('steps stop at −2 and +2 and show today for each step', (tester) async {
    await open(tester);
    await openSheet(tester);
    expect(find.text('4 Jumada I 1448'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(plus());
      await tester.pumpAndSettle();
    }
    expect(find.text('+2 days'), findsOneWidget);
    expect(find.text('6 Jumada I 1448'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.tap(minus());
      await tester.pumpAndSettle();
    }
    expect(find.text('−2 days'), findsOneWidget);
    expect(find.text('2 Jumada I 1448'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('save keeps it and the row shows it, closing without save changes nothing', (
    tester,
  ) async {
    await open(tester);
    await openSheet(tester);
    await tester.tap(plus());
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('+1 day'))).pop();
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).hijriAdjust, 0);

    await openSheet(tester);
    await tester.tap(plus());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect((await settingsOf(tester)).hijriAdjust, 1);
    await tester.pumpAndSettle();
    expect(find.text('+1 day'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('arabic', (tester) async {
    await open(tester, locale: const Locale('ar'));
    await tapText(tester, 'تعديل التاريخ الهجري');
    await tester.tap(plus());
    await tester.pumpAndSettle();
    expect(find.text('+١ يوم'), findsOneWidget);
    await unmount(tester);
  });
}
