import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/hijri/hijri_date.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/features/hijri_calendar/model/calendar_month.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_format.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the arrows and what the grid area shows: the month and the other calendar's months it spans,
/// the year, or the 12 years. the title steps to the next view (FR-007)
class MonthHeader extends ConsumerWidget {
  const MonthHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(calendarPageProvider);
    final adjust = ref.watch(hijriAdjustProvider);
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final pager = ref.read(calendarPageProvider.notifier);
    final month = page.month;
    final days = month.days(adjust);
    final start = pager.pageStart(month.year);
    final title = switch (page.view) {
      CalendarView.days => switch (month) {
        HijriMonth() => context.formatDigits('${context.tr(month.monthKey)} ${month.year}', digits),
        GregorianMonth() => context.gregorianMonth(month.year, month.month, digits),
      },
      CalendarView.months => context.formatDigits('${month.year}', digits),
      CalendarView.years => context.formatDigits(
        context.tr(StringsManager.yearSpan, {
          'first': '$start',
          'last': '${start + yearsPerPage - 1}',
        }),
        digits,
      ),
    };
    final span = page.view != CalendarView.days
        ? null
        : switch (month) {
            HijriMonth() => context.monthSpan(days.first, days.last, digits),
            GregorianMonth() => context.hijriSpan(
              HijriDate.of(days.first, adjust),
              HijriDate.of(days.last, adjust),
              digits,
            ),
          };
    final (back, forward) = switch (page.view) {
      CalendarView.days => (StringsManager.previousMonth, StringsManager.nextMonth),
      CalendarView.months => (StringsManager.previousYear, StringsManager.nextYear),
      CalendarView.years => (StringsManager.previousYears, StringsManager.nextYears),
    };
    return Row(
      children: [
        _Arrow(icon: BmUiIcon.back, label: back, onTap: pager.canGoBack ? pager.back : null),
        Expanded(
          child: Semantics(
            button: true,
            label: context.tr(switch (page.view) {
              CalendarView.days => StringsManager.showMonths,
              CalendarView.months => StringsManager.showYears,
              CalendarView.years => StringsManager.showDays,
            }),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                BmHaptics.selection();
                pager.zoomOut();
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: SizeManager.hit.r),
                child: BmSwitcher(
                  child: Column(
                    key: ValueKey((title, span)),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RegularText(
                        title,
                        translate: false,
                        font: FontEnum.display,
                        fontSize: FontSizeManager.monthTitle,
                        textAlign: TextAlign.center,
                      ),
                      if (span != null) ...[
                        const RSizedBox.vertical(SpaceManager.monthNameGap),
                        RegularText(
                          span,
                          translate: false,
                          fontSize: FontSizeManager.cardNote,
                          color: ThemeEnum.text2,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _Arrow(
          icon: BmUiIcon.forward,
          label: forward,
          onTap: pager.canGoForward ? pager.forward : null,
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
    final reduce = MediaQuery.disableAnimationsOf(context);
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
            child: AnimatedOpacity(
              opacity: onTap == null ? BmOpacity.disabled : 1,
              duration: reduce ? Duration.zero : BmMotion.micro,
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
