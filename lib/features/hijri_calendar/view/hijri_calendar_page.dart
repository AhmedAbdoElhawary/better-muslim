import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/calendar_title.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/day_details.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/month_grid.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/month_header.dart';
import 'package:better_muslim/features/hijri_calendar/view/widgets/picker_grid.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:flutter/gestures.dart' show kMinFlingVelocity;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 4.13: one scroll view, so a six row month pushes the rest down instead of squeezing (FR-017)
class HijriCalendarPage extends StatelessWidget {
  const HijriCalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TitleGlow(
        child: Column(
          children: [
            const CompactAppBar(
              StringsManager.hijriCalendar,
              titleChild: CalendarTitle(),
              action: _TodayButton(),
            ),
            Expanded(
              child: ListView(
                padding: REdgeInsets.only(bottom: SpaceManager.s6),
                children: const [
                  RSizedBox.vertical(SpaceManager.monthHeaderTop),
                  HorizontalPadding(padding: SpaceManager.screen, child: MonthHeader()),
                  RSizedBox.vertical(SpaceManager.gridTop),
                  HorizontalPadding(padding: SpaceManager.gridSide, child: _GridArea()),
                  RSizedBox.vertical(SpaceManager.comingUpTop),
                  HorizontalPadding(padding: SpaceManager.screen, child: DayDetails()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// the days, months or years. zooming out the new view comes from near and the old one goes far,
/// zooming in the reverse (FR-007). a flick pages like the header's arrows
class _GridArea extends ConsumerStatefulWidget {
  const _GridArea();

  @override
  ConsumerState<_GridArea> createState() => _GridAreaState();
}

class _GridAreaState extends ConsumerState<_GridArea> {
  static const _rest = 1.0;

  var _view = CalendarView.days;
  var _out = true;

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(calendarPageProvider.select((page) => page.view));
    if (view != _view) {
      _out = view.index > _view.index;
      _view = view;
    }
    final reduce = MediaQuery.disableAnimationsOf(context);
    final switcher = AnimatedSwitcher(
      duration: reduce ? BmMotion.micro : BmMotion.standard,
      switchInCurve: BmMotion.standardCurve,
      switchOutCurve: BmMotion.standardCurve,
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        final fade = FadeTransition(opacity: animation, child: child);
        if (reduce) return fade;
        final incoming = child.key == ValueKey(view);
        return ScaleTransition(
          scale: Tween(
            begin: incoming == _out ? BmMotion.zoomNear : BmMotion.zoomFar,
            end: _rest,
          ).animate(animation),
          child: fade,
        );
      },
      child: switch (view) {
        CalendarView.days => MonthGrid(key: ValueKey(view)),
        CalendarView.months => PickerGrid(years: false, key: ValueKey(view)),
        CalendarView.years => PickerGrid(years: true, key: ValueKey(view)),
      },
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: _onFlick,
      child: switcher,
    );
  }

  void _onFlick(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < kMinFlingVelocity) return;

    /// the next month waits on the end side, so arabic flicks the other way
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final pager = ref.read(calendarPageProvider.notifier);
    final forward = isRtl ? velocity > 0 : velocity < 0;
    if (forward ? !pager.canGoForward : !pager.canGoBack) return;
    BmHaptics.selection();
    forward ? pager.forward() : pager.back();
  }
}

class _TodayButton extends ConsumerWidget {
  const _TodayButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(todayEnabledProvider);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: context.tr(StringsManager.today),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () {
                BmHaptics.selection();
                ref.read(calendarPageProvider.notifier).today();
                ref.read(selectedDayProvider.notifier).select(ref.read(todayProvider));
              }
            : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: SizeManager.hit.r, minHeight: SizeManager.hit.r),
          child: Center(
            widthFactor: 1,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : BmOpacity.disabled,
              duration: reduce ? Duration.zero : BmMotion.micro,
              child: const MediumText(StringsManager.today, color: ThemeEnum.accent),
            ),
          ),
        ),
      ),
    );
  }
}
