import 'dart:ui';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/screen_util_init.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
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

  Future<List<bool>> pumpRow(WidgetTester tester, {bool value = true}) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.dark(BmThemeId.qiyamEmerald),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => ToggleRow(
                title: StringsManager.azkarReminders,
                subtitle: StringsManager.azkarRemindersSub,
                args: const {'minutes': '20'},
                value: value,
                onChanged: (next) => setState(() {
                  changes.add(next);
                  value = next;
                }),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return changes;
  }

  testWidgets('a tap anywhere on the row flips it with the selection haptic', (tester) async {
    final changes = await pumpRow(tester);
    expect(find.text('Azkar reminders'), findsOneWidget);
    expect(find.text('20 min after Fajr and Asr'), findsOneWidget);

    await tester.tap(find.text('Azkar reminders'));
    await tester.pumpAndSettle();
    expect(changes, [false]);
    expect(haptics, ['HapticFeedbackType.selectionClick']);
    expect(tester.getSemantics(find.byType(ToggleRow)).flagsCollection.isToggled, Tristate.isFalse);
  });

  testWidgets('the row is at least 44 tall and reads as a toggle', (tester) async {
    await pumpRow(tester);

    expect(tester.getSize(find.byType(ToggleRow)).height, greaterThanOrEqualTo(44));
    expect(tester.getSemantics(find.byType(ToggleRow)).flagsCollection.isToggled, Tristate.isTrue);
  });
}
