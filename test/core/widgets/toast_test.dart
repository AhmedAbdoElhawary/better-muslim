import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/screen_util_init.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// the app's own builder: the outermost overlay over the navigator
  Future<BuildContext> pump(WidgetTester tester) async {
    late BuildContext page;
    await tester.pumpWidget(
      AppScreenUtilInit(
        child: MaterialApp(
          theme: AppTheme.dark(BmThemeId.qiyamEmerald),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => Overlay.wrap(child: child!),
          home: Builder(
            builder: (context) {
              page = context;
              return const Scaffold();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return page;
  }

  /// a tap on undo only lands when the toast is the top layer
  Future<void> expectOnTop(WidgetTester tester, BuildContext from) async {
    var undone = 0;
    showToast(from, StringsManager.downloadFailed, onUndo: () => undone++);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(undone, 1);
    expect(find.text('Undo'), findsNothing, reason: 'undo takes it away');
  }

  testWidgets('a toast from a sheet sits above the sheet', (tester) async {
    final page = await pump(tester);
    late BuildContext sheet;
    showBmSheet<void>(
      page,
      builder: (context) {
        sheet = context;
        return const SizedBox.square(dimension: 300);
      },
    );
    await tester.pumpAndSettle();
    await expectOnTop(tester, sheet);
  });

  testWidgets('a toast shown before a dialog stays above it', (tester) async {
    final page = await pump(tester);
    showBmDialog(
      page,
      title: StringsManager.resetJourneyTitle,
      body: StringsManager.resetJourneyBody,
      action: StringsManager.reset,
    );
    await tester.pumpAndSettle();
    await expectOnTop(tester, page);
  });

  testWidgets('a second toast replaces the first, then it leaves after 4 s', (tester) async {
    final page = await pump(tester);
    showToast(page, StringsManager.downloadFailed);
    await tester.pump();
    showToast(page, StringsManager.copied);
    await tester.pumpAndSettle();
    expect(find.textContaining('translation'), findsNothing);
    expect(find.text('Copied'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Copied'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
