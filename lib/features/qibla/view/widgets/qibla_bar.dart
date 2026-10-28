import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/sheet/location_sheet.dart';
import 'package:better_muslim/core/widgets/title_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the tree's 56 pt bar with no surface and no border, the gear opens the location sheet
class QiblaBar extends StatelessWidget {
  const QiblaBar({super.key});

  @override
  Widget build(BuildContext context) {
    return const RSizedBox(
      height: SizeManager.appBar,
      child: HorizontalPadding(
        padding: SpaceManager.s2,
        child: Row(
          children: [
            BarBackButton(),
            Expanded(
              child: Center(
                child: TitleHero(
                  tag: Routes.qibla,
                  child: SemiBoldText(
                    StringsManager.qibla,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            _Gear(),
          ],
        ),
      ),
    );
  }
}

class _Gear extends StatelessWidget {
  const _Gear();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.tr(StringsManager.location),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showLocationSheet(context),
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: BmIcon(
              BmIconName.settings,
              size: SizeManager.icon.r,
              color: context.getColor(ThemeEnum.text),
            ),
          ),
        ),
      ),
    );
  }
}
