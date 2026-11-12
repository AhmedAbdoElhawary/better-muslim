import 'dart:math' as math;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/next_prayer.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/ellipse_transform.dart';
import 'package:better_muslim/features/theme_picker/view/widgets/snippet_sky.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

const _ringAlpha = .08;
const _barTrackAlpha = .1;
const _glowAlpha = .6;
const _glowStop = .72;
const _currentAlpha = .15;
const _currentRingAlpha = .3;

/// Theme Snippet.dc.html with today's values, drawn in whatever theme is above it. the verse
/// card, button and tab bar sit below the preview's 300 pt clip, so they aren't built (R4)
class ThemeSnippet extends StatelessWidget {
  const ThemeSnippet({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(RadiusManager.snippet.r),
      child: ColoredBox(
        color: context.getColor(ThemeEnum.bg),
        child: RSizedBox(
          width: SizeManager.snippet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const RSizedBox(
                height: SizeManager.snippetSky,
                child: Stack(
                  children: [
                    Positioned.fill(child: SnippetSky()),
                    _SkyText(),
                  ],
                ),
              ),
              Transform.translate(
                offset: Offset(0, -SpaceManager.snippetCardOverlap.r),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HorizontalPadding(padding: SpaceManager.snippetCardSide, child: _NextCard()),
                    RSizedBox.vertical(SpaceManager.snippetStripTop),
                    HorizontalPadding(padding: SpaceManager.snippetCardSide, child: _Strip()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Makkah · Thu 15 Oct", the hijri date, NOW and the period
class _SkyText extends ConsumerWidget {
  const _SkyText();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(
      locationProvider.select(
        (location) => (name: location?.placeName, nameAr: location?.placeNameAr),
      ),
    );
    final today = ref.watch(todayProvider);
    final hijri = ref.watch(hijriDateProvider(today));
    final now = ref.watch(nowPrayerProvider.select((now) => now?.$1));
    final prayer = now ?? ref.watch(nextPrayerProvider.select((next) => next?.$1));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final locale = Localizations.localeOf(context).languageCode;
    final name = (locale == 'ar' ? place.nameAr : null) ?? place.name;
    final day = DateFormat('EEE d MMM', locale).format(today);
    return SymmetricPadding(
      horizontal: SpaceManager.snippetTopH,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RSizedBox.vertical(SpaceManager.snippetTopV),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: RegularText(
                  context.formatDigits(name == null ? day : '$name · $day', digits),
                  translate: false,
                  fontSize: FontSizeManager.snippetPlace,
                  color: ThemeEnum.onSkyMuted,
                  maxLines: 1,
                ),
              ),
              RegularText(
                context.formatDigits(
                  '${hijri.day} ${context.tr(hijri.monthKey)} ${hijri.year}',
                  digits,
                ),
                translate: false,
                fontSize: FontSizeManager.snippetPlace,
                color: ThemeEnum.onSkyMuted,
                maxLines: 1,
              ),
            ],
          ),
          if (prayer != null) ...[
            const RSizedBox.vertical(SpaceManager.snippetNowTop),
            RegularText(
              context
                  .tr(now == null ? StringsManager.surfaceNext : StringsManager.now)
                  .toUpperCase(),
              translate: false,
              fontSize: FontSizeManager.snippetNow,
              letterSpacing: LetterSpacingManager.snippetNow,
              color: ThemeEnum.onSkyMuted,
            ),
            RegularText(
              prayer.nameKey,
              font: FontEnum.display,
              fontSize: FontSizeManager.largeTitle,
              height: LineHeightManager.largeTitle,
              color: ThemeEnum.onSky,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}

class _NextCard extends ConsumerWidget {
  const _NextCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextPrayerProvider);
    if (next == null) return const SizedBox.shrink();
    final (prayer, time) = next;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final share = ref.watch(barShareProvider) ?? 0;
    final ring = context.getColor(ThemeEnum.text).withValues(alpha: _ringAlpha);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          left: -SizeManager.snippetGlowInset.r,
          right: -SizeManager.snippetGlowInset.r,
          top: -SizeManager.snippetGlowInset.r,
          bottom: -SizeManager.snippetGlowInset.r,
          child: const _Glow(),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.surface),
            borderRadius: BorderRadius.circular(RadiusManager.lg.r),
            boxShadow: [BoxShadow(color: ring, spreadRadius: 1)],
          ),
          child: OnlyPadding(
            start: SpaceManager.snippetCardH,
            end: SpaceManager.snippetCardH,
            top: SpaceManager.snippetCardTop,
            bottom: SpaceManager.snippetCardBottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const RegularText(
                      StringsManager.nextPrayer,
                      fontSize: FontSizeManager.tabLabel,
                      color: ThemeEnum.text2,
                    ),
                    RegularText(
                      prayer.nameArKey,
                      font: FontEnum.display,
                      fontSize: FontSizeManager.body,
                      height: LineHeightManager.nextPrayerAr,
                      color: ThemeEnum.text2,
                    ),
                  ],
                ),
                const RSizedBox.vertical(SpaceManager.snippetCardGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: RegularText(
                        prayer.nameKey,
                        font: FontEnum.display,
                        fontSize: FontSizeManager.snippetPrayer,
                        height: LineHeightManager.counter,
                        maxLines: 1,
                      ),
                    ),
                    const _Countdown(),
                  ],
                ),
                const RSizedBox.vertical(SpaceManager.snippetCardGap),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(RadiusManager.prayerBar.r),
                        child: RSizedBox(
                          height: SizeManager.prayerBar,
                          child: ColoredBox(
                            color: context
                                .getColor(ThemeEnum.text)
                                .withValues(alpha: _barTrackAlpha),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: FractionallySizedBox(
                                widthFactor: share,
                                heightFactor: 1,
                                child: ColoredBox(color: context.getColor(ThemeEnum.primary)),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const RSizedBox.horizontal(SpaceManager.duaGap),
                    RegularText(
                      StringsManager.adhanAt,
                      args: {'time': context.formatTime(time, digits)},
                      fontSize: FontSizeManager.tabLabel,
                      color: ThemeEnum.text2,
                      tabularFigures: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow();

  @override
  Widget build(BuildContext context) {
    final glow = context.getColor(ThemeEnum.glow);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: math.sqrt1_2,
          colors: [
            glow.withValues(alpha: _glowAlpha),
            glow.withValues(alpha: 0),
          ],
          stops: const [0, _glowStop],
          transform: const EllipseTransform(),
        ),
      ),
    );
  }
}

/// the one leaf on the theme page that changes every second
class _Countdown extends ConsumerWidget {
  const _Countdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:hours, :minutes, :seconds) = countdownParts(
      ref.watch(timeLeftProvider) ?? Duration.zero,
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final text =
        '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediumText(
        context.formatDigits(text, digits),
        translate: false,
        fontSize: FontSizeManager.snippetCountdown,
        letterSpacing: LetterSpacingManager.snippetCountdown,
        color: ThemeEnum.primary,
        tabularFigures: true,
      ),
    );
  }
}

