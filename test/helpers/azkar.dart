import 'dart:async';

import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/azkar/azkar_content.dart';
import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'home.dart';
import 'prayer.dart';

/// the app at 393 x 852 on the azkar tab, or at a deep link
Future<void> pumpAzkar(
  WidgetTester tester,
  List<Override> overrides, {
  String location = Routes.azkar,
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

  /// pushed from the tab like a tap would, so back goes to the tab
  router.go(Routes.azkar);
  await tester.pumpAndSettle();
  if (location != Routes.azkar) {
    router.push(location);
    await tester.pumpAndSettle();
  }
}

/// More › Duas at 393 x 852, the way its tile opens it
Future<void> pumpDuas(
  WidgetTester tester,
  List<Override> overrides, {
  Locale locale = const Locale('en'),
  Brightness brightness = Brightness.dark,
  double textScale = 1,
  Size size = const Size(393, 852),
}) async {
  await pumpHome(
    tester,
    overrides,
    size: size,
    locale: locale,
    brightness: brightness,
    textScale: textScale,
    settle: false,
  );
  await tester.pump();
  final router = containerOf(tester).read(routerProvider);
  router.go(Routes.more);
  await tester.pumpAndSettle();
  router.push(Routes.duas);
  await tester.pumpAndSettle();
}

/// plays nothing, remembers what it was asked
class FakeClipPlayer implements ClipPlayer {
  final played = <String>[];
  final ends = <Duration?>[];
  int stops = 0;
  final _ended = StreamController<void>.broadcast();

  @override
  Future<void> play(String asset, {Duration? end}) async {
    played.add(asset);
    ends.add(end);
  }

  @override
  Future<void> stop() async => stops++;

  @override
  Stream<void> get ended => _ended.stream;

  void end() => _ended.add(null);

  @override
  void dispose() => _ended.close();
}

/// the route the app shows now
String pathOf(WidgetTester tester) =>
    containerOf(tester).read(routerProvider).routerDelegate.currentConfiguration.uri.path;

Zikr _zikr(String id, int count, {bool quran = false}) => Zikr(
  id: id,
  arabic: quran ? 'قُلْ هُوَ اللَّهُ أَحَدٌ' : 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
  transliteration: 'Subhan Allahi wa bihamdihi $id',
  translation: 'Glory be to Allah and praise be to Him.',
  source: (en: 'Sahih Muslim 2692', ar: 'صحيح مسلم ٢٦٩٢'),
  grading: (en: 'Sahih', ar: 'صحيح'),
  count: count,
  quran: quran,
);

/// 3 cards a set, said once, three times and once (the last a verse), so a test taps through
const shortCounts = [1, 3, 1];

Override shortAzkar() => azkarContentProvider.overrideWith(
  (ref) => AzkarContent(
    morning: AzkarSetContent(
      minutes: 1,
      items: [_zikr('m1', 1), _zikr('m2', 3), _zikr('m3', 1, quran: true)],
    ),
    evening: AzkarSetContent(
      minutes: 1,
      items: [_zikr('e1', 1), _zikr('e2', 3), _zikr('e3', 1, quran: true)],
    ),
  ),
);

const bead = 'HapticFeedbackType.lightImpact';
const complete = 'HapticFeedbackType.mediumImpact';
const selection = 'HapticFeedbackType.selectionClick';

/// the haptics and screen reader announcements the app sends from now on, for a setUp
({List<String> haptics, List<String> announcements}) recordPhone() {
  final haptics = <String>[];
  final announcements = <String>[];
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
    return null;
  });
  messenger.setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (message) async {
    final data = (message! as Map)['data'] as Map;
    if (data['message'] case final String text) announcements.add(text);
    return null;
  });
  return (haptics: haptics, announcements: announcements);
}
