import 'dart:ui';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/azkar.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  int? badge(WidgetTester tester) => tester.widget<NavBar>(find.byType(NavBar)).badge;

  testWidgets('the large title and the three rows with their progress', (tester) async {
    await pumpAzkar(tester, await designOverrides());

    expect(find.text('Azkar'), findsWidgets);
    for (final text in [
      'Morning azkar',
      'After Fajr · 0 of 12',
      'Evening azkar',
      'After Asr · 0 of 24',
      'Tasbih',
      'After prayer',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    await unmount(tester);
  });

  for (final (row, path) in [
    ('Morning azkar', '/azkar/morning'),
    ('Evening azkar', '/azkar/evening'),
    ('Tasbih', Routes.tasbih),
  ]) {
    testWidgets('$row opens $path in the tab', (tester) async {
      await pumpAzkar(tester, await designOverrides());
      await tester.tap(find.text(row));
      await tester.pumpAndSettle();

      expect(pathOf(tester), path);
      expect(find.byType(NavBar), findsOneWidget);
      await unmount(tester);
    });
  }

  testWidgets('the badge shows until the evening set is opened (FR-002)', (tester) async {
    await pumpAzkar(tester, await designOverrides());
    expect(badge(tester), 3);

    await tester.tap(find.text('Evening azkar'));
    await tester.pumpAndSettle();
    expect(badge(tester), isNull);

    await tester.tap(find.byType(BarBackButton));
    await tester.pumpAndSettle();
    expect(badge(tester), isNull);
    await unmount(tester);
  });

  testWidgets('the badge comes back when fajr opens the morning window', (tester) async {
    /// 04:40 in makkah, before home's glow starts breathing for fajr
    await pumpAzkar(tester, makkahAt(tester, DateTime.utc(2026, 10, 16, 1, 40)));
    await dbOf(tester)
        .updateSettings(SettingsCompanion(eveningOpenedOn: Value(DateTime(2026, 10, 15))));
    await tester.pumpAndSettle();
    expect(badge(tester), isNull);

    await tester.pump(const Duration(minutes: 25));
    await tester.pump();
    expect(badge(tester), 3);
    await unmount(tester);
  });

  testWidgets('the reminders switch is on, a flip writes it with the selection haptic', (
    tester,
  ) async {
    final phone = recordPhone();
    await pumpAzkar(tester, await designOverrides());
    expect(find.text('Azkar reminders'), findsOneWidget);
    expect(find.text('20 min after Fajr and Asr'), findsOneWidget);
    expect(tester.getSemantics(find.byType(ToggleRow)).flagsCollection.isToggled, Tristate.isTrue);

    await tester.tap(find.text('Azkar reminders'));
    await tester.pumpAndSettle();
    expect(containerOf(tester).read(settingsProvider).value!.azkarNudges, isFalse);
    expect(phone.haptics, [selection]);
    await unmount(tester);
  });

  testWidgets('no badge without a location', (tester) async {
    await pumpAzkar(tester, testOverrides());

    expect(badge(tester), isNull);
    await unmount(tester);
  });
}
