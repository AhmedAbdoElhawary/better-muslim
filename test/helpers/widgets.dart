import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/screen_util_init.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// one core widget on a dark qiyam emerald page, in a language and text scale
Future<void> pumpCoreWidget(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  double textScale = 1,
  bool reduceMotion = false,

  /// false for a loop, which never settles
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view)
          .copyWith(textScaler: TextScaler.linear(textScale), disableAnimations: reduceMotion),
      child: AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.dark(BmThemeId.qiyamEmerald),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
  settle ? await tester.pumpAndSettle() : await tester.pump();
}

/// the haptics the app asked for, by type
List<String> recordHaptics() {
  final haptics = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') haptics.add('${call.arguments}');
      return null;
    },
  );
  return haptics;
}
