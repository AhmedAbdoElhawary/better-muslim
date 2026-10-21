import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/features/home/view/widgets/date_line.dart';
import 'package:better_muslim/features/home/view/widgets/location_pill.dart';
import 'package:better_muslim/features/home/view/widgets/next_prayer_card.dart';
import 'package:better_muslim/features/home/view/widgets/no_location_card.dart';
import 'package:better_muslim/features/home/view/widgets/now_block.dart';
import 'package:better_muslim/features/home/view/widgets/prayer_strip.dart';
import 'package:better_muslim/features/home/view/widgets/shortcuts_card.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header.dart';
import 'package:better_muslim/features/home/view/widgets/sky_labels.dart';
import 'package:better_muslim/features/home/view/widgets/verse_card.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = ref.watch(locationProvider.select((location) => location != null));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      /// the top of every sky is dark, so the status bar stays light in both modes
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Sky(),
              HorizontalPadding(
                padding: SpaceManager.screen,
                child: BmSwitcher(
                  child: hasLocation
                      ? const NextPrayerCard(key: ValueKey(true))
                      : const NoLocationCard(key: ValueKey(false)),
                ),
              ),
              BmSwitcher(
                child: hasLocation
                    ? const OnlyPadding(
                        top: SpaceManager.s4,
                        start: SpaceManager.stripSide,
                        end: SpaceManager.stripSide,
                        child: PrayerStrip(),
                      )
                    : const SizedBox.shrink(),
              ),
              const OnlyPadding(
                top: SpaceManager.homeCardGap,
                start: SpaceManager.screen,
                end: SpaceManager.screen,
                child: VerseCard(),
              ),
              const OnlyPadding(
                top: SpaceManager.homeCardGap,
                start: SpaceManager.screen,
                end: SpaceManager.screen,
                bottom: SpaceManager.s4,
                child: ShortcutsCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the sky's box ends where the card starts, the painter goes on 60 pt under the card. it grows
/// with the header text, and the arc keeps its place from the box's bottom
class _Sky extends ConsumerWidget {
  const _Sky();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = ref.watch(locationProvider.select((location) => location != null));

    /// above 1.0 the text reaches the arc's side, so the arc goes under it
    final scaled = MediaQuery.textScalerOf(context).scale(1) > 1;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: (SizeManager.homeSkyHeight - SpaceManager.homeCardOverlap).r,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: SkyHeader(overlap: SpaceManager.homeCardOverlap.r)),
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: BmMotion.standard,
              layoutBuilder: (current, previous) =>
                  Stack(fit: StackFit.expand, children: [...previous, ?current]),
              child: hasLocation ? const SkyLabels() : null,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HeaderText(),
              if (scaled)
                RSizedBox.vertical(BmSunArc.radius + SkyHeader.horizonAboveBottom(context)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderText extends ConsumerWidget {
  const _HeaderText();

  /// the pill's hit area is taller than its drawing, the paddings give that back
  static const _hitInset = (SizeManager.hit - SizeManager.locationPill) / 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = ref.watch(locationProvider.select((location) => location != null));
    final bright = ref.watch(skyBrightProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final clear = context.getColor(ThemeEnum.transparent);
    final scrim = context.getColor(ThemeEnum.skyScrim);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        /// bm_sky: a 0 → 28% black scrim behind the header text on the bright skies. it fades out
        /// below the text instead of ending on a hard line
        Positioned.fill(
          child: _Scrim(
            bright: bright,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [clear, scrim],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: -SizeManager.skyScrimFade.r,
          height: SizeManager.skyScrimFade.r,
          child: _Scrim(
            bright: bright,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [scrim, clear],
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnlyPadding(
              top: SpaceManager.skyTextTop - _hitInset,
              start: SpaceManager.skyTextSide,
              end: SpaceManager.s5,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [LocationPill(), DateLine()],
              ),
            ),
            BmSwitcher(
              child: hasLocation
                  ? OnlyPadding(
                      top: (isArabic ? SpaceManager.nowTopAr : SpaceManager.nowTop) - _hitInset,
                      start: SpaceManager.s5,
                      end: SpaceManager.s5,
                      child: const NowBlock(),
                    )
                  : const SizedBox.shrink(),
            ),
            const RSizedBox.vertical(SpaceManager.s4),
          ],
        ),
      ],
    );
  }
}

/// the bright skies' scrim fades with the sky instead of popping in
class _Scrim extends StatelessWidget {
  const _Scrim({required this.bright, required this.child});
  final bool bright;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: bright ? 1 : 0,
      duration: MediaQuery.disableAnimationsOf(context) ? BmMotion.micro : BmMotion.standard,
      child: child,
    );
  }
}
