import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timezone/timezone.dart';

/// dev builds only, shows milestone 2's data until milestone 3 builds the real home
class DevReadout extends ConsumerWidget {
  const DevReadout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasLocation = ref.watch(locationProvider.select((location) => location != null));
    if (!hasLocation) return const RegularText(StringsManager.noLocationYet);
    return Column(
      children: [
        const _Line(label: StringsManager.location, value: _PlaceValue()),
        const _Line(label: StringsManager.calculationMethod, value: _MethodValue()),
        const _Line(label: StringsManager.asr, value: _AsrValue()),
        const RSizedBox.vertical(SpaceManager.s3),
        for (final time in _Time.values) _Line(label: time.label, value: _TimeValue(time)),
        const RSizedBox.vertical(SpaceManager.s3),
        const _Line(label: StringsManager.nowShort, value: _PeriodValue()),
        const _Line(label: StringsManager.nextPrayer, value: _NextValue()),
        const _Line(label: StringsManager.hijriCalendar, value: _HijriValue()),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return VerticalPadding(
      padding: SpaceManager.s1,
      child: Row(
        children: [
          Expanded(child: RegularText(label, color: ThemeEnum.text2)),
          const RSizedBox.horizontal(SpaceManager.s3),
          Flexible(child: value),
        ],
      ),
    );
  }
}

class _PlaceValue extends ConsumerWidget {
  const _PlaceValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(
      locationProvider.select(
        (location) =>
            (name: location?.placeName, nameAr: location?.placeNameAr, mode: location?.mode),
      ),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    /// the latin name when the list has no arabic one (FR-003)
    final name = (isArabic ? place.nameAr : null) ?? place.name ?? '';
    final suffix = place.mode == LocationMode.manual
        ? StringsManager.manualSuffix
        : StringsManager.autoSuffix;
    return MediumText(suffix, args: {'city': name});
  }
}

class _MethodValue extends ConsumerWidget {
  const _MethodValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(todayTimesProvider.select((times) => times?.method));
    return method == null ? const _Missing() : MediumText(method.nameKey);
  }
}

class _AsrValue extends ConsumerWidget {
  const _AsrValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asrMethod = ref.watch(todayTimesProvider.select((times) => times?.asrMethod));
    return asrMethod == null ? const _Missing() : MediumText(asrMethod.nameKey);
  }
}

enum _Time {
  fajr(StringsManager.fajr),
  sunrise(StringsManager.sunrise),
  dhuhr(StringsManager.dhuhr),
  asr(StringsManager.asr),
  maghrib(StringsManager.maghrib),
  isha(StringsManager.isha);

  const _Time(this.label);
  final String label;

  TZDateTime? of(DayTimes times) => switch (this) {
    fajr => times.fajr,
    sunrise => times.sunrise,
    dhuhr => times.dhuhr,
    asr => times.asr,
    maghrib => times.maghrib,
    isha => times.isha,
  };
}

class _TimeValue extends ConsumerWidget {
  const _TimeValue(this.time);
  final _Time time;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(
      todayTimesProvider.select((times) => times == null ? null : time.of(times)),
    );
    final digits = ref.watch(settingsProvider.select((settings) => settings.value?.digits));
    if (value == null) return const _Missing();
    return MediumText(context.formatTime(value, digits ?? Digits.eastern), translate: false);
  }
}

class _PeriodValue extends ConsumerWidget {
  const _PeriodValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(periodProvider);
    return period == null ? const _Missing() : MediumText(period.nameKey);
  }
}

class _NextValue extends ConsumerWidget {
  const _NextValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextPrayerProvider);
    final now = ref.watch(tickerProvider).value ?? ref.watch(clockProvider)();
    final digits = ref.watch(settingsProvider.select((settings) => settings.value?.digits));
    if (next == null) return const _Missing();
    final (prayer, time) = next;
    final left = time.difference(now);
    final duration =
        '${left.inHours}:${_twoDigits(left.inMinutes % 60)}:${_twoDigits(left.inSeconds % 60)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MediumText(prayer.nameKey),
        const RSizedBox.horizontal(SpaceManager.s2),
        Flexible(
          child: RegularText(
            StringsManager.inDuration,
            args: {'duration': context.formatDigits(duration, digits ?? Digits.eastern)},
          ),
        ),
      ],
    );
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _HijriValue extends ConsumerWidget {
  const _HijriValue();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hijri = ref.watch(hijriDateProvider(ref.watch(todayProvider)));
    final digits = ref.watch(settingsProvider.select((settings) => settings.value?.digits));
    final date = '${hijri.day} ${context.tr(hijri.monthKey)} ${hijri.year}';
    return MediumText(context.formatDigits(date, digits ?? Digits.eastern), translate: false);
  }
}

/// a time the day doesn't have (polar) or a value not loaded yet
class _Missing extends StatelessWidget {
  const _Missing();

  static const _dash = '–';

  @override
  Widget build(BuildContext context) => const MediumText(_dash, translate: false);
}
