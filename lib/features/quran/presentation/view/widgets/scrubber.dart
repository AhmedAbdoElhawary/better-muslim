import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the dock's page scrubber (4.21). it runs right to left like the mushaf in both languages, shows
/// the page under the finger and opens it on release
class Scrubber extends ConsumerStatefulWidget {
  const Scrubber({required this.page, super.key});

  final ValueNotifier<int> page;

  @override
  ConsumerState<Scrubber> createState() => _ScrubberState();
}

class _ScrubberState extends ConsumerState<Scrubber> {
  /// the page under the finger while dragging
  int? _dragging;

  int _pageAt(double x, double width) =>
      (1 + ((1 - x / width) * (quranPageCount - 1)).round()).clamp(1, quranPageCount);

  void _open(int page) {
    setState(() => _dragging = null);
    widget.page.value = page;
  }

  @override
  Widget build(BuildContext context) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final assets = ref.watch(quranAssetsProvider).value;
    final direction = Directionality.of(context);
    return ValueListenableBuilder(
      valueListenable: widget.page,
      builder: (context, page, _) {
        final shown = _dragging ?? page;

        /// the label row takes taps too, so the 28 pt track still has a 44 pt target
        return Directionality(
          textDirection: TextDirection.ltr,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return MergeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) =>
                      setState(() => _dragging = _pageAt(details.localPosition.dx, width)),
                  onHorizontalDragUpdate: (details) =>
                      setState(() => _dragging = _pageAt(details.localPosition.dx, width)),
                  onHorizontalDragEnd: (_) => _open(_dragging ?? page),
                  onTapUp: (details) => _open(_pageAt(details.localPosition.dx, width)),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: SizeManager.hit.r),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            RegularText(
                              context.formatDigits('$quranPageCount', digits),
                              translate: false,
                              fontSize: FontSizeManager.label,
                              color: ThemeEnum.text2,
                            ),
                            Directionality(
                              textDirection: direction,
                              child: MediumText(
                                StringsManager.pageJuz,
                                fontSize: FontSizeManager.label,
                                args: {
                                  'p': context.formatDigits('$shown', digits),
                                  'j': context.formatDigits(
                                    '${assets?.pageInfo(shown).juz ?? 1}',
                                    digits,
                                  ),
                                },
                              ),
                            ),
                            RegularText(
                              context.formatDigits('1', digits),
                              translate: false,
                              fontSize: FontSizeManager.label,
                              color: ThemeEnum.text2,
                            ),
                          ],
                        ),
                        CustomPaint(
                          painter: _TrackPainter(
                            page: shown,
                            juzPages: [
                              for (final juz in assets?.juzs.skip(1) ?? <QuranJuz>[]) juz.page,
                            ],
                            track: context.getColor(ThemeEnum.variant),
                            progress: context.getColor(ThemeEnum.primary),
                            tick: context.getColor(ThemeEnum.outlineStrong).withValues(alpha: .5),
                          ),
                          child: RSizedBox(
                            height: SizeManager.scrubber,
                            child: Align(
                              alignment: Alignment(1 - 2 * (shown - 1) / (quranPageCount - 1), 0),
                              child: const _Thumb(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb();

  @override
  Widget build(BuildContext context) {
    final shadow = context.getColor(ThemeEnum.scrim);
    return Container(
      width: SizeManager.scrubberThumb.r,
      height: SizeManager.scrubberThumb.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.getColor(ThemeEnum.surface),
        boxShadow: [
          BoxShadow(
            color: shadow.withValues(alpha: .3),
            blurRadius: SizeManager.scrubberThumbShadow.r,
            offset: Offset(0, SizeManager.scrubberThumbShadowY.r),
          ),
          BoxShadow(color: shadow.withValues(alpha: .1), spreadRadius: SizeManager.divider.r),
        ],
      ),
    );
  }
}

/// the track, the read part from page 1 on the right, and a tick at each juz
class _TrackPainter extends CustomPainter {
  const _TrackPainter({
    required this.page,
    required this.juzPages,
    required this.track,
    required this.progress,
    required this.tick,
  });

  final int page;
  final List<int> juzPages;
  final Color track;
  final Color progress;
  final Color tick;

  double _x(int page, double width) => width * (1 - (page - 1) / (quranPageCount - 1));

  @override
  void paint(Canvas canvas, Size size) {
    final height = SizeManager.scrubberTrack.r;
    final radius = Radius.circular(height);
    final top = size.height / 2 - height / 2;
    canvas
      ..drawRRect(RRect.fromLTRBR(0, top, size.width, top + height, radius), Paint()..color = track)
      ..drawRRect(
        RRect.fromLTRBR(_x(page, size.width), top, size.width, top + height, radius),
        Paint()..color = progress,
      );
    final tickHeight = SizeManager.scrubberTick.r;
    final paint = Paint()..color = tick;
    for (final juz in juzPages) {
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(_x(juz, size.width), size.height / 2),
          width: SizeManager.divider.r,
          height: tickHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.page != page ||
      old.juzPages.length != juzPages.length ||
      old.track != track ||
      old.progress != progress ||
      old.tick != tick;
}
