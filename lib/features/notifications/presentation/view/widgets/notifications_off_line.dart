import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' offline toast as a line on the page, the choices still save (FR-030)
class NotificationsOffLine extends StatelessWidget {
  const NotificationsOffLine({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.getColor(ThemeEnum.text),
        borderRadius: BorderRadius.circular(RadiusManager.md.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: SizeManager.toast.r),
        child: OnlyPadding(
          start: SpaceManager.s4,
          end: SpaceManager.s2,
          child: Row(
            children: [
              BmIcon.ui(
                BmUiIcon.bell_off,
                size: SizeManager.iconList.r,
                color: context.getColor(ThemeEnum.warning),
              ),
              const RSizedBox.horizontal(SpaceManager.s3),
              const Expanded(
                child: RegularText(
                  StringsManager.notificationsOff,
                  fontSize: FontSizeManager.secondary,
                  color: ThemeEnum.bg,
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: SystemChannel.openNotificationSettings,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: SizeManager.hit.r,
                      minWidth: SizeManager.hit.r,
                    ),
                    child: const HorizontalPadding(
                      padding: SpaceManager.s3,
                      child: Center(
                        widthFactor: 1,
                        child: SemiBoldText(
                          StringsManager.openSettings,
                          fontSize: FontSizeManager.secondary,
                          color: ThemeEnum.toastAction,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
