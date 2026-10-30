import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/features/quran/data/search_text.dart';
import 'package:better_muslim/features/quran/domain/quran_search.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/tafsir_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

extension on SearchScope {
  String get label => switch (this) {
    SearchScope.all => StringsManager.catAll,
    SearchScope.arabic => StringsManager.ayahText,
  };
}

/// 4.27. the first surah's hits are open, the rest are rows that open in place
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  var _scope = SearchScope.all;

  /// null is the first surah only, a new query or chip starts there again
  Set<int>? _open;

  /// the last search, a row opening doesn't search again
  ({String query, SearchScope scope, List<SearchAyah> ayahs})? _searched;
  var _result = (jump: null as QuranJump?, groups: const <int, List<SearchHit>>{});

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle(int surah, int first) => setState(() {
    final open = {
      ...(_open ?? {first}),
    };
    if (!open.remove(surah)) open.add(surah);
    _open = open;
  });

  @override
  Widget build(BuildContext context) {
    final ayahs = ref.watch(searchAyahsProvider).value;
    final assets = ref.watch(quranAssetsProvider).value;
    final query = _controller.text;
    if (ayahs != null && assets != null) {
      final searched = (query: query, scope: _scope, ayahs: ayahs);
      if (searched != _searched) {
        _searched = searched;
        _result = searchQuran(query, ayahs, assets, scope: _scope);
      }
    }
    final (:jump, :groups) = _result;
    final first = groups.keys.firstOrNull;
    final open = _open ?? {?first};
    final entries = <Widget>[
      if (jump != null) _JumpCard(jump),
      for (final (i, surah) in groups.keys.indexed)
        if (open.contains(surah)) ...[
          _GroupHeader(surah, count: groups[surah]!.length, onTap: () => _toggle(surah, first!)),
          for (final hit in groups[surah]!) _HitCard(hit),
        ] else if (i == 0 || open.contains(groups.keys.elementAt(i - 1)))
          _SurahRows([
            for (final next in groups.keys.skip(i).takeWhile((n) => !open.contains(n))) next,
          ], onTap: (surah) => _toggle(surah, first!)),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchBar(_controller, onChanged: () => setState(() => _open = null)),
            const RSizedBox.vertical(SpaceManager.s3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: REdgeInsetsDirectional.only(start: SpaceManager.s4, end: SpaceManager.s4),
              child: Row(
                children: [
                  for (final (i, scope) in SearchScope.values.indexed) ...[
                    if (i > 0) const RSizedBox.horizontal(SpaceManager.s2),
                    TafsirChip(
                      scope.label,
                      selected: scope == _scope,
                      onTap: () => setState(() {
                        _scope = scope;
                        _open = null;
                      }),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Column(
                      children: [
                        Expanded(
                          child: query.trim().isEmpty || ayahs == null
                              ? const SizedBox.shrink()
                              : const Center(
                                  child: RegularText(
                                    StringsManager.noAyahsFound,
                                    fontSize: FontSizeManager.body,
                                    color: ThemeEnum.text2,
                                  ),
                                ),
                        ),
                        const SafeArea(top: false, child: _Hint()),
                      ],
                    )
                  : ListView.builder(
                      padding: REdgeInsetsDirectional.only(
                        start: SpaceManager.s4,
                        end: SpaceManager.s4,
                        top: SpaceManager.searchSection,
                      ),
                      itemCount: entries.length + 1,
                      itemBuilder: (context, i) => i < entries.length
                          ? entries[i]
                          : const SafeArea(top: false, child: _Hint()),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// the field, its clear button and Cancel
class _SearchBar extends StatelessWidget {
  const _SearchBar(this.controller, {required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final text = controller.text;
    final style = GetRegularStyle(
      fontSize: FontSizeManager.searchField.sp,
      color: context.getColor(ThemeEnum.text),
      fontFamily: FontEnum.dua.arabic,
      fontFamilyFallback: [FontEnum.body.latin, FontEnum.body.arabic],
    );
    return OnlyPadding(
      top: SpaceManager.searchBarTop,
      start: SpaceManager.s4,
      end: SpaceManager.s4,
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(minHeight: SizeManager.hit.r),
              padding: REdgeInsetsDirectional.only(
                start: SpaceManager.searchFieldStart,
                end: SpaceManager.searchFieldEnd,
              ),
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.variant),
                borderRadius: BorderRadius.circular(RadiusManager.searchField.r),
              ),
              child: Row(
                children: [
                  BmIcon.ui(
                    BmUiIcon.search,
                    size: SizeManager.iconList.r,
                    color: context.getColor(ThemeEnum.text2),
                  ),
                  const RSizedBox.horizontal(SpaceManager.s2),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      onChanged: (_) => onChanged(),
                      style: style,
                      cursorColor: context.getColor(ThemeEnum.primary),
                      textInputAction: TextInputAction.search,

                      /// arabic sits on the right as 4.27 draws it, whatever the app's language
                      textDirection: RegExp('[؀-ۿ]').hasMatch(text) ? TextDirection.rtl : null,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintText: context.tr(StringsManager.searchQuran),
                        hintStyle: style.copyWith(color: context.getColor(ThemeEnum.text2)),
                      ),
                    ),
                  ),
                  if (text.isNotEmpty)
                    Semantics(
                      button: true,
                      label: context.tr(StringsManager.close),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          controller.clear();
                          onChanged();
                        },
                        child: RSizedBox.square(
                          dimension: SizeManager.hit,
                          child: Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: context.getColor(ThemeEnum.outlineStrong),
                                shape: BoxShape.circle,
                              ),
                              child: RSizedBox.square(
                                dimension: SizeManager.searchClear,
                                child: Center(
                                  child: BmIcon.ui(
                                    BmUiIcon.close,
                                    size: SizeManager.searchClearIcon.r,
                                    color: context.getColor(ThemeEnum.bg),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const RSizedBox.horizontal(SpaceManager.s3),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: context.pop,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: SizeManager.hit.r),
              child: const Center(
                child: RegularText(
                  StringsManager.cancel,
                  fontSize: FontSizeManager.body,
                  color: ThemeEnum.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JumpCard extends ConsumerWidget {
  const _JumpCard(this.jump);

  final QuranJump jump;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(quranAssetsProvider).value;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (assets == null) return const SizedBox.shrink();
    String number(int n) => context.formatDigits('$n', digits);
    final surah = assets.surah(jump.surah);
    final name = Localizations.localeOf(context).languageCode == 'ar' ? surah.ar : surah.en;
    final ayah = jump.ayah;
    final (label, title, meta) = switch (jump.kind) {
      JumpKind.surah => (
        StringsManager.jumpToSurah,
        context.tr(StringsManager.numberName, {'n': number(surah.n), 'name': name}),
        context.tr(StringsManager.jumpSurahMeta, {
          'place': context.tr(surah.medinan ? StringsManager.medinan : StringsManager.meccan),
          'count': number(surah.ayahs),
          'page': number(surah.page),
        }),
      ),
      JumpKind.page => (
        StringsManager.jumpToPage,
        context.tr(StringsManager.pageN, {'n': number(jump.page)}),
        context.tr(StringsManager.pageRow, {
          'juz': number(assets.pageInfo(jump.page).juz),
          'surah': name,
        }),
      ),
      JumpKind.ayah => (
        StringsManager.jumpToAyah,
        context.tr(StringsManager.numberName, {
          'n': context.formatDigits('${ayah!.surah}:${ayah.ayah}', digits),
          'name': name,
        }),
        context.tr(StringsManager.pageN, {'n': number(jump.page)}),
      ),
    };
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.quranPage(jump.page, ayah: ayah)),
        child: SurfaceCard(
          child: OnlyPadding(
            top: SpaceManager.s3,
            bottom: SpaceManager.s3,
            start: SpaceManager.listRowStart,
            end: SpaceManager.listRowEnd,
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.getColor(ThemeEnum.primaryContainer),
                    borderRadius: BorderRadius.circular(RadiusManager.searchJumpIcon.r),
                  ),
                  child: RSizedBox.square(
                    dimension: SizeManager.searchJumpIcon,
                    child: Center(
                      child: BmIcon(
                        BmIconName.quran,
                        size: SizeManager.iconList.r,
                        color: context.getColor(ThemeEnum.onPrimaryContainer),
                      ),
                    ),
                  ),
                ),
                const RSizedBox.horizontal(SpaceManager.listRowGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RegularText(label, fontSize: FontSizeManager.label, color: ThemeEnum.text3),
                      const RSizedBox.vertical(SpaceManager.rowLineGap),
                      MediumText(
                        title,
                        translate: false,
                        fontSize: FontSizeManager.searchJumpTitle,
                      ),
                      const RSizedBox.vertical(SpaceManager.rowLineGap),
                      RegularText(
                        meta,
                        translate: false,
                        fontSize: FontSizeManager.searchJumpMeta,
                        color: ThemeEnum.text2,
                      ),
                    ],
                  ),
                ),
                RegularText(
                  surah.ar,
                  translate: false,
                  font: FontEnum.dua,
                  fontSize: FontSizeManager.searchJumpName,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AL-FATIHA and its hit count over the open hits, a tap folds them back into a row
class _GroupHeader extends ConsumerWidget {
  const _GroupHeader(this.surah, {required this.count, required this.onTap});

  final int surah;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(quranAssetsProvider).value?.surah(surah);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (info == null) return const SizedBox.shrink();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Semantics(
      button: true,
      expanded: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: OnlyPadding(
          top: SpaceManager.searchSection,
          bottom: SpaceManager.searchHitGap,
          start: SpaceManager.s1,
          end: SpaceManager.s1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RegularText(
                isArabic ? info.ar : info.en.toUpperCase(),
                translate: false,
                fontSize: FontSizeManager.sectionLabel,
                letterSpacing: LetterSpacingManager.sectionLabel,
                color: ThemeEnum.text3,
              ),
              RegularText(
                context.formatDigits('$count', digits),
                translate: false,
                fontSize: FontSizeManager.sectionLabel,
                letterSpacing: LetterSpacingManager.sectionLabel,
                color: ThemeEnum.text3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// the ayah with the matched words washed behind their glyphs, the glyphs keep their ink
class _HitCard extends ConsumerWidget {
  const _HitCard(this.hit);

  final SearchHit hit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(quranAssetsProvider).value;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final font = ref.watch(
      settingsProvider.select((settings) => settings.value?.quranFont ?? QuranFont.kfgqpc),
    );
    if (assets == null) return const SizedBox.shrink();
    final key = hit.ayah.key;
    final page = assets.pageOf(key);
    return BottomPadding(
      padding: SpaceManager.searchHitGap,
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push(Routes.quranPage(page, ayah: key)),
          child: SurfaceCard(
            child: OnlyPadding(
              top: SpaceManager.searchHitTop,
              bottom: SpaceManager.s3,
              start: SpaceManager.s4,
              end: SpaceManager.s4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SemiBoldText(
                        context.formatDigits('$key', digits),
                        translate: false,
                        fontSize: FontSizeManager.label,
                        color: ThemeEnum.primary,
                        tabularFigures: true,
                      ),
                      RegularText(
                        StringsManager.pageN,
                        args: {'n': context.formatDigits('$page', digits)},
                        fontSize: FontSizeManager.label,
                        color: ThemeEnum.text3,
                      ),
                    ],
                  ),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Wrap(
                      spacing: SpaceManager.s1.r,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final (i, word) in hit.ayah.words.indexed)
                          _Word(word, font: font.font, washed: hit.arabic.contains(i)),
                      ],
                    ),
                  ),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: RegularText(
                      hit.ayah.translation,
                      translate: false,
                      fontSize: FontSizeManager.caption,
                      height: LineHeightManager.searchTranslation,
                      color: ThemeEnum.text2,
                    ),
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

class _Word extends StatelessWidget {
  const _Word(this.word, {required this.font, required this.washed});

  final String word;
  final FontEnum font;
  final bool washed;

  @override
  Widget build(BuildContext context) {
    final text = RegularText(
      word,
      translate: false,
      font: font,
      fontSize: FontSizeManager.searchAyah,
      height: LineHeightManager.searchAyah,
      color: ThemeEnum.text,
    );
    if (!washed) return text;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.primaryContainer),
        borderRadius: BorderRadius.circular(RadiusManager.searchWash.r),
      ),
      child: HorizontalPadding(padding: SpaceManager.searchWashSide, child: text),
    );
  }
}

/// the closed surahs between open ones, one card
class _SurahRows extends ConsumerWidget {
  const _SurahRows(this.surahs, {required this.onTap});

  final List<int> surahs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(quranAssetsProvider).value;
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (assets == null) return const SizedBox.shrink();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return TopPadding(
      padding: SpaceManager.searchSection - SpaceManager.searchHitGap,
      child: GroupedSection(
        children: [
          for (final surah in surahs)
            Semantics(
              button: true,
              expanded: false,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(surah),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: SizeManager.searchRow.r),
                  child: OnlyPadding(
                    start: SpaceManager.listRowStart,
                    end: SpaceManager.listRowEnd,
                    child: Row(
                      children: [
                        RSizedBox(
                          width: SizeManager.searchRowNumber,
                          child: RegularText(
                            context.formatDigits('$surah', digits),
                            translate: false,
                            fontSize: FontSizeManager.label,
                            color: ThemeEnum.text3,
                            tabularFigures: true,
                          ),
                        ),
                        const RSizedBox.horizontal(SpaceManager.listRowGap),
                        Expanded(
                          child: RegularText(
                            isArabic ? assets.surah(surah).ar : assets.surah(surah).en,
                            translate: false,
                            fontSize: FontSizeManager.body,
                          ),
                        ),
                        Transform.flip(
                          flipX: Directionality.of(context) == TextDirection.rtl,
                          child: BmIcon.ui(
                            BmUiIcon.forward,
                            size: SizeManager.searchChevron.r,
                            color: context.getColor(ThemeEnum.text3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint();

  @override
  Widget build(BuildContext context) {
    return const SymmetricPadding(
      horizontal: SpaceManager.searchHintSide,
      vertical: SpaceManager.s4,
      child: RegularText(
        StringsManager.searchQuranHint,
        fontSize: FontSizeManager.label,
        height: LineHeightManager.searchTranslation,
        color: ThemeEnum.text2,
      ),
    );
  }
}
