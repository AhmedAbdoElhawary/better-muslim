import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/title_hero.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// qibla, the hijri calendar and duas, visited less often than the tabs (4.09)
class MoreTiles extends StatelessWidget {
  const MoreTiles({super.key});

  @override
  Widget build(BuildContext context) {
    return const IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Tile(icon: BmUiIcon.compass, label: StringsManager.qibla, route: Routes.qibla),
          ),
          RSizedBox.horizontal(SpaceManager.tileGap),
          Expanded(
            child: _Tile(
              icon: BmUiIcon.calendar,
              label: StringsManager.calendar,
              route: Routes.hijriCalendar,
            ),
          ),
          RSizedBox.horizontal(SpaceManager.tileGap),
          Expanded(
            child: _Tile(icon: BmUiIcon.dua, label: StringsManager.duas, route: Routes.duas),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.route});
  final BmUiIcon icon;

  /// a StringsManager key
  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(route),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.tile.r),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.getColor(ThemeEnum.surface),
              borderRadius: BorderRadius.circular(RadiusManager.lg.r),
              boxShadow: [BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1)],
            ),
            child: AllPadding(
              padding: SpaceManager.tilePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RSizedBox.square(
                    dimension: SizeManager.tileIconBox,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.getColor(ThemeEnum.primaryContainer),
                        borderRadius: BorderRadius.circular(RadiusManager.tileIcon.r),
                      ),
                      child: Center(
                        child: BmIcon.ui(
                          icon,
                          size: SizeManager.iconList.r,
                          color: context.getColor(ThemeEnum.onPrimaryContainer),
                        ),
                      ),
                    ),
                  ),
                  const RSizedBox.vertical(SpaceManager.tileGap),
                  TitleHero(
                    tag: route,
                    child: MediumText(label, fontSize: FontSizeManager.secondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
