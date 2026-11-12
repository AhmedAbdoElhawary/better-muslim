import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_log/prayer_log.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/features/prayer/presentation/providers/qada.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/progress_ring.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// always the prayer day, whatever day is shown (FR-014). it opens the qada list
class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(prayerDayProvider);
    final count = ref.watch(prayedProvider(today).select((prayed) => prayed.length));
    final missed = ref.watch(qadaMonthCountProvider(today).select((count) => count.value ?? 0));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SymmetricPadding(
      horizontal: SpaceManager.screen,
      child: TopPadding(
        padding: SpaceManager.summaryTop,
        child: Semantics(
          button: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => context.push(Routes.qada),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.surface),
                borderRadius: BorderRadius.circular(RadiusManager.lg.r),
                border: Border.all(color: context.getColor(ThemeEnum.outline)),
              ),
              child: SymmetricPadding(
                horizontal: SpaceManager.s4,
                vertical: SpaceManager.summaryPaddingV,
                child: Row(
                  children: [
                    ExcludeSemantics(child: ProgressRing(count)),
                    const RSizedBox.horizontal(SpaceManager.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BmSwitcher(
                            child: MediumText(
                              StringsManager.prayedToday,
                              key: ValueKey(count),
                              args: {'count': context.formatDigits('$count', digits)},
                            ),
                          ),
                          const RSizedBox.vertical(SpaceManager.rowLineGap),
                          BmSwitcher(
                            child: missed == 0
                                ? const RegularText(
                                    StringsManager.nothingToMakeUp,
                                    key: ValueKey(0),
                                    color: ThemeEnum.text2,
                                  )
                                : RegularText(
                                    StringsManager.missedToMakeUp,
                                    key: ValueKey(missed),
                                    args: {'count': context.formatDigits('$missed', digits)},
                                    color: ThemeEnum.text2,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Transform.flip(
                      flipX: isRtl,
                      child: BmIcon.ui(
                        BmUiIcon.forward,
                        size: SizeManager.iconChevron.r,
                        color: context.getColor(ThemeEnum.text3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
