import 'package:better_muslim/core/prayer_times/sky_state.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/resources/theme_sky.dart';
import 'package:better_muslim/core/settings/appearance.dart';
import 'package:better_muslim/features/home/view/widgets/arc_turn.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header_painter.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

/// the living sky, still until the sky changes at a prayer. its short events are SkyEvents
class SkyHeader extends ConsumerStatefulWidget {
  const SkyHeader({required this.overlap, super.key});

  /// how far the sky goes on under the next-prayer card
  final double overlap;

  /// the horizon's distance above the sky box's bottom in design points: the mockup's 20, plus
  /// what larger text adds to the labels under it
  static double horizonAboveBottom(BuildContext context) {
    const box = SizeManager.homeSkyHeight - SpaceManager.homeCardOverlap;
    final growth =
        MediaQuery.textScalerOf(context).scale(FontSizeManager.skyLabel) /
            FontSizeManager.skyLabel -
        1;
    return box - BmSunArc.horizonY + (box - SpaceManager.skyLabelTop) * growth;
  }

  /// the room above the arc's top for the label of a point near it, in design points
  static double labelRoom(BuildContext context) =>
      SpaceManager.arcLabelGap +
      MediaQuery.textScalerOf(context).scale(FontSizeManager.skyLabel) * LineHeightManager.label;

  @override
  ConsumerState<SkyHeader> createState() => _SkyHeaderState();
}

class _SkyHeaderState extends ConsumerState<SkyHeader> {
  /// kept while the colors stay, BmSkyStops has no == and a new one restarts the sky change
  BmSkyStops? _stops;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skyStateProvider);
    final starsOn = ref.watch(starsOnProvider);
    final markerShare = ref.watch(markerShareProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final next = state == null
        ? BmSkyStops(
            context.getColor(ThemeEnum.sky1),
            context.getColor(ThemeEnum.sky2),
            context.getColor(ThemeEnum.sky3),
          )
        : themeSky(ref.watch(themeIdProvider))[state]!;
    final last = _stops;
    final stops =
        last != null && last.top == next.top && last.mid == next.mid && last.bottom == next.bottom
        ? last
        : _stops = next;
    final duration = reduceMotion ? BmMotion.standard : BmMotion.skyChange;
    final curve = reduceMotion ? Curves.linear : BmMotion.sacred;
    return RepaintBoundary(
      child: TweenAnimationBuilder(
        tween: _StopsTween(end: stops),
        duration: duration,
        curve: curve,
        builder: (context, stops, _) => TweenAnimationBuilder(
          tween: Tween(end: starsOn ? 1.0 : 0.0),
          duration: duration,
          curve: curve,
          builder: (context, starsStrength, _) => ArcTurn(
            builder: (context, points, outgoing, turn) => CustomPaint(
              painter: SkyHeaderPainter(
                stops: stops,
                starsStrength: starsStrength,
                points: points,
                markerShare: markerShare,
                outgoing: outgoing,
                turn: turn,
                wheel: !reduceMotion,
                onSky: context.getColor(ThemeEnum.onSky),
                sun: context.getColor(ThemeEnum.sun),
                starOpacity: context.starOpacity,

                /// the .r factor every other size uses, so the arc and the labels stay together
                unit: ScreenUtil().radius(1),
                horizonAboveBottom: SkyHeader.horizonAboveBottom(context).r,
                overlap: widget.overlap,
                bleed: MediaQuery.sizeOf(context).height,
                rtl: Directionality.of(context) == TextDirection.rtl,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StopsTween extends Tween<BmSkyStops> {
  _StopsTween({required super.end});

  @override
  BmSkyStops lerp(double t) => BmSkyStops.lerp(begin ?? end!, end!, t);
}
