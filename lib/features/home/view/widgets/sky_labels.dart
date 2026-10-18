import 'dart:math';

import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timezone/timezone.dart';

/// the times under the arc's feet. the arc is never mirrored, so they are placed left to right
class SkyLabels extends ConsumerWidget {
  const SkyLabels({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(arcLabelsProvider);
    if (labels == null) return const SizedBox.shrink();
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final center = (rtl ? BmSunArc.centerRtl : BmSunArc.center).dx;
    final start = labels.start;
    final end = labels.end;
    return CustomMultiChildLayout(
      delegate: _LabelsLayout(
        feet: ((center - BmSunArc.radius).r, (center + BmSunArc.radius).r),
        edge: SpaceManager.skyLabelEdge.r,
        startLeft: rtl ? null : SpaceManager.skyLabelStart.r,
        endInset: rtl ? SpaceManager.skyLabelEndAr.r : null,
        scale:
            MediaQuery.textScalerOf(context).scale(FontSizeManager.skyLabel) /
            FontSizeManager.skyLabel,
        horizonAboveBottom: SkyHeader.horizonAboveBottom(context).r,

        /// 4.16's arabic labels start on the horizon, 4.01's 6 below it
        gap: rtl ? 0 : (SpaceManager.skyLabelTop - BmSunArc.horizonY).r,
      ),
      children: [
        if (start != null)
          LayoutId(
            id: _LabelsLayout.start,
            child: _Label(labelKey: labels.startKey, time: start, direction: direction),
          ),
        if (end != null)
          LayoutId(
            id: _LabelsLayout.end,
            child: _Label(labelKey: labels.endKey, time: end, direction: direction),
          ),
      ],
    );
  }
}

/// the mockups' offsets from the arc's feet, grown with the text so larger labels stay under
/// their foot, and kept 14 pt inside the screen. a null offset sits on the edge
class _LabelsLayout extends MultiChildLayoutDelegate {
  _LabelsLayout({
    required this.feet,
    required this.edge,
    required this.startLeft,
    required this.endInset,
    required this.scale,
    required this.horizonAboveBottom,
    required this.gap,
  });

  static const start = #start;
  static const end = #end;

  final (double, double) feet;
  final double edge;
  final double? startLeft;
  final double? endInset;
  final double scale;
  final double horizonAboveBottom;
  final double gap;

  @override
  void performLayout(Size size) {
    final top = size.height - horizonAboveBottom + gap;
    double inside(double x, double width) =>
        x.clamp(edge, max(edge, size.width - edge - width)).toDouble();
    if (hasChild(start)) {
      final label = layoutChild(start, BoxConstraints.loose(size));
      final left = startLeft;
      final x = left == null ? edge : feet.$1 - (feet.$1 - left) * scale;
      positionChild(start, Offset(inside(x, label.width), top));
    }
    if (hasChild(end)) {
      final label = layoutChild(end, BoxConstraints.loose(size));
      final inset = endInset;
      final right = inset == null
          ? size.width - edge
          : feet.$2 + (size.width - inset - feet.$2) * scale;
      positionChild(end, Offset(inside(right - label.width, label.width), top));
    }
  }

  @override
  bool shouldRelayout(_LabelsLayout old) =>
      old.feet != feet ||
      old.edge != edge ||
      old.startLeft != startLeft ||
      old.endInset != endInset ||
      old.scale != scale ||
      old.horizonAboveBottom != horizonAboveBottom ||
      old.gap != gap;
}

class _Label extends ConsumerWidget {
  const _Label({required this.labelKey, required this.time, required this.direction});
  final String labelKey;
  final TZDateTime time;
  final TextDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final bright = ref.watch(skyBrightProvider);
    return Directionality(
      textDirection: direction,
      child: RegularText(
        labelKey,
        args: {'time': context.formatTime(time, digits)},
        fontSize: FontSizeManager.skyLabel,
        height: direction == TextDirection.rtl ? LineHeightManager.skyLabelAr : null,
        color: bright ? ThemeEnum.onSkyBright : ThemeEnum.onSkyMuted,
        tabularFigures: true,
      ),
    );
  }
}
