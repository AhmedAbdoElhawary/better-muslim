import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the prayer's adhan, tone or silent, a tap moves to the next one (the adhan page's segments)
class SoundButton extends ConsumerWidget {
  const SoundButton(this.prayer, {super.key});
  final Prayer prayer;

  void _next(BuildContext context, WidgetRef ref, PrayerSound sound) {
    final next = PrayerSound.values[(sound.index + 1) % PrayerSound.values.length];
    ref.read(databaseProvider).updateSettings(soundChoice(prayer, next));
    BmHaptics.selection();
    showToast(
      context,
      StringsManager.prayerSound,
      args: {'prayer': context.tr(prayer.nameKey), 'sound': context.tr(next.nameKey)},
      icon: BmIconName.adhan,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sound = ref.watch(
      settingsProvider.select((settings) => settings.value?.soundOf(prayer) ?? PrayerSound.tone),
    );
    final size = SizeManager.iconList.r;
    final color = context.getColor(ThemeEnum.text2);
    final label = context.tr(StringsManager.prayerSound, {
      'prayer': context.tr(prayer.nameKey),
      'sound': context.tr(sound.nameKey),
    });

    /// an action, not a button: a second tap inside the row's merge would split R13's one node
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: label): () => _next(context, ref, sound),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () => _next(context, ref, sound),
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: AnimatedSwitcher(
              duration: BmMotion.micro,
              child: KeyedSubtree(
                key: ValueKey(sound),
                child: switch (sound) {
                  PrayerSound.adhan => BmIcon(BmIconName.adhan, size: size, color: color),
                  PrayerSound.tone => BmIcon.ui(BmUiIcon.sound, size: size, color: color),
                  PrayerSound.silent => BmIcon.ui(BmUiIcon.bell_off, size: size, color: color),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
