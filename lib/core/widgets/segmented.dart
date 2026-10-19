import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the components' segmented control: 4.15's full width one, or 4.12's small one sized to its labels
class Segmented<T> extends StatelessWidget {
  const Segmented({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
    this.small = false,
    this.muted = const {},
    super.key,
  });

  final List<T> values;
  final T selected;

  /// a StringsManager key for each value
  final String Function(T value) labelOf;
  final ValueChanged<T> onChanged;
  final bool small;

  /// drawn in text2 while not picked, 4.15's Follow sky
  final Set<T> muted;

  @override
  Widget build(BuildContext context) {
    final height = small ? SizeManager.segmentSmall : SizeManager.segment;

    /// the small track is 36 tall, its segments still take taps across 44
    final reach = math.max(0.0, (SizeManager.hit - height) / 2 - SpaceManager.segmentTrack);
    _Segment segment(T value) => _Segment(
      label: labelOf(value),
      selected: value == selected,
      small: small,
      muted: small || muted.contains(value),
      reach: reach,
      onTap: () {
        if (value == selected) return;
        BmHaptics.selection();
        onChanged(value);
      },
    );
    return Stack(
      children: [
        Positioned.fill(
          child: VerticalPadding(
            padding: reach,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.getColor(ThemeEnum.variant),
                borderRadius: BorderRadius.circular(
                  (small ? RadiusManager.segmentSmallTrack : RadiusManager.segmentTrack).r,
                ),
              ),
            ),
          ),
        ),
        HorizontalPadding(
          padding: SpaceManager.segmentTrack,
          child: Row(
            mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
            children: [
              for (final (index, value) in values.indexed) ...[
                if (index > 0) const RSizedBox.horizontal(SpaceManager.segmentGap),
                if (small) segment(value) else Expanded(child: segment(value)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.small,
    required this.muted,
    required this.reach,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool small;
  final bool muted;
  final double reach;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(
      (small ? RadiusManager.segmentSmall : RadiusManager.segment).r,
    );
    final color = selected || !muted ? ThemeEnum.text : ThemeEnum.text2;
    final fontSize = small ? FontSizeManager.dhikrChip : FontSizeManager.secondary;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: VerticalPadding(
          padding: reach + SpaceManager.segmentTrack,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (small ? SizeManager.segmentSmall : SizeManager.segment).r,
            ),
            child: DecoratedBox(
              decoration: selected
                  ? BoxDecoration(
                      color: context.getColor(ThemeEnum.surface),
                      borderRadius: radius,
                      boxShadow: [
                        BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1),
                      ],
                    )
                  : const BoxDecoration(),
              child: HorizontalPadding(
                padding: small ? SpaceManager.segmentSmallSide : 0,
                child: Center(
                  widthFactor: small ? 1 : null,
                  child: selected && small
                      ? MediumText(label, fontSize: fontSize, textAlign: TextAlign.center)
                      : RegularText(
                          label,
                          fontSize: fontSize,
                          color: color,
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
