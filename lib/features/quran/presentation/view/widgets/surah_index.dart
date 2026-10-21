import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/motion/container_transform.dart';
import 'package:better_muslim/core/widgets/motion/skeleton.dart';
import 'package:better_muslim/core/widgets/motion/stagger.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum _Index { surah, juz, page }

/// 4.18's index: 114 surahs, 30 juz or 604 pages, each row grows into its page
class SurahIndex extends ConsumerStatefulWidget {
  const SurahIndex({super.key});

  @override
  ConsumerState<SurahIndex> createState() => _SurahIndexState();
}

class _SurahIndexState extends ConsumerState<SurahIndex> {
  var _index = _Index.surah;

  static const _skeletonRows = 8;

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(quranAssetsProvider).value;
    final count = switch (_index) {
      _ when assets == null => _skeletonRows,
      _Index.surah => assets.surahs.length,
      _Index.juz => assets.juzs.length,
      _Index.page => quranPageCount,
    };
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: OnlyPadding(
            top: SpaceManager.quranIndexTop,
            bottom: SpaceManager.s2,
            start: SpaceManager.s4,
            end: SpaceManager.s4,
            child: Segmented(
              values: _Index.values,
              selected: _index,
              labelOf: (index) => switch (index) {
                _Index.surah => StringsManager.surah,
                _Index.juz => StringsManager.juz,
                _Index.page => StringsManager.page,
              },
              onChanged: (index) => setState(() => _index = index),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: count,
          itemBuilder: (context, i) => BmStagger(
            index: i,
            child: assets == null
                ? const _SkeletonRow()
                : switch (_index) {
                    _Index.surah => _SurahRow(assets.surahs[i]),
                    _Index.juz => _JuzRow(assets.juzs[i]),
                    _Index.page => _PageRow(i + 1),
                  },
          ),
        ),
      ],
    );
  }
}

class _SurahRow extends ConsumerWidget {
  const _SurahRow(this.surah);

  final QuranSurah surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(_digitsProvider);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return _Row(
      number: context.formatDigits('${surah.n}', digits),
      page: surah.page,
      title: isArabic ? surah.ar : surah.en,
      subtitle: StringsManager.surahRow,
      args: {
        'place': context.tr(surah.medinan ? StringsManager.medinan : StringsManager.meccan),
        'n': context.formatDigits('${surah.ayahs}', digits),
        'page': context.formatDigits('${surah.page}', digits),
      },
      arabic: isArabic ? null : surah.ar,
    );
  }
}

class _JuzRow extends ConsumerWidget {
  const _JuzRow(this.juz);

  final QuranJuz juz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(_digitsProvider);
    final surah = ref.watch(quranAssetsProvider).requireValue.surah(juz.start.surah);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final number = context.formatDigits('${juz.n}', digits);
    return _Row(
      number: number,
      page: juz.page,
      title: StringsManager.juzN,
      titleArgs: {'n': number},
      subtitle: StringsManager.juzRow,
      args: {
        'surah': isArabic ? surah.ar : surah.en,
        'ayah': context.formatDigits('${juz.start.ayah}', digits),
        'page': context.formatDigits('${juz.page}', digits),
      },
    );
  }
}

class _PageRow extends ConsumerWidget {
  const _PageRow(this.page);

  final int page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(_digitsProvider);
    final assets = ref.watch(quranAssetsProvider).requireValue;
    final info = assets.pageInfo(page);
    final surah = assets.surah(info.start.surah);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final number = context.formatDigits('$page', digits);
    return _Row(
      number: number,
      page: page,
      title: StringsManager.pageN,
      titleArgs: {'n': number},
      subtitle: StringsManager.pageRow,
      args: {
        'juz': context.formatDigits('${info.juz}', digits),
        'surah': isArabic ? surah.ar : surah.en,
      },
    );
  }
}

final _digitsProvider = Provider.autoDispose(
  (ref) =>
      ref.watch(settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern)),
);

/// suraRow() of _gen/quran.js: the number in the star, the name over its line, the arabic name
class _Row extends StatelessWidget {
  const _Row({
    required this.number,
    required this.page,
    required this.title,
    required this.subtitle,
    required this.args,
    this.titleArgs,
    this.arabic,
  });

  final String number;

  /// the page the row opens
  final int page;

  /// a StringsManager key with titleArgs, the name itself without
  final String title;
  final Map<String, String>? titleArgs;

  /// a StringsManager key
  final String subtitle;
  final Map<String, String> args;

  /// the arabic name at the end, in the english ui only
  final String? arabic;

  @override
  Widget build(BuildContext context) {
    final titleArgs = this.titleArgs;
    final arabic = this.arabic;
    return BmContainerTransform(
      radius: 0,
      closedColor: ThemeEnum.bg,
      closedBuilder: (context, open) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: open,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.getColor(ThemeEnum.outline))),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: SizeManager.surahRow.r),
              child: HorizontalPadding(
                padding: SpaceManager.s4,
                child: Row(
                  children: [
                    MushafStar(
                      child: SemiBoldText(
                        number,
                        translate: false,
                        fontSize: FontSizeManager.rowSubtitle,
                        tabularFigures: true,
                      ),
                    ),
                    const RSizedBox.horizontal(SpaceManager.surahRowGap),
                    Expanded(
                      child: VerticalPadding(
                        padding: SpaceManager.s1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MediumText(
                              title,
                              translate: titleArgs != null,
                              args: titleArgs ?? const {},
                              fontSize: FontSizeManager.surahName,
                            ),
                            const RSizedBox.vertical(SpaceManager.surahRowLineGap),
                            RegularText(
                              subtitle,
                              args: args,
                              fontSize: FontSizeManager.rowSubtitle,
                              color: ThemeEnum.text2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (arabic != null)
                      RegularText(
                        arabic,
                        translate: false,
                        font: FontEnum.dua,
                        fontSize: FontSizeManager.surahNameAr,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      openBuilder: (context) => ReaderPage(page: page),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const RSizedBox(
      height: SizeManager.surahRow,
      child: HorizontalPadding(
        padding: SpaceManager.s4,
        child: Row(
          children: [
            BmSkeleton(
              height: SizeManager.surahStar,
              width: SizeManager.surahStar,
              radius: SizeManager.surahStar / 2,
            ),
            RSizedBox.horizontal(SpaceManager.surahRowGap),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BmSkeleton(height: FontSizeManager.surahName, width: SizeManager.pageThumbH),
                  RSizedBox.vertical(SpaceManager.s1),
                  BmSkeleton(height: FontSizeManager.rowSubtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
