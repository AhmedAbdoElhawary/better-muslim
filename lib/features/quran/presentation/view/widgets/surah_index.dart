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
import 'package:better_muslim/core/widgets/mushaf_star.dart';
import 'package:better_muslim/core/widgets/segmented.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

enum _Index { surah, juz, page }

/// 4.18's index: 114 surahs, 30 juz or 604 pages, each row grows into its page
class SurahIndex extends ConsumerStatefulWidget {
  const SurahIndex({this.current, this.onPick, super.key});

  /// the Index sheet's: the reader's page, its surah, juz and page marked
  final int? current;

  /// the Index sheet turns the reader it's over instead of opening one
  final ValueChanged<int>? onPick;

  @override
  ConsumerState<SurahIndex> createState() => _SurahIndexState();
}

class _SurahIndexState extends ConsumerState<SurahIndex> {
  var _index = _Index.surah;

  static const _skeletonRows = 8;

  void _pick(_Index index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final assetRaw = ref.watch(quranAssetsProvider);
    final digits = ref.watch(_digitsProvider);
    final assets = assetRaw.value;
    final surah = assetRaw.requireValue;

    final current = switch (widget.current) {
      final page? when assets != null => (page: page, info: assets.pageInfo(page)),
      _ => null,
    };
    final onPick = widget.onPick;

    final count = switch (_index) {
      _ when assets == null => _skeletonRows,
      _Index.surah => assets.surahs.length,
      _Index.juz => assets.juzs.length,
      _Index.page => quranPageCount,
    };

    return SliverMainAxisGroup(
      slivers: [
        if (onPick == null)
          SliverToBoxAdapter(
            child: _IndexTabs(index: _index, onChanged: _pick),
          )
        else
          /// the sheet opens at the reader's surah, the tabs stay in reach above it
          PinnedHeaderSliver(
            child: ColoredBox(
              color: context.getColor(ThemeEnum.surface),
              child: _IndexTabs(index: _index, onChanged: _pick),
            ),
          ),
        SliverList.builder(
          itemCount: count,
          itemBuilder: (context, i) => BmStagger(
            index: i,
            child: assets == null
                ? const _SkeletonRow()
                : switch (_index) {
                    _Index.surah => _SurahRow(
                      digits: digits,
                      surah: assets.surahs[i],
                      marked: current?.info.start.surah == i + 1,
                      onPick: onPick,
                    ),
                    _Index.juz => _JuzRow(
                      surah: surah.surah(assets.juzs[i].start.surah),
                      digits: digits,
                      juz: assets.juzs[i],
                      marked: current?.info.juz == i + 1,
                      onPick: onPick,
                    ),
                    _Index.page => _PageRow(
                      digits: digits,
                      assets: assets,
                      page: i + 1,
                      marked: current?.page == i + 1,
                      onPick: onPick,
                    ),
                  },
          ),
        ),
      ],
    );
  }
}

class _IndexTabs extends StatelessWidget {
  const _IndexTabs({required this.index, required this.onChanged});

  final _Index index;
  final ValueChanged<_Index> onChanged;

  @override
  Widget build(BuildContext context) {
    return OnlyPadding(
      top: SpaceManager.quranIndexTop,
      bottom: SpaceManager.s2,
      start: SpaceManager.s4,
      end: SpaceManager.s4,
      child: Segmented(
        values: _Index.values,
        selected: index,
        labelOf: (index) => switch (index) {
          _Index.surah => StringsManager.surah,
          _Index.juz => StringsManager.juz,
          _Index.page => StringsManager.page,
        },
        onChanged: onChanged,
      ),
    );
  }
}

class _SurahRow extends ConsumerWidget {
  const _SurahRow({
    required this.surah,
    required this.digits,
    required this.marked,
    required this.onPick,
  });

  final QuranSurah surah;
  final Digits digits;
  final bool marked;
  final ValueChanged<int>? onPick;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      marked: marked,
      onPick: onPick,
    );
  }
}

class _JuzRow extends ConsumerWidget {
  const _JuzRow({
    required this.juz,
    required this.digits,
    required this.surah,
    required this.marked,
    required this.onPick,
  });

  final QuranJuz juz;
  final Digits digits;
  final QuranSurah surah;
  final bool marked;
  final ValueChanged<int>? onPick;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      marked: marked,
      onPick: onPick,
    );
  }
}

class _PageRow extends ConsumerWidget {
  const _PageRow({
    required this.page,
    required this.digits,
    required this.assets,
    required this.marked,
    required this.onPick,
  });

  final int page;
  final Digits digits;
  final QuranAssets assets;
  final bool marked;
  final ValueChanged<int>? onPick;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      marked: marked,
      onPick: onPick,
    );
  }
}

final _digitsProvider = Provider.autoDispose(
  (ref) =>
      ref.watch(settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern)),
);

/// suraRow() of _gen/quran.js: the number in the star, the name over its line, the arabic name
class _Row extends ConsumerWidget {
  const _Row({
    required this.number,
    required this.page,
    required this.title,
    required this.subtitle,
    required this.args,
    required this.marked,
    required this.onPick,
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
  final bool marked;
  final ValueChanged<int>? onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onPick = this.onPick;
    if (onPick != null) {
      return _RowContent(
        number: number,
        page: page,
        title: title,
        titleArgs: titleArgs,
        subtitle: subtitle,
        args: args,
        arabic: arabic,
        marked: marked,
        onTap: () => onPick(page),
      );
    }
    return BmContainerTransform(
      radius: 0,
      closedColor: ThemeEnum.bg,
      closedBuilder: (context, open) => _RowContent(
        number: number,
        page: page,
        title: title,
        titleArgs: titleArgs,
        subtitle: subtitle,
        args: args,
        arabic: arabic,
        marked: marked,
        onTap: () async {
          await warmMushafPage(context, ref, page);
          if (context.mounted) open();
        },
      ),
      openBuilder: (context) => ReaderPage(page: page),
    );
  }
}

class _RowContent extends ConsumerWidget {
  const _RowContent({
    required this.number,
    required this.page,
    required this.title,
    required this.titleArgs,
    required this.subtitle,
    required this.args,
    required this.arabic,
    required this.marked,
    required this.onTap,
  });

  final String number;
  final int page;
  final String title;
  final Map<String, String>? titleArgs;
  final String subtitle;
  final Map<String, String> args;
  final String? arabic;

  /// the Index sheet's row of the page the reader is on
  final bool marked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleArgs = this.titleArgs;
    final arabic = this.arabic;
    return Semantics(
      button: true,
      selected: marked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        /// the page starts loading while the finger is still down
        onTapDown: (_) => warmMushafPage(context, ref, page),
        onTap: onTap,
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
                            color: marked ? ThemeEnum.primary : null,
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
                      color: marked ? ThemeEnum.primary : null,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
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
