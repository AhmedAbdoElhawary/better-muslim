import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the components' empty state: the octagon, a title, and a line under it when there is one
class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, this.body, super.key});

  /// StringsManager keys
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final body = this.body;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.raised),
        borderRadius: BorderRadius.circular(RadiusManager.lg.r),
        boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
      ),
      child: SymmetricPadding(
        vertical: SpaceManager.zikrCardV + SpaceManager.s3,
        horizontal: SpaceManager.s5,
        child: Column(
          children: [
            RSizedBox.square(
              dimension: SizeManager.emptyIcon,
              child: CustomPaint(
                painter: _Octagon(
                  color: context.getColor(ThemeEnum.primary),
                  stroke: SizeManager.emptyIconStroke.r,
                ),
              ),
            ),
            const RSizedBox.vertical(SpaceManager.s2),
            MediumText(title, textAlign: TextAlign.center),
            if (body != null) ...[
              const RSizedBox.vertical(SpaceManager.s2),
              RegularText(
                body,
                color: ThemeEnum.text2,
                height: LineHeightManager.body,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// the 8 point star of the components' empty state, in its 100 box
class _Octagon extends CustomPainter {
  const _Octagon({required this.color, required this.stroke});
  final Color color;
  final double stroke;

  static const _points = [
    (50.0, 8.0),
    (62.3, 20.3),
    (79.7, 20.3),
    (79.7, 37.7),
    (92.0, 50.0),
    (79.7, 62.3),
    (79.7, 79.7),
    (62.3, 79.7),
    (50.0, 92.0),
    (37.7, 79.7),
    (20.3, 79.7),
    (20.3, 62.3),
    (8.0, 50.0),
    (20.3, 37.7),
    (20.3, 20.3),
    (37.7, 20.3),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    final path = Path()..addPolygon([for (final (x, y) in _points) Offset(x, y) * scale], true);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_Octagon old) => old.color != color || old.stroke != stroke;
}
