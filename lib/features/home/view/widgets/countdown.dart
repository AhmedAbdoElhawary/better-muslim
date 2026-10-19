import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/next_prayer.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/home/view/widgets/countdown_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// h:mm:ss to the next prayer, the one leaf on home that rebuilds every second. never mirrored
class Countdown extends ConsumerWidget {
  const Countdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = ref.watch(timeLeftProvider) ?? Duration.zero;
    final prayer = ref.watch(nextPrayerProvider.select((next) => next?.$1));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final (:hours, :minutes, :seconds) = countdownParts(left);
    final text = context.formatDigits(
      '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      digits,
    );

    /// read once a minute and not a live region, so a screen reader isn't told every second
    return Semantics(
      label: prayer == null
          ? null
          : context.tr(StringsManager.timeLeftSemantics, {
              'hours': context.formatDigits('$hours', digits),
              'minutes': context.formatDigits('$minutes', digits),
              'prayer': context.tr(prayer.nameKey),
            }),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            /// keyed from the end, so the seconds keep their slot when the hours lose a digit
            for (final (index, digit) in text.split('').indexed)
              CountdownDigit(digit, key: ValueKey(text.length - index)),
          ],
        ),
      ),
    );
  }
}
