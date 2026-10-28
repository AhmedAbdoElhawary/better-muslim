import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/system/system_channel.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' offline toast as a line on the page, the choices still save (FR-030)
class NotificationsOffLine extends ConsumerWidget {
  const NotificationsOffLine({super.key});

  /// ios has no switch for an app that never asked, so the first tap asks like 4.12 (FR-026)
  Future<void> _open(WidgetRef ref) async {
    if (ref.read(settingsProvider).value?.notificationsAsked ?? false) {
      return SystemChannel.openNotificationSettings();
    }
    final scheduler = ref.read(notificationSchedulerProvider);
    if (await scheduler.askPermission()) await scheduler.askExactAlarms();
    await ref
        .read(databaseProvider)
        .updateSettings(const SettingsCompanion(notificationsAsked: Value(true)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  onTap: () => _open(ref),
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
