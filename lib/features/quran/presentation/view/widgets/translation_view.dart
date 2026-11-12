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
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/animated_decorated_box.dart';
import 'package:better_muslim/core/widgets/mushaf_star.dart';
import 'package:better_muslim/features/quran/data/mushaf_files.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/mushaf_style_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/saved_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the Turn strips beside the small page, in the top half
Size translationStrip(Size screen) => Size(SizeManager.turnStrip.r, screen.height / 2);

/// 4.07, the mushaf page at the screen's size, taller above 100%, and the ayahs starting on it as
/// verse cells under it, so the layouts share the page and its last read
class TranslationView extends ConsumerStatefulWidget {
  const TranslationView(
    this.page, {
    required this.onAyah,
    required this.onCheck,
    required this.mushaf,
    required this.shown,
    required this.onHidden,
    required this.followCells,
    this.entering = false,
    super.key,
  });

  final int page;

  /// a long press or a double tap on a cell
  final ValueChanged<AyahKey> onAyah;

  /// a tap on a cell while choosing, null otherwise so the tap goes on to the controls
  final ValueChanged<AyahKey>? onCheck;

  /// laid out at the screen's width, at least its height
  final Widget mushaf;

  /// false scrolls back up to the page, then [onHidden] switches the layout
  final bool shown;
  final VoidCallback onHidden;

  /// the page the Translation button turned on, the only one that scrolls in
  final bool entering;

  /// the reader's pick at each new ayah, true scrolls the playing ayah's cell into view
  final ValueListenable<bool> followCells;

  @override
  ConsumerState<TranslationView> createState() => _TranslationViewState();
}

class _TranslationViewState extends ConsumerState<TranslationView> {
  /// an open or a turn shows the whole page, only the Translation button scrolls to the ayahs
  final scrollController = ScrollController();
  final _mushaf = GlobalKey();

