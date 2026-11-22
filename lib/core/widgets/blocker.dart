import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/motion/star_loader.dart';
import 'package:material_ui/material_ui.dart';

/// runs [task] under the star loader. a route on the root navigator, so the sheet, the tab bar
/// and the back gesture all wait for it
Future<T> whileBlocked<T>(BuildContext context, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = RawDialogRoute<void>(
    barrierDismissible: false,
    barrierColor: null,
    transitionDuration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : BmMotion.micro,
    pageBuilder: (_, _, _) => const PopScope(canPop: false, child: _Blocker()),
    transitionBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
  );
  unawaited(navigator.push(route));
  try {
    return await task();
  } finally {
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      navigator.removeRoute(route);
    }
  }
}

class _Blocker extends StatelessWidget {
  const _Blocker();

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: BmGlass.blurSigma, sigmaY: BmGlass.blurSigma),
      child: ColoredBox(
        color: context.getColor(ThemeEnum.scrim).withValues(alpha: BmOpacity.pressed),
        child: const Center(child: BmStarLoader()),
      ),
    );
  }
}
