import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/core/widgets/step/step_reveal.dart';
import 'package:better_muslim/features/onboarding/view/location_step_page.dart';
import 'package:better_muslim/features/onboarding/view/widgets/welcome_sun.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import '../../../helpers/fonts.dart';
import '../../../helpers/onboarding.dart';
import '../../../helpers/prayer.dart';
import '../../../helpers/providers.dart';

void main() {
  setUpAll(() async {
    tz.initializeTimeZones();
    await loadAppFonts();
  });

  Future<void> begin(WidgetTester tester) async {
    await tester.tap(
      find.text('Swipe up to begin').evaluate().isEmpty
          ? find.text('اسحب للأعلى لتبدأ')
          : find.text('Swipe up to begin'),
    );
    await frames(tester, const Duration(milliseconds: 2400));
  }

  testWidgets('every action on the welcome is at least 44 x 44 (FR-040)', (tester) async {
    await pumpWelcome(tester);
    final hint = tester.getSize(
      find
          .ancestor(of: find.text('Swipe up to begin'), matching: find.byType(ConstrainedBox))
          .first,
    );
    expect(hint.height, greaterThanOrEqualTo(44));
    await begin(tester);
    for (final button in find.byType(BmButton).evaluate()) {
      expect(button.size!.height, greaterThanOrEqualTo(44));
    }

    /// the sun's grab area around its rest spot on 4.10
    final grab = tester.getSize(
      find.byWidgetPredicate((widget) => widget is Listener && widget.onPointerMove != null),
    );
    expect(grab.shortestSide, greaterThanOrEqualTo(44));
    await unmount(tester);
  });

  testWidgets('a tablet gets the phone layout, the sun still rises (FR-012)', (tester) async {
    await pumpWelcome(tester, size: const Size(820, 1180));
    await begin(tester);
    expect(tester.takeException(), isNull);
    expect(tester.widget<WelcomeSun>(find.byType(WelcomeSun)).opacity, greaterThan(.99));
    final title = tester.getRect(find.text('Better Muslim'));
    expect(title.center.dx, closeTo(410, 1));
    await unmount(tester);
  });

  testWidgets('a step in light mode, read as step 1 of 3, its rows heard', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpStep(
      tester,
      Routes.onboardingLocation,
      overrides: await designOverrides(onboarded: false),
      brightness: Brightness.light,
    );
    expect(find.bySemanticsLabel('Step 1 of 3'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Accurate prayer times')), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Prayer times for where you are')),
      matchesSemantics(label: 'Prayer times for where you are', isHeader: true),
    );
    semantics.dispose();
    await unmount(tester);
  });

  testWidgets('reduce motion: a step crossfades in 300 ms, nothing rises', (tester) async {
    await pumpWelcome(
      tester,
      overrides: await designOverrides(onboarded: false),
      reduceMotion: true,
    );
    containerOf(tester).read(routerProvider).push(Routes.onboardingLocation);
    await frames(tester, const Duration(milliseconds: 160));
    final title = find.byWidgetPredicate(
      (widget) => widget is StepReveal && widget.slot == StepSlot.title,
    );
    expect(
      find
          .descendant(of: title, matching: find.byType(Transform))
          .evaluate()
          .where((element) => (element.widget as Transform).transform.getTranslation().y != 0),
      isEmpty,
    );
    await frames(tester, const Duration(milliseconds: 200));
    expect(find.byType(LocationStepPage), findsOneWidget);
    final opacity = tester.widget<CustomOpacity>(
      find.descendant(of: title.first, matching: find.byType(CustomOpacity)).first,
    );
    expect(opacity.opacity, 1);
    await unmount(tester);
  });

  testWidgets('arabic: the steps mirror, the sun does not', (tester) async {
    await pumpWelcome(tester, locale: const Locale('ar'));
    await begin(tester);
    expect(tester.widget<WelcomeSun>(find.byType(WelcomeSun)).center, const Offset(196.5, 452));
    containerOf(tester).read(routerProvider).push(Routes.onboardingLocation);
    await frames(tester, const Duration(milliseconds: 1000));
    final title = tester.getRect(find.text('مواقيت الصلاة حيث أنت'));
    expect(title.right, closeTo(393 - 24, 1));
    expect(tester.element(find.byType(LocationStepPage)).findRenderObject(), isA<RenderBox>());
    await unmount(tester);
  });
}
