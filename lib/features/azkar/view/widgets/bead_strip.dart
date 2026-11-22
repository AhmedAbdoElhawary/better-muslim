import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/features/azkar/view_model/tasbih_controller.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the markers after subhanallah's and alhamdulillah's 33, then the head bead (FR-030)
const _markers = {33, 67};
const _head = 101;

/// MOTION 11 on one finite string: the bead in focus slides to its place on a spring, a new place
/// during the spring retargets it from where it is. never mirrored in arabic
class BeadStrip extends ConsumerStatefulWidget {
  const BeadStrip({super.key});

  @override
  ConsumerState<BeadStrip> createState() => _BeadStripState();
}

class _BeadStripState extends ConsumerState<BeadStrip> with SingleTickerProviderStateMixin {
  /// the bead in focus, between beads while it moves
  late final _focus = AnimationController.unbounded(
    vsync: this,
    value: (ref.read(tasbihControllerProvider)?.position ?? -1).toDouble(),
  );

  /// a hundredth of a bead, or a third of a point a frame, can't be seen. the default keeps it
  /// going past 400 ms
  static const _rest = Tolerance(distance: .01, velocity: .5);

  void _moveTo(int? before, int? position) {
    if (position == null) return;
    if (before == null || MediaQuery.disableAnimationsOf(context)) {
      _focus.value = position.toDouble();
      return;
    }
    _focus
        .animateWith(
          SpringSimulation(
            BmMotion.snappy,
            _focus.value,
            position.toDouble(),
            _focus.velocity,
            tolerance: _rest,
          ),
        )
        /// the spring stops inside its tolerance, a hair before the bead
        .then((_) => _focus.value = position.toDouble());
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(tasbihControllerProvider.select((state) => state?.position), _moveTo);
    return RepaintBoundary(
      child: RSizedBox(
        height: SizeManager.beadHead,
        width: double.infinity,
        child: CustomPaint(
          painter: _BeadPainter(
            focus: _focus,
            bead: Color.lerp(
              context.getColor(ThemeEnum.raised),
              context.getColor(ThemeEnum.primary),
              .45,
            )!,
            raised: context.getColor(ThemeEnum.raised),
            line: context.getColor(ThemeEnum.outlineStrong),
            ring: context.getColor(ThemeEnum.primary),
            accent: context.getColor(ThemeEnum.accent),
          ),
        ),
      ),
    );
  }
}

class _BeadPainter extends CustomPainter {
  _BeadPainter({
    required this.focus,
    required this.bead,
    required this.raised,
    required this.line,
    required this.ring,
    required this.accent,
  }) : super(repaint: focus);

  final Animation<double> focus;
  final Color bead;
  final Color raised;
  final Color line;
  final Color ring;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    /// the box is the head bead's height, everything else is in the tree's points from it
    final scale = size.height / SizeManager.beadHead;
    final center = size.center(Offset.zero);
    final step = BmMotion.beadStep * scale;

    /// the spring may overshoot, the string still stops at its ends
    final at = focus.value.clamp(-1.0, _head.toDouble());
    double x(num index) => center.dx + (index - at) * step;
    final stroke = SizeManager.beadLine * scale;
    final tasselEnd = x(_head) + (SizeManager.beadHead / 2 + SizeManager.tassel) * scale;

    /// the free end shows a step before bead 0, the tassel hangs past the head bead
    canvas
      ..drawLine(
        Offset(x(-1), center.dy),
        Offset(x(_head), center.dy),
        Paint()
          ..color = line
          ..strokeWidth = stroke,
      )
      ..drawLine(
        Offset(x(_head), center.dy),
        Offset(tasselEnd, center.dy),
        Paint()
          ..color = accent
          ..strokeWidth = stroke * 3
          ..strokeCap = StrokeCap.round,
      );
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = line;
    final reach = (size.width / 2 / step).ceil() + 1;
    final first = (at - reach).floor().clamp(0, _head);
    final last = (at + reach).ceil().clamp(0, _head);
    for (var i = first; i <= last; i++) {
      final place = Offset(x(i), center.dy);
      final special = i == _head || _markers.contains(i);
      final diameter = i == _head
          ? SizeManager.beadHead
          : special
          ? SizeManager.beadMarker
          : SizeManager.bead;
      final radius = diameter * scale / 2;
      final rect = Rect.fromCircle(center: place, radius: radius);

      /// css radial-gradient(circle at 35% 30%), out to the farthest corner
      final shader = RadialGradient(
        center: const Alignment(-.3, -.4),
        radius: .96,
        colors: [if (special) accent else bead, raised],
      ).createShader(rect);
      canvas
        ..drawCircle(place, radius, Paint()..shader = shader)
        ..drawCircle(place, radius + stroke / 2, outline);
    }
    canvas.drawCircle(
      center,
      SizeManager.beadFocus * scale / 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = SizeManager.beadFocusStroke * scale
        ..color = ring,
    );
  }

  @override
  bool shouldRepaint(_BeadPainter old) =>
      old.focus != focus ||
      old.bead != bead ||
      old.raised != raised ||
      old.line != line ||
      old.ring != ring ||
      old.accent != accent;
}
