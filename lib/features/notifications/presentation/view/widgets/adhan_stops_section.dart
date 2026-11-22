import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/bm_switcher.dart';
import 'package:better_muslim/core/widgets/grouped_section.dart';
import 'package:better_muslim/core/widgets/nav_row.dart';
import 'package:better_muslim/core/widgets/toggle_row.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/presentation/view/widgets/silent_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// flip, buttons and silent during prayer, android only: ios plays the adhan as the
/// notification's own sound and lets no app touch do not disturb
class AdhanStopsSection extends StatelessWidget {
  const AdhanStopsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const GroupedSection(
      label: StringsManager.whileAdhanPlays,
      children: [_FlipRow(), _ButtonsRow(), _SilentRow()],
    );
  }
}

class _FlipRow extends ConsumerWidget {
  const _FlipRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      settingsProvider.select((settings) => settings.value?.adhanFlipStops ?? true),
    );
    return ToggleRow(
      title: StringsManager.flipStopsAdhan,
      subtitle: StringsManager.flipStopsAdhanSub,
      value: on,
      onChanged: (value) => ref
          .read(databaseProvider)
          .updateSettings(SettingsCompanion(adhanFlipStops: Value(value))),
    );
  }
}

class _ButtonsRow extends ConsumerWidget {
  const _ButtonsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final on = ref.watch(
      settingsProvider.select((settings) => settings.value?.adhanButtonsStop ?? true),
    );
    return ToggleRow(
      title: StringsManager.buttonsStopAdhan,
      subtitle: StringsManager.buttonsStopAdhanSub,
      value: on,
      onChanged: (value) => ref
          .read(databaseProvider)
          .updateSettings(SettingsCompanion(adhanButtonsStop: Value(value))),
    );
  }
}

/// turning it on without do not disturb access opens the phone's page for it, it turns on when
/// the app comes back with the access
class _SilentRow extends ConsumerStatefulWidget {
  const _SilentRow();

  @override
  ConsumerState<_SilentRow> createState() => _SilentRowState();
}

class _SilentRowState extends ConsumerState<_SilentRow> {
  late final AppLifecycleListener _lifecycle;
  var _asked = false;

  /// only turning it on scrolls, not opening the page with it on
  var _reveal = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _check);
    ref.listenManual(settingsProvider.select((settings) => settings.value?.prayerSilent ?? false), (
      _,
      on,
    ) {
      if (on && _reveal) _scroll();
      _reveal = false;
    });
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final can = await ref.read(adhanChannelProvider).canSilence();
    final on = ref.read(settingsProvider).value?.prayerSilent ?? false;

    /// taken back in the phone's settings, the switch shows it
    if (_asked && can || on && !can) _save(can);
    _asked = false;
  }

  void _save(bool on) {
    _reveal = on;
    ref.read(databaseProvider).updateSettings(SettingsCompanion(prayerSilent: Value(on)));
  }

  /// after silent for has grown in, before that the row's bottom isn't known
  Future<void> _scroll() async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (!reduce) await Future<void>.delayed(BmMotion.standard);
    if (!mounted) return;
    await Scrollable.ensureVisible(
      context,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      duration: reduce ? Duration.zero : BmMotion.standard,
      curve: BmMotion.standardCurve,
    );
  }

  Future<void> _turn(bool on) async {
    final channel = ref.read(adhanChannelProvider);
    if (!on || await channel.canSilence()) return _save(on);
    _asked = true;
    await channel.openSilenceAccess();
  }

  @override
  Widget build(BuildContext context) {
    final (on, minutes) = ref.watch(
      settingsProvider.select(
        (settings) =>
            (settings.value?.prayerSilent ?? false, settings.value?.prayerSilentMinutes ?? 20),
      ),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );

    /// in the same section child, so the row can grow in with its divider
    return Column(
      children: [
        ToggleRow(
          title: StringsManager.silentDuringPrayer,
          subtitle: StringsManager.silentDuringPrayerSub,
          value: on,
          onChanged: _turn,
        ),
        BmSwitcher(
          child: on
              ? Column(
                  children: [
                    Divider(
                      height: SizeManager.divider,
                      thickness: SizeManager.divider,
                      color: context.getColor(ThemeEnum.outline),
                    ),
                    NavRow(
                      title: StringsManager.silentFor,
                      value: StringsManager.reminderValue,
                      args: {'minutes': context.formatDigits('$minutes', digits)},
                      onTap: () => showSilentSheet(context),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
