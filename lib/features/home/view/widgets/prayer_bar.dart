import 'package:better_muslim/core/prayer_times/next_prayer.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the share of the current period passed. a progress bar, so it is never mirrored
class PrayerBar extends ConsumerWidget {
  const PrayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final share = ref.watch(barShareProvider) ?? 0;
    final radius = BorderRadius.circular(RadiusManager.prayerBar.r);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RSizedBox(
        height: SizeManager.prayerBar,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.variant),
            borderRadius: radius,
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: share,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.primary),
                borderRadius: radius,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
