import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/step_button.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// prayers missed before the app, many at once for someone coming back to prayer (R15). the
/// toast goes on the list's context, the sheet's is gone by then
Future<void> showAddOlderSheet(BuildContext context, Prayer prayer) => showBmSheet(
  context,
  title: SheetTitle(StringsManager.addMissedTitle, args: {'prayer': context.tr(prayer.nameKey)}),
  builder: (_) => _AddOlderSheet(listContext: context, prayer: prayer),
);

class _AddOlderSheet extends ConsumerStatefulWidget {
  const _AddOlderSheet({required this.listContext, required this.prayer});
  final BuildContext listContext;
  final Prayer prayer;

  @override
  ConsumerState<_AddOlderSheet> createState() => _AddOlderSheetState();
}

class _AddOlderSheetState extends ConsumerState<_AddOlderSheet> {
  static const _min = 1;
  static const _max = 999;

  var _count = _min;

  void _step(int by) => setState(() => _count = (_count + by).clamp(_min, _max));

  Future<void> _add() async {
    Navigator.of(context).pop();
    final qada = ref.read(qadaRepositoryProvider);
    final ids = await qada.addOlder(widget.prayer, _count);
    final listContext = widget.listContext;
    if (!listContext.mounted) return;
    showToast(
      listContext,
      StringsManager.addedToQada,
      args: {'prayer': listContext.tr(widget.prayer.nameKey)},
      onUndo: () => qada.removeIds(ids),
    );
  }

  @override
  Widget build(BuildContext context) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    return SafeArea(
      top: false,
      child: BottomPadding(
        padding: SpaceManager.s6,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VerticalPadding(
              padding: SpaceManager.s4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StepButton(icon: BmUiIcon.minus, enabled: _count > _min, onStep: () => _step(-1)),
                  ConstrainedBox(
                    constraints: BoxConstraints(minWidth: SizeManager.countValue.r),
                    child: MediumText(
                      context.formatDigits('$_count', digits),
                      translate: false,
                      fontSize: FontSizeManager.monthTitle,
                      textAlign: TextAlign.center,
                      tabularFigures: true,
                    ),
                  ),
                  StepButton(icon: BmUiIcon.plus, enabled: _count < _max, onStep: () => _step(1)),
                ],
              ),
            ),
            HorizontalPadding(
              padding: SpaceManager.s5,
              child: BmButton.primary(StringsManager.add, onPressed: _add),
            ),
          ],
        ),
      ),
    );
  }
}
