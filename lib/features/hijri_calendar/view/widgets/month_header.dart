import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the arrows, "Jumada I 1448" and the gregorian months it spans
class MonthHeader extends ConsumerWidget {
  const MonthHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(shownMonthProvider);
    final adjust = ref.watch(hijriAdjustProvider);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final days = month.days(adjust);
    final shown = ref.read(shownMonthProvider.notifier);
    return Row(
      children: [
        _Arrow(
          icon: BmUiIcon.back,
          label: StringsManager.previousMonth,
          onTap: month.canGoBack ? shown.back : null,
        ),
        Expanded(
          child: Column(
            children: [
              RegularText(
                context.formatDigits('${context.tr(month.monthKey)} ${month.year}', digits),
                translate: false,
                font: FontEnum.display,
                fontSize: FontSizeManager.monthTitle,
                textAlign: TextAlign.center,
              ),
              const RSizedBox.vertical(SpaceManager.monthNameGap),
              RegularText(
                context.monthSpan(days.first, days.last, digits),
                translate: false,
                fontSize: FontSizeManager.cardNote,
                color: ThemeEnum.text2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        _Arrow(
          icon: BmUiIcon.forward,
          label: StringsManager.nextMonth,
          onTap: month.canGoForward ? shown.forward : null,
        ),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});
  final BmUiIcon icon;

  /// a StringsManager key for screen readers
  final String label;

  /// null at the ends of the table
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: context.tr(label),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: Opacity(
              opacity: onTap == null ? BmOpacity.disabled : 1,
              child: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: BmIcon.ui(
                  icon,
                  size: SizeManager.icon.r,
                  color: context.getColor(ThemeEnum.text),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
