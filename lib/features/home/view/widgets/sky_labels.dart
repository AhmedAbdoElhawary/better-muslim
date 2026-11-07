import 'dart:math';

import 'package:better_muslim/core/extensions/time_format.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/home/model/home_moment.dart';
import 'package:better_muslim/features/home/view/widgets/arc_turn.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:timezone/timezone.dart';

/// the arc's points. the feet under the horizon, the others outside the arc, some inside it in
/// arabic. the arc is never mirrored, so they are placed left to right
class SkyLabels extends ConsumerWidget {
  const SkyLabels({super.key});

  /// above it the middle labels show only their time
  static const _shortScale = 1.4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final center = (rtl ? BmSunArc.centerRtl : BmSunArc.center).dx;
    final scale =
        MediaQuery.textScalerOf(context).scale(FontSizeManager.skyLabel) / FontSizeManager.skyLabel;
    final horizonAboveBottom = SkyHeader.horizonAboveBottom(context).r;
    return ArcTurn(
      builder: (context, points, outgoing, turn) {
        /// the old labels fade out in the first half of the turn, the new ones in during the second
        final arcs = [
          if (outgoing != null && turn < 1) (points: outgoing, opacity: max(0.0, 1 - 2 * turn)),
          if (points != null)
            (points: points, opacity: outgoing != null && turn < 1 ? max(0.0, 2 * turn - 1) : 1.0),
        ];
        final slots = <SkyLabelSlot>[];
        final children = <Widget>[];
        for (var arc = 0; arc < arcs.length; arc++) {
          final list = arcs[arc].points.points;
          for (var index = 0; index < list.length; index++) {
            final point = list[index];
            final middle = index > 0 && index < list.length - 1;
            for (final short in [false, if (middle) true]) {
              slots.add((arc: arc, index: index, short: short));
              children.add(
                _Label(labelKey: point.name, time: point.time, short: short, direction: direction),
              );
            }
          }
        }
        return Flow(
          delegate: SkyLabelsFlow(
            arcs: arcs,
            slots: slots,
            center: center.r,
            radius: BmSunArc.radius.r,
            edge: SpaceManager.skyLabelEdge.r,
            startLeft: rtl ? null : SpaceManager.skyLabelStart.r,
            endInset: rtl ? SpaceManager.skyLabelEndAr.r : null,
            scale: scale,
            horizonAboveBottom: horizonAboveBottom,

            /// 4.16's arabic labels start on the horizon, 4.01's 6 below it
            gap: rtl ? 0 : (SpaceManager.skyLabelTop - BmSunArc.horizonY).r,
            arcGap: SpaceManager.arcLabelGap.r,
            insideGap: rtl ? SpaceManager.arcLabelInsideGap.r : null,
            shortOnly: scale > _shortScale,
          ),
          children: children,
        );
      },
    );
  }
}

/// which arc, which of its points, and whether it is the time only label
typedef SkyLabelSlot = ({int arc, int index, bool short});

/// the feet keep the mockups' offsets, grown with the text so larger labels stay under their
/// foot. a middle label sits outside the arc along its point's normal, and shows only its time
/// when it would touch another. all kept [edge] inside the screen, a null offset sits on the edge.
/// with an [insideGap], asr and a label the edge pushes onto the arc sit inside the arc instead
class SkyLabelsFlow extends FlowDelegate {
  SkyLabelsFlow({
    required this.arcs,
    required this.slots,
    required this.center,
    required this.radius,
    required this.edge,
    required this.startLeft,
    required this.endInset,
    required this.scale,
    required this.horizonAboveBottom,
    required this.gap,
    required this.arcGap,
    required this.insideGap,
    required this.shortOnly,
  });

