import 'dart:math' as math;

import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/styles_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/core/settings/quran.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/quran/data/mushaf_files.dart';
import 'package:better_muslim/features/quran/domain/mushaf_page.dart';
import 'package:better_muslim/features/quran/presentation/providers/mushaf_style_providers.dart';
import 'package:better_muslim/features/quran/presentation/providers/page_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the page's V4 font in one palette, loaded the way the reader will load it
final _familyProvider = FutureProvider.autoDispose.family<String, int>(
  (ref, palette) => ref
      .read(mushafFilesProvider)
      .family(MushafStyle.qcfV4, DevTajweedPage.page, palette: palette),
);

// TODO(ahmed): open this on the iPhone and the Android phone and put what shows in ticket 05, a phone with no colors gets V4 hidden in 06.
/// dev builds only, to see if the phone draws the V4 colors (specs/016 ticket 05). its text is for
/// me, so it is not in the arb files
class DevTajweedPage extends ConsumerWidget {
  const DevTajweedPage({super.key});

  static const page = 3;
  static const _title = 'Tajweed (dev)';
  static const _body =
      'Page 3 in QCF V4: palette 0 on Paper, 1 on Night, 2 on Sepia. Colored words mean this '
      'phone draws COLRv1, plain ink or nothing means it does not.';
  static const _download = 'Download QCF V4, 68 MB';
  static const _downloading = 'Downloading';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(mushafStyleStatusProvider(MushafStyle.qcfV4));
    final progress = '$_downloading ${((status.progress ?? 0) * 100).round()}%';
    return Scaffold(
      body: TitleGlow(
        child: SafeArea(
          /// a column, so the three palettes load together
          child: SingleChildScrollView(
            padding: REdgeInsets.all(SpaceManager.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SemiBoldText(_title, translate: false),
                const RSizedBox.vertical(SpaceManager.s2),
                const RegularText(_body, translate: false),
                const RSizedBox.vertical(SpaceManager.s4),
                if (status.ready)
                  for (final (color, palette) in [
                    (PageColor.paper, 0),
                    (PageColor.night, 1),
                    (PageColor.sepia, 2),
                  ])
                    _Palette(color, palette)
                else if (status.downloading)
                  RegularText(progress, translate: false)
                else
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => ref
                          .read(mushafStyleStatusProvider(MushafStyle.qcfV4).notifier)
                          .download()
                          .ignore(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: SizeManager.listRow.r),
                        child: const Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: RegularText(
                            _download,
                            translate: false,
                            fontSize: FontSizeManager.body,
                            color: ThemeEnum.accent,
                          ),
                        ),
                      ),
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

/// the page's lines on one page color, each scaled to the width
class _Palette extends ConsumerWidget {
  const _Palette(this.color, this.palette);

  final PageColor color;
  final int palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final family = ref.watch(_familyProvider(palette)).value;
    final page = ref.watch(mushafPageProvider(DevTajweedPage.page)).value;
    return Theme(
      data: AppTheme.page(color, ref.watch(themeIdProvider)),
      child: BottomPadding(
        padding: SpaceManager.s4,
        child: Builder(
          builder: (context) => ColoredBox(
            color: context.getColor(ThemeEnum.page),
            child: AllPadding(
              padding: SpaceManager.s4,
              child: family == null || page == null
                  ? const RSizedBox.vertical(SizeManager.listRow)
                  : _Lines(page, family, context.getColor(ThemeEnum.ink)),
            ),
          ),
        ),
      ),
    );
  }
}

class _Lines extends StatelessWidget {
  const _Lines(this.page, this.family, this.ink);

  final MushafPage page;
  final String family;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painters = [
          for (final line in page.lines)
            if (line.words.map((word) => word.glyph).join() case final text when text.isNotEmpty)
              TextPainter(
                text: TextSpan(
                  text: text,
                  style: GetRegularStyle(
                    fontSize: FontSizeManager.quranPage,
                    fontFamily: family,
                    color: ink,
                  ),
                ),
                textDirection: TextDirection.rtl,
              )..layout(),
        ];
        final scale =
            constraints.maxWidth / painters.map((painter) => painter.width).reduce(math.max);
        final height = painters.fold(0.0, (sum, painter) => sum + painter.height) * scale;
        return CustomPaint(
          size: Size(constraints.maxWidth, height),
          painter: _LinesPainter(painters, scale),
        );
      },
    );
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.painters, this.scale);

  final List<TextPainter> painters;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    var y = 0.0;
    for (final painter in painters) {
      painter.paint(canvas, Offset((size.width / scale - painter.width) / 2, y));
      y += painter.height;
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => old.painters != painters || old.scale != scale;
}
