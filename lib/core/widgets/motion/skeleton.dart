import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// a placeholder box with a light band sweeping across it, still with reduce motion
class BmSkeleton extends StatefulWidget {
  const BmSkeleton({required this.height, this.width, this.radius = RadiusManager.sm, super.key});

  final double height;

  /// null fills the width
  final double? width;
  final double radius;

  @override
  State<BmSkeleton> createState() => _BmSkeletonState();
}

class _BmSkeletonState extends State<BmSkeleton> with SingleTickerProviderStateMixin {
  late final _shimmer = AnimationController(vsync: this, duration: BmMotion.shimmer);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.getColor(ThemeEnum.variant);
    final band = context.getColor(ThemeEnum.raised);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _shimmer,
          builder: (context, _) {
            /// the band runs from off the start edge to off the end edge
            final x = -2 + 4 * _shimmer.value;
            return Container(
              width: widget.width?.r,
              height: widget.height.r,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.radius.r),
                gradient: LinearGradient(
                  begin: AlignmentDirectional(x - 1, 0).resolve(Directionality.of(context)),
                  end: AlignmentDirectional(x + 1, 0).resolve(Directionality.of(context)),
                  colors: [base, band, base],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// skeleton to content in one 150 ms crossfade, the two stacked so nothing below jumps mid fade
class BmSkeletonSwitch extends StatelessWidget {
  const BmSkeletonSwitch({
    required this.loading,
    required this.skeleton,
    required this.child,
    super.key,
  });

  final bool loading;
  final Widget skeleton;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : BmMotion.micro,
      layoutBuilder: (current, previous) =>
          Stack(alignment: AlignmentDirectional.topStart, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(loading), child: loading ? skeleton : child),
    );
  }
}
