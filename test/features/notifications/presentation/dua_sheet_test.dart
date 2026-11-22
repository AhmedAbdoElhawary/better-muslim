import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/notifications/data/dua_after_adhan.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_page.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/dua_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/notifications.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  setUp(muteAdhanChannel);

  Future<FakePlayer> openDua(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    final player = FakePlayer();
    await pumpHome(tester, [
      ...await designOverrides(),
      adhanPlayerProvider.overrideWithValue(player),
    ], locale: locale);
    containerOf(tester)
        .read(routerProvider)
        .push(Routes.adhan(Prayer.maghrib, DateTime(2026, 10, 15)));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.textContaining(locale.languageCode == 'ar' ? 'اقرأ' : 'Read dua'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return player;
  }

  testWidgets('english shows the title, source, arabic, transliteration and translation', (
    tester,
  ) async {
    final player = await openDua(tester);

    final sheet = find.byType(DuaSheet);
    expect(sheet, findsOneWidget);
    for (final text in [
      'After the adhan',
      DuaAfterAdhan.sourceEn,
      DuaAfterAdhan.arabic,
      DuaAfterAdhan.transliteration,
      DuaAfterAdhan.translation,
    ]) {
      expect(
        find.descendant(of: sheet, matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }

    /// closing the sheet goes back to the adhan, still playing
    Navigator.of(tester.element(sheet)).pop();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DuaSheet), findsNothing);
    expect(find.byType(AdhanPage), findsOneWidget);
    expect(player.stops, 0);
    await unmount(tester);
  });

  testWidgets('arabic shows only the arabic and its source', (tester) async {
    await openDua(tester, locale: const Locale('ar'));

    final sheet = find.byType(DuaSheet);
    expect(find.descendant(of: sheet, matching: find.text(DuaAfterAdhan.arabic)), findsOneWidget);
    expect(find.descendant(of: sheet, matching: find.text(DuaAfterAdhan.sourceAr)), findsOneWidget);
    expect(
      find.descendant(of: sheet, matching: find.text(DuaAfterAdhan.transliteration)),
      findsNothing,
    );
    expect(
      find.descendant(of: sheet, matching: find.text(DuaAfterAdhan.translation)),
      findsNothing,
    );
    await unmount(tester);
  });
}
