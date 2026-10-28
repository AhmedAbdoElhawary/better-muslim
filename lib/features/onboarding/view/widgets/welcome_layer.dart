import 'dart:math' as math;

import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/features/onboarding/model/sun_choreography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.10's title, tagline and buttons at the build value b. the tree's positions at text scale
/// 1, a scroll instead of overlaps at 2.0
class WelcomeLayer extends ConsumerWidget {
  const WelcomeLayer({
    required this.ch,
    required this.b,
    required this.covered,
    required this.interactive,
    required this.onGetStarted,
    required this.onRestore,
    super.key,
  });

  final SunChoreography ch;
  final double b;

  /// 0 to 1 while 4.11 covers the welcome
  final double covered;
  final bool interactive;
  final VoidCallback onGetStarted;
  final VoidCallback onRestore;

  /// the tree's .85
  static const _taglineAlpha = .85;

  /// the tagline starts faint and develops
  static const _taglineFaint = .35;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bright = ref.watch(
      skyStateProvider.select((state) => state != null && bmSkyIsBright(state)),
    );
    final color = bright ? ThemeEnum.onSkyBright : ThemeEnum.onSky;
    double out(WelcomePart part) => 1 - SunChoreography.covered(covered, part);

    /// 46 from the bottom as designed, but never under a 3 button navigation bar
    final bottom = math.max(
      SpaceManager.welcomeButtonsBottom,
      MediaQuery.viewPaddingOf(context).bottom / ScreenUtil().radius(1),
    );
    final ink = _taglineFaint + (1 - _taglineFaint) * ch.taglineInk(b);
    return IgnorePointer(
      ignoring: !interactive,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const RSizedBox.vertical(SpaceManager.welcomeTitleTop),
                  Transform.translate(
                    offset: Offset(0, ch.titleTravel(b)),
                    child: HorizontalPadding(
                      padding: SpaceManager.welcomeTextSide,
                      child: Column(
                        children: [
                          CustomOpacity(
                            opacity: ch.titleOpacity(b) * out(WelcomePart.title),
                            child: RegularText(
                              StringsManager.appName,
                              font: FontEnum.display,
                              fontSize: FontSizeManager.wordmark,
                              height: LineHeightManager.wordmark,
                              color: color,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const RSizedBox.vertical(SpaceManager.welcomeTaglineGap),
                          CustomOpacity(
                            opacity:
                                _taglineAlpha *
                                ink *
                                ch.taglineOpacity(b) *
                                out(WelcomePart.tagline),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: SizeManager.welcomeTaglineWidth.r,
                              ),
                              child: RegularText(
                                StringsManager.welcomeTagline,
                                fontSize: FontSizeManager.bodyLarge,
                                height: LineHeightManager.bodyLarge,
                                color: color,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  HorizontalPadding(
                    padding: SpaceManager.welcomeButtonsSide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Rise(
                          t: ch.getStartedIn(b) * out(WelcomePart.buttons),
                          child: BmButton.primary(
                            StringsManager.getStarted,
                            onPressed: onGetStarted,
                          ),
                        ),
                        const RSizedBox.vertical(SpaceManager.welcomeButtonGap),
                        _Rise(
                          t: ch.restoreIn(b) * out(WelcomePart.buttons),
                          child: BmButton.text(
                            StringsManager.restoreBackup,
                            color: ThemeEnum.onSky,
                            onPressed: onRestore,
                          ),
                        ),
                      ],
                    ),
                  ),
                  RSizedBox.vertical(bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// fades in rising 14 pt
class _Rise extends StatelessWidget {
  const _Rise({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final shown = t.clamp(0.0, 1.0);

    /// a button works once it shows (FR-013)
    return IgnorePointer(
      ignoring: shown < .5,
      child: CustomOpacity(
        opacity: shown,
        child: Transform.translate(
          offset: Offset(0, (1 - shown) * SpaceManager.stepRise.r),
          child: child,
        ),
      ),
    );
  }
}
