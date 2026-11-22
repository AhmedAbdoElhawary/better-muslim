import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// css "radial-gradient(ellipse ...)": stretches the circle on the short side into the box's
/// ellipse. home's card glow and the prayer header use it
class EllipseTransform extends GradientTransform {
  const EllipseTransform();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = bounds.center;
    final aspect = bounds.width / bounds.height;
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(math.max(aspect, 1), math.max(1 / aspect, 1), 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}
