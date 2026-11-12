import 'dart:async';

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
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
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:better_muslim/core/widgets/search_field.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/features/quran/data/quran_store.dart';
import 'package:better_muslim/features/quran/data/search_text.dart';
import 'package:better_muslim/features/quran/domain/quran_search.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/tafsir_chip.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

extension on SearchScope {
  String get label => switch (this) {
    SearchScope.all => StringsManager.catAll,
    SearchScope.arabic => StringsManager.ayahText,
    SearchScope.translation => StringsManager.translation,
    SearchScope.root => StringsManager.root,
  };
}

/// 4.27. every surah starts as a row with its count, a tap opens its hits in place
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({this.fromReader = false, super.key});

  /// a result goes back to the reader that opened it instead of opening another one
  final bool fromReader;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  /// one search after a pause, not one per letter on a slow phone
  static const _typingPause = Duration(milliseconds: 150);

  final _controller = TextEditingController();
  var _query = '';
  Timer? _typing;
  var _scope = SearchScope.all;

  /// a new query or chip folds every surah again
  var _open = <int>{};

  /// the last search, a row opening doesn't search again
  ({String query, SearchScope scope, List<SearchAyah> ayahs})? _searched;
  var _result = (jump: null as QuranJump?, groups: const <int, List<SearchHit>>{});

  @override
  void dispose() {
    _typing?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _type(String text) {
    setState(() {});
    _typing?.cancel();
    _typing = Timer(
      _typingPause,
      () => setState(() {
        _query = text;
        _open = {};
      }),
    );
  }

  /// only a search I meant is kept, a half typed one is not
  void _save() {
    final query = _controller.text.trim();
    if (query.isNotEmpty) ref.read(quranStoreProvider).saveSearch(query);
  }

  void _go(int page, AyahKey? ayah) {
    _save();
    if (widget.fromReader) {
      context.pop((page, ayah));
    } else {
      context.push(Routes.quranPage(page, ayah: ayah));
    }
  }

  void _submit(String text) {
    _typing?.cancel();
    setState(() {
      _query = text;
      _open = {};
    });
    _save();
  }

  void _pick(String query) {
    _controller.text = query;
    _submit(query);
  }

  void _toggle(int surah) => setState(() {
    final open = {..._open};
    if (!open.remove(surah)) open.add(surah);
    _open = open;
  });

  @override
  Widget build(BuildContext context) {
    final ayahs = ref.watch(searchAyahsProvider).value;
    final assets = ref.watch(quranAssetsProvider).value;
    final query = _query;
    if (ayahs != null && assets != null) {
      final searched = (query: query, scope: _scope, ayahs: ayahs);
      if (searched != _searched) {
        _searched = searched;
        _result = searchQuran(query, ayahs, assets, scope: _scope);
      }
    }
    final (:jump, :groups) = _result;
    final open = _open;
    final entries = <Widget>[
      if (jump != null) _JumpCard(jump, onOpen: _go),
      for (final (i, surah) in groups.keys.indexed)
        if (open.contains(surah)) ...[
          _GroupHeader(surah, count: groups[surah]!.length, onTap: () => _toggle(surah)),
          for (final hit in groups[surah]!) _HitCard(hit, onOpen: _go),
        ] else if (i == 0 || open.contains(groups.keys.elementAt(i - 1)))
          _SurahRows([
            for (final next in groups.keys.skip(i).takeWhile((n) => !open.contains(n)))
              (surah: next, count: groups[next]!.length),
          ], onTap: _toggle),
    ];
    final allOpen = open.length == groups.length;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SearchBar(_controller, onChanged: _type, onSubmitted: _submit),
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
                        _open = {};
                      }),
                    ),
                  ],
                ],
              ),
            ),
            if (groups.isNotEmpty)
              _ResultCount(
                matches: groups.values
                    .expand((hits) => hits)
                    .fold(0, (sum, hit) => sum + hit.count),
                ayahs: groups.values.fold(0, (sum, hits) => sum + hits.length),
                surahs: groups.length,
                allOpen: allOpen,
                onToggle: () => setState(() => _open = allOpen ? {} : {...groups.keys}),
              ),
            Expanded(
              child: entries.isEmpty
                  ? Column(
                      children: [
                        Expanded(
                          child: query.trim().isEmpty
                              ? _Recent(onPick: _pick)
                              : ayahs == null || assets == null
                              ? const Center(child: BmStarLoader())
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
                        top: groups.isEmpty ? SpaceManager.searchSection : SpaceManager.s1,
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

/// the back chevron and the field
class _SearchBar extends StatelessWidget {
  const _SearchBar(this.controller, {required this.onChanged, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return OnlyPadding(
      top: SpaceManager.searchBarTop,
      start: SpaceManager.s2,
      end: SpaceManager.s4,
      child: Row(
        children: [
          const BarBackButton(),
          Expanded(
            child: SearchField(
              hint: StringsManager.searchQuran,
              controller: controller,
              filled: true,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

class _JumpCard extends ConsumerWidget {
  const _JumpCard(this.jump, {required this.onOpen});

  final QuranJump jump;
  final void Function(int page, AyahKey? ayah) onOpen;

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
        context.tr(StringsManager.surahRow, {
          'place': context.tr(surah.medinan ? StringsManager.medinan : StringsManager.meccan),
          'n': number(surah.ayahs),
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
        onTapDown: (_) => warmMushafPage(context, ref, jump.page),
        onTap: () => onOpen(jump.page, ayah),
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
  const _HitCard(this.hit, {required this.onOpen});

  final SearchHit hit;
  final void Function(int page, AyahKey? ayah) onOpen;

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
          onTapDown: (_) => warmMushafPage(context, ref, page),
          onTap: () => onOpen(page, key),
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
                  _Words(
                    [for (final word in hit.ayah.words) font.drawn(word)],
                    washed: hit.arabic,
                    direction: TextDirection.rtl,
                    font: font.font,
                    fontSize: FontSizeManager.searchAyah,
                    height: LineHeightManager.searchAyah,
                    color: ThemeEnum.text,
                  ),
                  _Words(
                    hit.ayah.translation,
                    washed: hit.translation,
                    direction: TextDirection.ltr,
                    fontSize: FontSizeManager.caption,
                    height: LineHeightManager.searchTranslation,
                    color: ThemeEnum.text2,
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

/// word by word, so a matched word is washed behind its glyphs and never recolored
class _Words extends StatelessWidget {
  const _Words(
    this.words, {
    required this.washed,
    required this.direction,
    required this.fontSize,
    required this.height,
    required this.color,
    this.font = FontEnum.body,
  });

  final List<String> words;

  final Set<int> washed;
  final TextDirection direction;
  final FontEnum font;
  final double fontSize;
  final double height;
  final ThemeEnum color;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: direction,
      child: Wrap(
        spacing: SpaceManager.s1.r,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final (i, word) in words.indexed)
            _Wash(
              washed: washed.contains(i),
              child: RegularText(
                word,
                translate: false,
                font: font,
                fontSize: fontSize,
                height: height,
                color: color,
              ),
            ),
        ],
      ),
    );
  }
}

class _Wash extends StatelessWidget {
  const _Wash({required this.washed, required this.child});

  final bool washed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!washed) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.primaryContainer),
        borderRadius: BorderRadius.circular(RadiusManager.searchWash.r),
      ),
      child: HorizontalPadding(padding: SpaceManager.searchWashSide, child: child),
    );
  }
}

/// the closed surahs between open ones, one card
class _SurahRows extends ConsumerWidget {
  const _SurahRows(this.surahs, {required this.onTap});

  final List<({int surah, int count})> surahs;
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
          for (final (:surah, :count) in surahs)
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
                        RegularText(
                          context.formatDigits('$count', digits),
                          translate: false,
                          fontSize: FontSizeManager.label,
                          color: ThemeEnum.text3,
                          tabularFigures: true,
                        ),
                        const RSizedBox.horizontal(SpaceManager.s2),
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

/// 15 times in 12 ayahs in 5 surahs, and one switch that opens or folds every surah
class _ResultCount extends ConsumerWidget {
  const _ResultCount({
    required this.matches,
    required this.ayahs,
    required this.surahs,
    required this.allOpen,
    required this.onToggle,
  });

  final int matches;
  final int ayahs;
  final int surahs;
  final bool allOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return OnlyPadding(
      top: SpaceManager.s1,
      start: SpaceManager.s4 + SpaceManager.s1,
      end: SpaceManager.s4,
      child: Row(
        children: [
          Expanded(
            child: RegularText(
              StringsManager.searchCount,
              args: {
                'matches': context.formatDigits('$matches', digits),
                'ayahs': context.formatDigits('$ayahs', digits),
                'surahs': context.formatDigits('$surahs', digits),
              },
              fontSize: FontSizeManager.label,
              color: ThemeEnum.text2,
            ),
          ),
          _TextButton(allOpen ? StringsManager.foldAll : StringsManager.expandAll, onTap: onToggle),
        ],
      ),
    );
  }
}

/// the last searches while the field is empty, a tap searches again
class _Recent extends ConsumerWidget {
  const _Recent({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searches = ref.watch(searchesProvider).value ?? const [];
    if (searches.isEmpty) return const SizedBox.shrink();
    return ListView(
      padding: REdgeInsetsDirectional.only(
        start: SpaceManager.s4,
        end: SpaceManager.s4,
        top: SpaceManager.s3,
      ),
      children: [
        OnlyPadding(
          start: SpaceManager.s1,
          child: Row(
            children: [
              const Expanded(
                child: RegularText(
                  StringsManager.recentSearches,
                  fontSize: FontSizeManager.sectionLabel,
                  letterSpacing: LetterSpacingManager.sectionLabel,
                  color: ThemeEnum.text3,
                ),
              ),
              _TextButton(
                StringsManager.clearAll,
                onTap: () => ref.read(quranStoreProvider).clearSearches(),
              ),
            ],
          ),
        ),
        GroupedSection(
          children: [
            for (final query in searches)
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onPick(query),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: SizeManager.searchRow.r),
                    child: OnlyPadding(
                      start: SpaceManager.listRowStart,
                      child: Row(
                        children: [
                          BmIcon.ui(
                            BmUiIcon.search,
                            size: SizeManager.searchChevron.r,
                            color: context.getColor(ThemeEnum.text3),
                          ),
                          const RSizedBox.horizontal(SpaceManager.listRowGap),
                          Expanded(
                            child: RegularText(
                              query,
                              translate: false,
                              fontSize: FontSizeManager.body,
                              maxLines: 1,
                            ),
                          ),
                          _RemoveSearch(query),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RemoveSearch extends ConsumerWidget {
  const _RemoveSearch(this.query);

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: context.tr(StringsManager.removeSearch, {'query': query}),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(quranStoreProvider).removeSearch(query),
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: BmIcon.ui(
              BmUiIcon.close,
              size: SizeManager.searchChevron.r,
              color: context.getColor(ThemeEnum.text3),
            ),
          ),
        ),
      ),
    );
  }
}

/// a primary word with the whole 44 high hit
class _TextButton extends StatelessWidget {
  const _TextButton(this.label, {required this.onTap});

  /// a StringsManager key
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r),
          child: Center(
            child: RegularText(label, fontSize: FontSizeManager.label, color: ThemeEnum.primary),
          ),
        ),
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
