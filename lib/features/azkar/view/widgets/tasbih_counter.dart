import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/ring_painter.dart';
import 'package:better_muslim/core/widgets/rolling_digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.08's ring and count, the digits rolling. at the target the glow and MOTION 12's burst, the
/// ring alone with reduce motion. never mirrored in arabic
class TasbihCounter extends StatefulWidget {
  const TasbihCounter({
    required this.count,
    required this.target,
    required this.label,
    required this.targetLabel,
    required this.complete,
    super.key,
  });
  final int count;
  final int target;

  /// all three done, set complete in place of the target
  final bool complete;

  /// the count and target with the app's digits
  final String label;
  final String targetLabel;

  @override
  State<TasbihCounter> createState() => _TasbihCounterState();
}

class _TasbihCounterState extends State<TasbihCounter> with TickerProviderStateMixin {
  /// the burst starts once the ring's 300 ms fill is over
  late final _burst = AnimationController(
    vsync: this,
    duration: BmMotion.standard + BmMotion.burst,
  );

  /// MOTION cnt, each count starts this much larger and scales back
  late final _pulse = AnimationController(vsync: this, duration: BmMotion.micro, value: 1);
  static const _rest = 1.0;
  late final _scale = Tween(
    begin: 1.06,
    end: _rest,
  ).animate(CurvedAnimation(parent: _pulse, curve: BmMotion.standardCurve));

  bool get _done => widget.count >= widget.target;

  @override
  void didUpdateWidget(TasbihCounter old) {
    super.didUpdateWidget(old);
    final wasDone = old.count >= old.target;
    if (_done && !wasDone && !MediaQuery.disableAnimationsOf(context)) _burst.forward(from: 0);
    if (!_done) _burst.reset();
    if (widget.count != old.count && !MediaQuery.disableAnimationsOf(context)) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _burst.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RSizedBox.square(
        dimension: SizeManager.tasbihRing,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (_done) const _Glow(),
            RepaintBoundary(
              child: RSizedBox.square(
                dimension: SizeManager.tasbihRingArc,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: widget.count / widget.target),
                  duration: reduceMotion ? Duration.zero : BmMotion.standard,
                  curve: BmMotion.standardCurve,
                  builder: (context, share, _) => CustomPaint(
                    painter: RingPainter(
                      share: share,
                      track: context.getColor(ThemeEnum.variant),
                      arc: context.getColor(ThemeEnum.primary),
                      stroke: SizeManager.tasbihRingStroke.r,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            CustomPaint(
              painter: _BurstPainter(
                progress: _burst,
                color: context.getColor(ThemeEnum.onPrimaryContainer),
              ),
              size: Size.infinite,
            ),
            MediaQuery.withClampedTextScaling(
              maxScaleFactor: SizeManager.counterMaxTextScale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: _scale,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final (index, digit) in widget.label.split('').indexed)
                          RollingDigit(
                            digit,
                            key: ValueKey(widget.label.length - index),
                            child: RegularText(
                              digit,
                              translate: false,
                              font: FontEnum.display,
                              fontSize: FontSizeManager.counter,
                              height: LineHeightManager.counter,
                              tabularFigures: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const RSizedBox.vertical(SpaceManager.counterGap),
                  BmSwitcher(
                    child: widget.complete
                        ? const MediumText(
                            StringsManager.setComplete,
                            key: ValueKey(true),
                            fontSize: FontSizeManager.secondary,
                            color: ThemeEnum.primary,
                          )
                        : RegularText(
                            StringsManager.ofTarget,
                            key: const ValueKey(false),
                            args: {'target': widget.targetLabel},
                            fontSize: FontSizeManager.secondary,
                            color: ThemeEnum.text2,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow();

  @override
  Widget build(BuildContext context) {
    final glow = context.getColor(ThemeEnum.glow);
    return OverflowBox(
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: RSizedBox.square(
        dimension: SizeManager.tasbihGlow,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [glow.withValues(alpha: .35), glow.withValues(alpha: 0)],
              stops: const [0, .62],
            ),
          ),
        ),
      ),
    );
  }
}

/// 8 particles out from the center, in and out of sight over 700 ms decelerate
class _BurstPainter extends CustomPainter {
  _BurstPainter({required this.progress, required this.color}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  static const _particles = 8;
  static final _curve = Interval(
    BmMotion.standard.inMilliseconds / (BmMotion.standard + BmMotion.burst).inMilliseconds,
    1,
    curve: BmMotion.decelerate,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (progress.value == 0 || progress.value == 1) return;
    final t = _curve.transform(progress.value);
    if (t == 0) return;

    /// css keyframes: transparent, fully in at 10%, then out by the end
    final opacity = t < .1 ? t / .1 : 1 - (t - .1) / .9;
    final paint = Paint()..color = color.withValues(alpha: color.a * opacity);
    final scale = size.width / SizeManager.tasbihRing;
    final center = size.center(Offset.zero);
    for (var i = 0; i < _particles; i++) {
      final angle = 2 * math.pi * i / _particles - math.pi / 2;
      canvas.drawCircle(
        center + Offset.fromDirection(angle, SizeManager.burstReach * scale * t),
        SizeManager.burstParticle * scale / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress || old.color != color;
}
