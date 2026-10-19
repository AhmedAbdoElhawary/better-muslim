import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/shortcut_row.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/features/home/model/home_samples.dart';
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
    return SurfaceCard(
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
    final set = ref.watch(currentAzkarSetProvider);
    final progress = ref.watch(azkarProgressProvider(set));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return ShortcutRow(
      icon: BmIconName.azkar,
      title: set.titleKey,
      subtitle: set.subtitleKey,
      args: {
        'done': context.formatDigits('${progress.done}', digits),
        'total': context.formatDigits('${progress.total}', digits),
      },
      onTap: () => context.go(Routes.azkarSet(set)),
    );
  }
}
