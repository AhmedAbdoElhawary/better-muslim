import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/features/prayer/presentation/providers/qada.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/qada_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// no PNG: only the components' compact bar and grouped rows (FR-022)
class QadaPage extends ConsumerWidget {
  const QadaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(
      qadaOpenCountsProvider.select(
        (counts) => counts.value?.values.fold(0, (sum, count) => sum + count) ?? 0,
      ),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return Scaffold(
      body: Column(
        children: [
          const CompactAppBar(StringsManager.qadaList),
          Expanded(
            child: ListView(
              padding: REdgeInsets.all(SpaceManager.screen),
              children: [
                HorizontalPadding(
                  padding: SpaceManager.s4,
                  child: MediumText(
                    StringsManager.qadaTotal,
                    args: {'count': context.formatDigits('$total', digits)},
                  ),
                ),
                const RSizedBox.vertical(SpaceManager.s3),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.getColor(ThemeEnum.surface),
                    borderRadius: BorderRadius.circular(RadiusManager.lg.r),
                    border: Border.all(color: context.getColor(ThemeEnum.outline)),
                  ),
                  child: Column(
                    children: [
                      for (final prayer in Prayer.values)
                        QadaRow(prayer, divider: prayer != Prayer.isha),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
