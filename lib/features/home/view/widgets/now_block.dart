import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/extensions/window_size.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// NOW and the prayer in its now window, after it NEXT and the next prayer. english adds the
/// arabic name, arabic has no second name (4.16)
class NowBlock extends ConsumerWidget {
  const NowBlock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowPrayerProvider.select((now) => now?.$1));
    final next = ref.watch(nextPrayerProvider.select((next) => next?.$1));
    final bright = ref.watch(skyBrightProvider);
    final prayer = now ?? next;
    if (prayer == null) return const SizedBox.shrink();
    final label = now == null ? StringsManager.surfaceNext : StringsManager.now;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final color = bright ? ThemeEnum.onSkyBright : ThemeEnum.onSky;

    /// bm_sky asks for white at 92% on the bright skies, the 85% would drop it below AA
    final muted = bright ? ThemeEnum.onSkyBright : ThemeEnum.onSkyMuted;
    if (isArabic) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RegularText(label, color: muted),
          RegularText(
            prayer.nameKey,
            font: FontEnum.display,
            fontSize: FontSizeManager.heroAr,
            height: LineHeightManager.heroAr,
            color: color,
          ),
          _Until(now: now != null, color: muted),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegularText(
          label,
          fontSize: FontSizeManager.overline,
          letterSpacing: LetterSpacingManager.overline,
          color: muted,
        ),
        _Names(prayer: prayer, color: color, muted: muted),
        const RSizedBox.vertical(SpaceManager.nowUntilGap),
        _Until(now: now != null, color: muted),
      ],
    );
  }
}

/// the arabic name sits on the english name's baseline, and goes under it above text scale 1.4
class _Names extends StatelessWidget {
  const _Names({required this.prayer, required this.color, required this.muted});
  final Prayer prayer;
  final ThemeEnum color;
  final ThemeEnum muted;

  @override
  Widget build(BuildContext context) {
    final name = RegularText(
      prayer.nameKey,
      font: FontEnum.display,
      fontSize: FontSizeManager.hero,
      height: LineHeightManager.hero,
      color: color,
    );
    final nameAr = RegularText(
      prayer.nameArKey,
      font: FontEnum.display,
      fontSize: FontSizeManager.accentAr,
      height: LineHeightManager.accentAr,
      color: muted,
    );
    if (context.isLargeText) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [name, nameAr]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(child: name),
        const RSizedBox.horizontal(SpaceManager.s1),
        nameAr,
      ],
    );
  }
}

/// until the next prayer while one is now, otherwise the time of the next prayer shown above
class _Until extends ConsumerWidget {
  const _Until({required this.now, required this.color});
  final bool now;
  final ThemeEnum color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextPrayerProvider);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (next == null) return const SizedBox.shrink();
    final (prayer, time) = next;
    final at = context.formatTime(time, digits);
    if (!now) return RegularText(StringsManager.nextAt, args: {'time': at}, color: color);
    return RegularText(
      StringsManager.untilPrayerAt,
      args: {'prayer': context.tr(prayer.nameKey), 'time': at},
      color: color,
    );
  }
}
