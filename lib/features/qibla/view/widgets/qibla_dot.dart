import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the dial's hub, the needle's head and the accuracy dot
class QiblaDot extends StatelessWidget {
  const QiblaDot({required this.size, required this.color, super.key});

  final double size;
  final ThemeEnum color;

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: context.getColor(color), shape: BoxShape.circle),
      ),
    );
  }
}
