import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// english "Thu 15 Oct · 4 Jumada I 1448", arabic the full weekday and the hijri date (4.16)
class DateLine extends ConsumerWidget {
  const DateLine({super.key});

  static const _separator = ' · ';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final hijri = ref.watch(hijriDateProvider(today));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final bright = ref.watch(skyBrightProvider);
    final locale = Localizations.localeOf(context).languageCode;
    final day = locale == 'ar'
        ? DateFormat.EEEE(locale).format(today)
        : DateFormat('EEE d MMM', locale).format(today);
    final date = '$day$_separator${hijri.day} ${context.tr(hijri.monthKey)} ${hijri.year}';
    return RegularText(
      context.formatDigits(date, digits),
      translate: false,
      color: bright ? ThemeEnum.onSkyBright : ThemeEnum.onSky,
    );
  }
}
