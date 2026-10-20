import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/onboarding/model/sun_choreography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the first screen's words: the headline, "let go to begin" and "swipe up to begin"
class IntroLayer extends ConsumerWidget {
  const IntroLayer({
    required this.ch,
    required this.lift,
    required this.b,
    required this.shown,
    required this.ready,
    required this.onBegin,
    super.key,
  });

  final SunChoreography ch;
  final double lift;
  final double b;

  /// the headline and the hint fade in last on the first launch (FR-006)
  final double shown;
  final ValueListenable<bool> ready;

  /// null while the welcome builds or is up
  final VoidCallback? onBegin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bright = ref.watch(
      skyStateProvider.select((state) => state != null && bmSkyIsBright(state)),
    );
    final color = bright ? ThemeEnum.onSkyBright : ThemeEnum.onSky;
    final opacity = ch.headlineOpacity(lift, b) * shown;
    final blur = ch.headlineBlur(lift, b);
    final inset = math.max(
      MediaQuery.viewPaddingOf(context).bottom,
      SpaceManager.swipeHintMinInset.r,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        if (opacity > .001)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: ch.headlineCenter * 2,
            child: Center(
              child: HorizontalPadding(
                padding: SpaceManager.welcomeTextSide,
                child: Opacity(
                  opacity: opacity,
                  child: ImageFiltered(
                    enabled: blur > .05,
                    imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                    child: RegularText(
                      StringsManager.firstHeadline,
                      font: FontEnum.display,
                      fontSize: FontSizeManager.onboardingTitle,
                      height: LineHeightManager.onboardingTitle,
                      color: color,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          top: ch.readyHintTop,
          child: _ReadyHint(ready: ready, color: color),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: inset + SpaceManager.swipeHintBottom.r,
          child: Opacity(
            opacity: ch.hintOpacity(lift, b) * shown,
            child: Center(
              child: Semantics(
                button: true,
                onTap: onBegin,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onBegin,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: SizeManager.hit.r),
                    child: SymmetricPadding(
                      horizontal: SpaceManager.s4,
                      child: Center(
                        widthFactor: 1,
                        child: MediumText(
                          StringsManager.swipeToBegin,
                          fontSize: FontSizeManager.cardNote,
                          color: bright ? ThemeEnum.onSkyBright : ThemeEnum.onSkyMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// shown while the sun is held above the horizon
class _ReadyHint extends StatelessWidget {
  const _ReadyHint({required this.ready, required this.color});

  final ValueListenable<bool> ready;
  final ThemeEnum color;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ValueListenableBuilder(
      valueListenable: ready,
      builder: (context, show, child) => AnimatedSlide(
        offset: show || reduce ? Offset.zero : const Offset(0, .4),
        duration: BmMotion.standard,
        curve: BmMotion.decelerate,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: BmMotion.standard,
          child: Semantics(
            liveRegion: true,
            child: ExcludeSemantics(excluding: !show, child: child),
          ),
        ),
      ),
      child: MediumText(StringsManager.letGoToBegin, color: color, textAlign: TextAlign.center),
    );
  }
}
