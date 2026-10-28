import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/mushaf_star.dart';
import 'package:better_muslim/core/widgets/share/share_frame.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:better_muslim/features/quran/data/tafsir_files.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// what goes under each ayah, english is the translation and the rest arabic tafsir (FR-023)
enum ShareTextSource {
  none(StringsManager.ayahOnly),
  translation(StringsManager.translation),
  muyassar(StringsManager.alMuyassar, tafsir: TafsirSource.muyassar),
  ibnKathir(StringsManager.ibnKathir, tafsir: TafsirSource.ibnKathir),
  saadi(StringsManager.asSadi, tafsir: TafsirSource.saadi);

  const ShareTextSource(this.label, {this.tafsir});

  final String label;
  final TafsirSource? tafsir;
}

/// one or more ayahs in mushaf order. ayahs in a row are one paragraph, a divider between the
/// rest (FR-016)
class AyahShare extends ShareContent {
  AyahShare({
    required this.arabic,
    this.texts = const {},
    this.source = ShareTextSource.none,
    this.surahs = const {},
    this.digits = Digits.eastern,
  }) : keys = arabic.keys.toList()..sort();

  final Map<AyahKey, String> arabic;

  /// the source's text of each ayah, an ayah without one shows none
  final Map<AyahKey, String> texts;
  final ShareTextSource source;
  final Map<int, QuranSurah> surahs;
  final Digits digits;
  final List<AyahKey> keys;

  /// what the last layout kept of the texts, build draws it
  Map<AyahKey, String> _shown = const {};

  /// an ayah is added only when all of them still fit with the most forgiving options, the first
  /// one never asks (FR-018)
  static bool canAdd(BuildContext context, Map<AyahKey, String> arabic) =>
      AyahShare(arabic: arabic)
          .layout(context, const ShareOptions(size: ShareSize.story, sizeLocked: true))
          .fits;

  @override
  String get title => StringsManager.shareAyah;

  @override
  String get file => 'ayah.png';

  /// the same surah with each ayah after the one before
  List<List<AyahKey>> get runs {
    final runs = <List<AyahKey>>[];
    for (final key in keys) {
      final last = runs.lastOrNull?.last;
      if (last != null && last.surah == key.surah && last.ayah + 1 == key.ayah) {
        runs.last.add(key);
      } else {
        runs.add([key]);
      }
    }
    return runs;
  }

  /// "Al-Baqarah 255–257 · Aal-'Imran 18"
  @override
  String footer(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final bySurah = <int, List<List<AyahKey>>>{};
    for (final run in runs) {
      bySurah.putIfAbsent(run.first.surah, () => []).add(run);
    }
    return [
      for (final MapEntry(key: surah, value: runs) in bySurah.entries)
        context.tr(StringsManager.shareRun, {
          'surah': (isArabic ? surahs[surah]?.ar : surahs[surah]?.en) ?? '',
          'ayahs': context.formatDigits(
            runs
                .map(
                  (run) =>
                      run.length == 1 ? '${run.first.ayah}' : '${run.first.ayah}–${run.last.ayah}',
                )
                .join(isArabic ? '، ' : ', '),
            digits,
          ),
        }),
    ].join(' · ');
  }

  /// scale down to the last step, then story unless a size was picked, then each ayah's text from
  /// the last one back is cut at a sentence or hidden (FR-017)
  @override
  ShareLayout layout(BuildContext context, ShareOptions options) {
    final all = {
      for (final key in keys)
        if (texts[key] case final text? when text.isNotEmpty) key: text,
    };
    bool fits(ShareSize size, double scale, Map<AyahKey, String> shown) {
      final box = shareBox(size);
      return _height(options.font, scale, shown, box.width) <= box.height;
    }

    ShareLayout keep(ShareSize size, double scale, Map<AyahKey, String> shown, {bool fits = true}) {
      _shown = shown;
      final hidden = all.length - shown.length;
      return (
        size: size,
        scale: scale,
        fits: fits,
        note: hidden == 0
            ? null
            : context.tr(StringsManager.tafsirHidden, {
                'n': context.formatDigits('$hidden', digits),
              }),
      );
    }

    final sizes = options.sizeLocked || options.size == ShareSize.story
        ? [options.size]
        : ShareSize.values;
    for (final size in sizes) {
      for (final scale in SizeManager.shareFit) {
        if (fits(size, scale, all)) return keep(size, scale, all);
      }
    }
    final size = sizes.last;
    var scale = SizeManager.shareFit.last;
    final shown = {...all};
    for (final key in all.keys.toList().reversed) {
      if (source.tafsir != null) {
        final cut = _cut(all[key]!, (text) => fits(size, scale, {...shown, key: text}));
        if (cut != null) return keep(size, scale, {...shown, key: cut});
      }
      shown.remove(key);
      if (fits(size, scale, shown)) return keep(size, scale, shown);
    }

    /// the ayah itself is never cut, it gets smaller instead
    while (scale > SizeManager.shareFitStep * 2 && !fits(size, scale, shown)) {
      scale -= SizeManager.shareFitStep;
    }
    return keep(size, scale, shown, fits: false);
  }

