import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/picker_row.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:better_muslim/features/prayer/presentation/providers/prayer_actions.dart';
import 'package:better_muslim/features/prayer/presentation/view/widgets/day_complete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// a passed prayer with no log: prayed it and forgot to tap, or missed it (FR-008). the toast and
/// Day complete go on the row's context, the sheet's is gone by then
Future<void> showPassedSheet(BuildContext context, DateTime day, Prayer prayer) => showBmSheet(
  context,
  title: SheetTitle(
    StringsManager.prayerPassedTitle,
    args: {'prayer': context.tr(prayer.nameKey)},
    subtitle: StringsManager.prayerPassedBody,
  ),
  builder: (_) => _PassedSheet(rowContext: context, day: day, prayer: prayer),
);

class _PassedSheet extends ConsumerWidget {
  const _PassedSheet({required this.rowContext, required this.day, required this.prayer});
  final BuildContext rowContext;
  final DateTime day;
  final Prayer prayer;

  /// no toast, like Mark. tapping "Prayed" undoes it
  Future<void> _prayed(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final complete = await ref.read(prayerActionsProvider).mark(day, prayer);
    if (complete && rowContext.mounted) showDayComplete(rowContext);
  }

  Future<void> _addToQada(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).pop();
    final qada = ref.read(qadaRepositoryProvider);
    await qada.add(day, prayer);
    if (!rowContext.mounted) return;
    showToast(
      rowContext,
      StringsManager.addedToQada,
      args: {'prayer': rowContext.tr(prayer.nameKey)},
      onUndo: () => qada.remove(day, prayer),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: BottomPadding(
        padding: SpaceManager.s6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HorizontalPadding(
              padding: SpaceManager.s1,
              child: Column(
                children: [
                  PickerRow(
                    title: StringsManager.iPrayedIt,
                    selected: false,
                    onTap: () => _prayed(context, ref),
                  ),
                  PickerRow(
                    title: StringsManager.addToQada,
                    selected: false,
                    onTap: () => _addToQada(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
