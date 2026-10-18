import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// surface, radius 20 and the outline ring every home card has
class HomeCard extends StatelessWidget {
  const HomeCard({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.surface),
        borderRadius: BorderRadius.circular(RadiusManager.lg.r),

        /// css box-shadow 0 0 0 1px draws the ring outside the box, a Border would draw inside
        boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
      ),
      child: child,
    );
  }
}
