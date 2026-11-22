import 'dart:math' as math;

import 'package:flutter/rendering.dart';

/// a track and an arc from 12 o'clock, the prayer summary and tasbih rings
class RingPainter extends CustomPainter {
  const RingPainter({
    required this.share,
    required this.track,
    required this.arc,
    required this.stroke,
  });

  final double share;
  final Color track;
  final Color arc;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    /// the stroke sits half inside the box
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawOval(circle, paint..color = track);
    if (share <= 0) return;
    canvas.drawArc(
      circle,
      -math.pi / 2,
      2 * math.pi * share,
      false,
      paint
        ..color = arc
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(RingPainter old) =>
      old.share != share || old.track != track || old.arc != arc || old.stroke != stroke;
}
