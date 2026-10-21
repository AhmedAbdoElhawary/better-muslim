import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/animated_decorated_box.dart';
import 'package:better_muslim/features/quran/domain/recitation.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/recitation_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/selection.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_page_view.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/mushaf_star.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.07, the ayahs starting on a mushaf page as verse cells, so the layouts share the page and its
/// last read. Both puts the page itself above them
class TranslationView extends ConsumerWidget {
  const TranslationView(this.page, {required this.onAyah, this.mushaf, super.key});

  final int page;
  final ValueChanged<AyahKey> onAyah;
  final Widget? mushaf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahs = ref.watch(quranAssetsProvider).value?.pageAyahs(page) ?? const [];
    final marked =
        ref.watch(selectionProvider.select((key) => key != null)) ||
        ref.watch(playingAyahProvider.select((key) => key != null));
    final mushaf = this.mushaf;
    return ColoredBox(
      color: context.getColor(ThemeEnum.page),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          mushaf ?? const SafeArea(bottom: false, child: RSizedBox.vertical(SpaceManager.s1)),
          for (final key in ayahs)
            HorizontalPadding(
              padding: SpaceManager.s3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (key.ayah == 1) _SurahHeader(key.surah),
                  _VerseCell(key, onTap: () => onAyah(key)),
                ],
              ),
            ),

          /// the last cell scrolls clear of the mini player, or of a sheet over its ayah
          SafeArea(
            top: false,
            child: RSizedBox.vertical(
              marked ? SizeManager.recitationSheet : SizeManager.miniPlayer + SpaceManager.s4,
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
/// scrolls into view when it takes either, when the layout switches to it and when the text size
/// changes under it
class _VerseCell extends ConsumerStatefulWidget {
  const _VerseCell(this.ayah, {required this.onTap});

  final AyahKey ayah;
  final VoidCallback onTap;

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
    if (_marked()) _show();
  }

  bool _marked() {
    final playing = ref.read(playingAyahProvider);
    return ref.read(selectionProvider) == widget.ayah ||
        (playing != null && readAyah(playing) == widget.ayah);
  }

  /// after the frame, so the new size is laid out first
  void _show() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
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
    final selected = ref.watch(selectionProvider.select((key) => key == ayah));
    final playing = ref.watch(
      playingAyahProvider.select((key) => key != null && readAyah(key) == ayah),
    );
    final (arabicStep, translationStep) = ref.watch(
      settingsProvider.select(
        (settings) =>
            (settings.value?.quranArabicSize ?? 0, settings.value?.quranTranslationSize ?? 0),
      ),
    );
    ref
      ..listen(selectionProvider.select((key) => key == ayah), (_, on) {
        if (on) _show();
      })
      ..listen(playingAyahProvider.select((key) => key != null && readAyah(key) == ayah), (_, on) {
        if (on) _show();
      })
      ..listen(
        settingsProvider.select(
          (settings) => (settings.value?.quranArabicSize, settings.value?.quranTranslationSize),
        ),
        (_, _) {
          if (_marked()) _show();
        },
      );
    final arabic = ref.watch(ayahTextProvider(ayah)).value ?? '';
    final text = ref.watch(surahTextProvider(ayah.surah)).value;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    /// in arabic the translation slot is al-muyassar (FR-020)
    final translation = isArabic ? text?.tafsir[ayah.ayah - 1] : text?.translation[ayah.ayah - 1];
    final wash = selected
        ? ThemeEnum.selectionWash
        : playing
        ? ThemeEnum.followWash
        : ThemeEnum.transparent;
    final surah = ref.watch(quranAssetsProvider).value?.surah(ayah.surah);
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: surah == null
          ? null
          : ayahLabel(context, surah: surah, ayah: ayah, arabic: arabic, text: text),
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onLongPress: widget.onTap,
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
                  child: Wrap(
                    spacing: SpaceManager.verseMarkerGap.r,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RegularText(
                        arabic,
                        translate: false,
                        font: FontEnum.quran,
                        fontSize: FontSizeManager.quranAr + arabicStep * FontSizeManager.arabicStep,
                        height: LineHeightManager.quranAr,
                        color: ThemeEnum.ink,
                      ),
                      _VerseMarker(ayah.ayah),
                    ],
                  ),
                ),
                const RSizedBox.vertical(SpaceManager.verseGap),
                RegularText(
                  translation ?? '',
                  translate: false,
                  fontSize:
                      FontSizeManager.verseTranslation +
                      translationStep * FontSizeManager.translationStep,
                  height: LineHeightManager.verseCell,
                  color: ThemeEnum.text2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 4.07's ayah marker, eastern digits in both languages as the mushaf prints them
class _VerseMarker extends StatelessWidget {
  const _VerseMarker(this.number);

  final int number;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MarkerPainter(context.getColor(ThemeEnum.primary)),
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
  const _MarkerPainter(this.color);

  final Color color;

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
    canvas
      ..drawPath(
        Path()..addPolygon([
          for (final (x, y) in _points)
            center + Offset((x - half) * star * unit, (y - half) * star * unit),
        ], true),
        paint,
      )
      ..drawCircle(center, SizeManager.verseMarkerRing * unit, paint);
  }

  @override
  bool shouldRepaint(_MarkerPainter old) => old.color != color;
}
