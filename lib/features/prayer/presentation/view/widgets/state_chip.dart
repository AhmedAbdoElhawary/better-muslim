import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// prayed and made up are green, add to qada and in qada an outline, the countdown accent
enum ChipLook { success, outline, accent }

/// the 26 pt chips of a prayer row
class StateChip extends StatelessWidget {
  const StateChip(
    this.label, {
    this.look = ChipLook.success,
    this.check = false,
    this.checkProgress = kAlwaysCompleteAnimation,
    this.args = const {},
    super.key,
  });

  /// a StringsManager key
  final String label;
  final ChipLook look;
  final bool check;

  /// Motion 07 draws the check in once the prayer is marked
  final Animation<double> checkProgress;
  final Map<String, String> args;

  static const _successFill = .16;

  @override
  Widget build(BuildContext context) {
    final color = switch (look) {
      ChipLook.success => ThemeEnum.success,
      ChipLook.outline => ThemeEnum.text2,
      ChipLook.accent => ThemeEnum.onAccentContainer,
    };
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: SizeManager.stateChip.r),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(RadiusManager.pill.r),
          color: switch (look) {
            ChipLook.success => context.getColor(ThemeEnum.success).withValues(alpha: _successFill),
            ChipLook.outline => null,
            ChipLook.accent => context.getColor(ThemeEnum.accentContainer),
          },
          border: look == ChipLook.outline
              ? Border.all(color: context.getColor(ThemeEnum.outlineStrong))
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,

          child: SymmetricPadding(
            horizontal: SpaceManager.chipSide,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (check) ...[
                  FittedBox(
                    child: CheckMark(
                      progress: checkProgress,
                      size: SizeManager.iconChip,
                      color: context.getColor(color),
                    ),
                  ),
                  const RSizedBox.horizontal(SpaceManager.s1),
                ],
                MediumText(
                  label,
                  args: args,
                  fontSize: FontSizeManager.chip,
                  color: color,
                  tabularFigures: look == ChipLook.accent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ui/check drawn as a stroke, so Motion 07 can draw it in with PathMetric.extractPath
class CheckMark extends StatelessWidget {
  const CheckMark({
    required this.size,
    required this.color,
    this.progress = kAlwaysCompleteAnimation,
    super.key,
  });

  /// unscaled, like the other SizeManager values
  final double size;
  final Color color;
  final Animation<double> progress;

  @override
  Widget build(BuildContext context) {
    return RSizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CheckPainter(progress: progress, color: color),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  /// ui/check.svg in its 24 box: M5 12.5l4.5 4.5L19 7.5, stroke 1.25
  static const _box = 24.0;
  static const _stroke = 1.25;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _box;
    final path = Path()
      ..moveTo(5 * scale, 12.5 * scale)
      ..lineTo(9.5 * scale, 17 * scale)
      ..lineTo(19 * scale, 7.5 * scale);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress.value),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress || old.color != color;
}
