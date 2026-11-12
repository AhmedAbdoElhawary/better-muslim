import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'home.dart';
import 'prayer.dart';

/// the app at 393 x 852 on the more tab, or a page pushed from it
Future<void> pumpMore(
  WidgetTester tester,
  List<Override> overrides, {
  String? push,
  Size size = const Size(393, 852),
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  bool reduceMotion = false,
}) async {
  await pumpHome(
    tester,
    overrides,
    size: size,
    locale: locale,
    brightness: brightness,
    textScale: textScale,
    reduceMotion: reduceMotion,
    settle: false,
  );
  await tester.pump();
  final router = containerOf(tester).read(routerProvider);
  router.go(Routes.more);
  await tester.pumpAndSettle();
  if (push != null) {
    router.push(push);
    await tester.pumpAndSettle();
  }
}

/// what the page asked the phone through better_muslim/system
List<MethodCall> mockSystemChannel({
  String version = '1.0.0 (12)',
  bool opened = true,
  bool mailed = true,
}) {
  final calls = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('better_muslim/system'),
    (call) async {
      calls.add(call);
      return switch (call.method) {
        'version' => version,
        'openUrl' => opened,
        'mail' => mailed,
        'device' => {'model': 'Google Pixel 8', 'os': 'Android 16'},
        _ => null,
      };
    },
  );
  return calls;
}

/// centers the text in the list that holds it, at the top the compact bar would cover it
Future<void> scrollTo(WidgetTester tester, String text) async {
  await Scrollable.ensureVisible(tester.element(find.text(text)), alignment: .5);
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await scrollTo(tester, text);
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

/// the store's row, read outside the test's fake time like every store call
Future<AppSettings> settingsOf(WidgetTester tester) async {
  final db = dbOf(tester);
  return (await tester.runAsync(() => db.select(db.settings).getSingle()))!;
}

/// a store write outside the test's fake time, then the screens catch up
Future<void> writeSettings(WidgetTester tester, SettingsCompanion values) async {
  await tester.runAsync(() => dbOf(tester).updateSettings(values));
  await tester.pumpAndSettle();
}
