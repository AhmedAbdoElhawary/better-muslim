import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// scales sizes from the phone design, capped so tablets and foldables don't get giant ui
class AppScreenUtilInit extends StatelessWidget {
  const AppScreenUtilInit({required this.child, super.key});
  final Widget child;

  static const double _designWidth = 393;
  static const double _maxScale = 1.3;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);

    /// android can give an empty size on the first frame, dividing by it breaks every size
    if (screen.isEmpty) return const SizedBox.shrink();
    final scale = min(screen.shortestSide / _designWidth, _maxScale);
    return ScreenUtilInit(designSize: screen / scale, child: child);
  }
}
