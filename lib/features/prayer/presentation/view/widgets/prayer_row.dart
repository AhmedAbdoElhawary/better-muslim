import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/extensions/window_size.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/animated_decorated_box.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/features/prayer/presentation/providers/selected_day.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_cell.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/row_trailing.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/sound_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart';

/// one prayer of the shown day, filled in its now window and outlined as the next prayer. a
/// screen reader hears it as one node: prayer, time, state (R13)
class PrayerRow extends ConsumerWidget {
  const PrayerRow(this.prayer, {super.key});
  final Prayer prayer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(shownDayProvider);
    final (:state, :isHighlighted, :isNow) = ref.watch(rowStateProvider((day, prayer)));
    final time = ref.watch(dayTimesProvider(day).select((times) => times?.timeOf(prayer)));
    final name = _Name(prayer: prayer, highlighted: isHighlighted, now: isNow);
    final clock = _Time(time: time, minor: false);
    final trailing = RowTrailing(day: day, prayer: prayer, state: state);
    final icon = isNow
        ? ThemeEnum.onPrimaryContainer
        : isHighlighted
        ? ThemeEnum.primary
        : ThemeEnum.text2;
    return MergeSemantics(
      child: AnimatedDecoratedBox(
        decoration: BoxDecoration(
          color: isNow ? context.getColor(ThemeEnum.primaryContainer) : null,
          borderRadius: BorderRadius.circular(RadiusManager.row.r),
          border: isNow
              ? Border.all(color: DayCell.shownBorder(context))
              : isHighlighted
              ? Border.all(
                  color: context.getColor(ThemeEnum.primary),
                  width: SizeManager.nextRing.r,
                )
              : null,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.prayerRow.r),
          child: OnlyPadding(
            start: SpaceManager.s4,
            end: SpaceManager.s2,
            child: context.isLargeText
                ? _Stacked(
                    icon: _PrayerIcon(prayer: prayer, color: icon),
                    name: name,
                    time: clock,
                    sound: SoundButton(prayer),
                    trailing: trailing,
                  )
                : Row(
                    children: [
                      _PrayerIcon(prayer: prayer, color: icon),
                      const RSizedBox.horizontal(SpaceManager.prayerRowGap),
                      Expanded(child: name),
                      clock,
                      SoundButton(prayer),
                      RSizedBox(
                        width: SizeManager.rowTrailing,
                        height: SizeManager.hit,
                        child: EndPadding(
                          padding: SpaceManager.s2,
                          child: Align(alignment: AlignmentDirectional.centerEnd, child: trailing),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// sunrise is a time, never a prayer: smaller, muted and with no action
class SunriseRow extends ConsumerWidget {
  const SunriseRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(shownDayProvider);
    final time = ref.watch(dayTimesProvider(day).select((times) => times?.sunrise));
    return MergeSemantics(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: SizeManager.prayerRowMinor.r),
        child: OnlyPadding(
          start: SpaceManager.s4,
          end: SpaceManager.s2,
          child: Row(
            children: [
              BmIcon(
                BmIconName.sunrise,
                size: SizeManager.iconList.r,
                color: context.getColor(ThemeEnum.text2),
              ),
              const RSizedBox.horizontal(SpaceManager.prayerRowGap),
              const Expanded(
                child: RegularText(
                  StringsManager.sunrise,
                  font: FontEnum.display,
                  fontSize: FontSizeManager.prayerNameMinor,
                  color: ThemeEnum.text2,
                ),
              ),
              _Time(time: time, minor: true),
              if (!context.isLargeText)
                const RSizedBox.horizontal(SizeManager.hit + SizeManager.rowTrailing),
            ],
          ),
        ),
      ),
    );
  }
}

/// above text scale 1.4 the time and the action go under the name
class _Stacked extends StatelessWidget {
  const _Stacked({
    required this.icon,
    required this.name,
    required this.time,
    required this.sound,
    required this.trailing,
  });

  final Widget icon;
  final Widget name;
  final Widget time;
  final Widget sound;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return VerticalPadding(
      padding: SpaceManager.s2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const RSizedBox.horizontal(SpaceManager.prayerRowGap),
              Expanded(child: name),
            ],
          ),
          Row(
            children: [
              Expanded(child: time),
              sound,
              EndPadding(padding: SpaceManager.s2, child: trailing),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerIcon extends StatelessWidget {
  const _PrayerIcon({required this.prayer, required this.color});
  final Prayer prayer;
  final ThemeEnum color;

  @override
  Widget build(BuildContext context) {
    final size = SizeManager.icon.r;
    final tint = context.getColor(color);
    return switch (prayer) {
      Prayer.dhuhr || Prayer.asr => BmIcon.ui(BmUiIcon.sun, size: size, color: tint),
      Prayer.isha => BmIcon(BmIconName.night, size: size, color: tint),
      Prayer.fajr || Prayer.maghrib => BmIcon(BmIconName.sunrise, size: size, color: tint),
    };
  }
}

class _Name extends StatelessWidget {
  const _Name({required this.prayer, required this.highlighted, required this.now});
  final Prayer prayer;
  final bool highlighted;
  final bool now;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final color = now
        ? ThemeEnum.onPrimaryContainer
        : highlighted
        ? ThemeEnum.primary
        : ThemeEnum.text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: RegularText(
            prayer.nameKey,
            font: FontEnum.display,
            fontSize: FontSizeManager.prayerName,
            color: color,
            maxLines: 1,
          ),
        ),
        BmSwitcher(
          child: now
              ? StartPadding(
                  padding: SpaceManager.nowTagGap,
                  child: RegularText(
                    StringsManager.now,
                    fontSize: isArabic ? FontSizeManager.label : FontSizeManager.nowTag,
                    letterSpacing: isArabic ? null : LetterSpacingManager.nowTag,
                    color: ThemeEnum.onPrimaryContainer,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// a dash on a polar day with no time
class _Time extends ConsumerWidget {
  const _Time({required this.time, required this.minor});
  final TZDateTime? time;
  final bool minor;

  static const _dash = '—';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final time = this.time;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MediumText(
        time == null ? _dash : context.formatTime(time, digits),
        translate: false,
        fontSize: minor ? FontSizeManager.secondary : FontSizeManager.time,
        color: minor ? ThemeEnum.text2 : ThemeEnum.text,
        tabularFigures: true,
        maxLines: 1,
      ),
    );
  }
}
