import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/theme_picker/view/theme_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../helpers/fonts.dart';
import '../../helpers/more.dart';
import '../../helpers/onboarding.dart';
import '../../helpers/prayer.dart';
import '../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });
  setUp(mockSystemChannel);

  testWidgets('the onboarding step has no back chevron', (tester) async {
    await pumpStep(
      tester,
      Routes.onboardingTheme,
      overrides: await designOverrides(onboarded: false),
    );
    expect(find.byType(ThemePage), findsOneWidget);
    expect(find.byType(BarBackButton), findsNothing);
    await unmount(tester);
  });

  testWidgets('apply saves the theme and mode, finishes onboarding, home fades in', (tester) async {
    await pumpStep(
      tester,
      Routes.onboardingTheme,
      overrides: await designOverrides(onboarded: false),
    );
    await tester.tap(find.text('Iznik'));
    await tester.tap(find.text('Dark'));
    await frames(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text('Apply theme'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await frames(tester, const Duration(milliseconds: 150));

    /// halfway through its 300 ms fade
    expect(find.byType(HomePage), findsOneWidget);
    await frames(tester, const Duration(milliseconds: 400));

    final settings = await settingsOf(tester);
    expect((settings.theme, settings.themeMode), (BmThemeId.iznik, BmThemeMode.dark));
    expect(settings.onboarded, isTrue);
    expect(containerOf(tester).read(onboardingProvider), (done: true, replay: false));
    expect(find.byType(ThemePage), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('from more it keeps its back chevron', (tester) async {
    await pumpMore(tester, await designOverrides(), push: Routes.theme);
    expect(find.byType(BarBackButton), findsOneWidget);
    await unmount(tester);
  });
}
