import 'dart:async';
import 'dart:math' as math;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// a tap steps once with the selection haptic. holding repeats faster and faster, with no
/// haptic on the repeats so a long hold doesn't buzz on every step
class StepButton extends StatefulWidget {
  const StepButton({
    required this.icon,
    required this.enabled,
    required this.onStep,
    this.label,
    super.key,
  });
  final BmUiIcon icon;
  final bool enabled;
  final VoidCallback onStep;

  /// a StringsManager key for screen readers
  final String? label;

  @override
  State<StepButton> createState() => StepButtonState();
}

class StepButtonState extends State<StepButton> {
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
    final label = widget.label;
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: label == null ? null : context.tr(label),
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
            child: AnimatedOpacity(
              duration: BmMotion.standard,
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
