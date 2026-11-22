import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:better_muslim/features/prayer/presentation/view/qada_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/qada_row.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/summary_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  Finder qadaRow(Prayer prayer) =>
      find.byWidgetPredicate((widget) => widget is QadaRow && widget.prayer == prayer);
  Finder inQadaRow(Prayer prayer, Finder matching) =>
      find.descendant(of: qadaRow(prayer), matching: matching);
  Finder plus(Prayer prayer) => inQadaRow(
    prayer,
    find.byWidgetPredicate((widget) => widget is BmIcon && widget.asset.endsWith('ui/plus.svg')),
  );
  Finder sheetIcon(String name) =>
      find.byWidgetPredicate((widget) => widget is BmIcon && widget.asset.endsWith('ui/$name.svg'));

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> openList(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await pumpPrayer(tester, await designOverrides(), locale: locale);
    await tapAndSettle(tester, find.byType(SummaryCard));
  }

  testWidgets('the card leads to the list with the open counts (FR-017, FR-018)', (tester) async {
    await openList(tester);

    expect(find.byType(QadaPage), findsOneWidget);
    expect(
      find.descendant(of: find.byType(CompactAppBar), matching: find.text('Qada list')),
      findsOneWidget,
    );
    expect(find.text('3 to make up'), findsOneWidget);
    for (final (prayer, left) in [
      (Prayer.fajr, 2),
      (Prayer.dhuhr, 0),
      (Prayer.asr, 0),
      (Prayer.maghrib, 0),
      (Prayer.isha, 1),
    ]) {
      expect(inQadaRow(prayer, find.text('$left left')), findsOneWidget, reason: prayer.name);
    }
    await unmount(tester);
  });

  testWidgets('arabic counts use their plural form', (tester) async {
    await openList(tester, locale: const Locale('ar'));

    expect(find.text('٣ صلوات للقضاء'), findsOneWidget);
    expect(inQadaRow(Prayer.fajr, find.text('بقي ٢')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('made one up is disabled at 0', (tester) async {
    await openList(tester);

    await tapAndSettle(tester, inQadaRow(Prayer.dhuhr, find.text('Made one up')));
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('3 to make up'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('made one up on isha, and undo (FR-019)', (tester) async {
    await openList(tester);

    await tapAndSettle(tester, inQadaRow(Prayer.isha, find.text('Made one up')));
    expect(find.text('Isha made up'), findsOneWidget);
    expect(inQadaRow(Prayer.isha, find.text('0 left')), findsOneWidget);

    await tapAndSettle(tester, find.bySemanticsLabel('Back'));
    expect(find.text('2 missed this month to make up'), findsOneWidget);
    expect(find.text('Isha made up'), findsOneWidget);

    await tapAndSettle(tester, find.text('Undo'));
    expect(find.text('3 missed this month to make up'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('+ adds older prayers from 1 to 999, and undo removes the batch (FR-020)', (
    tester,
  ) async {
    await openList(tester);

    await tapAndSettle(tester, plus(Prayer.fajr));
    expect(find.text('Add missed Fajr'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tapAndSettle(tester, sheetIcon('minus'));
    expect(find.text('1'), findsOneWidget);

    final hold = await tester.startGesture(tester.getCenter(sheetIcon('plus').last));
    await tester.pump(const Duration(seconds: 2));
    final held = int.parse(
      tester.widgetList<Text>(find.textContaining(RegExp(r'^\d+$'))).first.data!,
    );
    expect(held, greaterThan(10));
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await hold.up();
    await tester.pumpAndSettle();
    expect(find.text('999'), findsOneWidget);

    /// a new sheet starts at 1 again
    Navigator.of(tester.element(find.text('999'))).pop();
    await tester.pumpAndSettle();
    await tapAndSettle(tester, plus(Prayer.fajr));
    await tapAndSettle(tester, sheetIcon('plus').last);
    expect(find.text('2'), findsOneWidget);

    await tapAndSettle(tester, find.text('Add'));
    expect(inQadaRow(Prayer.fajr, find.text('4 left')), findsOneWidget);
    expect(find.text('5 to make up'), findsOneWidget);
    expect(find.text('Fajr added to qada'), findsOneWidget);

    await tapAndSettle(tester, find.text('Undo'));
    expect(inQadaRow(Prayer.fajr, find.text('2 left')), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('older prayers never count in this month', (tester) async {
    await pumpPrayer(tester, await designOverrides());
    final qada = containerOf(tester).read(qadaRepositoryProvider);
    await qada.addOlder(Prayer.fajr, 4);
    await tester.pumpAndSettle();

    expect(find.text('3 missed this month to make up'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('with nothing open this month the card says so (FR-016)', (tester) async {
    await pumpPrayer(tester, await designOverrides());
    final qada = containerOf(tester).read(qadaRepositoryProvider);
    for (final prayer in [Prayer.fajr, Prayer.fajr, Prayer.isha]) {
      await qada.makeUpOldest(prayer);
    }
    await tester.pumpAndSettle();

    expect(find.text('Nothing to make up this month'), findsOneWidget);
    await unmount(tester);
  });
}
