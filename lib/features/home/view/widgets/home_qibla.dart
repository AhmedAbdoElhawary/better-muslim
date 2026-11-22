import 'dart:math' as math;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/qibla/qibla_math.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// the small qibla dial above the countdown. the compass runs only while Home shows the card
class HomeQibla extends StatelessWidget {
  const HomeQibla({this.flying, super.key});

  /// true once the card has gone under the Home bar
  final ValueListenable<bool>? flying;

  @override
  Widget build(BuildContext context) {
    if (!TickerMode.valuesOf(context).enabled) return const SizedBox.shrink();
    final flying = this.flying;
    if (flying == null) return const _Dial();
    return ValueListenableBuilder(
      valueListenable: flying,
      builder: (context, flying, _) => flying ? const SizedBox.shrink() : const _Dial(),
    );
  }
}

class _Dial extends ConsumerWidget {
  const _Dial();

  /// the icon's needle points this far right of up
  static const _needle = 45;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turn = ref.watch(homeQiblaProvider);
    if (turn == null) return const SizedBox.shrink();
    final aligned = turn.abs() <= qiblaAlignedWithin;
    return Semantics(
      button: true,
      label: context.tr(StringsManager.qibla),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.qibla),
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: Transform.rotate(
              angle: (turn - _needle) * math.pi / 180,
              child: AnimatedSwitcher(
                duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : BmMotion.micro,
                child: KeyedSubtree(
                  key: ValueKey(aligned),
                  child: BmIcon(
                    BmIconName.qibla,
                    filled: aligned,
                    size: SizeManager.homeQibla.r,
                    color: context.getColor(aligned ? ThemeEnum.accent : ThemeEnum.text2),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
