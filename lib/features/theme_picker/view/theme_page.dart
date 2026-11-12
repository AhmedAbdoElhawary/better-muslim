import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_theme.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/step/step_reveal.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/theme_picker/view/widgets/mode_control.dart';
import 'package:better_muslim/features/theme_picker/view/widgets/theme_snippet.dart';
import 'package:better_muslim/features/theme_picker/view/widgets/theme_swatches.dart';
import 'package:better_muslim/features/theme_picker/view_model/theme_preview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// 4.15: the preview restyles at once, only apply saves (FR-009 to FR-012). the last onboarding
/// step too, without the back button, building on its route like the other steps
class ThemePage extends ConsumerWidget {
  const ThemePage({this.onboarding = false, super.key});

  final bool onboarding;

  Future<void> _apply(BuildContext context, WidgetRef ref) async {
    await ref.read(themePreviewProvider.notifier).apply();
    if (!onboarding) {
      if (context.mounted) context.pop();
      return;
    }

    /// finishing sends the router home too, the go keeps it on the home tab (FR-027)
    await ref.read(onboardingProvider.notifier).finish();
    if (context.mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CompactAppBar(StringsManager.theme, back: !onboarding, heroTag: Routes.theme),
        const Expanded(
          child: SingleChildScrollView(
            child: HorizontalPadding(
              padding: SpaceManager.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RSizedBox.vertical(SpaceManager.previewTop),
                  StepReveal(slot: StepSlot.title, child: _Preview()),
                  RSizedBox.vertical(SpaceManager.modeTop),
                  StepReveal(slot: StepSlot.body, child: ModeControl()),
                  RSizedBox.vertical(SpaceManager.swatchesTop),
                  StepReveal(slot: StepSlot.cards, child: ThemeSwatches()),
                  RSizedBox.vertical(SpaceManager.themeNoteTop),
                  HorizontalPadding(
                    padding: SpaceManager.s1,
                    child: RegularText(
                      StringsManager.followSkyNote,
                      fontSize: FontSizeManager.cardNote,
                      height: LineHeightManager.body,
                      color: ThemeEnum.text2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  RSizedBox.vertical(SpaceManager.s4),
                ],
              ),
            ),
          ),
        ),
        StepReveal(
          slot: StepSlot.buttons,
          child: SafeArea(
            top: false,
            child: OnlyPadding(
              start: SpaceManager.s5,
              end: SpaceManager.s5,
              bottom: SpaceManager.s3,
              child: BmButton.primary(
                StringsManager.applyTheme,
                onPressed: () => _apply(context, ref),
              ),
            ),
          ),
        ),
      ],
    );
    return StepReveal(
      slot: StepSlot.background,
      child: Scaffold(body: onboarding ? content : TitleGlow(child: content)),
    );
  }
}

/// the snippet in the picked theme and mode, the rest of the page stays in the saved one
class _Preview extends ConsumerWidget {
  const _Preview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pick = ref.watch(themePreviewProvider);
    final followSky = ref.watch(followSkyProvider);
    final light = switch (pick.mode) {
      BmThemeMode.dark => false,
      BmThemeMode.light => true,
      BmThemeMode.followSky => switch (followSky) {
        ThemeMode.light => true,
        ThemeMode.dark => false,
        ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.light,
      },
      BmThemeMode.followPhone => MediaQuery.platformBrightnessOf(context) == Brightness.light,
    };
    final radius = BorderRadius.circular(RadiusManager.sheet.r);
    return RSizedBox(
      height: SizeManager.preview,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.getColor(ThemeEnum.variant),
          borderRadius: radius,
          boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: TopPadding(
                  padding: SpaceManager.previewSnippetTop,

                  /// a still picture of home at a fixed size, so screen readers skip it and its text
                  /// doesn't scale. it runs on under the box's bottom edge, which clips it like 4.15
                  child: ExcludeSemantics(
                    child: MediaQuery.withNoTextScaling(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        maxHeight: double.infinity,
                        child: AnimatedTheme(
                          data: light ? AppTheme.light(pick.theme) : AppTheme.dark(pick.theme),
                          duration: MediaQuery.disableAnimationsOf(context)
                              ? BmMotion.micro
                              : BmMotion.standard,
                          curve: BmMotion.standardCurve,
                          child: const ThemeSnippet(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                height: SizeManager.previewFade.r,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          context.getColor(ThemeEnum.variant).withValues(alpha: 0),
                          context.getColor(ThemeEnum.variant),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              PositionedDirectional(
                start: SpaceManager.previewChipStart.r,
                bottom: SpaceManager.previewChipBottom.r,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.getColor(ThemeEnum.surface),
                    borderRadius: BorderRadius.circular(RadiusManager.pill.r),
                    boxShadow: [
                      BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1),
                    ],
                  ),
                  child: SymmetricPadding(
                    horizontal: SpaceManager.previewChipH,
                    vertical: SpaceManager.previewChipV,
                    child: MediumText(
                      StringsManager.livePreview,
                      args: {'name': context.tr(pick.theme.nameKey)},
                      fontSize: FontSizeManager.label,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
