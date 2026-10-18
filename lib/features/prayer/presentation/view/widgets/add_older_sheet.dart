import 'dart:async';
import 'dart:math' as math;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/bm_button.dart';
import 'package:better_muslim/core/widgets/sheet/bm_sheet.dart';
import 'package:better_muslim/core/widgets/sheet/sheet_title.dart';
import 'package:better_muslim/core/widgets/toast/toast.dart';
import 'package:better_muslim/features/prayer/data/qada_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// prayers missed before the app, many at once for someone coming back to prayer (R15). the
/// toast goes on the list's context, the sheet's is gone by then
Future<void> showAddOlderSheet(BuildContext context, Prayer prayer) => showBmSheet(
  context,
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
            SheetTitle(
              StringsManager.addMissedTitle,
              args: {'prayer': context.tr(widget.prayer.nameKey)},
            ),
            VerticalPadding(
              padding: SpaceManager.s4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StepButton(
                    icon: BmUiIcon.minus,
                    enabled: _count > _min,
                    onStep: () => _step(-1),
                  ),
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
                  _StepButton(icon: BmUiIcon.plus, enabled: _count < _max, onStep: () => _step(1)),
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

/// a tap steps once with the selection haptic. holding repeats faster and faster, with no
/// haptic on the repeats so a long hold doesn't buzz on every step
class _StepButton extends StatefulWidget {
  const _StepButton({required this.icon, required this.enabled, required this.onStep});
  final BmUiIcon icon;
  final bool enabled;
  final VoidCallback onStep;

  @override
  State<_StepButton> createState() => _StepButtonState();
}

class _StepButtonState extends State<_StepButton> {
  static const _firstRepeat = Duration(milliseconds: 300);
  static const _fastest = Duration(milliseconds: 40);
  static const _speedUp = .8;

  Timer? _timer;

  void _repeat(Duration every) {
    _timer = Timer(every, () {
      if (!widget.enabled) return _stop();
      widget.onStep();
      _repeat(
        Duration(
          microseconds: math.max(
            _fastest.inMicroseconds,
            (every.inMicroseconds * _speedUp).round(),
          ),
        ),
      );
    });
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled
            ? () {
                BmHaptics.selection();
                widget.onStep();
              }
            : null,
        onLongPressStart: widget.enabled
            ? (_) {
                widget.onStep();
                _repeat(_firstRepeat);
              }
            : null,
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _stop,
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: Opacity(
              opacity: widget.enabled ? 1 : BmOpacity.disabled,
              child: BmIcon.ui(
                widget.icon,
                size: SizeManager.icon.r,
                color: context.getColor(ThemeEnum.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
