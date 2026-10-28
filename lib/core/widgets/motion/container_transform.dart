import 'package:animations/animations.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// a card grows into the screen it opens and shrinks back on close (11 Motion v2). reduce motion
/// is a plain 150 ms crossfade
class BmContainerTransform extends StatelessWidget {
  const BmContainerTransform({
    required this.closedBuilder,
    required this.openBuilder,
    this.radius = RadiusManager.lg,
    this.closedColor = ThemeEnum.surface,
    super.key,
  });

  /// open is the tap that starts it
  final Widget Function(BuildContext context, VoidCallback open) closedBuilder;
  final WidgetBuilder openBuilder;
  final double radius;
  final ThemeEnum closedColor;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return closedBuilder(
        context,
        () => Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder<void>(
            transitionDuration: BmMotion.micro,
            reverseTransitionDuration: BmMotion.micro,
            pageBuilder: (context, _, _) => openBuilder(context),
            transitionsBuilder: (context, animation, _, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        ),
      );
    }

    /// root navigator, so the opened screen covers the tab bar like every pushed screen
    return OpenContainer<void>(
      useRootNavigator: true,
      transitionDuration: BmMotion.containerOpen,
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      openElevation: 0,
      closedColor: context.getColor(closedColor),
      openColor: context.getColor(ThemeEnum.bg),
      middleColor: context.getColor(ThemeEnum.bg),
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius.r)),
      openShape: const RoundedRectangleBorder(),
      closedBuilder: closedBuilder,
      openBuilder: (context, _) => openBuilder(context),
    );
  }
}
