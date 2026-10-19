import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/compact_app_bar.dart';
import 'package:better_muslim/core/widgets/shortcut_row.dart';
import 'package:better_muslim/core/widgets/surface_card.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// no png, built from 4.01's shortcut rows and the components' toggle row
class AzkarPage extends StatelessWidget {
  const AzkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: LargeTitleScrollView(
        title: StringsManager.tabAzkar,
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          SliverToBoxAdapter(
            child: AllPadding(
              padding: SpaceManager.screen,
              child: Column(
                children: [
                  SurfaceCard(
                    child: Column(
                      children: [
                        _SetRow(AzkarSet.morning, icon: BmIconName.sunrise),
                        _SetRow(AzkarSet.evening, icon: BmIconName.night),
                        _TasbihRow(),
                      ],
                    ),
                  ),
                  RSizedBox.vertical(SpaceManager.s4),
                  SurfaceCard(child: _NudgesRow()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// the large title under the same empty button row as prayer's, so the tabs' titles line up
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return SafeArea(
      bottom: false,
      child: OnlyPadding(
        top: SpaceManager.s1 + SizeManager.hit,
        start: SpaceManager.s5,
        end: SpaceManager.s5,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: RegularText(
            StringsManager.tabAzkar,
            font: FontEnum.display,
            fontSize: isArabic ? FontSizeManager.titleAr : FontSizeManager.largeTitle,
            height: isArabic ? LineHeightManager.titleAr : LineHeightManager.largeTitle,
          ),
        ),
      ),
    );
  }
}

class _SetRow extends ConsumerWidget {
  const _SetRow(this.set, {required this.icon});
  final AzkarSet set;
  final BmIconName icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(azkarProgressProvider(set));
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return ShortcutRow(
      icon: icon,
      title: set.titleKey,
      subtitle: set.subtitleKey,
      args: {
        'done': context.formatDigits('${progress.done}', digits),
        'total': context.formatDigits('${progress.total}', digits),
      },
      divider: true,
      onTap: () => context.go(Routes.azkarSet(set)),
    );
  }
}

class _TasbihRow extends StatelessWidget {
  const _TasbihRow();

  @override
  Widget build(BuildContext context) {
    return ShortcutRow(
      icon: BmIconName.tasbih,
      title: StringsManager.tasbih,
      subtitle: StringsManager.afterPrayer,
      onTap: () => context.go(Routes.tasbih),
    );
  }
}

class _NudgesRow extends ConsumerWidget {
  const _NudgesRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      settingsProvider.select((settings) => settings.value?.azkarNudges ?? true),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return ToggleRow(
      title: StringsManager.azkarReminders,
      subtitle: StringsManager.azkarRemindersSub,
      args: {'minutes': context.formatDigits('${azkarNudgeDelay.inMinutes}', digits)},
      value: on,
      onChanged: (value) =>
          ref.read(databaseProvider).updateSettings(SettingsCompanion(azkarNudges: Value(value))),
    );
  }
}
