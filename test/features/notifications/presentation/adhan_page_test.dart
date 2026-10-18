import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
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

  final day = DateTime(2026, 10, 15);
  late List<MethodCall> channel;
  setUp(() => channel = muteAdhanChannel());

  /// the design scenario's moment and times, with a player the test can read
  Future<FakePlayer> openAdhan(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    double textScale = 1,
    bool reduceMotion = false,
    List<Override> extra = const [],
  }) async {
    final player = FakePlayer();
    await pumpHome(
      tester,
      [...await designOverrides(), adhanPlayerProvider.overrideWithValue(player), ...extra],
      locale: locale,
      textScale: textScale,
      reduceMotion: reduceMotion,
    );
    containerOf(tester).read(routerProvider).push(Routes.adhan(Prayer.maghrib, day));

    /// the halo breathes for ever, so no pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    return player;
  }

  testWidgets('shows the 4.03 texts', (tester) async {
    await openAdhan(tester);

    for (final text in [
      'ADHAN · MAKKAH',
      'المغرب',
      'Maghrib',
      '17:56',
      '0:42',
      '2:56',
      'After the adhan',
      'Read dua',
      'Mark prayed',
      'Stop adhan',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    await unmount(tester);
  });

  testWidgets('stop silences the adhan and closes the screen', (tester) async {
    final player = await openAdhan(tester);

    await tester.tap(find.text('Stop adhan'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(player.stops, greaterThanOrEqualTo(1));
    expect(find.byType(AdhanPage), findsNothing);
    await unmount(tester);
  });

  testWidgets('mark prayed logs once, keeps playing and shows prayed', (tester) async {
    final player = await openAdhan(tester);
    final db = dbOf(tester);
    await tester.tap(find.text('Mark prayed'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final rows = await (db.select(
      db.prayerLog,
    )..where((row) => row.prayer.equalsValue(Prayer.maghrib))).get();
    expect(rows.where((row) => row.date == day), hasLength(1));
    expect(find.text('Prayed'), findsOneWidget);
    expect(player.stops, 0);

    await tester.tap(find.text('Prayed'));
    await tester.pump();
    expect(find.text('Prayed'), findsOneWidget);
    expect(channel, hasLength(1));
    await unmount(tester);
  });

  testWidgets('reduce motion fades in and the halo stands still', (tester) async {
    await openAdhan(tester, reduceMotion: true);

    expect(
      find.ancestor(of: find.byType(AdhanPage), matching: find.byType(FadeTransition)),
      findsWidgets,
    );

    /// nothing loops, so the frames settle
    await tester.pumpAndSettle();
    expect(find.byType(AdhanPage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('arabic keeps the progress left to right', (tester) async {
    await openAdhan(tester, locale: const Locale('ar'));

    final elapsed = find.text('٠:٤٢');
    final total = find.text('٢:٥٦');
    expect(tester.getCenter(elapsed).dx, lessThan(tester.getCenter(total).dx));
    expect(find.text('أذان · مكة المكرمة'), findsNothing);
    expect(find.text('Maghrib'), findsNothing);
    await unmount(tester);
  });

  testWidgets('text scale 2.0 cuts nothing', (tester) async {
    await openAdhan(tester, textScale: 2);

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Stop adhan'), 100);
    expect(find.text('Stop adhan').hitTestable(), findsOneWidget);
    await unmount(tester);
  });
}
