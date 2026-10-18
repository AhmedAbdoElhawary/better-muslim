import 'package:better_muslim/core/power/power_saving.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_sky.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header_painter.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the living sky (MOTION 02, 03). one ticker writes the elapsed time into a notifier the painter
/// listens to, so the loop repaints one layer and rebuilds nothing
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

  @override
  ConsumerState<SkyHeader> createState() => _SkyHeaderState();
}

class _SkyHeaderState extends ConsumerState<SkyHeader> with SingleTickerProviderStateMixin {
  static const _frame = Duration(milliseconds: 33);

  late final Ticker _ticker = createTicker(_onTick);
  final _elapsed = ValueNotifier(Duration.zero);

  /// kept while the colors stay, BmSkyStops has no == and a new one restarts the sky change
  BmSkyStops? _stops;

  void _onTick(Duration elapsed) {
    /// 30 fps is enough for a slow loop and halves the repaints (MOTION tiers)
    if (elapsed - _elapsed.value >= _frame) _elapsed.value = elapsed;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _elapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(skyStateProvider);
    final starsOn = ref.watch(starsOnProvider);
    final sunFraction = ref.watch(sunShareProvider);

    /// unknown while it is read again on resume, so the loop restarts and fades back in
    final powerSavingOff = ref.watch(
      powerSavingProvider.select((saving) => !saving.isLoading && saving.value == false),
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final run = powerSavingOff && !reduceMotion && TickerMode.valuesOf(context).enabled;
    if (run && !_ticker.isActive) {
      _elapsed.value = Duration.zero;
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
    }

    final next = state == null
        ? BmSkyStops(
            context.getColor(ThemeEnum.sky1),
            context.getColor(ThemeEnum.sky2),
            context.getColor(ThemeEnum.sky3),
          )
        : bmSkyQiyamEmerald[state]!;
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
          builder: (context, starsStrength, _) => CustomPaint(
            painter: SkyHeaderPainter(
              stops: stops,
              starsStrength: starsStrength,
              sunFraction: sunFraction,
              onSky: context.getColor(ThemeEnum.onSky),
              sun: context.getColor(ThemeEnum.sun),
              starOpacity: context.starOpacity,

              /// the .r factor every other size uses, so the arc and the labels stay together
              unit: ScreenUtil().radius(1),
              horizonAboveBottom: SkyHeader.horizonAboveBottom(context).r,
              overlap: widget.overlap,
              bleed: MediaQuery.sizeOf(context).height,
              rtl: Directionality.of(context) == TextDirection.rtl,
              elapsed: run ? _elapsed : null,
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
