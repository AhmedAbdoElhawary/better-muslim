import 'dart:math' as math;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/features/qibla/model/qibla_math.dart';
import 'package:better_muslim/features/qibla/view/widgets/aligned_pulse.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_dot.dart';
import 'package:better_muslim/features/qibla/view/widgets/qibla_needle.dart';
import 'package:better_muslim/features/qibla/view_model/qibla_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the ring stays put, the face (ticks, letters, kaaba marker) turns by minus the heading and the
/// needle springs over it. never mirrored, north and east are the same in arabic (FR-012)
class QiblaDial extends ConsumerWidget {
  const QiblaDial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesign = ref.watch(flavorProvider.select((config) => config.isDesignScenario));
    return Directionality(
      textDirection: TextDirection.ltr,
      child: _DialSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isDesign ? () => ref.read(designHeadingProvider.notifier).toggle() : null,
          child: const RSizedBox.square(
            dimension: SizeManager.qiblaDial,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AlignedGlow(),
                _Ring(),
                AlignedPulse(),
                RepaintBoundary(child: _Face()),
                Positioned.fill(child: QiblaNeedle()),
                Center(
                  child: QiblaDot(size: SizeManager.qiblaHub, color: ThemeEnum.text),
                ),
                _TopTick(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// one node for screen readers, the title is not a live region so degrees are not read out (R13)
class _DialSemantics extends ConsumerWidget {
  const _DialSemantics({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(qiblaStateProvider);
    final aligned = ref.watch(qiblaAlignedProvider);
    final degrees = ref.watch(turnDegreesProvider);
    final right = ref.watch(qiblaDiffProvider.select((diff) => diff == null || diff >= 0));
    final target = ref.watch(qiblaTargetProvider);
    final accuracy = ref.watch(compassProvider.select((reading) => reading.value?.accuracy));
    final language = Localizations.localeOf(context).languageCode;
    final instruction = switch (state) {
      QiblaState.noLocation => context.tr(StringsManager.noLocationYet),
      QiblaState.noCompass => context.tr(StringsManager.noCompass),
      QiblaState.waiting => '',
      QiblaState.ready when aligned => context.tr(StringsManager.facingQibla),
      QiblaState.ready => context.tr(right ? StringsManager.turnRight : StringsManager.turnLeft, {
        'deg': '${degrees ?? 0}',
      }),
    };
    final distance = target == null
        ? null
        : formatDistance(target.distanceKm, language: language, digits: Digits.western);
    final level = accuracy?.key ?? StringsManager.accuracyNone;
    return Semantics(
      container: true,
      label: context.tr(StringsManager.qiblaCompass),
      value: [
        instruction,
        if (target != null) '${target.bearing.round() % 360}°',
        if (distance != null) context.tr(distance.key, {'distance': distance.value}),
        '${context.tr(StringsManager.compassAccuracy)} ${context.tr(level)}',
      ].where((part) => part.isNotEmpty).join(', '),
      child: ExcludeSemantics(child: child),
    );
  }
}

class _Ring extends ConsumerWidget {
  const _Ring();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aligned = ref.watch(qiblaAlignedProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Positioned.fill(
      child: AnimatedContainer(
        duration: reduceMotion ? Duration.zero : BmMotion.standard,
        curve: BmMotion.standardCurve,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [context.getColor(ThemeEnum.surface), context.getColor(ThemeEnum.bg)],
            stops: const [0, .72],
          ),
          border: Border.all(
            color: context.getColor(aligned ? ThemeEnum.accent : ThemeEnum.outline),
            width: (aligned ? SizeManager.qiblaRingAligned : SizeManager.qiblaRing).r,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
      ),
    );
  }
}

/// the tick above the ring, outside the turning face: where the top of the phone points
class _TopTick extends ConsumerWidget {
  const _TopTick();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aligned = ref.watch(qiblaAlignedProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Positioned(
      top: -(SizeManager.qiblaTopTickGap + SizeManager.qiblaTopTick).r,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : BmMotion.standard,
          curve: BmMotion.standardCurve,
          width: SizeManager.qiblaTopTickWidth.r,
          height: SizeManager.qiblaTopTick.r,
          decoration: BoxDecoration(
            color: context.getColor(aligned ? ThemeEnum.accent : ThemeEnum.text),
            borderRadius: BorderRadius.circular(RadiusManager.qiblaNeedle.r),
          ),
        ),
      ),
    );
  }
}

/// turns at once with each reading. the angle is kept continuous, so passing north never spins
/// the face the long way round (R7)
class _Face extends ConsumerStatefulWidget {
  const _Face();

  @override
  ConsumerState<_Face> createState() => _FaceState();
}

class _FaceState extends ConsumerState<_Face> {
  var _heading = 0.0;

  @override
  Widget build(BuildContext context) {
    final heading = ref.watch(compassProvider.select((reading) => reading.value?.heading)) ?? 0;
    final bearing = ref.watch(qiblaTargetProvider.select((target) => target?.bearing));
    _heading += qiblaDiff(heading, _heading);
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.rotate(
          angle: -_heading * math.pi / 180,
          child: CustomPaint(
            painter: DialPainter(
              bearing: bearing,
              major: context.getColor(ThemeEnum.text2),
              minor: context.getColor(ThemeEnum.outlineStrong),
              marker: context.getColor(ThemeEnum.accent),
              markerLine: context.getColor(ThemeEnum.primary),
            ),
          ),
        ),
        for (final (index, letter) in _letters.indexed)
          _Letter(angle: index * 90 - _heading, child: letter),
      ],
    );
  }
}

const _letters = [
  SemiBoldText(
    StringsManager.compassN,
    fontSize: FontSizeManager.secondary,
    color: ThemeEnum.primary,
  ),
  RegularText(StringsManager.compassE, fontSize: FontSizeManager.secondary, color: ThemeEnum.text2),
  RegularText(StringsManager.compassS, fontSize: FontSizeManager.secondary, color: ThemeEnum.text2),
  RegularText(StringsManager.compassW, fontSize: FontSizeManager.secondary, color: ThemeEnum.text2),
];

/// placed at its angle on the face, never turned, so it stays upright like the PNG
class _Letter extends StatelessWidget {
  const _Letter({required this.angle, required this.child});

