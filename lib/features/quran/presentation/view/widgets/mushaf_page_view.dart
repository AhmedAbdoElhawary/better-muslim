import 'dart:async';
import 'dart:math' as math;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/mushaf_star.dart';
import 'package:better_muslim/features/quran/data/mushaf_files.dart';
import 'package:better_muslim/features/quran/domain/bookmark.dart';
import 'package:better_muslim/features/quran/domain/kashida.dart';
import 'package:better_muslim/features/quran/domain/mushaf_layout.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';
import 'package:better_muslim/features/quran/domain/note.dart';
import 'package:better_muslim/features/quran/presentation/providers/mushaf_style_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the colors a page paints with, from the page palette
typedef MushafColors = ({
  Color page,
  Color ink,
  Color ink2,
  Color ornament,
  Color ornamentSoft,
  Color gutter,
  Color selection,
  Color follow,
  Color highlight,
});

/// a qcf style's page font and where its ink sits, null for text. a colored one keeps its own colors
typedef MushafGlyphs = ({String family, double ink, bool colored});

/// one color of V4's tajweed key and its name
typedef TajweedRule = ({Color color, String label});

/// how a screen reader reads an ayah, on the page and in its cell (FR-052), with the translation
/// shown
String ayahLabel(
  BuildContext context, {
  required QuranSurah surah,
  required AyahKey ayah,
  required String arabic,
  required String? translation,
}) {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return [
    context.tr(StringsManager.quranAyahN, {
      'surah': isArabic ? surah.ar : surah.en,
      'n': '${ayah.ayah}',
    }),
    arabic,
    ?translation,
  ].join('\n');
}

/// one page of the mushaf as printed (4.19), painted by one render object instead of a widget
/// per word, so a turn only paints. a long press or a double tap on a word gives its ayah
class MushafPageView extends ConsumerStatefulWidget {
  const MushafPageView(this.number, {this.onAyah, this.onCheck, super.key});

  final int number;
  final ValueChanged<AyahKey>? onAyah;
  final ValueChanged<AyahKey>? onCheck;

  @override
  ConsumerState<MushafPageView> createState() => _MushafPageViewState();
}

