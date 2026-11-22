import 'package:better_muslim/core/prayer_times/prayer_method.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/home.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(tz.initializeTimeZones);
  setUpAll(loadAppFonts);

  final haptics = <String>[];
  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
        return null;
      },
    );
  });

  Finder row(String title) =>
      find.byWidgetPredicate((widget) => widget is PickerRow && widget.title == title);
  bool selected(WidgetTester tester, Finder finder) => tester.widget<PickerRow>(finder).selected;

  /// makkah at 16:32 with the real calculation and no picks
  Future<void> openSheet(WidgetTester tester) async {
    await pumpPrayer(tester, makkahAt(tester, DateTime.utc(2026, 10, 15, 13, 32)));
    await tester.tap(
      find
          .byWidgetPredicate(
            (widget) => widget is BmIcon && widget.asset.endsWith('outline/settings.svg'),
          )
          .first,
    );
    await tester.pumpAndSettle();
  }

  /// the sheet's list builds only what is on screen
  Future<void> reveal(WidgetTester tester, Finder finder, {double delta = 100}) async {
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      finder,
      delta,
      scrollable: find
          .ancestor(of: find.byType(PickerRow).first, matching: find.byType(Scrollable))
          .first,
    );
  }

  Future<void> pick(WidgetTester tester, Finder finder, {double delta = 100}) async {
    await reveal(tester, finder, delta: delta);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<AppSettingsPicks> picks(WidgetTester tester) async {
    final settings = await containerOf(tester).read(settingsProvider.future);
    return (method: settings.method, asr: settings.asrMethod);
  }

  testWidgets('by country is selected with its method, then the 11, then asr (FR-023)', (
    tester,
  ) async {
    await openSheet(tester);

    final byCountry = row('byCountry').first;
    expect(selected(tester, byCountry), isTrue);
    expect(tester.widget<PickerRow>(byCountry).value, PrayerMethod.ummAlQura.nameKey);
    expect(find.text('Chosen for your country'), findsWidgets);
    for (final method in PrayerMethod.values) {
      await reveal(tester, row(method.nameKey));
      expect(row(method.nameKey), findsOneWidget, reason: method.name);
    }
    await reveal(tester, row('asrHanafi'));
    expect(find.text('ASR CALCULATION'), findsOneWidget);
    expect(row('asrStandard'), findsOneWidget);
    expect(selected(tester, row('byCountry').last), isTrue);
    expect(tester.widget<PickerRow>(row('byCountry').last).value, AsrMethod.standard.nameKey);
    await unmount(tester);
  });

  testWidgets('a pick is kept, the subtitle follows, by country clears it (FR-024)', (
    tester,
  ) async {
    await openSheet(tester);

    await pick(tester, row(PrayerMethod.muslimWorldLeague.nameKey));
    expect((await picks(tester)).method, PrayerMethod.muslimWorldLeague);
    expect(find.text('Makkah · Muslim World League'), findsOneWidget);
    expect(selected(tester, row(PrayerMethod.muslimWorldLeague.nameKey)), isTrue);

    final methodByCountry = find.byWidgetPredicate(
      (widget) =>
          widget is PickerRow &&
          widget.title == 'byCountry' &&
          widget.value == PrayerMethod.ummAlQura.nameKey,
    );
    await pick(tester, methodByCountry, delta: -100);
    expect((await picks(tester)).method, isNull);
    expect(find.text('Makkah · Umm al-Qura'), findsOneWidget);
    expect(haptics, everyElement('HapticFeedbackType.selectionClick'));
    expect(haptics, hasLength(2));
    await unmount(tester);
  });

  testWidgets('hanafi asr is kept and moves asr later', (tester) async {
    await openSheet(tester);
    final before = containerOf(tester).read(todayTimesProvider)!.asr!;

    await pick(tester, row('asrHanafi'));

    expect((await picks(tester)).asr, AsrMethod.hanafi);
    expect(containerOf(tester).read(todayTimesProvider)!.asr!.isAfter(before), isTrue);
    await unmount(tester);
  });

  testWidgets('reset is off on the defaults, then puts both back to by country', (tester) async {
    await openSheet(tester);
    final reset = find.text('Reset');
    expect(
      tester
          .widget<AnimatedOpacity>(find.ancestor(of: reset, matching: find.byType(AnimatedOpacity)))
          .opacity,
      lessThan(1),
    );

    await pick(tester, row(PrayerMethod.muslimWorldLeague.nameKey));
    await pick(tester, row('asrHanafi'));
    await reveal(tester, row('byCountry').first, delta: -100);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    expect(await picks(tester), (method: null, asr: null));
    expect(selected(tester, row('byCountry').first), isTrue);
    await unmount(tester);
  });
}

typedef AppSettingsPicks = ({PrayerMethod? method, AsrMethod? asr});