  final List<({ArcPoints points, double opacity})> arcs;
  final List<SkyLabelSlot> slots;
  final double center;
  final double radius;
  final double edge;
  final double? startLeft;
  final double? endInset;
  final double scale;
  final double horizonAboveBottom;
  final double gap;
  final double arcGap;
  final double? insideGap;
  final bool shortOnly;

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) => constraints.loosen();

  /// where each child is painted, null when the other label of its point shows
  List<Offset?> place(Size size, List<Size> children) {
    final horizon = size.height - horizonAboveBottom;
    final feet = (center - radius, center + radius);
    Rect inside(Offset topLeft, Size label) => Rect.fromLTWH(
      topLeft.dx.clamp(edge, max(edge, size.width - edge - label.width)).toDouble(),
      max(0, topLeft.dy),
      label.width,
      label.height,
    );

    final rects = <Rect>[];
    for (var i = 0; i < slots.length; i++) {
      final (:arc, :index, short: _) = slots[i];
      final points = arcs[arc].points.points;
      final label = children[i];
      final top = horizon + gap;
      if (index == 0) {
        final left = startLeft;
        final x = left == null ? edge : feet.$1 - (feet.$1 - left) * scale;
        rects.add(inside(Offset(x, top), label));
      } else if (index == points.length - 1) {
        final inset = endInset;
        final right = inset == null
            ? size.width - edge
            : feet.$2 + (size.width - inset - feet.$2) * scale;
        rects.add(inside(Offset(right - label.width, top), label));
      } else {
        final angle = pi * (1 - points[index].share);
        final normal = Offset(cos(angle), -sin(angle));
        final reach = normal.dx.abs() * label.width / 2 + normal.dy.abs() * label.height / 2;
        Offset at(double distance) =>
            Offset(center, horizon) + normal * distance - Offset(label.width / 2, label.height / 2);
        final outside = at(radius + arcGap + reach);
        final rect = inside(outside, label);
        final gap = insideGap;

        /// outside, arabic's asr sits against the big prayer name
        final goesIn =
            gap != null &&
            (points[index].name == StringsManager.asrLabel || rect.left != outside.dx);
        rects.add(goesIn ? inside(at(radius - gap - reach), label) : rect);
      }
    }

    bool touches(int i) => slots.indexed.any(
      (other) =>
          other.$1 != i &&
          other.$2.arc == slots[i].arc &&
          !other.$2.short &&
          rects[i].overlaps(rects[other.$1]),
    );

    /// a middle label's time only child comes right after its full one
    final timeOnly = [
      for (var i = 0; i < slots.length; i++)
        i + 1 < slots.length && slots[i + 1].short && (shortOnly || touches(i)),
    ];
    return [
      for (var i = 0; i < slots.length; i++)
        if (slots[i].short)
          timeOnly[i - 1] ? rects[i].topLeft : null
        else
          timeOnly[i] ? null : rects[i].topLeft,
    ];
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    final offsets = place(context.size, [
      for (var i = 0; i < context.childCount; i++) context.getChildSize(i)!,
    ]);
    for (var i = 0; i < offsets.length; i++) {
      final offset = offsets[i];
      final opacity = arcs[slots[i].arc].opacity;
      if (offset == null || opacity <= 0) continue;
      context.paintChild(
        i,
        transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
        opacity: opacity,
      );
    }
  }

  @override
  bool shouldRepaint(SkyLabelsFlow old) =>
      !listEquals(old.arcs, arcs) ||
      old.center != center ||
      old.radius != radius ||
      old.edge != edge ||
      old.startLeft != startLeft ||
      old.endInset != endInset ||
      old.scale != scale ||
      old.horizonAboveBottom != horizonAboveBottom ||
      old.gap != gap ||
      old.arcGap != arcGap ||
      old.insideGap != insideGap ||
      old.shortOnly != shortOnly;
}

class _Label extends ConsumerWidget {
  const _Label({
    required this.labelKey,
    required this.time,
    required this.short,
    required this.direction,
  });
  final String labelKey;
  final TZDateTime time;
  final bool short;
  final TextDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digits = ref.watch(
      settingsProvider.select((settings) => settings.value?.digits ?? Digits.eastern),
    );
    final bright = ref.watch(skyBrightProvider);
    final formatted = context.formatTime(time, digits);
    final text = RegularText(
      short ? formatted : labelKey,
      translate: !short,
      args: {'time': formatted},
      fontSize: FontSizeManager.skyLabel,
      height: direction == TextDirection.rtl ? LineHeightManager.skyLabelAr : null,
      color: bright ? ThemeEnum.onSkyBright : ThemeEnum.onSkyMuted,
      tabularFigures: true,
    );

    /// the full label is always there for a screen reader, the time only one would repeat it
    return Directionality(
      textDirection: direction,
      child: short ? ExcludeSemantics(child: text) : text,
    );
  }
}
