import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/title_hero.dart';
import 'package:better_muslim/features/hijri_calendar/view_model/calendar_providers.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the bar's title switches hijri and gregorian, the chevron says it can be tapped (FR-001)
class CalendarTitle extends ConsumerWidget {
  const CalendarTitle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(calendarModeProvider);
    final title = mode == CalendarMode.hijri
        ? StringsManager.hijriCalendar
        : StringsManager.gregorianCalendar;
    return Center(
      child: Semantics(
        button: true,
        label: context.tr(title),
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            BmHaptics.selection();
            ref
                .read(databaseProvider)
                .updateSettings(
                  SettingsCompanion(
                    calendarMode: Value(
                      mode == CalendarMode.hijri ? CalendarMode.gregorian : CalendarMode.hijri,
                    ),
                  ),
                );
          },
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: SizeManager.hit.r),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: TitleHero(
                    tag: Routes.hijriCalendar,
                    child: BmSwitcher(
                      child: SemiBoldText(title, key: ValueKey(title), maxLines: 1),
                    ),
                  ),
                ),
                const RSizedBox.horizontal(SpaceManager.s1),
                RotatedBox(
                  quarterTurns: 1,
                  child: BmIcon.ui(
                    BmUiIcon.forward,
                    size: SizeManager.iconChevron.r,
                    color: context.getColor(ThemeEnum.text2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