  /// the mushaf's bottom half screen over the ayahs
  double get _spot {
    final screen = MediaQuery.sizeOf(context).height;

    /// the last layout's, a tap on the button comes in a build
    final box = _mushaf.currentContext?.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize ? box.size.height : screen) - screen / 2;
  }

  @override
  void initState() {
    super.initState();

    /// a page turned to while hiding still has to hide
    if (widget.entering || !widget.shown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scroll();
      });
    }
  }

  @override
  void didUpdateWidget(TranslationView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shown != widget.shown) _scroll();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  /// a tap again mid scroll turns it around, so only a hide that lands switches the layout
  void _scroll() {
    final done = scrollController.animateTo(
      widget.shown ? _spot : 0,
      duration: BmMotion.emphasized,
      curve: BmMotion.standardCurve,
    );
    if (widget.shown) return;
    done.then((_) {
      if (mounted && !widget.shown) widget.onHidden();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ayahs = ref.watch(quranAssetsProvider).value?.pageAyahs(widget.page) ?? const [];
    final marked =
        ref.watch(selectionProvider.select((selection) => selection.sheet != null)) ||
        ref.watch(playingAyahProvider.select((key) => key != null));
    return ColoredBox(
      color: context.getColor(ThemeEnum.page),
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: ConstrainedBox(
              key: _mushaf,
              constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height),
              child: widget.mushaf,
            ),
          ),
          for (final key in ayahs)
            SliverToBoxAdapter(
              child: HorizontalPadding(
                padding: SpaceManager.s3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (key.ayah == 1) _SurahHeader(key.surah),
                    _VerseCell(
                      key,
                      onAyah: widget.onAyah,
                      onCheck: widget.onCheck,
                      followCells: widget.followCells,
                    ),
                  ],
                ),
              ),
            ),

          /// the last cell scrolls clear of the mini player, or of a sheet over its ayah
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: RSizedBox.vertical(
                marked ? SizeManager.recitationSheet : SizeManager.miniPlayer + SpaceManager.s4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahHeader extends ConsumerWidget {
  const _SurahHeader(this.surah);

  final int surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(quranAssetsProvider).value?.surah(surah);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    if (info == null) return const SizedBox.shrink();
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return OnlyPadding(
      start: SpaceManager.s1,
      end: SpaceManager.s1,
      bottom: SpaceManager.surahHeaderBottom,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusManager.lg.r),
          border: Border.all(color: context.getColor(ThemeEnum.outline)),
        ),
        child: OnlyPadding(
          top: SpaceManager.surahHeaderTop,
          bottom: SpaceManager.surahHeaderBottomPad,
          start: SpaceManager.s4,
          end: SpaceManager.s4,
          child: Column(
            children: [
              const _Ornament(),
              const RSizedBox.vertical(SpaceManager.s1),

              RegularText(
                info.title,
                translate: false,
                font: FontEnum.display,
                fontSize: FontSizeManager.surahHeader,
                height: LineHeightManager.surahHeader,
                textAlign: TextAlign.center,
              ),
              const RSizedBox.vertical(SpaceManager.s1),
              RegularText(
                StringsManager.surahMeta,
                args: {
                  'name': isArabic ? info.ar : info.en,
                  'place': context.tr(
                    info.medinan ? StringsManager.medinan : StringsManager.meccan,
                  ),
                  'count': context.formatDigits('${info.ayahs}', digits),
                },
                fontSize: FontSizeManager.caption,
                color: ThemeEnum.text2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// a star between two hairlines over the surah's name
class _Ornament extends StatelessWidget {
  const _Ornament();

  @override
  Widget build(BuildContext context) {
    final primary = context.getColor(ThemeEnum.primary);
    final line = ColoredBox(
      color: primary.withValues(alpha: .5),
      child: const RSizedBox(width: SizeManager.surahOrnamentLine, height: SizeManager.divider),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        line,
        const RSizedBox.horizontal(SpaceManager.s3),
        CustomPaint(
          painter: _OrnamentPainter(primary),
          child: const RSizedBox.square(dimension: SizeManager.surahOrnament),
        ),
        const RSizedBox.horizontal(SpaceManager.s3),
        line,
      ],
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  const _OrnamentPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      mushafStar(size.center(Offset.zero), size.width),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = SizeManager.verseMarkerStroke.r,
    );
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) => old.color != color;
}

/// the selected and the playing ayah fill the cell behind the text, the glyphs keep their ink. it
/// scrolls into view when it's pressed or starts playing, when the layout switches to it and when
/// the text size changes under it. an ayah opened on the page leaves the cells where they are, and
/// a playing one only scrolls while the reader follows the cells
class _VerseCell extends ConsumerStatefulWidget {
  const _VerseCell(
    this.ayah, {
    required this.onAyah,
    required this.onCheck,
    required this.followCells,
  });

  final AyahKey ayah;
  final ValueChanged<AyahKey> onAyah;
  final ValueChanged<AyahKey>? onCheck;
  final ValueListenable<bool> followCells;

  @override
  ConsumerState<_VerseCell> createState() => _VerseCellState();
}

class _VerseCellState extends ConsumerState<_VerseCell> {
  /// near the top, clear of the ayah sheet rising from the bottom
  static const _showAt = .1;

  /// a layout switch keeps the ayah in view
  @override
  void initState() {
    super.initState();
    _showMarked();
  }

  void _showMarked() {
    final playing = ref.read(playingAyahProvider);
    if (ref.read(selectionProvider).sheet == widget.ayah) {
      _show();
    } else if (playing != null && readAyah(playing) == widget.ayah) {
      _show(playing: true);
    }
  }

  /// after the frame, so the new size is laid out first and the reader has picked what it follows
  void _show({bool playing = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || (playing && !widget.followCells.value)) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      Scrollable.ensureVisible(
        context,
        alignment: _showAt,
        duration: reduce ? Duration.zero : BmMotion.standard,
        curve: BmMotion.standardCurve,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ayah = widget.ayah;
    final selected = ref.watch(
      selectionProvider.select(
        (selection) => selection.sheet == ayah || selection.chosen.contains(ayah),
      ),
    );
    final playing = ref.watch(
      playingAyahProvider.select((key) => key != null && readAyah(key) == ayah),
    );
    final (arabicStep, translationStep) = ref.watch(
      settingsProvider.select(
        (settings) =>
            (settings.value?.quranArabicSize ?? 0, settings.value?.quranTranslationSize ?? 0),
      ),
    );
    final font = ref.watch(
      settingsProvider.select((settings) => settings.value?.quranFont ?? QuranFont.kfgqpc),
    );
    ref
      ..listen(playingAyahProvider.select((key) => key != null && readAyah(key) == ayah), (_, on) {
        if (on) _show(playing: true);
      })
      ..listen(
        settingsProvider.select(
          (settings) => (settings.value?.quranArabicSize, settings.value?.quranTranslationSize),
        ),
        (_, _) => _showMarked(),
      );
    final arabic = ref.watch(ayahTextProvider(ayah)).value ?? '';
    final style = ref.watch(
      settingsProvider.select((settings) => settings.value?.mushafStyle ?? MushafStyle.text),
    );

    final bookmarked = ref.watch(
      bookmarksProvider.select(
        (bookmarks) =>
            bookmarks.value?.where((bookmark) => bookmark.ayah == ayah).lastOrNull?.color,
      ),
    );

    /// under a qcf style the ayah is its pages' glyphs, the text waits in their place
    var glyphs = const <({String family, String glyph, bool end, Rect? ink})>[];
    if (style != MushafStyle.text) {
      final files = ref.watch(mushafFilesProvider);
      final palette = style.palette(
        ref.watch(pageColorProvider).resolve(dark: context.isThemeDark),
      );
      final words = ref.watch(ayahGlyphsProvider(ayah)).value ?? const [];
      final families = {
        for (final page in words.map((word) => word.page).toSet())
          page:
              files.loaded(style, page, palette: palette) ??
              ref.watch(qcfFontProvider((style, page, palette))).value,
      };

      /// a bookmarked number centers on its marker's ink
      final inks = {
        if (bookmarked != null)
          for (final word in words)
            if (word.end) word.page: ref.watch(glyphInksProvider((style, word.page))).value,
      };
      if (families.values.every((family) => family != null)) {
        glyphs = [
          for (final word in words)
            (
              family: families[word.page]!,
              glyph: word.glyph,
              end: word.end,
              ink: word.end ? (inks[word.page] ?? const {})[word.glyph.runes.first] : null,
            ),
        ];
      }
    }
    final arabicSize = FontSizeManager.quranAr + arabicStep * FontSizeManager.arabicStep;
    final shown = shownTranslation(context, ref);
    final translation = ref
        .watch(translationProvider((shown, ayah.surah)))
        .value
        ?.elementAtOrNull(ayah.ayah - 1);
    final wash = selected
        ? ThemeEnum.selectionWash
        : playing
        ? ThemeEnum.followWash
        : ThemeEnum.transparent;
    final surah = ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
    final onCheck = widget.onCheck;
    final check = onCheck == null ? null : () => onCheck(ayah);
    final open = onCheck == null
        ? () {
            widget.onAyah(ayah);
            _show();
          }
        : null;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: surah == null
          ? null
          : ayahLabel(context, surah: surah, ayah: ayah, arabic: arabic, translation: translation),
      excludeSemantics: true,
      onTap: check ?? open,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: check,
        onDoubleTap: open,
        onLongPress: open,
        child: AnimatedDecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(wash),
            borderRadius: BorderRadius.circular(RadiusManager.verseCell.r),
          ),
          child: OnlyPadding(
            top: SpaceManager.verseCellTop,
            bottom: SpaceManager.verseCellBottom,
            start: SpaceManager.verseCellSide,
            end: SpaceManager.verseCellSide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: glyphs.isNotEmpty
                      ? _GlyphAyah(glyphs, fontSize: arabicSize, bookmarked: bookmarked?.theme)
                      : Wrap(
                          spacing: SpaceManager.verseMarkerGap.r,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            RegularText(
                              font.drawn(arabic),
                              translate: false,
                              font: font.font,
                              fontSize: arabicSize,
                              height: LineHeightManager.quranAr,
                              color: ThemeEnum.ink,
                            ),
                            _VerseMarker(ayah.ayah, bookmarked: bookmarked?.theme),
                          ],
                        ),
                ),
                const RSizedBox.vertical(SpaceManager.verseGap),
                Directionality(
                  textDirection: shown.arabic ? TextDirection.rtl : TextDirection.ltr,
                  child: RegularText(
                    translation ?? '',
                    translate: false,
                    fontSize:
                        FontSizeManager.verseTranslation +
                        translationStep * FontSizeManager.translationStep,
                    height: LineHeightManager.verseCell,
                    color: ThemeEnum.text2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// one glyph a word, so the ayah wraps between words like the text does. the end marker is the
/// font's own
class _GlyphAyah extends StatelessWidget {
  const _GlyphAyah(this.words, {required this.fontSize, this.bookmarked});

  final List<({String family, String glyph, bool end, Rect? ink})> words;
  final double fontSize;
  final ThemeEnum? bookmarked;

  @override
  Widget build(BuildContext context) {
    final bookmarked = this.bookmarked;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final word in words)
          if (word.end && bookmarked != null)
            CustomPaint(
              painter: _GlyphRibbonPainter(
                word,
                fontSize: fontSize.sp,
                color: context.getColor(bookmarked).withValues(alpha: SizeManager.bookmarkedNumber),
              ),
              child: _Glyph(word, fontSize: fontSize),
            )
          else
            _Glyph(word, fontSize: fontSize),
      ],
    );
  }
}

/// the ribbon on the marker's ink, from its baseline laid out like the glyph's own text
class _GlyphRibbonPainter extends CustomPainter {
  const _GlyphRibbonPainter(this.word, {required this.fontSize, required this.color});

  final ({String family, String glyph, bool end, Rect? ink}) word;
  final double fontSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = word.ink;
    final Offset center;
    final double height;
    if (ink == null) {
      center = size.center(Offset.zero);
      height = fontSize;
    } else {
      final baseline = (TextPainter(
        text: TextSpan(
          text: word.glyph,
          style: GetTextStyle(
            fontSize: fontSize,
            fontWeight: FontWeightManager.regular,
            height: LineHeightManager.quranAr,
            leadingDistribution: TextLeadingDistribution.even,
            fontFamily: word.family,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout()).computeDistanceToActualBaseline(TextBaseline.alphabetic);
      center = Offset(fontSize * ink.center.dx, baseline + fontSize * ink.center.dy);
      height = fontSize * ink.height;
    }
    canvas.drawPath(
      bookmarkRibbon(center, SizeManager.bookmarkRibbon * height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_GlyphRibbonPainter old) =>
      old.word != word || old.fontSize != fontSize || old.color != color;
}

class _Glyph extends StatelessWidget {
  const _Glyph(this.word, {required this.fontSize});

  final ({String family, String glyph, bool end, Rect? ink}) word;
  final double fontSize;

  @override
  Widget build(BuildContext context) => RegularText(
    word.glyph,
    translate: false,
    family: word.family,
    fontSize: fontSize,
    height: LineHeightManager.quranAr,
    color: ThemeEnum.ink,
  );
}

/// 4.07's ayah marker, eastern digits in both languages as the mushaf prints them
class _VerseMarker extends StatelessWidget {
  const _VerseMarker(this.number, {this.bookmarked});

  final int number;

  /// the category's color of the ribbon behind the star
  final ThemeEnum? bookmarked;

  @override
  Widget build(BuildContext context) {
    final bookmarked = this.bookmarked;
    return CustomPaint(
      painter: _MarkerPainter(
        context.getColor(ThemeEnum.primary),
        fill: bookmarked == null
            ? null
            : context.getColor(bookmarked).withValues(alpha: SizeManager.bookmarkedNumber),
      ),
      child: RSizedBox.square(
        dimension: SizeManager.verseMarker,
        child: Center(
          child: RegularText(
            formatDigitsIn('$number', language: 'ar', digits: Digits.eastern),
            translate: false,
            fontSize: FontSizeManager.verseMarker,
            height: LineHeightManager.verseMarker,
            color: ThemeEnum.primary,
          ),
        ),
      ),
    );
  }
}

class _MarkerPainter extends CustomPainter {
  const _MarkerPainter(this.color, {this.fill});

  final Color color;
  final Color? fill;

  /// the eight point star of 4.07's marker in its 40 box
  static const _points = [
    (20.0, 0.0),
    (25.86, 5.86),
    (34.14, 5.86),
    (34.14, 14.14),
    (40.0, 20.0),
    (34.14, 25.86),
    (34.14, 34.14),
    (25.86, 34.14),
    (20.0, 40.0),
    (14.14, 34.14),
    (5.86, 34.14),
    (5.86, 25.86),
    (0.0, 20.0),
    (5.86, 14.14),
    (5.86, 5.86),
    (14.14, 5.86),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / SizeManager.verseMarkerBox;
    final center = size.center(Offset.zero);
    const half = SizeManager.verseMarkerBox / 2;
    const star = SizeManager.verseMarkerStar;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = SizeManager.verseMarkerStroke * unit;
    final path = Path()
      ..addPolygon([
        for (final (x, y) in _points)
          center + Offset((x - half) * star * unit, (y - half) * star * unit),
      ], true);
    if (fill case final fill?) {
      canvas.drawPath(
        bookmarkRibbon(center, SizeManager.bookmarkRibbon * size.width * star),
        Paint()..color = fill,
      );
    }
    canvas
      ..drawPath(path, paint)
      ..drawCircle(center, SizeManager.verseMarkerRing * unit, paint);
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.color != color || old.fill != fill;
}
