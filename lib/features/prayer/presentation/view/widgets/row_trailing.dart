import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_log/prayer_row_state.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:better_muslim/features/prayer/presentation/providers/prayer_actions.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_complete.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/mark_button.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/passed_sheet.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/state_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// what a row offers, from its state (FR-002)
class RowTrailing extends ConsumerWidget {
  const RowTrailing({required this.day, required this.prayer, required this.state, super.key});
  final DateTime day;
  final Prayer prayer;
  final PrayerRowState state;

  Future<void> _mark(BuildContext context, WidgetRef ref) async {
    final complete = await ref.read(prayerActionsProvider).mark(day, prayer);
    if (complete && context.mounted) showDayComplete(context);
  }

  Future<void> _unmark(BuildContext context, WidgetRef ref) async {
    final actions = ref.read(prayerActionsProvider);
    await actions.unmark(day, prayer);
    if (!context.mounted) return;

    /// the toast keeps its own day and prayer, so undo is right even after fajr moves the screen
    showToast(
      context,
      StringsManager.prayerUnmarked,
      args: {'prayer': context.tr(prayer.nameKey)},
      onUndo: () => actions.mark(day, prayer),
    );
  }

  Future<void> _leaveQada(BuildContext context, WidgetRef ref) async {
    final qada = ref.read(qadaRepositoryProvider);
    await qada.remove(day, prayer);
    if (!context.mounted) return;
    showToast(
      context,
      StringsManager.removedFromQada,
      args: {'prayer': context.tr(prayer.nameKey)},
      onUndo: () => qada.add(day, prayer),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = switch (state) {
      PrayerRowState.mark || PrayerRowState.prayed => MarkButton(
        prayed: state == PrayerRowState.prayed,
        onTap: () => state == PrayerRowState.prayed ? _unmark(context, ref) : _mark(context, ref),
      ),
      PrayerRowState.next => const _NextChip(),
      PrayerRowState.addToQada => _ChipButton(
        onTap: () => showPassedSheet(context, day, prayer),
        child: const StateChip(StringsManager.addToQada, look: ChipLook.outline),
      ),
      PrayerRowState.inQada => _ChipButton(
        onTap: () => _leaveQada(context, ref),
        child: const StateChip(StringsManager.inQada, look: ChipLook.outline),
      ),

      /// a label, made up stays made up from here (FR-021)
      PrayerRowState.madeUp => const StateChip(StringsManager.madeUp, check: true),
      PrayerRowState.later || PrayerRowState.unavailable => const SizedBox.shrink(),
    };
    return AnimatedSwitcher(
      duration: BmMotion.micro,

      /// mark and prayed keep one key, the button draws its own check (Motion 07)
      child: KeyedSubtree(
        key: ValueKey(state == PrayerRowState.prayed ? PrayerRowState.mark : state),
        child: child,
      ),
    );
  }
}

/// a chip with the 44 pt hit area around it
class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: SizeManager.hit.r, minWidth: SizeManager.hit.r),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
  }
}

/// "in h:mm" to the next prayer, rebuilt once a minute
class _NextChip extends ConsumerWidget {
  const _NextChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextPrayerProvider.select((next) => next?.$2));
    final clock = ref.watch(clockProvider);
    final minutes = ref.watch(
      minuteProvider.select(
        (now) => next == null ? 0 : next.difference(now.value ?? clock()).inMinutes,
      ),
    );
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final duration = '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';
    return StateChip(
      StringsManager.inDuration,
      look: ChipLook.accent,
      args: {'duration': context.formatDigits(duration, digits)},
    );
  }
}
