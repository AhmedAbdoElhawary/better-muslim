import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_dialog.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/empty_state.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// More › Downloads: the surahs on the phone under each reciter, with their size and a delete
class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider).value;
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            const CompactAppBar(StringsManager.downloads, heroTag: Routes.downloads),
            if (downloads == null || downloads.isEmpty) ...[
              const Spacer(),
              const EmptyState(
                title: StringsManager.noDownloads,
                body: StringsManager.noDownloadsBody,
              ),
              const Spacer(),
            ] else ...[
              Expanded(
                child: ListView(
                  padding: REdgeInsets.all(SpaceManager.screen),
                  children: [
                    for (final MapEntry(key: reciter, value: surahs) in downloads.entries) ...[
                      GroupedSection(
                        label: reciter.short,
                        children: [
                          for (final (:surah, :bytes) in surahs)
                            _DownloadRow(reciter: reciter, surah: surah, bytes: bytes),
                        ],
                      ),
                      const RSizedBox.vertical(SpaceManager.sectionGap),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({required this.reciter, required this.surah, required this.bytes});

  final Reciter reciter;
  final int surah;
  final int bytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(quranAssetsProvider).value?.surah(surah);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
      child: OnlyPadding(
        start: SpaceManager.listRowStart,
        top: SpaceManager.s1,
        bottom: SpaceManager.s1,
        child: Row(
          children: [
            Expanded(
              child: RegularText(
                info == null ? '' : (isArabic ? info.ar : info.en),
                translate: false,
                fontSize: FontSizeManager.body,
              ),
            ),
            const RSizedBox.horizontal(SpaceManager.listRowGap),
            RegularText(
              StringsManager.sizeMb,
              args: {'n': context.formatDigits((bytes / 1000000).toStringAsFixed(1), digits)},
              fontSize: FontSizeManager.secondary,
              color: ThemeEnum.text2,
            ),
            Semantics(
              button: true,
              label: context.tr(StringsManager.delete),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () async {
                  final confirmed = await showBmDialog(
                    context,
                    title: StringsManager.deleteDownloadTitle,
                    body: StringsManager.deleteDownloadBody,
                    action: StringsManager.delete,
                  );
                  if (confirmed) {
                    await ref.read(surahDownloadProvider((reciter, surah)).notifier).delete();
                  }
                },
                child: RSizedBox.square(
                  dimension: SizeManager.hit,
                  child: Center(
                    child: BmIcon.ui(
                      BmUiIcon.close,
                      size: SizeManager.iconInline.r,
                      color: context.getColor(ThemeEnum.text3),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
