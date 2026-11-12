import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/home/view/widgets/sky_labels.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

import 'providers.dart';

/// the app on home at 393 x 852 like the PNGs, on a 24 hour phone unless a test says otherwise
Future<void> pumpHome(
  WidgetTester tester,
  List<Override> overrides, {
  Size size = const Size(393, 852),
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  bool use24 = true,
  bool reduceMotion = false,
  bool settle = true,
  Widget app = const App(),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localesTestValue = [locale];
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearAllTestValues);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MediaQuery(
        data: MediaQueryData.fromView(tester.view).copyWith(
          alwaysUse24HourFormat: use24,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduceMotion,
        ),
        child: app,
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Location makkah() => Location(
  latitude: 21.4225,
  longitude: 39.8262,
  placeName: 'Makkah',
  placeNameAr: 'مكة المكرمة',
  countryCode: 'SA',
  zone: tz.getLocation('Asia/Riyadh'),
  mode: LocationMode.auto,
);

/// makkah with the real calculation (maghrib is 17:56 there too) and a clock that moves with the
/// test's fake time
List<Override> makkahAt(
  WidgetTester tester,
  DateTime start, {
  BmThemeId? theme,
  List<Override> extra = const [],
}) {
  final origin = tester.binding.clock.now();
  return [
    ...testOverrides(theme: theme),
    clockProvider.overrideWithValue(() => start.add(tester.binding.clock.now().difference(origin))),
    locationProvider.overrideWithValue(makkah()),
    ...extra,
  ];
}

/// the arc labels home paints right now, with their text and whether it is a time only label.
/// the flow keeps both labels of a point and paints one, so this asks its delegate
List<({Rect rect, String text, bool short})> skyLabels(WidgetTester tester) {
  final finder = find.descendant(of: find.byType(SkyLabels), matching: find.byType(Flow));
  if (finder.evaluate().isEmpty) return [];
  final flow = tester.widget<Flow>(finder);
  final delegate = flow.delegate as SkyLabelsFlow;
  final box = tester.renderObject<RenderFlow>(finder);
  final sizes = <Size>[];
  box.visitChildren((child) => sizes.add((child as RenderBox).size));
  final offsets = delegate.place(box.size, sizes);
  return [
    for (var i = 0; i < offsets.length; i++)
      if (offsets[i] case final offset?)
        (
          rect: box.localToGlobal(offset) & sizes[i],
          text: tester
              .widget<Text>(
                find.descendant(of: find.byWidget(flow.children[i]), matching: find.byType(Text)),
              )
              .data!,
          short: delegate.slots[i].short,
        ),
  ];
}
