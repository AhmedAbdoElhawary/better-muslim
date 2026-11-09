import 'dart:math' as math;

import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/sliding_selection.dart';
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
    this.empty = const {},
    this.checked = const {},
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

  /// nothing behind it, drawn in text2 with a close icon even when picked, still tappable
  final Set<T> empty;

  /// a success check after the label, the calendar's full day
  final Set<T> checked;

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
      empty: empty.contains(value),
      checked: checked.contains(value),
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
          padding: SpaceManager.previewChipBottom,
          child: SlidingSelection(
            selected: values.indexOf(selected),
            highlight: VerticalPadding(
              padding: reach + SpaceManager.segmentTrack,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.getColor(ThemeEnum.surface),
                  borderRadius: BorderRadius.circular(
                    (small ? RadiusManager.segmentSmall : RadiusManager.segment).r,
                  ),
                  boxShadow: [
                    BoxShadow(color: context.getColor(ThemeEnum.outline), spreadRadius: 1),
                  ],
                ),
              ),
            ),
            layout: (children) => Row(
              mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
              children: [
                for (final (index, child) in children.indexed) ...[
                  if (index > 0) const RSizedBox.horizontal(SpaceManager.segmentGap),
                  if (small) child else Expanded(child: child),
                ],
              ],
            ),
            children: [for (final value in values) segment(value)],
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
    required this.empty,
    required this.checked,
    required this.reach,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool small;
  final bool muted;
  final bool empty;
  final bool checked;
  final double reach;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = (selected || !muted) && !empty ? ThemeEnum.text : ThemeEnum.text2;
    final fontSize = small ? FontSizeManager.dhikrChip : FontSizeManager.secondary;
    final text = selected && small && !empty
        ? MediumText(label, fontSize: fontSize, textAlign: TextAlign.center)
        : RegularText(label, fontSize: fontSize, color: color, textAlign: TextAlign.center);
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
            child: HorizontalPadding(
              padding: small ? SpaceManager.segmentSmallSide : 0,
              child: Center(
                widthFactor: small ? 1 : null,
                child: AnimatedSwitcher(
                  duration: BmMotion.micro,
                  child: empty || checked
                      ? Row(
                          key: ValueKey((empty, checked)),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(child: text),
                            const RSizedBox.horizontal(SpaceManager.segmentIconGap),
                            BmIcon.ui(
                              empty ? BmUiIcon.close : BmUiIcon.check,
                              size: SizeManager.iconChip.r,
                              color: context.getColor(empty ? ThemeEnum.text2 : ThemeEnum.success),
                            ),
                          ],
                        )
                      : KeyedSubtree(
                          key: const ValueKey(false),
                          child: FittedBox(child: text),
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