class _MushafPageViewState extends ConsumerState<MushafPageView>
    with SingleTickerProviderStateMixin {
  /// only the wash's alpha moves, the glyphs never do (research R4)
  late final _wash = AnimationController(vsync: this, duration: BmMotion.micro);

  /// kept while its wash fades out
  AyahKey? _washed;

  @override
  void initState() {
    super.initState();
    _washed = ref.read(selectionProvider).sheet;
    _wash.value = _washed == null ? 0 : 1;
    ref.listenManual(selectionProvider.select((selection) => selection.sheet), (_, key) {
      if (key == null) {
        _wash.reverse();
        return;
      }
      setState(() => _washed = key);
      _wash.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _wash.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final number = widget.number;
    final page = ref.watch(mushafPageProvider(number));
    final style = ref.watch(
      settingsProvider.select((settings) => settings.value?.mushafStyle ?? MushafStyle.text),
    );

    /// the page waits for its font, a font loaded once lays out in the first frame
    String? family;
    List<Color>? palette;
    var waiting = false;
    if (style != MushafStyle.text) {
      final files = ref.watch(mushafFilesProvider);
      final index = style.palette(ref.watch(pageColorProvider).resolve(dark: context.isThemeDark));
      family = files.loaded(style, number, palette: index);
      if (family == null) {
        final font = ref.watch(qcfFontProvider((style, number, index)));

        /// a page color change keeps the old palette's words until the new one is loaded
        family =
            font.value ??
            [for (var other = 0; other < 3; other++) files.loaded(style, number, palette: other)]
                .nonNulls
                .firstOrNull;
        waiting = family == null && font.isLoading;
      }
      if (style.colored && family != null) {
        palette = ref.watch(tajweedColorsProvider((number, index))).value;
      }
    }
    final assets = ref.watch(quranAssetsProvider).value;
    final info = assets?.pageInfo(number);
    final lines = page.value?.lines ?? const <MushafLine>[];
    final keys = {for (final line in lines) ...line.words.map((word) => word.key)};
    final shown = shownTranslation(context, ref);
    final texts = {
      for (final surah in keys.map((key) => key.surah).toSet())
        surah: ref.watch(translationProvider((shown, surah))).value,
    };
    return _MushafPaper(
      /// a switch to or from V1 reloads the page, the old print's words never meet the new font
      page: waiting || page.isLoading ? null : page.value,
      number: _eastern(number),
      placeholder: page.hasValue && page.value == null,
      surah: info == null ? '' : assets!.surah(info.start.surah).ar,
      juz: info == null ? '' : '$mushafJuzWord ${_eastern(info.juz)}',
      names: _names(page.value, assets),
      eastern: _eastern,
      unit: ScreenUtil().scaleWidth,
      selected: _washed,
      wash: _wash,
      chosen: ref.watch(selectionProvider.select((selection) => selection.chosen)),
      highlighted: ref.watch(
        notesProvider.select(
          (notes) => {
            for (final note in notes.value ?? const <Note>[])
              if (note.highlight && keys.contains(note.ayah)) note.ayah,
          },
        ),
      ),
      bookmarked: {
        for (final bookmark
            in ref.watch(bookmarksProvider.select((bookmarks) => bookmarks.value)) ??
                const <Bookmark>[])
          if (bookmark.ayah case final ayah? when keys.contains(ayah))
            ayah: context.getColor(bookmark.color.theme),
      },

      /// moves on the frame the next file starts, no fade (SC-003)
      following: ref.watch(playingAyahProvider),
      onAyah: widget.onAyah,
      onCheck: widget.onCheck,
      labels: {
        if (assets != null)
          for (final key in keys)
            key: ayahLabel(
              context,
              surah: assets.surah(key.surah),
              ayah: key,
              arabic: ayahText([?page.value], key),
              translation: texts[key.surah]?.elementAtOrNull(key.ayah - 1),
            ),
      },
      direction: Directionality.of(context),
      font: ref.watch(
        settingsProvider.select((settings) => settings.value?.quranFont ?? QuranFont.kfgqpc),
      ),
      glyphs: family == null ? null : (family: family, ink: style.ink, colored: style.colored),
      tajweed:
          palette == null || palette.length <= _tajweedKey.map((rule) => rule.$1).reduce(math.max)
          ? null
          : [
              for (final (entry, label) in _tajweedKey)
                (color: palette[entry], label: context.tr(label)),
            ],
      step: ref.watch(settingsProvider.select((settings) => settings.value?.mushafSize ?? 0)),
      colors: (
        page: context.getColor(ThemeEnum.page),
        ink: context.getColor(ThemeEnum.ink),
        ink2: context.getColor(ThemeEnum.ink2),
        ornament: context.getColor(ThemeEnum.ornament),
        ornamentSoft: context.getColor(ThemeEnum.ornamentSoft),
        gutter: context.getColor(ThemeEnum.gutter),
        selection: context.getColor(ThemeEnum.selectionWash),
        follow: context.getColor(ThemeEnum.followWash),
        highlight: context.getColor(ThemeEnum.highlightWash),
      ),
    );
  }
}

/// the printed key with each rule's entry in V4's palettes, the madd first for the right side
const _tajweedKey = [
  (3, StringsManager.tajweedLazim),
  (9, StringsManager.tajweedWajib),
  (4, StringsManager.tajweedJaiz),
  (5, StringsManager.tajweedTabii),
  (6, StringsManager.tajweedIkhfa),
  (1, StringsManager.tajweedIdgham),
  (7, StringsManager.tajweedTafkheem),
  (8, StringsManager.tajweedQalqalah),
];

/// the page's digits as the mushaf prints them, in both languages
String _eastern(int n) => formatDigitsIn('$n', language: 'ar', digits: Digits.eastern);

/// the arabic names of the surahs starting on the page
Map<int, String> _names(MushafPage? page, QuranAssets? assets) => {
  for (final line in page?.lines ?? const <MushafLine>[])
    if (line.surah case final surah? when assets != null) surah: assets.surah(surah).ar,
};

/// lays the page out the way the reader will before it opens, so the container transform never
/// waits a frame on its words. a size, font or ink the reader doesn't end up with only misses
Future<void> warmMushafPage(BuildContext context, WidgetRef ref, int number) async {
  final assets = await ref.read(quranAssetsProvider.future);
  final json = await assets.page(number);
  if (json == null || !context.mounted) return;
  final page = MushafPage.fromJson(number, json);

  /// decoded now, the reader's labels then find them in the assets' cache
  for (final surah in {
    for (final line in page.lines) ...line.words.map((word) => word.key.surah),
  }) {
    await assets.surahText(surah);
  }
  final settings = ref.read(settingsProvider).value;
  final style = settings?.mushafStyle ?? MushafStyle.text;
  if (!context.mounted) return;
  final color = ref.read(pageColorProvider).resolve(dark: context.isThemeDark);
  String? family;
  if (style != MushafStyle.text) {
    family = await ref.read(qcfFontProvider((style, number, style.palette(color))).future);
  }
  if (!context.mounted) return;
  _laidOf((
    page: page,
    number: _eastern(number),
    names: _names(page, assets),
    eastern: _eastern,
    unit: ScreenUtil().scaleWidth,
    font: settings?.quranFont ?? QuranFont.kfgqpc,
    glyphs: family == null ? null : (family: family, ink: style.ink, colored: style.colored),
    step: settings?.mushafSize ?? 0,
    ink: AppTheme.page(color, ref.read(themeIdProvider)).getColor(ThemeEnum.ink),

    /// the reader fills the root navigator, in its transition too. a copy, in debug a size belongs
    /// to its render object and the page may not adopt it
    viewport: Size.copy(Navigator.of(context, rootNavigator: true).context.size!),
  ));
}

class _MushafPaper extends LeafRenderObjectWidget {
  const _MushafPaper({
    required this.page,
    required this.number,
    required this.placeholder,
    required this.surah,
    required this.juz,
    required this.names,
    required this.eastern,
    required this.unit,
    required this.selected,
    required this.wash,
    required this.chosen,
    required this.highlighted,
    required this.bookmarked,
    required this.following,
    required this.onAyah,
    required this.onCheck,
    required this.labels,
    required this.direction,
    required this.font,
    required this.glyphs,
    required this.tajweed,
    required this.step,
    required this.colors,
  });

  final MushafPage? page;
  final String number;
  final bool placeholder;
  final String surah;
  final String juz;
  final Map<int, String> names;
  final String Function(int n) eastern;
  final double unit;
  final AyahKey? selected;
  final Animation<double> wash;
  final Set<AyahKey> chosen;
  final Set<AyahKey> highlighted;
  final Map<AyahKey, Color> bookmarked;
  final AyahKey? following;
  final ValueChanged<AyahKey>? onAyah;
  final ValueChanged<AyahKey>? onCheck;
  final Map<AyahKey, String> labels;
  final TextDirection direction;
  final QuranFont font;
  final MushafGlyphs? glyphs;
  final List<TajweedRule>? tajweed;
  final int step;
  final MushafColors colors;

  @override
  RenderMushafPage createRenderObject(BuildContext context) => RenderMushafPage(
    page: page,
    number: number,
    placeholder: placeholder,
    surah: surah,
    juz: juz,
    names: names,
    eastern: eastern,
    unit: unit,
    selected: selected,
    wash: wash,
    chosen: chosen,
    highlighted: highlighted,
    bookmarked: bookmarked,
    following: following,
    onAyah: onAyah,
    onCheck: onCheck,
    labels: labels,
    direction: direction,
    font: font,
    glyphs: glyphs,
    tajweed: tajweed,
    step: step,
    colors: colors,
  );

  @override
  void updateRenderObject(BuildContext context, RenderMushafPage renderObject) {
    renderObject
      ..page = page
      ..number = number
      ..placeholder = placeholder
      ..surah = surah
      ..juz = juz
      ..names = names
      ..eastern = eastern
      ..unit = unit
      ..selected = selected
      ..wash = wash
      ..chosen = chosen
      ..highlighted = highlighted
      ..bookmarked = bookmarked
      ..following = following
      ..onAyah = onAyah
      ..onCheck = onCheck
      ..labels = labels
      ..direction = direction
      ..font = font
      ..glyphs = glyphs
      ..tajweed = tajweed
      ..step = step
      ..colors = colors;
  }
}

/// laid out once per page and size and kept while the page lives. an ink crossfade only repaints,
/// the text is laid out in the new ink once it ends
class RenderMushafPage extends RenderBox {
  RenderMushafPage({
    required this._page,
    required this._number,
    required this._placeholder,
    required this._surah,
    required this._juz,
    required this._names,
    required this.eastern,
    required this._unit,
    required this._selected,
    required this._wash,
    required this._chosen,
    required this._highlighted,
    required this._bookmarked,
    required this._following,
    required this.onAyah,
    required this._onCheck,
    required this._labels,
    required this._direction,
    required this._font,
    required this._glyphs,
    required this._tajweed,
    required this._step,
    required this._colors,
  });

  MushafPage? _page;
  set page(MushafPage? value) {
    if (identical(value, _page)) return;
    _page = value;
    _relayout();
  }

  String _number;
  set number(String value) {
    if (value == _number) return;
    _number = value;
    _relayout();
  }

  bool _placeholder;
  set placeholder(bool value) {
    if (value == _placeholder) return;
    _placeholder = value;
    markNeedsPaint();
  }

  String _surah;
  set surah(String value) {
    if (value == _surah) return;
    _surah = value;
    _header = null;
    markNeedsPaint();
  }

  String _juz;
  set juz(String value) {
    if (value == _juz) return;
    _juz = value;
    _header = null;
    markNeedsPaint();
  }

  Map<int, String> _names;
  set names(Map<int, String> value) {
    if (mapEquals(value, _names)) return;
    _names = value;
    _relayout();
  }

  String Function(int n) eastern;

  double _unit;
  set unit(double value) {
    if (value == _unit) return;
    _unit = value;
    _relayout();
  }

  AyahKey? _selected;
  set selected(AyahKey? value) {
    if (value == _selected) return;
    _selected = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  Animation<double> _wash;
  set wash(Animation<double> value) {
    if (value == _wash) return;
    if (attached) {
      _wash.removeListener(markNeedsPaint);
      value.addListener(markNeedsPaint);
    }
    _wash = value;
    markNeedsPaint();
  }

  /// the ayahs picked for sharing, washed in full
  Set<AyahKey> _chosen;
  set chosen(Set<AyahKey> value) {
    if (setEquals(value, _chosen)) return;
    _chosen = value;
    markNeedsPaint();
  }

  Set<AyahKey> _highlighted;
  Set<AyahKey> get highlighted => _highlighted;
  set highlighted(Set<AyahKey> value) {
    if (setEquals(value, _highlighted)) return;
    _highlighted = value;
    markNeedsPaint();
  }

  /// each bookmarked ayah on the page in its category's color
  Map<AyahKey, Color> _bookmarked;
  Map<AyahKey, Color> get bookmarked => _bookmarked;
  set bookmarked(Map<AyahKey, Color> value) {
    if (mapEquals(value, _bookmarked)) return;
    _bookmarked = value;
    markNeedsPaint();
  }

  AyahKey? _following;
  AyahKey? get following => _following;
  set following(AyahKey? value) {
    if (value == _following) return;
    _following = value;
    markNeedsPaint();
  }

  /// a long press or a double tap on a word
  ValueChanged<AyahKey>? onAyah;

  /// while choosing ayahs to share a tap checks or unchecks one at once, nothing waits for a
  /// double tap
  ValueChanged<AyahKey>? _onCheck;
  set onCheck(ValueChanged<AyahKey>? value) {
    if ((value == null) != (_onCheck == null)) markNeedsSemanticsUpdate();
    _onCheck = value;
  }

  /// what a screen reader reads for each ayah on the page
  Map<AyahKey, String> _labels;
  set labels(Map<AyahKey, String> value) {
    if (mapEquals(value, _labels)) return;
    _labels = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsSemanticsUpdate();
  }

  /// another font measures every word again
  QuranFont _font;
  set font(QuranFont value) {
    if (value == _font) return;
    _font = value;
    _relayout();
  }

  MushafGlyphs? _glyphs;
  MushafGlyphs? get glyphs => _glyphs;
  set glyphs(MushafGlyphs? value) {
    if (value == _glyphs) return;
    _glyphs = value;
    _relayout();
  }

  /// Display's mushaf size, above 0 the page is as tall as its rewrapped lines
  int _step;
  bool get reflow => _step > 0;
  set step(int value) {
    if (value == _step) return;
    _step = value;
    _relayout();
  }

  List<TajweedRule>? _tajweed;
  List<TajweedRule>? get tajweed => _tajweed;
  set tajweed(List<TajweedRule>? value) {
    if (listEquals(value, _tajweed)) return;
    _tajweed = value;
    _tajweedLabels = null;
    markNeedsPaint();
  }

  List<TextPainter>? _tajweedLabels;

  MushafColors _colors;
  set colors(MushafColors value) {
    if (value == _colors) return;
    if (value.ink2 != _colors.ink2) {
      _header = null;
      _tajweedLabels = null;
    }
    if (value.ink != _colors.ink) {
      _settle?.cancel();
      _settle = Timer(BmMotion.standard, _relayout);
    }
    _colors = value;
    markNeedsPaint();
  }

  _Laid? _laid;

  /// the text takes a new ink once the crossfade stops, laying it out every frame is too heavy
  Timer? _settle;
  (TextPainter, TextPainter)? _header;

  void _relayout() {
    _laid = null;
    _tajweedLabels = null;
    markNeedsLayout();
  }

  /// its own layer, a turn moves the page without painting it again
  @override
  bool get isRepaintBoundary => true;

  /// the screen's height comes as the min when the page sits in a scroll view
  @override
  void performLayout() {
    final viewport = Size(
      constraints.maxWidth,
      constraints.hasBoundedHeight ? constraints.maxHeight : constraints.minHeight,
    );
    if (_laid?.viewport != viewport) {
      _laid = _laidOf((
        page: _page,
        number: _number,
        names: _names,
        eastern: eastern,
        unit: _unit,
        font: _font,
        glyphs: _glyphs,
        step: _step,
        ink: _colors.ink,
        viewport: viewport,
      ));
      markNeedsSemanticsUpdate();
    }
    size = constraints.constrain(_laid!.size);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _wash.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _wash.removeListener(markNeedsPaint);
    super.detach();
  }

  /// the ayah under the pointer when it went down
  AyahKey? _down;
  late final _tap = TapGestureRecognizer(debugOwner: this)..onTap = () => _call(_onCheck);
  late final _double = DoubleTapGestureRecognizer(debugOwner: this)
    ..onDoubleTap = () => _call(onAyah);
  late final _long = LongPressGestureRecognizer(debugOwner: this)
    ..onLongPress = () => _call(onAyah);

  void _call(ValueChanged<AyahKey>? callback) {
    if (_down case final key?) callback?.call(key);
  }

  @override
  void dispose() {
    _settle?.cancel();
    _tap.dispose();
    _double.dispose();
    _long.dispose();
    super.dispose();
  }

  /// only the words are hit. a single tap on them waits out a double tap, then goes on to the
  /// turner like a tap on the margin and toggles the controls
  @override
  bool hitTestSelf(Offset position) =>
      (onAyah != null || _onCheck != null) && ayahAt(position) != null;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is! PointerDownEvent) return;
    _down = ayahAt(entry.localPosition);
    if (_onCheck != null) {
      _tap.addPointer(event);
      return;
    }
    _double.addPointer(event);
    _long.addPointer(event);
  }

  /// the line band under the position, then the nearest word on it (research R3)
  AyahKey? ayahAt(Offset position) {
    final laid = _laid;
    if (laid == null || _page == null) return null;
    final page = laid.page;
    final layout = laid.layout;
    for (var i = 0; i < layout.lines.length; i++) {
      final words = layout.words[i];
      if (words.isEmpty || !layout.lines[i].contains(position)) continue;
      var nearest = 0;
      for (var j = 1; j < words.length; j++) {
        if (_distance(words[j], position.dx) < _distance(words[nearest], position.dx)) nearest = j;
      }
      return page.lines[i].words[nearest].key;
    }
    return null;
  }

  static double _distance(Rect word, double x) =>
      x < word.left ? word.left - x : (x > word.right ? x - word.right : 0);

  List<Rect> _washRects(_Laid laid, AyahKey key) {
    final height = laid.textHeight + 2 * SpaceManager.ayahWashV * _unit;
    final side = SpaceManager.ayahWashH * _unit;
    if (key.ayah == 0) return [?_basmallahRect(laid, key.surah, height, side)];
    return washRects(laid.page, laid.layout, key, height: height, side: side, shift: laid.inkShift);
  }

  /// ayah 0 is the surah's bismillah, the line after its name
  Rect? _basmallahRect(_Laid laid, int surah, double height, double side) {
    var owner = laid.page.firstAyah?.surah;
    var index = 0;
    for (final line in laid.page.lines) {
      if (line.type == MushafLineType.surahName) owner = line.surah;
      if (line.type != MushafLineType.basmallah) continue;
      if (owner == surah) {
        final (band, text) = laid.basmallahs[index];
        return Rect.fromCenter(
          center: band.center.translate(0, laid.inkShift),
          width: text.width + 2 * side,
          height: height,
        );
      }
      index++;
    }
    return null;
  }

  /// one node per ayah over its words, read in the mushaf's order. a tap opens its sheet, or checks
  /// it while choosing (FR-052)
  final _nodes = <AyahKey, SemanticsNode>{};

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
  }

  @override
  void assembleSemanticsNode(
    SemanticsNode node,
    SemanticsConfiguration config,
    Iterable<SemanticsNode> children,
  ) {
    _nodes.removeWhere((key, _) => !_labels.containsKey(key));
    final action = _onCheck ?? onAyah;
    final nodes = [
      for (final (i, MapEntry(:key, :value)) in _labels.entries.indexed)
        if (washBounds(key) case final rect?)
          (_nodes[key] ??= SemanticsNode())
            /// a short line's wash can be under the 44 pt a tap target needs
            ..rect = Rect.fromCenter(
              center: rect.center,
              width: rect.width,
              height: math.max(rect.height, SizeManager.hit * _unit),
            )
            ..updateWith(
              config: SemanticsConfiguration()
                ..sortKey = OrdinalSortKey(i.toDouble())
                ..label = value
                ..textDirection = _direction
                ..isButton = true
                ..isSelected = key == _selected
                ..onTap = action == null ? null : () => action(key),
            ),
    ];
    node.updateWith(config: config, childrenInInversePaintOrder: nodes);
  }

  @override
  void clearSemantics() {
    super.clearSemantics();
    _nodes.clear();
  }

  /// a bookmarked ayah's number on this page, the text's star or the qcf font's circle. null on a
  /// page the ayah doesn't end on
  Path? bookmarkedNumber(AyahKey key) {
    final laid = _laid;
    if (laid == null || _page == null || !_bookmarked.containsKey(key)) return null;
    final lines = laid.page.lines;
    for (var i = 0; i < lines.length; i++) {
      for (var j = 0; j < lines[i].words.length; j++) {
        final word = lines[i].words[j];
        if (!word.end || word.key != key) continue;
        final rect = laid.layout.words[i][j];
        if (_glyphs == null) return mushafStar(rect.center, laid.marker);

        /// the font's circle sits on the ink like the words, as wide as its glyph
        return Path()..addOval(
          Rect.fromCircle(
            center: rect.center.translate(0, laid.inkShift),
            radius: math.min(rect.width, laid.textHeight) / 2,
          ),
        );
      }
    }
    return null;
  }

  /// the ayah's wash on this page in its own coordinates, null when it isn't on it
  Rect? washBounds(AyahKey key) {
    final laid = _laid;
    if (laid == null || _page == null) return null;
    final rects = _washRects(laid, key);
    return rects.isEmpty ? null : rects.reduce((a, b) => a.expandToInclude(b));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final laid = _laid;
    if (laid == null) return;
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    _paintPaper(canvas, laid);
    _paintHeader(canvas);
    _paintFrame(canvas, laid);
    for (final (rect, _) in laid.cartouches) {
      _paintCartouche(canvas, rect);
    }
    if (_placeholder) _paintPlaceholder(canvas, laid);
    _paintWash(canvas, laid);
    _paintMarkers(canvas, laid);

    /// the text carries its own ink, an offscreen layer makes it soft on android (T085). only while
    /// the ink crossfades a layer tints the text laid out in the old one, never a colored font's
    final tinted = laid.ink != _colors.ink && !(_glyphs?.colored ?? false);
    if (tinted) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..colorFilter = ColorFilter.mode(_colors.ink, BlendMode.srcIn),
      );
    }
    _paintInk(canvas, laid);
    if (tinted) canvas.restore();
    canvas.restore();
  }

  Paint _stroke(Color color, double width) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * _unit
    ..strokeJoin = StrokeJoin.round;

  void _paintPaper(Canvas canvas, _Laid laid) {
    final bounds = Offset.zero & size;
    canvas.drawRect(bounds, Paint()..color = _colors.page);

    /// edges() of _gen/quran.js: the spine's shadow, the fore-edge's leaves, the vignette
    final spine = Rect.fromLTRB(size.width - SizeManager.spine * _unit, 0, size.width, size.height);
    canvas.drawRect(
      spine,
      Paint()
        ..shader = LinearGradient(colors: [_colors.gutter.withValues(alpha: 0), _colors.gutter])
            .createShader(spine),
    );
    final leaf = Paint()..color = _colors.ornamentSoft.withValues(alpha: .7 * .7);
    for (var x = 0.0; x < SizeManager.foreEdge * _unit; x += SpaceManager.foreEdgeStripe * _unit) {
      canvas.drawRect(Rect.fromLTWH(x, 0, SizeManager.foreEdgeLine * _unit, size.height), leaf);
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.1, -.2),
          radius: _vignetteWide * size.width / size.shortestSide,
          colors: [
            _colors.ornament.withValues(alpha: 0),
            _colors.ornament.withValues(alpha: 0),
            _colors.ornament.withValues(alpha: .07),
          ],
          stops: const [0, .62, 1],
          transform: _Ellipse(_vignetteTall * size.height / (_vignetteWide * size.width)),
        ).createShader(bounds),
    );
  }

  void _paintHeader(Canvas canvas) {
    final (surah, juz) = _header ??= (_amiri(_surah, _colors.ink2), _amiri(_juz, _colors.ink2));
    final top = SpaceManager.mushafHeaderTop * _unit;

    /// the page reads right to left, the surah on the right
    surah.paint(
      canvas,
      Offset(size.width - SpaceManager.mushafHeaderRight * _unit - surah.width, top),
    );
    juz.paint(canvas, Offset(SpaceManager.mushafHeaderLeft * _unit, top));
  }

  TextPainter _amiri(String text, Color color) => TextPainter(
    text: TextSpan(
      text: text,
      style: GetRegularStyle(
        fontSize: FontSizeManager.mushafHeader * _unit,
        fontFamily: FontFamilyManager.dua,
        color: color,
      ),
    ),
    textDirection: TextDirection.rtl,
  )..layout();

  void _paintFrame(Canvas canvas, _Laid laid) {
    final ornament = _colors.ornament;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(laid.frame, Radius.circular(RadiusManager.mushafFrame * _unit)),
        _stroke(ornament, SizeManager.mushafFrameStroke),
      )
      ..drawRect(
        laid.frame.deflate(SpaceManager.mushafFrameInner * _unit),
        _stroke(ornament, SizeManager.mushafFrameInnerStroke),
      );
    final box = SizeManager.mushafCorner * _unit;
    final fill = Paint()..color = Color.lerp(_colors.page, ornament, .22)!;
    for (final corner in [
      laid.frame.topLeft,
      laid.frame.topRight,
      laid.frame.bottomLeft,
      laid.frame.bottomRight,
    ]) {
      final star = mushafStar(corner, SizeManager.mushafCornerStar * _unit);
      canvas
        ..drawRect(
          Rect.fromCenter(center: corner, width: box, height: box),
          Paint()..color = _colors.page,
        )
        ..drawPath(star, fill)
        ..drawPath(star, _stroke(ornament, SizeManager.mushafFrameStroke));
    }
    if (_page?.number == 1 && !reflow) _paintArch(canvas, laid);

    final number = Offset(
      size.width / 2,
      size.height - (SpaceManager.mushafNumberBottom + SizeManager.mushafNumber / 2) * _unit,
    );
    canvas.drawPath(
      mushafStar(number, SizeManager.mushafNumber * _unit),
      _stroke(ornament.withValues(alpha: .9), SizeManager.starStroke),
    );
    _paintTajweed(canvas, laid, number);
  }

  /// two rows of two on each side of the number, read right to left
  void _paintTajweed(Canvas canvas, _Laid laid, Offset number) {
    final key = _tajweed;
    if (key == null) return;
    final scale = tajweedKeyScale(_step) * _unit;
    final side = (SizeManager.mushafNumber / 2 + SpaceManager.tajweedKeyGap) * _unit;
    final column = (laid.frame.width / 2 - side) / 2;
    final dot = SizeManager.tajweedDot * scale;
    final gap = SpaceManager.tajweedDotGap * scale;
    final labels = _tajweedLabels ??= _tajweedLabelsOf(
      key,
      fontSize: FontSizeManager.tajweedKey * scale,
      room: column - dot - gap,
    );
    for (var i = 0; i < key.length; i++) {
      final right = (i < 4 ? laid.frame.right : number.dx - side) - i % 2 * column;
      final y = number.dy + ((i % 4) ~/ 2 - .5) * SizeManager.tajweedKeyRow * scale;
      canvas.drawCircle(Offset(right - dot / 2, y), dot / 2, Paint()..color = key[i].color);
      labels[i].paint(
        canvas,
        Offset(right - dot - gap - labels[i].width, y - labels[i].height / 2),
      );
    }
  }

  /// the longest name sets one size for all eight, a cut name loses its rule
  List<TextPainter> _tajweedLabelsOf(
    List<TajweedRule> key, {
    required double fontSize,
    required double room,
  }) {
    List<TextPainter> at(double fontSize) => [
      for (final rule in key)
        TextPainter(
          text: TextSpan(
            text: rule.label,
            style: GetRegularStyle(
              fontSize: fontSize,
              fontFamily: FontEnum.body.arabic,
              color: _colors.ink2,
            ),
          ),
          textDirection: TextDirection.rtl,
        )..layout(),
    ];
    final labels = at(fontSize);
    final widest = labels.map((label) => label.width).reduce(math.max);
    return widest <= room ? labels : at(fontSize * room / widest);
  }

  @visibleForTesting
  List<TextPainter>? get tajweedLabels => _tajweedLabels;

  /// page 1's arch, the two paths of page1() in its 319 x 612 box
  void _paintArch(Canvas canvas, _Laid laid) {
    final left = SpaceManager.openingArchLeft * _unit;
    final top = laid.y(SpaceManager.openingArchTop);
    Offset at(double x, double y) => Offset(left + x * _unit, top + y * _unit * laid.vy);

    /// M a h V b C a c d e w/2 f C w-d e w-a c w-a b V h Z, with h the box's height less a
    Path arch(double a, double b, double c, double d, double e, double f) {
      const w = SizeManager.openingArchW;
      const h = SizeManager.openingArchH;
      final (start, shoulder) = (at(a, h - a), at(a, b));
      final (c1, c2, peak) = (at(a, c), at(d, e), at(w / 2, f));
      final (c3, c4, end, foot) = (at(w - d, e), at(w - a, c), at(w - a, b), at(w - a, h - a));
      return Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(shoulder.dx, shoulder.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, peak.dx, peak.dy)
        ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, end.dx, end.dy)
        ..lineTo(foot.dx, foot.dy)
        ..close();
    }

    canvas
      ..drawPath(arch(1, 132, 70, 70, 34, 1), _stroke(_colors.ornament, SizeManager.archStroke))
      ..drawPath(
        arch(7, 134, 76, 74, 42, 9),
        _stroke(_colors.ornament, SizeManager.archInnerStroke),
      );
  }

  /// cartouche() of _gen/quran.js, its name painted with the ink
  void _paintCartouche(Canvas canvas, Rect rect) {
    final ornament = _colors.ornament;

    /// M cut inset H w-cut L w-tip 22 L w-cut 44-inset H cut L tip 22 Z, in the 44 tall box
    Path shape(double inset, double cut, double tip) => Path()
      ..moveTo(rect.left + cut * _unit, rect.top + inset * _unit)
      ..lineTo(rect.right - cut * _unit, rect.top + inset * _unit)
      ..lineTo(rect.right - tip * _unit, rect.center.dy)
      ..lineTo(rect.right - cut * _unit, rect.bottom - inset * _unit)
      ..lineTo(rect.left + cut * _unit, rect.bottom - inset * _unit)
      ..lineTo(rect.left + tip * _unit, rect.center.dy)
      ..close();
    final outer = shape(1, 16, 1);
    canvas
      ..drawPath(outer, Paint()..color = Color.lerp(_colors.page, ornament, .09)!)
      ..drawPath(outer, _stroke(ornament, SizeManager.mushafFrameStroke))
      ..drawPath(shape(5, 19, 6), _stroke(ornament, SizeManager.mushafFrameInnerStroke));
    final star = SpaceManager.cartoucheStar * _unit;
    final dy = rect.top + (SpaceManager.cartoucheStarTop * _unit) + star / 2;
    for (final dx in [rect.left + star * 1.5, rect.right - star * 1.5]) {
      canvas.drawPath(
        mushafStar(Offset(dx, dy), star),
        _stroke(ornament, SizeManager.mushafFrameStroke),
      );
    }
  }

  void _paintPlaceholder(Canvas canvas, _Laid laid) {
    final bands = regularBands(laid.inner.height);
    var top = laid.inner.top;
    for (var i = 0; i < bands.length; i++) {
      final bar = Rect.fromCenter(
        center: Offset(laid.inner.center.dx, top + bands[i] / 2),
        width: laid.inner.width - 2 * SpaceManager.mushafTextInset * _unit,
        height: SizeManager.mushafPlaceholder * _unit,
      );
      top += bands[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(bar, Radius.circular(RadiusManager.mushafPlaceholder * _unit)),
        Paint()..color = _colors.ink.withValues(alpha: i % 3 == 0 ? .1 : .08),
      );
    }
  }

  /// behind the markers and the ink, so the glyphs are never recolored
  void _paintWash(Canvas canvas, _Laid laid) {
    if (_page == null) return;
    final radius = Radius.circular(RadiusManager.ayahWash * _unit);
    void wash(AyahKey key, Color color) {
      final paint = Paint()..color = color;
      for (final rect in _washRects(laid, key)) {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
      }
    }

    for (final key in _highlighted) {
      wash(key, _colors.highlight);
    }
    if (_following case final key?) wash(key, _colors.follow);
    for (final key in _chosen) {
      wash(key, _colors.selection);
    }
    final key = _selected;
    if (key != null && _wash.value > 0) {
      wash(key, _colors.selection.withValues(alpha: _colors.selection.a * _wash.value));
    }

    /// over the washes, so its color stays the category's
    for (final MapEntry(:key, :value) in _bookmarked.entries) {
      if (bookmarkedNumber(key) case final path?) {
        canvas.drawPath(
          path,
          Paint()..color = value.withValues(alpha: SizeManager.bookmarkedNumber),
        );
      }
    }
  }

  /// K.ayahMark: the star and its ring in the ornament, the digit goes with the ink
  void _paintMarkers(Canvas canvas, _Laid laid) {
    final paint = _stroke(_colors.ornament, SizeManager.ayahMarkerStroke * laid.markerScale);
    for (final (center, _) in laid.markers) {
      canvas
        ..drawPath(mushafStar(center, laid.marker), paint)
        ..drawCircle(center, laid.marker * _ring, paint);
    }
  }

  static const _ring = 12.5 / 40;

  void _paintInk(Canvas canvas, _Laid laid) {
    final lines = laid.layout.lines;
    for (var i = 0; i < lines.length; i++) {
      final scale = laid.layout.scales[i];
      final rects = laid.layout.words[i];
      for (var j = 0; j < rects.length; j++) {
        final word = laid.words[i][j];
        if (word == null) continue;
        canvas
          ..save()
          ..translate(rects[j].left, lines[i].center.dy - word.height / 2)
          ..scale(scale, 1);
        word.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
    for (final (center, digit) in laid.markers) {
      digit.paint(
        canvas,
        center - Offset(digit.width / 2, digit.height / 2 - SpaceManager.mushafNumberTop * _unit),
      );
    }
    for (final (rect, name) in laid.cartouches) {
      name.paint(
        canvas,
        rect.center -
            Offset(name.width / 2, name.height / 2 - SpaceManager.cartoucheNameTop * _unit),
      );
    }
    for (final (rect, basmallah) in laid.basmallahs) {
      basmallah.paint(canvas, rect.center - Offset(basmallah.width / 2, basmallah.height / 2));
    }
    final number = laid.number;
    number.paint(
      canvas,
      Offset(
        size.width / 2 - number.width / 2,
        size.height -
            (SpaceManager.mushafNumberBottom + SizeManager.mushafNumber / 2) * _unit -
            number.height / 2 +
            SpaceManager.mushafNumberTop * _unit,
      ),
    );
  }
}

/// what a page's layout is made from
typedef _LaidInput = ({
  MushafPage? page,
  String number,
  Map<int, String> names,
  String Function(int n) eastern,
  double unit,
  QuranFont font,
  MushafGlyphs? glyphs,
  int step,
  Color ink,
  Size viewport,
});

/// the last pages laid out, so turning back or opening a warmed page measures no word again
final _laids = <Object, _Laid>{};

_Laid _laidOf(_LaidInput input) {
  final page = input.page;
  if (page == null) return _Laid.of(input);

  /// the words, names and digits follow from the page number and its print, which the glyphs'
  /// style decides (text is always 1421H)
  final key = (
    page.number,
    input.viewport,
    input.unit,
    input.font,
    input.glyphs,
    input.step,
    input.ink,
  );
  final laid = _laids.remove(key) ?? _Laid.of(input);
  _laids[key] = laid;
  if (_laids.length > 5) _laids.remove(_laids.keys.first);
  return laid;
}

/// a page's measured words and their places, made once per page and size
class _Laid {
  _Laid({
    required this.viewport,
    required this.size,
    required this.page,
    required this.frame,
    required this.inner,
    required this.vy,
    required this.unit,
    required this.layout,
    required this.words,
    required this.marker,
    required this.markerScale,
    required this.markers,
    required this.cartouches,
    required this.basmallahs,
    required this.number,
    required this.textHeight,
    required this.inkShift,
    required this.ink,
  });

  factory _Laid.of(_LaidInput input) {
    final (:page, :number, :names, :eastern, :unit, :font, :glyphs, :step, :ink, :viewport) = input;
    final reflow = step > 0;
    Rect frameOf(Size size) => Rect.fromLTRB(
      SpaceManager.mushafFrameLeft * unit,
      SpaceManager.mushafFrameTop * unit,
      size.width - SpaceManager.mushafFrameRight * unit,
      size.height - SpaceManager.mushafFrameBottom * unit,
    );
    var size = viewport;
    var frame = frameOf(size);
    var inner = frame.deflate(SpaceManager.mushafFrameInner * unit);

    /// a phone shorter than the design packs the opening's lines closer, never further apart
    const designInner =
        SizeManager.mushafDesignHeight -
        SpaceManager.mushafFrameTop -
        SpaceManager.mushafFrameBottom -
        2 * SpaceManager.mushafFrameInner;
    final vy = math.min(1.0, inner.height / (designInner * unit));
    double y(double design) => frame.top + (design - SpaceManager.mushafFrameTop) * unit * vy;

    var mushaf = page ?? const MushafPage(number: 0, lines: []);
    var lines = mushaf.lines;

    /// a rewrapped opening is laid out like any other page
    final opening = mushaf.opening && !reflow;
    final first = page?.number == 1;
    Rect area;
    List<double> bands;
    if (opening) {
      area = Rect.fromLTRB(
        SpaceManager.openingTextLeft * unit,
        y(first ? SpaceManager.openingCartoucheTop : SpaceManager.secondCartoucheTop),
        size.width - SpaceManager.openingTextRight * unit,
        inner.bottom,
      );
      bands = [
        for (final line in lines)
          unit *
              vy *
              switch (line.type) {
                MushafLineType.surahName =>
                  first
                      ? SpaceManager.openingTextTop - SpaceManager.openingCartoucheTop
                      : SpaceManager.secondBasmalaTop - SpaceManager.secondCartoucheTop,
                MushafLineType.basmallah =>
                  SpaceManager.secondTextTop - SpaceManager.secondBasmalaTop,
                MushafLineType.ayah when line.words.isEmpty => 0,
                MushafLineType.ayah => SpaceManager.mushafLine,
              },
      ];
    } else {
      area = Rect.fromLTRB(
        inner.left + SpaceManager.mushafTextInset * unit,
        inner.top,
        inner.right - SpaceManager.mushafTextInset * unit,
        inner.bottom,
      );
      bands = regularBands(area.height);
    }

    /// below 100% the lines narrow and keep their places
    if (step < 0) {
      area = Rect.fromCenter(
        center: area.center,
        width: area.width * mushafScale(step),
        height: area.height,
      );
    }

    TextPainter quran(String text, double fontSize) => TextPainter(
      text: TextSpan(
        text: font.drawn(text),
        style: GetRegularStyle(fontSize: fontSize, fontFamily: font.family, color: ink),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    /// a qcf word is one glyph of the page's own font, its end marker too
    TextPainter glyph(String code, double fontSize) => TextPainter(
      text: TextSpan(
        text: code,
        style: GetRegularStyle(fontSize: fontSize, fontFamily: glyphs!.family, color: ink),
      ),
      textDirection: TextDirection.rtl,
    )..layout();

    /// one size for the whole page
    var fontSize = reflow
        ? FontSizeManager.mushafReflow * mushafScale(step) * unit
        : FontSizeManager.quranPage * unit;
    var scale = fontSize / (FontSizeManager.quranPage * unit);
    List<List<TextPainter?>> measure() => [
      for (final line in lines)
        [
          for (final word in line.words)
            glyphs != null
                ? glyph(word.glyph, fontSize)
                : word.end
                ? null
                : quran(word.text, fontSize),
        ],
    ];
    double markerWidth() =>
        (SizeManager.ayahMarker * scale + 2 * SpaceManager.ayahMarkerGap) * unit;
    List<List<double>> widths(List<MushafLine> lines, List<List<TextPainter?>> words) => [
      for (var i = 0; i < lines.length; i++)
        [for (var j = 0; j < words[i].length; j++) words[i][j]?.width ?? markerWidth()],
    ];

    /// a qcf glyph carries its word's spacing, the print's usual line fills the area
    var gap = glyphs != null ? 0.0 : quran(' ', fontSize).width;

    /// a page still loading has no lines, while its qcf font can already be there
    if (glyphs != null && !reflow && lines.any((line) => line.words.isNotEmpty)) {
      final widths = [
        for (final (i, line) in measure().indexed)
          if (line.isNotEmpty)
            (lines[i].centered, line.fold(0.0, (sum, word) => sum + word!.width)),
      ];
      final full = [
        for (final (centered, width) in widths)
          if (!centered) width,
      ]..sort();
      scale =
          area.width /
          (full.isEmpty ? widths.map((line) => line.$2).reduce(math.max) : full[full.length ~/ 2]);
      fontSize *= scale;
    } else if (!opening && !reflow) {
      /// a whole line in one painter is as wide as its words and spaces, so the words are measured
      /// once, at the size the page ends up with
      final widest = lines.fold(0.0, (widest, line) {
        final text = [
          for (final word in line.words)
            if (!word.end) word.text,
        ];
        final ends = line.words.where((word) => word.end).length * markerWidth();
        final spaces = math.max(0, line.words.length - 1) - math.max(0, text.length - 1);
        final width =
            (text.isEmpty ? 0.0 : quran(text.join(' '), fontSize).width) + ends + spaces * gap;
        return math.max(widest, width);
      });
      if (widest > area.width) {
        scale = area.width / widest;
        fontSize *= scale;
        gap = quran(' ', fontSize).width;
      }
    }
    var words = measure();
    if (reflow) {
      /// the same words in the new lines, measured once, and the page as tall as they need
      mushaf = reflowMushaf(mushaf, widths: widths(lines, words), width: area.width, gap: gap);
      lines = mushaf.lines;
      final measured = words.expand((line) => line).iterator;
      words = [
        for (final line in lines) [for (final _ in line.words) (measured..moveNext()).current],
      ];
      bands = [for (final _ in lines) fontSize * LineHeightManager.quranPage];
      final bottom = area.top + bands.fold(0.0, (sum, band) => sum + band);
      size = Size(size.width, math.max(size.height, bottom + viewport.height - inner.bottom));
      frame = frameOf(size);
      inner = frame.deflate(SpaceManager.mushafFrameInner * unit);
    }

    /// a justified line's gaps stop at one and a half spaces, the rest goes into kashidas (ADR 0003).
    /// a stretched line still wider than the area keeps its words as they are
    if (glyphs == null && !opening && step >= 0) {
      final tatweel = quran(kashidaTatweel, fontSize).width;
      final all = widths(lines, words);
      for (var i = 0; i < lines.length; i++) {
        final row = all[i];
        final total = row.fold(0.0, (sum, width) => sum + width);
        final spaces = gap * (row.length - 1);
        if (lines[i].centered || row.length < 2 || total + spaces > area.width) continue;
        final counts = shareKashidas(
          widths: row,
          stretchable: [
            for (final word in lines[i].words) !word.end && kashidaPoint(word.text) != null,
          ],
          width: area.width,
          cap: gap * kashidaGap,
          tatweel: tatweel,
        );
        if (counts.every((n) => n == 0)) continue;
        final stretched = [
          for (var j = 0; j < row.length; j++)
            counts[j] == 0
                ? words[i][j]
                : quran(kashida(lines[i].words[j].text, counts[j]), fontSize),
        ];
        var wide = 0.0;
        for (var j = 0; j < row.length; j++) {
          wide += stretched[j]?.width ?? row[j];
        }
        if (wide + spaces <= area.width) words[i] = stretched;
      }
    }
    final layout = layoutMushaf(
      page: mushaf,
      widths: widths(lines, words),
      bands: bands,
      area: area,
      gap: gap,
    );

    final marker = SizeManager.ayahMarker * scale * unit;
    final space = glyphs != null
        ? words.expand((line) => line).nonNulls.firstOrNull ?? quran(' ', fontSize)
        : quran(' ', fontSize);
    TextPainter amiri(String text, double fontSize, {bool bold = false}) => TextPainter(
      text: TextSpan(
        text: text,
        style: bold
            ? GetBoldStyle(fontSize: fontSize, fontFamily: FontFamilyManager.dua, color: ink)
            : GetRegularStyle(fontSize: fontSize, fontFamily: FontFamilyManager.dua, color: ink),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    final markers = <(Offset, TextPainter)>[];
    final cartouches = <(Rect, TextPainter)>[];
    final basmallahs = <(Rect, TextPainter)>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final band = layout.lines[i];
      for (var j = 0; j < line.words.length; j++) {
        final word = line.words[j];
        if (!word.end || glyphs != null) continue;
        markers.add((
          layout.words[i][j].center,
          amiri(eastern(word.key.ayah), FontSizeManager.ayahMarker * scale * unit),
        ));
      }
      if (line.type == MushafLineType.surahName) {
        final width = math.min(
          area.width,
          (page?.number == 2 ? SizeManager.cartoucheWideW : SizeManager.cartoucheW) * unit,
        );
        final height = SizeManager.cartoucheH * unit;
        cartouches.add((
          Rect.fromLTWH(
            band.center.dx - width / 2,
            opening ? band.top : band.center.dy - height / 2,
            width,
            height,
          ),
          amiri(
            '$mushafSurahWord ${names[line.surah] ?? ''}',
            FontSizeManager.cartouche * unit,
            bold: true,
          ),
        ));
      }
      if (line.type == MushafLineType.basmallah) {
        basmallahs.add((band, quran(mushafBasmallah, fontSize)));
      }
    }

    return _Laid(
      viewport: viewport,
      size: size,
      page: mushaf,
      frame: frame,
      inner: inner,
      vy: vy,
      unit: unit,
      layout: layout,
      words: words,
      marker: marker,
      markerScale: scale,
      markers: markers,
      cartouches: cartouches,
      basmallahs: basmallahs,
      number: amiri(number, FontSizeManager.mushafHeader * unit),
      textHeight: space.height,
      inkShift:
          space.computeDistanceToActualBaseline(TextBaseline.alphabetic) -
          space.height / 2 -
          (glyphs?.ink ?? font.ink) * fontSize,
      ink: ink,
    );
  }

  /// what the parent gave, size is what the page takes
  final Size viewport;
  final Size size;

  /// the page as laid out, its lines rewrapped above 100%
  final MushafPage page;
  final Rect frame;
  final Rect inner;
  final double vy;
  final MushafLayout layout;

  /// null on an ayah's end marker, it is drawn
  final List<List<TextPainter?>> words;
  final double marker;
  final double markerScale;
  final List<(Offset, TextPainter)> markers;
  final List<(Rect, TextPainter)> cartouches;
  final List<(Rect, TextPainter)> basmallahs;
  final TextPainter number;

  /// a line's text box, the wash is this plus its padding
  final double textHeight;

  /// from the middle of a line to the middle of its ink, where the washes center
  final double inkShift;

  /// the color the text was laid out in
  final Color ink;

  final double unit;

  /// a design y of the 852 frame on this page
  double y(double design) => frame.top + (design - SpaceManager.mushafFrameTop) * unit * vy;
}

/// the 130% and 90% of the vignette's radial-gradient(130% 90%)
const _vignetteWide = 1.3;
const _vignetteTall = .9;

/// css radial-gradient(130% 90%): the circle squeezed into an ellipse around its center
class _Ellipse extends GradientTransform {
  const _Ellipse(this.squeeze);

  final double squeeze;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = const Alignment(-.1, -.2).withinRect(bounds);
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(1, squeeze, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}
