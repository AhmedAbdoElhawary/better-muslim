import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// elapsed, bar and total. a timeline, so it reads left to right in arabic too (FR-033)
class AdhanProgress extends ConsumerWidget {
  const AdhanProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(playbackProvider.select((playback) => playback.value?.position));
    final duration = ref.watch(playbackProvider.select((playback) => playback.value?.duration));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final total = duration ?? Duration.zero;
    final elapsed = position ?? Duration.zero;
    final fraction = total == Duration.zero
        ? 0.0
        : (elapsed.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    String clock(Duration value) => context.formatDigits(
      '${value.inMinutes}:${(value.inSeconds % 60).toString().padLeft(2, '0')}',
      digits,
    );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: RSizedBox(
        width: SizeManager.adhanProgress,
        child: Row(
          children: [
            RegularText(
              clock(elapsed),
              translate: false,
              fontSize: FontSizeManager.label,
              color: null,
              tabularFigures: true,
            ),
            const RSizedBox.horizontal(SpaceManager.adhanProgressGap),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(RadiusManager.adhanBar.r),
                child: RSizedBox(
                  height: SizeManager.adhanBar,
                  child: ColoredBox(
                    color: AdhanColors.track,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: fraction,
                      child: const ColoredBox(color: AdhanColors.fill),
                    ),
                  ),
                ),
              ),
            ),
            const RSizedBox.horizontal(SpaceManager.adhanProgressGap),
            RegularText(
              clock(total),
              translate: false,
              fontSize: FontSizeManager.label,
              color: null,
              tabularFigures: true,
            ),
          ],
        ),
      ),
    );
  }
}
