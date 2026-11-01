import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/core/widgets/step/step_dots.dart';
import 'package:better_muslim/core/widgets/step/step_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// 4.11: why the app needs the location, then the phone's dialog or a city (FR-019 to FR-021)
class LocationStepPage extends ConsumerStatefulWidget {
  const LocationStepPage({super.key});

  @override
  ConsumerState<LocationStepPage> createState() => _LocationStepPageState();
}

class _LocationStepPageState extends ConsumerState<LocationStepPage> {
  var _busy = false;

  Future<void> _useMyLocation() async {
    setState(() => _busy = true);
    final found = await ref.read(locationControllerProvider).useAuto();
    if (!mounted) return;
    setState(() => _busy = false);
    if (found) return _next();

    /// refused, now or before, or no fix: the city search at once (FR-020)
    await _chooseCity(failed: true);
  }

  Future<void> _chooseCity({bool failed = false}) async {
    final chosen = await showLocationSheet(context, failed: failed);
    if (chosen && mounted) _next();
  }

  void _next() => context.push(Routes.onboardingNotifications);

  @override
  Widget build(BuildContext context) {
    /// 46 from the bottom as designed, but never under a 3 button navigation bar
    final bottom = math.max(
      SpaceManager.stepButtonsBottom,
      MediaQuery.viewPaddingOf(context).bottom / ScreenUtil().radius(1),
    );
    return StepReveal(
      slot: StepSlot.background,
      child: PopScope(
        canPop: !_busy,
        child: Scaffold(
          body: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const RSizedBox.vertical(SpaceManager.stepDotsTop),
                          const StepDots(step: 1),
                          const RSizedBox.vertical(
                            SpaceManager.stepContentTop -
                                SpaceManager.stepDotsTop -
                                SizeManager.stepDot,
                          ),
                          HorizontalPadding(
                            padding: SpaceManager.stepContentSide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                StepReveal(
                                  slot: StepSlot.title,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const _IconTile(),
                                      const RSizedBox.vertical(
                                        SpaceManager.stepTitleGap + SpaceManager.stepIconTitleGap,
                                      ),
                                      Semantics(
                                        header: true,
                                        child: const RegularText(
                                          StringsManager.locTitle,
                                          font: FontEnum.display,
                                          fontSize: FontSizeManager.onboardingTitle,
                                          height: LineHeightManager.onboardingTitle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const RSizedBox.vertical(SpaceManager.stepTitleGap),
                                const StepReveal(
                                  slot: StepSlot.body,
                                  child: RegularText(
                                    StringsManager.locBody,
                                    fontSize: FontSizeManager.body,
                                    height: LineHeightManager.stepBody,
                                    color: ThemeEnum.text2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const RSizedBox.vertical(SpaceManager.stepBodyCardGap),
                          const HorizontalPadding(
                            padding: SpaceManager.stepCardSide,
                            child: StepReveal(
                              slot: StepSlot.cards,
                              child: GroupedSection(
                                children: [
                                  _Benefit(
                                    icon: BmUiIcon.sun,
                                    title: StringsManager.locB1,
                                    subtitle: StringsManager.locB1s,
                                  ),
                                  _Benefit(
                                    icon: BmUiIcon.compass,
                                    title: StringsManager.locB2,
                                    subtitle: StringsManager.locB2s,
                                  ),
                                  _Benefit(
                                    icon: BmUiIcon.lock,
                                    title: StringsManager.locB3,
                                    subtitle: StringsManager.locB3s,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const RSizedBox.vertical(SpaceManager.s4),
                        ],
                      ),
                    ),
                  ),
                  StepReveal(
                    slot: StepSlot.buttons,
                    child: OnlyPadding(
                      start: SpaceManager.stepButtonsSide,
                      end: SpaceManager.stepButtonsSide,
                      bottom: bottom,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BmButton.primary(
                            StringsManager.useMyLocation,
                            busy: _busy,
                            onPressed: _useMyLocation,
                          ),
                          const RSizedBox.vertical(SpaceManager.locationButtonGap),
                          BmButton.secondary(
                            StringsManager.chooseCity,
                            busy: _busy,
                            onPressed: _chooseCity,
                          ),
                          const RSizedBox.vertical(
                            SpaceManager.locationButtonGap + SpaceManager.locationFootnoteTop,
                          ),
                          const RegularText(
                            StringsManager.changeLocationLater,
                            fontSize: FontSizeManager.cardNote,
                            color: ThemeEnum.text2,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : BmMotion.micro,
                  child: _busy ? const _Blocker() : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the phone's dialog and the fix can take seconds, nothing on the step is tappable meanwhile
class _Blocker extends StatelessWidget {
  const _Blocker();

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(
      child: AbsorbPointer(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: BmGlass.blurSigma, sigmaY: BmGlass.blurSigma),
          child: ColoredBox(
            color: context.getColor(ThemeEnum.scrim).withValues(alpha: BmOpacity.pressed),
            child: const Center(child: BmStarLoader()),
          ),
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile();

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: SizeManager.stepIconTile,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.getColor(ThemeEnum.primaryContainer),
          borderRadius: BorderRadius.circular(RadiusManager.stepIconTile.r),
        ),
        child: Center(
          child: BmIcon(
            BmIconName.location,
            size: SizeManager.stepIcon.r,
            color: context.getColor(ThemeEnum.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

/// one of the card's three rows
class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.subtitle});

  final BmUiIcon icon;

  /// StringsManager keys
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: SymmetricPadding(
        horizontal: SpaceManager.listRowStart,
        vertical: SpaceManager.stepRowV,
        child: Row(
          children: [
            RSizedBox.square(
              dimension: SizeManager.stepRowIcon,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.getColor(ThemeEnum.primaryContainer),
                  borderRadius: BorderRadius.circular(RadiusManager.tileIcon.r),
                ),
                child: Center(
                  child: BmIcon.ui(
                    icon,
                    size: SizeManager.iconList.r,
                    color: context.getColor(ThemeEnum.onPrimaryContainer),
                  ),
                ),
              ),
            ),
            const RSizedBox.horizontal(SpaceManager.listRowGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MediumText(title),
                  const RSizedBox.vertical(SpaceManager.rowLineGap),
                  RegularText(subtitle, height: LineHeightManager.caption, color: ThemeEnum.text2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
