import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// MOTION 11: one bead step per tap on a spring, a tap during the spring retargets it from where
/// it is. never mirrored in arabic
class BeadStrip extends StatefulWidget {
  const BeadStrip({required this.taps, super.key});

  /// taps since the page opened, each new one is a step
  final int taps;

  @override
  State<BeadStrip> createState() => _BeadStripState();
}

class _BeadStripState extends State<BeadStrip> with SingleTickerProviderStateMixin {
  /// the strip's offset in design points, the beads repeat every step so it never runs out
  late final _offset = AnimationController.unbounded(vsync: this);

  /// a quarter point, or a third of one a frame, can't be seen. the default keeps it going past 400 ms
  static const _rest = Tolerance(distance: .25, velocity: 20);
  double _target = 0;

  @override
  void didUpdateWidget(BeadStrip old) {
    super.didUpdateWidget(old);
    if (widget.taps <= old.taps || MediaQuery.disableAnimationsOf(context)) return;
    const step = BmMotion.beadStep;
    final velocity = _offset.velocity;
    var value = _offset.value;

    /// the beads repeat every step, so a backlog of whole steps goes without a visible jump
    final behind = value - _target;
    if (behind > step) value -= step * (behind ~/ step);
    _target -= step;
    _offset.animateWith(
      SpringSimulation(BmMotion.snappy, value, _target, velocity, tolerance: _rest),
    );
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: RSizedBox(
        height: SizeManager.beadFocus,
        width: double.infinity,
        child: CustomPaint(
          painter: _BeadPainter(
            offset: _offset,
            bead: Color.lerp(
              context.getColor(ThemeEnum.raised),
              context.getColor(ThemeEnum.primary),
              .45,
            )!,
            raised: context.getColor(ThemeEnum.raised),
            line: context.getColor(ThemeEnum.outlineStrong),
            focus: context.getColor(ThemeEnum.primary),
          ),
        ),
      ),
    );
  }
}

class _BeadPainter extends CustomPainter {
  _BeadPainter({
    required this.offset,
    required this.bead,
    required this.raised,
    required this.line,
    required this.focus,
  }) : super(repaint: offset);

  final Animation<double> offset;
  final Color bead;
  final Color raised;
  final Color line;
  final Color focus;

  @override
  void paint(Canvas canvas, Size size) {
    /// the box is the focus ring's height, everything else is in the tree's points from it
    final scale = size.height / SizeManager.beadFocus;
    final center = size.center(Offset.zero);
    final step = BmMotion.beadStep * scale;
    final radius = SizeManager.bead * scale / 2;
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      Paint()
        ..color = line
        ..strokeWidth = SizeManager.beadLine * scale,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = SizeManager.beadLine * scale
      ..color = line;
    final shift = offset.value * scale % step;
    final count = (size.width / 2 / step).ceil() + 1;
    for (var i = -count; i <= count; i++) {
      final at = Offset(center.dx + i * step + shift, center.dy);
      final rect = Rect.fromCircle(center: at, radius: radius);

      /// css radial-gradient(circle at 35% 30%), out to the farthest corner
      final shader = RadialGradient(
        center: const Alignment(-.3, -.4),
        radius: .96,
        colors: [bead, raised],
      ).createShader(rect);
      canvas
        ..drawCircle(at, radius, Paint()..shader = shader)
        ..drawCircle(at, radius + ring.strokeWidth / 2, ring);
    }
    canvas.drawCircle(
      center,
      SizeManager.beadFocus * scale / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = SizeManager.beadFocusStroke * scale
        ..color = focus,
    );
  }

  @override
  bool shouldRepaint(_BeadPainter old) =>
      old.offset != offset ||
      old.bead != bead ||
      old.raised != raised ||
      old.line != line ||
      old.focus != focus;
}
