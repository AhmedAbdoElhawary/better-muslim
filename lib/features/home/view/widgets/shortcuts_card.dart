import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/home/model/home_samples.dart';
import 'package:better_muslim/features/home/view/widgets/home_card.dart';
import 'package:better_muslim/features/home/view/widgets/shortcut_row.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// continue reading, and the morning or evening azkar in english. 4.16 has only the first
class ShortcutsCard extends ConsumerWidget {
  const ShortcutsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String number(int value) => context.formatDigits('$value', digits);
    return HomeCard(
      child: Column(
        children: [
          ShortcutRow(
            icon: BmIconName.quran,
            title: StringsManager.continueReading,
            subtitle: StringsManager.continueReadingSub,
            args: {
              'surah': isArabic ? HomeSamples.readingSurahAr : HomeSamples.readingSurah,
              'ayah': number(HomeSamples.readingAyah),
              'total': number(HomeSamples.readingAyahs),
            },
            divider: !isArabic,
            onTap: () => context.go(Routes.quran),
          ),
          if (!isArabic) const _AzkarRow(),
        ],
      ),
    );
  }
}

class _AzkarRow extends ConsumerWidget {
  const _AzkarRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final morning = ref.watch(morningAzkarProvider);
    return ShortcutRow(
      icon: BmIconName.azkar,
      title: morning ? StringsManager.morningAzkar : StringsManager.eveningAzkar,
      subtitle: morning ? StringsManager.morningAzkarSub : StringsManager.eveningAzkarSub,
      args: morning
          ? {'done': '${HomeSamples.morningAzkarDone}', 'total': '${HomeSamples.morningAzkarTotal}'}
          : {
              'done': '${HomeSamples.eveningAzkarDone}',
              'total': '${HomeSamples.eveningAzkarTotal}',
            },
      onTap: () => context.go(Routes.azkar),
    );
  }
}
