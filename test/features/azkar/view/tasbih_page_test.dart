import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:better_muslim/features/azkar/view/widgets/tasbih_counter.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/azkar.dart';
import '../../../helpers/fonts.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';
import '../../../helpers/sounds.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  late ({List<String> haptics, List<String> announcements}) phone;
  setUp(() => phone = recordPhone());

  Future<void> open(WidgetTester tester, {bool reduceMotion = false}) async => pumpAzkar(
    tester,
    await designOverrides(),
    location: Routes.tasbih,
    reduceMotion: reduceMotion,
  );

  final area = find.text('Tap anywhere to count');

  /// frames of 20 ms like a phone, a single long pump would start the springs late
  Future<void> frames(WidgetTester tester, Duration total) async {
    await tester.pump();
    for (var left = total; left > Duration.zero; left -= const Duration(milliseconds: 20)) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  Future<void> tap(WidgetTester tester, int times, {Duration gap = Duration.zero}) async {
    for (var i = 0; i < times; i++) {
      await tester.tap(area);
      await (i < times - 1 ? frames(tester, gap) : tester.pump());
    }
  }

  ({int count, int target}) counter(WidgetTester tester) {
    final widget = tester.widget<TasbihCounter>(find.byType(TasbihCounter));
    return (count: widget.count, target: widget.target);
  }

  testWidgets('the 4.08 copy at subhanallah 16 of 33, in the azkar tab', (tester) async {
    await open(tester);

    for (final text in [
      'Tasbih',
      'After prayer',
      'Alhamdulillah',
      'Allahu Akbar',
      '34',
      'سُبْحَانَ اللَّهِ',
      'Glory be to Allah',
      '16',
      'of 33',
      'Tap anywhere to count',
    ]) {
      expect(find.text(text), findsWidgets, reason: text);
    }
    expect(find.text('SubhanAllah'), findsNWidgets(2));
    expect(find.text('33'), findsNWidgets(2));
    expect(tester.widget<NavBar>(find.byType(NavBar)).index, 3);
    await unmount(tester);
  });

  testWidgets('17 taps finish the set once, the next starts alhamdulillah at 1', (tester) async {
    await open(tester);
    await tap(tester, 17);
    await tester.pumpAndSettle();

    expect(find.text('Set complete'), findsOneWidget);
    expect(find.text('33'), findsWidgets);
    expect(phone.haptics.where((haptic) => haptic == bead), hasLength(17));
    expect(phone.haptics.where((haptic) => haptic == complete), hasLength(2));
    expect(phone.announcements, ['Set complete']);

    await tap(tester, 1);
    await tester.pumpAndSettle();
    expect(counter(tester), (count: 1, target: 33));
    expect(find.text('Alhamdulillah'), findsNWidgets(2));
    expect(find.text('of 33'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('with ui sounds on each count plays the bead and the 33rd the complete', (
    tester,
  ) async {
    final sounds = FakeSoundOutput();
    BmSounds.output = sounds;
    addTearDown(() => BmSounds.enabled = false);
    await open(tester);
    await dbOf(tester).updateSettings(const SettingsCompanion(uiSounds: Value(true)));
    await tester.pumpAndSettle();

    await tap(tester, 17);
    await tester.pumpAndSettle();
    expect(sounds.played.where((asset) => asset.endsWith('ui_bead.m4a')), hasLength(17));
    expect(sounds.played.where((asset) => asset.endsWith('ui_complete.m4a')), hasLength(1));
    await unmount(tester);
  });

  testWidgets('with ui sounds off a count plays nothing', (tester) async {
    final sounds = FakeSoundOutput();
    BmSounds.output = sounds;
    await open(tester);
    await tap(tester, 1);
    await tester.pumpAndSettle();
    expect(sounds.played, isEmpty);
    await unmount(tester);
  });

  testWidgets('the chips, the dhikr and the bar never count, a chip starts from 0', (tester) async {
    await open(tester);
    await tester.tap(find.text('Glory be to Allah'));
    await tester.tap(find.text('After prayer'));
    await tester.pumpAndSettle();
    expect(counter(tester).count, 16);
    expect(phone.haptics, isEmpty);

    await tester.tap(find.text('Allahu Akbar').first);
    await tester.pumpAndSettle();
    expect(counter(tester), (count: 0, target: 34));
    expect(phone.haptics, [selection]);
    await unmount(tester);
  });

  testWidgets('reset goes to subhanallah 0 with a toast, undo brings back the count', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Alhamdulillah').first);
    await tap(tester, 5);
    await tester.tap(find.bySemanticsLabel('Reset count'));
    await tester.pumpAndSettle();
    expect(counter(tester), (count: 0, target: 33));
    expect(find.text('SubhanAllah'), findsNWidgets(2));
    expect(find.text('Count reset'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(counter(tester), (count: 5, target: 33));
    expect(find.text('Alhamdulillah'), findsNWidgets(2));
    await unmount(tester);
  });

  testWidgets('one tap is at rest within 400 ms', (tester) async {
    await open(tester);
    await tap(tester, 1);
    await frames(tester, const Duration(milliseconds: 400));

    expect(tester.binding.hasScheduledFrame, isFalse);
    await unmount(tester);
  });

  testWidgets('20 taps in 2 s count exactly 20, at rest 400 ms after the last (SC-002)', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Alhamdulillah').first);
    await tester.pumpAndSettle();
    phone.haptics.clear();
    await tap(tester, 20, gap: const Duration(milliseconds: 100));

    expect(counter(tester).count, 20);
    expect(phone.haptics, List.filled(20, bead));

    await frames(tester, const Duration(milliseconds: 400));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await unmount(tester);
  });

  testWidgets('a new app start on the same store has the same dhikr and count (FR-016)', (
    tester,
  ) async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final db = await designScenarioStore();
    addTearDown(db.close);
    final overrides = [
      databaseProvider.overrideWithValue(db),
      flavorProvider.overrideWithValue(
        const FlavorConfig(
          flavor: Flavor.dev,
          appName: 'Better Muslim',
          apiBaseUrl: '',
          sentryDsn: '',
          scenario: 'design',
        ),
      ),
      ...designScenarioOverrides(),
      onboardingProvider.overrideWith(() => OnboardingNotifier(done: true)),
    ];
    await pumpAzkar(tester, overrides, location: Routes.tasbih);
    await tester.tap(find.text('Allahu Akbar').first);
    await tap(tester, 3);
    await tester.pumpAndSettle();
    await unmount(tester);

    await pumpAzkar(tester, overrides, location: Routes.tasbih);
    expect(counter(tester), (count: 3, target: 34));
    await unmount(tester);
  });

  testWidgets('reduce motion fills the ring with no burst and nothing left moving', (tester) async {
    await open(tester, reduceMotion: true);
    await tap(tester, 17);
    await tester.pump();

    expect(find.text('Set complete'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);

    /// the set complete haptic's second tap
    await tester.pump(const Duration(milliseconds: 80));
    await unmount(tester);
  });
}
