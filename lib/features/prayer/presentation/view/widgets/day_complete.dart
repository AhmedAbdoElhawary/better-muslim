import 'dart:ui';

import 'package:better_muslim/core/audio/ui_sounds.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Motion 08 over the whole screen, tab bar too. it never blocks: any tap dismisses it
void showDayComplete(BuildContext context) {
  BmHaptics.dayComplete();
  BmSounds.complete();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => DayComplete(onDone: entry.remove));
  overlay.insert(entry);
}

/// the five dots fold into the star, a ring spreads from it and the caption rises. with reduce
/// motion the dots fade out and the star fades in over 300 ms
class DayComplete extends ConsumerStatefulWidget {
  const DayComplete({required this.onDone, super.key});
  final VoidCallback onDone;

  @override
  ConsumerState<DayComplete> createState() => _DayCompleteState();
}

class _DayCompleteState extends ConsumerState<DayComplete> with TickerProviderStateMixin {
  /// the demo's timeline in 05 Motion.dc.html, then a hold to read it and a 300 ms fade out
  static const _total = Duration(milliseconds: 2800);
  static const _hold = Duration(milliseconds: 2500);
  static const _backdrop = .92;

  late final _timeline = AnimationController(vsync: this, duration: _total);
  late final _star = AnimationController.unbounded(vsync: this);

  /// read once, a setting change mid ceremony doesn't restart it
  bool? _reduceMotion;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion ??= context.reduceMotion(ref.read(settingsProvider).value?.reduceMotion ?? false);
  }

  @override
  void initState() {
    super.initState();
    _timeline.forward().whenCompleteOrCancel(_done);
    _timeline.addListener(_startStar);
  }

  void _startStar() {
    if (_reduceMotion! || _timeline.value < _at(950)) return;
    _timeline.removeListener(_startStar);
    _star.animateWith(SpringSimulation(BmMotion.gentle, .5, 1, 0));
  }

  var _finished = false;

  void _done() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  double _at(int ms) => ms / _total.inMilliseconds;

  Animation<double> _between(int from, int duration, {Curve curve = Curves.linear}) =>
      CurvedAnimation(
        parent: _timeline,
        curve: Interval(_at(from), _at(from + duration), curve: curve),
      );

  @override
  void dispose() {
    _timeline.dispose();
    _star.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = _reduceMotion!;
    final dots = _between(500, reduce ? 300 : 520, curve: BmMotion.standardCurve);
    final starIn = _between(reduce ? 700 : 950, reduce ? 300 : 150);
    final ring = _between(950, 900, curve: BmMotion.decelerate);
    final caption = _between(reduce ? 800 : 1200, reduce ? 300 : 520, curve: BmMotion.decelerate);
    final out = _between(_hold.inMilliseconds, BmMotion.standard.inMilliseconds);
    final primary = context.getColor(ThemeEnum.primary);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _done,
      child: AnimatedBuilder(
        animation: Listenable.merge([_timeline, _star]),
        builder: (context, _) => CustomOpacity(
          opacity: 1 - out.value,
          child: ColoredBox(
            color: context.getColor(ThemeEnum.bg).withValues(alpha: _backdrop),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RSizedBox.square(
                    dimension: SizeManager.dayCompleteRing,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        for (final (index, _) in Prayer.values.indexed)
                          Transform.translate(
                            offset: Offset(
                              (index - 2) *
                                  SpaceManager.dayCompleteDots.r *
                                  (reduce ? 1 : 1 - dots.value),
                              0,
                            ),
                            child: Transform.scale(
                              scale: reduce ? 1 : lerpDouble(1, .4, dots.value),
                              child: CustomOpacity(
                                opacity: 1 - dots.value,
                                child: _Circle(
                                  size: SizeManager.dayCompleteDot,
                                  color: primary,
                                  filled: true,
                                ),
                              ),
                            ),
                          ),
                        if (!reduce)
                          CustomOpacity(
                            opacity: ring.value == 0 ? 0 : .7 * (1 - ring.value),
                            child: Transform.scale(
                              scale: 1 + ring.value,
                              child: _Circle(
                                size: SizeManager.dayCompleteRing,
                                color: primary,
                                filled: false,
                              ),
                            ),
                          ),
                        CustomOpacity(
                          opacity: starIn.value,
                          child: Transform.scale(
                            scale: reduce || _star.value == 0 ? 1 : _star.value,
                            child: CustomPaint(
                              size: Size.square(SizeManager.dayCompleteStar.r),
                              painter: _StarPainter(primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const RSizedBox.vertical(SpaceManager.s4),
                  CustomOpacity(
                    opacity: caption.value,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        reduce ? 0 : SpaceManager.dayCompleteRise.r * (1 - caption.value),
                      ),
                      child: const RegularText(
                        StringsManager.allFivePrayed,
                        font: FontEnum.display,
                        fontSize: FontSizeManager.dayComplete,
                      ),
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

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color, required this.filled});
  final double size;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: filled ? color : null,
          border: filled ? null : Border.all(color: color),
        ),
      ),
    );
  }
}

/// the eight-pointed star of the motion file, its 16 points in a 20 box
class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);
  final Color color;

  static const _points = [
    (0.0, -10.0),
    (2.93, -7.07),
    (7.07, -7.07),
    (7.07, -2.93),
    (10.0, 0.0),
    (7.07, 2.93),
    (7.07, 7.07),
    (2.93, 7.07),
    (0.0, 10.0),
    (-2.93, 7.07),
    (-7.07, 7.07),
    (-7.07, 2.93),
    (-10.0, 0.0),
    (-7.07, -2.93),
    (-7.07, -7.07),
    (-2.93, -7.07),
  ];

  /// the star's viewBox is 22 wide
  static const _box = 22.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _box;
    final center = size.center(Offset.zero);
    final path = Path()
      ..addPolygon([for (final (x, y) in _points) center + Offset(x * scale, y * scale)], true);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color;
}