/// today's five times, the current one highlighted
class _Strip extends ConsumerWidget {
  const _Strip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final times = ref.watch(todayTimesProvider);
    final highlighted = ref.watch(highlightedPrayerProvider);
    final inWindow = ref.watch(nowPrayerProvider.select((now) => now != null));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (times == null) return const SizedBox.shrink();
    return Row(
      children: [
        for (final (index, prayer) in Prayer.values.indexed) ...[
          if (index > 0) const RSizedBox.horizontal(SpaceManager.stripCellGap),
          Expanded(
            child: _Cell(
              prayer: prayer,
              time: times.timeOf(prayer) == null
                  ? ''
                  : context.formatTime(times.timeOf(prayer)!, digits),
              current:
                  highlighted?.$1 == prayer &&
                  (times.timeOf(prayer)?.isAtSameMomentAs(highlighted!.$2) ?? false),
              inWindow: inWindow,
              past:
                  highlighted != null && (times.timeOf(prayer)?.isBefore(highlighted.$2) ?? false),
            ),
          ),
        ],
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.prayer,
    required this.time,
    required this.current,
    required this.inWindow,
    required this.past,
  });

  final Prayer prayer;
  final String time;
  final bool current;

  /// the highlighted prayer is in its now window, so the current cell is filled, not outlined
  final bool inWindow;
  final bool past;

  @override
  Widget build(BuildContext context) {
    final primary = context.getColor(ThemeEnum.primary);
    final now = current && inWindow;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: now ? primary.withValues(alpha: _currentAlpha) : null,
        borderRadius: BorderRadius.circular(RadiusManager.tileIcon.r),
        border: !current
            ? null
            : now
            ? Border.all(color: primary.withValues(alpha: _currentRingAlpha))
            : Border.all(color: primary, width: SizeManager.nextRing.r),
      ),
      child: VerticalPadding(
        padding: SpaceManager.snippetCellV,
        child: Column(
          children: [
            if (current)
              SemiBoldText(
                prayer.nameKey,
                fontSize: FontSizeManager.tabLabel,
                color: ThemeEnum.primary,
                maxLines: 1,
              )
            else
              RegularText(
                prayer.nameKey,
                fontSize: FontSizeManager.tabLabel,
                color: ThemeEnum.text2,
                maxLines: 1,
              ),
            const RSizedBox.vertical(SpaceManager.snippetCellGap),
            if (current)
              MediumText(time, translate: false, fontSize: FontSizeManager.caption, maxLines: 1)
            else
              RegularText(
                time,
                translate: false,
                color: past ? ThemeEnum.text2 : ThemeEnum.text,
                maxLines: 1,
                tabularFigures: true,
              ),
          ],
        ),
      ),
    );
  }
}
