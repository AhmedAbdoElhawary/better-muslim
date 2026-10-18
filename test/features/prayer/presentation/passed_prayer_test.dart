import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  final thursday = DateTime(2026, 10, 15);

  /// the scenario at 16:32 with dhuhr not logged
  Future<void> pumpPassedDhuhr(WidgetTester tester) async {
    await pumpPrayer(tester, await designOverrides());
    await dbOf(tester).unmarkPrayed(thursday, Prayer.dhuhr);
    await tester.pumpAndSettle();
  }

  Finder dhuhr(String text) => inRow(Prayer.dhuhr, find.text(text));
  Finder option(String text) =>
      find.descendant(of: find.byType(PickerRow), matching: find.text(text));

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// the toast lives 4 s
  Future<void> toastGone(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('a passed prayer offers both paths in a sheet', (tester) async {
    await pumpPassedDhuhr(tester);

    expect(dhuhr('Add to qada'), findsOneWidget);
    await tapAndSettle(tester, dhuhr('Add to qada'));

    expect(find.text('Dhuhr has passed'), findsOneWidget);
    expect(find.text("You can add it to your qada list whenever you're ready."), findsOneWidget);
    expect(option('I prayed it'), findsOneWidget);
    expect(option('Add to qada'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('"I prayed it" logs it with no toast', (tester) async {
    await pumpPassedDhuhr(tester);

    await tapAndSettle(tester, dhuhr('Add to qada'));
    await tapAndSettle(tester, option('I prayed it'));

    expect(dhuhr('Prayed'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('2 of 5 prayed today'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('add to qada shows in qada and a toast, undo takes it back', (tester) async {
    await pumpPassedDhuhr(tester);

    await tapAndSettle(tester, dhuhr('Add to qada'));
    await tapAndSettle(tester, option('Add to qada'));
    expect(dhuhr('In qada'), findsOneWidget);
    expect(find.text('Dhuhr added to qada'), findsOneWidget);
    expect(find.text('4 missed this month to make up'), findsOneWidget);

    await tapAndSettle(tester, find.text('Undo'));
    expect(dhuhr('Add to qada'), findsOneWidget);
    expect(find.text('3 missed this month to make up'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('tapping in qada removes it with a toast, undo puts it back (FR-009)', (
    tester,
  ) async {
    await pumpPassedDhuhr(tester);
    await tapAndSettle(tester, dhuhr('Add to qada'));
    await tapAndSettle(tester, option('Add to qada'));
    await toastGone(tester);

    await tapAndSettle(tester, dhuhr('In qada'));
    expect(dhuhr('Add to qada'), findsOneWidget);
    expect(find.text('Dhuhr removed from qada'), findsOneWidget);

    await tapAndSettle(tester, find.text('Undo'));
    expect(dhuhr('In qada'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a made up entry shows made up, and a tap changes nothing', (tester) async {
    await pumpPassedDhuhr(tester);
    final qada = containerOf(tester).read(qadaRepositoryProvider);
    await qada.add(thursday, Prayer.dhuhr);
    await qada.makeUpOldest(Prayer.dhuhr);
    await tester.pumpAndSettle();

    expect(dhuhr('Made up'), findsOneWidget);
    await tapAndSettle(tester, dhuhr('Made up'));
    expect(dhuhr('Made up'), findsOneWidget);
    expect(find.byType(PickerRow), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
    await unmount(tester);
  });
}
