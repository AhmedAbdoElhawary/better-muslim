import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// K.STAR of _gen/kit.js, its 16 points in a 22 wide box
Path mushafStar(Offset center, double size) {
  const points = [
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
  final unit = size / 22;
  return Path()
    ..addPolygon([for (final (x, y) in points) center + Offset(x * unit, y * unit)], true);
}

/// the outlined star behind a number, 4.18's surah rows
class MushafStar extends StatelessWidget {
  const MushafStar({required this.child, this.color = ThemeEnum.primary, super.key});

  final Widget child;
  final ThemeEnum color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StarPainter(context.getColor(color), SizeManager.surahStarGlyph.r),
      child: RSizedBox.square(
        dimension: SizeManager.surahStar,
        child: Center(child: child),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color, this.size);

  final Color color;
  final double size;

  @override
  void paint(Canvas canvas, Size box) {
    canvas.drawPath(
      mushafStar(box.center(Offset.zero), size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = SizeManager.starStroke.r
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.color != color || old.size != size;
}
