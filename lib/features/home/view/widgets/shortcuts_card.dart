import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/last_read.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/shortcut_row.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// continue reading, and the morning or evening azkar in english. 4.16 has only the first
class ShortcutsCard extends ConsumerWidget {
  const ShortcutsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final (ayah, page) = ref.watch(
      lastReadProvider.select((lastRead) => (lastRead.ayah, lastRead.page)),
    );
    final surah = ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
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
              'surah': surah == null ? '' : (isArabic ? surah.ar : surah.en),
              'ayah': number(ayah.ayah),
              'total': number(surah?.ayahs ?? 0),
            },
            divider: !isArabic,
            onTap: () => context.push(Routes.quranPage(page)),
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