  /// the longest whole sentences that fit, with "…" (FR-024)
  static String? _cut(String text, bool Function(String text) fits) {
    final ends = [
      for (var i = 0; i < text.length; i++)
        if ('.۔؛'.contains(text[i])) i + 1,
    ];
    var (low, high) = (0, ends.length - 1);
    String? best;
    while (low <= high) {
      final middle = (low + high) ~/ 2;
      final candidate = '${text.substring(0, ends[middle]).trimRight()}…';
      if (fits(candidate)) {
        best = candidate;
        low = middle + 1;
      } else {
        high = middle - 1;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context, ShareOptions options, ShareLayout layout) =>
      _AyahCard(share: this, options: options, scale: layout.scale);

  static double get _gap => SpaceManager.shareCardGap.r;

  /// the star, then each run with a divider before all but the first
  double _height(QuranFont font, double scale, Map<AyahKey, String> shown, double width) {
    var height = SizeManager.shareStar.r;
    for (final (i, (ayah, text)) in _paragraphs(font, scale, shown, width).indexed) {
      height += _gap + (i == 0 ? 0 : SizeManager.shareDivider.r + _gap) + ayah.height;
      if (text != null) height += _gap + text.height;
      ayah.dispose();
      text?.dispose();
    }
    return height;
  }

  /// per run, the arabic with its markers and its ayahs' texts
  List<(TextPainter, TextPainter?)> _paragraphs(
    QuranFont font,
    double scale,
    Map<AyahKey, String> shown,
    double width, {
    Color? ink,
    Color? ornament,
    Color? textColor,
  }) {
    final style = GetRegularStyle(
      fontSize: FontSizeManager.shareAyah.sp * scale,
      height: LineHeightManager.shareAyah,
      fontFamily: font.family,
      color: ink,
    );
    final english = source == ShareTextSource.translation;
    final numbered = keys.length > 1;
    String number(AyahKey key) =>
        formatDigitsIn('${key.ayah}', language: english ? 'en' : 'ar', digits: digits);
    return [
      for (final run in runs)
        (
          TextPainter(
            text: TextSpan(
              style: style,
              children: [
                for (final (i, key) in run.indexed) ...[
                  TextSpan(text: '${i == 0 ? '' : ' '}${arabic[key]} '),

                  /// quran markers are eastern whatever the app's digits
                  TextSpan(
                    text:
                        '﴿${formatDigitsIn('${key.ayah}', language: 'ar', digits: Digits.eastern)}﴾',
                    style: style.copyWith(color: ornament),
                  ),
                ],
              ],
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          )..layout(maxWidth: width),
          switch ([
            for (final key in run)
              if (shown[key] case final text?) numbered ? '(${number(key)}) $text' : text,
          ]) {
            [] => null,
            final lines => TextPainter(
              text: TextSpan(
                text: lines.join(' '),
                style: GetRegularStyle(
                  fontSize: FontSizeManager.shareTranslation.sp * scale,
                  height: LineHeightManager.shareTranslation,
                  fontFamily: english ? FontEnum.body.latin : FontEnum.body.arabic,
                  color: textColor,
                ),
              ),
              textAlign: TextAlign.center,
              textDirection: english ? TextDirection.ltr : TextDirection.rtl,
            )..layout(maxWidth: width),
          },
        ),
    ];
  }
}

/// read under the frame's theme, so its colors are the card's
class _AyahCard extends StatelessWidget {
  const _AyahCard({required this.share, required this.options, required this.scale});

  final AyahShare share;
  final ShareOptions options;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final width = shareBox(ShareSize.square).width;
    final ornament = context.getColor(options.background.ornament);
    final paragraphs = share._paragraphs(
      options.font,
      scale,
      share._shown,
      width,
      ink: context.getColor(ThemeEnum.ink),
      ornament: ornament,
      textColor: context.getColor(ThemeEnum.ink2),
    );
    final label = [
      for (final key in share.keys) ...[?share.arabic[key], '${key.ayah}', ?share._shown[key]],
    ].join(' ');
    return Semantics(
      label: label,
      excludeSemantics: true,

      /// a last guard, the layout already picked a scale it all fits at
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(width: width),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: Size(width, SizeManager.shareStar.r),
                painter: _Star(color: ornament, stroke: SizeManager.starStroke.r),
              ),
              for (final (i, (ayah, text)) in paragraphs.indexed) ...[
                if (i > 0) ...[
                  const RSizedBox.vertical(SpaceManager.shareCardGap),
                  SvgPicture.asset(
                    'assets/ornaments/divider_section.svg',
                    width: width,
                    height: SizeManager.shareDivider.r,
                    colorFilter: ColorFilter.mode(ornament, BlendMode.srcIn),
                  ),
                ],
                const RSizedBox.vertical(SpaceManager.shareCardGap),
                CustomPaint(
                  size: Size(
                    width,
                    ayah.height + (text == null ? 0 : AyahShare._gap + text.height),
                  ),
                  painter: _Run(ayah: ayah, text: text, gap: AyahShare._gap),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Star extends CustomPainter {
  const _Star({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      mushafStar(Offset(size.width / 2, size.height / 2), size.height),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Star old) => old.color != color || old.stroke != stroke;
}

class _Run extends CustomPainter {
  const _Run({required this.ayah, required this.text, required this.gap});

  final TextPainter ayah;
  final TextPainter? text;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    ayah.paint(canvas, Offset((size.width - ayah.width) / 2, 0));
    final text = this.text;
    text?.paint(canvas, Offset((size.width - text.width) / 2, ayah.height + gap));
  }

  @override
  bool shouldRepaint(_Run old) => old.ayah != ayah || old.text != text;
}