  /// degrees clockwise from the top of the screen
  final double angle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final radians = angle * math.pi / 180;
    final radius = SizeManager.qiblaLetterRadius.r;
    return Transform.translate(
      offset: Offset(math.sin(radians) * radius, -math.cos(radians) * radius),
      child: Center(child: child),
    );
  }
}

/// the face's shapes in the tree's 300 pt units, scaled to the box. the letters are text widgets
@visibleForTesting
class DialPainter extends CustomPainter {
  DialPainter({
    required this.bearing,
    required this.major,
    required this.minor,
    required this.marker,
    required this.markerLine,
  });

  /// null without a location, then there is no kaaba marker
  final double? bearing;
  final Color major;
  final Color minor;
  final Color marker;
  final Color markerLine;

  /// counts paints, so a test can see what makes the face repaint
  static int paints = 0;

  @override
  void paint(Canvas canvas, Size size) {
    paints++;
    const half = SizeManager.qiblaDial / 2;
    canvas
      ..scale(size.width / SizeManager.qiblaDial)
      ..translate(half, half);
    final paint = Paint();
    for (var degrees = 0; degrees < 360; degrees += 5) {
      final cardinal = degrees % 90 == 0;
      final long = degrees % 30 == 0;
      paint
        ..color = cardinal ? major : minor
        ..strokeWidth = long ? SizeManager.qiblaTickMajorStroke : SizeManager.qiblaTickMinorStroke;
      final radians = degrees * math.pi / 180;
      final direction = Offset(math.sin(radians), -math.cos(radians));
      const outer = SizeManager.qiblaTickOuter;
      final inner = outer - (long ? SizeManager.qiblaTickMajor : SizeManager.qiblaTickMinor);
      canvas.drawLine(direction * outer, direction * inner, paint);
    }

    final bearing = this.bearing;
    if (bearing == null) return;
    final radians = bearing * math.pi / 180;
    const side = SizeManager.qiblaMarker / 2;
    canvas
      ..save()
      ..translate(
        math.sin(radians) * SizeManager.qiblaTickOuter,
        -math.cos(radians) * SizeManager.qiblaTickOuter,
      )
      ..rotate(radians)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCircle(center: Offset.zero, radius: side),
          const Radius.circular(RadiusManager.qiblaMarker),
        ),
        Paint()..color = marker,
      )
      ..drawLine(
        const Offset(-side, -SizeManager.qiblaMarkerLine),
        const Offset(side, -SizeManager.qiblaMarkerLine),
        Paint()
          ..color = markerLine
          ..strokeWidth = SizeManager.qiblaMarkerStroke,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(DialPainter old) =>
      old.bearing != bearing ||
      old.major != major ||
      old.minor != minor ||
      old.marker != marker ||
      old.markerLine != markerLine;
}
