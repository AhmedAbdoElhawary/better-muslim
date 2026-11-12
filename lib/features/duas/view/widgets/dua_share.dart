import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/share/share_frame.dart';
import 'package:better_muslim/core/widgets/share/share_options.dart';
import 'package:better_muslim/core/widgets/share/share_sheet.dart';
import 'package:better_muslim/features/duas/model/dua.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the dua on the share card: the arabic, then in english its transliteration and translation.
/// the source is the footer (FR-014)
class DuaShare extends ShareContent {
  const DuaShare(this.dua);

  final Dua dua;

  @override
  String get title => StringsManager.shareDua;

  @override
  String get file => 'dua.png';

  /// only a verse is drawn in the quran font
  @override
  bool get usesFont => dua.quran;

  @override
  String footer(BuildContext context) => dua.sourceIn(Localizations.localeOf(context).languageCode);

  /// the ayah's steps without the tafsir: smaller, then story, then smaller still
  @override
  ShareLayout layout(BuildContext context, ShareOptions options) {
    final english = Localizations.localeOf(context).languageCode != 'ar';
    bool fits(ShareSize size, double scale) {
      final box = shareBox(size);
      final painters = _painters(options, scale, box.width, english: english);
      final height = _height(painters);
      for (final painter in painters) {
        painter.dispose();
      }
      return height <= box.height;
    }

    final sizes = ShareSize.tried(options);
    for (final size in sizes) {
      for (final scale in SizeManager.shareFit) {
        if (fits(size, scale)) return (size: size, scale: scale, fits: true, note: null);
      }
    }
    var scale = SizeManager.shareFit.last;
    while (scale > SizeManager.shareFitStep * 2 && !fits(sizes.last, scale)) {
      scale -= SizeManager.shareFitStep;
    }
    return (size: sizes.last, scale: scale, fits: false, note: null);
  }

  @override
  Widget build(BuildContext context, ShareOptions options, ShareLayout layout) =>
      _DuaCard(share: this, options: options, scale: layout.scale);

  static double get _gap => SpaceManager.shareCardGap.r;

  static double _height(List<TextPainter> painters) =>
      painters.fold(0.0, (height, painter) => height + painter.height) +
      _gap * (painters.length - 1);

  List<TextPainter> _painters(
    ShareOptions options,
    double scale,
    double width, {
    required bool english,
    Color? ink,
    Color? textColor,
  }) {
    TextPainter painter(String text, TextStyle style, TextDirection direction) => TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: direction,
    )..layout(maxWidth: width);
    final small = GetRegularStyle(
      fontSize: FontSizeManager.shareTranslation.sp * scale,
      height: LineHeightManager.shareTranslation,
      fontFamily: FontEnum.body.latin,
      color: textColor,
    );
    return [
      painter(
        dua.quran ? options.font.drawn(dua.arabic) : dua.arabic,
        GetRegularStyle(
          fontSize: FontSizeManager.shareAyah.sp * scale,
          height: LineHeightManager.shareAyah,
          fontFamily: dua.quran ? options.font.family : FontFamilyManager.dua,
          color: ink,
        ),
        TextDirection.rtl,
      ),

      /// an empty line would still take its height and gap
      if (english && dua.transliteration.isNotEmpty)
        painter(
          dua.transliteration,
          small.copyWith(fontStyle: FontStyle.italic),
          TextDirection.ltr,
        ),
      if (english && dua.translation.isNotEmpty) painter(dua.translation, small, TextDirection.ltr),
    ];
  }
}

/// read under the frame's theme, so its colors are the card's
class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.share, required this.options, required this.scale});

  final DuaShare share;
  final ShareOptions options;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final width = shareBox(ShareSize.square).width;
    final painters = share._painters(
      options,
      scale,
      width,
      english: Localizations.localeOf(context).languageCode != 'ar',
      ink: context.getColor(ThemeEnum.ink),
      textColor: context.getColor(ThemeEnum.ink2),
    );
    return Semantics(
      label: painters.map((painter) => painter.plainText).join('\n'),
      excludeSemantics: true,

      /// a last guard, the layout already picked a scale it all fits at
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: CustomPaint(
          size: Size(width, DuaShare._height(painters)),
          painter: _Lines(painters, gap: DuaShare._gap),
        ),
      ),
    );
  }
}

class _Lines extends CustomPainter {
  const _Lines(this.painters, {required this.gap});

  final List<TextPainter> painters;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    var top = 0.0;
    for (final painter in painters) {
      painter.paint(canvas, Offset((size.width - painter.width) / 2, top));
      top += painter.height + gap;
    }
  }

  @override
  bool shouldRepaint(_Lines old) => old.painters != painters;
}
