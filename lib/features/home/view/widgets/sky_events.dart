import 'dart:async';
import 'dart:math';

import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/features/home/view/widgets/sky_events_painter.dart';
import 'package:better_muslim/features/home/view/widgets/sky_header.dart';
import 'package:better_muslim/features/home/view_model/home_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the sky comes alive for under 2 s every 6 to 10 s and a second after a tap, between events it
/// draws nothing. paused, not disposed: off the tab, under a page, scrolled away or in the
/// background it just waits
class SkyEvents extends ConsumerStatefulWidget {
  const SkyEvents({required this.collapsed, super.key});

  /// the sky is under the bar, nobody sees it
  final ValueListenable<bool> collapsed;

  @override
  ConsumerState<SkyEvents> createState() => SkyEventsState();
}

class SkyEventsState extends ConsumerState<SkyEvents> with TickerProviderStateMixin {
  static const _most = 3;

  late final AppLifecycleListener _lifecycle;
  final _random = Random();
  final _runs = <({SkyEvent event, AnimationController controller})>[];
  final _waits = <Timer>{};
  Timer? _timer;
  var _foreground = true;
  var _shown = false;

  bool get _live =>
      _shown &&
      _foreground &&
      !widget.collapsed.value &&
      !ref.read(flavorProvider.select((config) => config.isDesignScenario));

  void _setForeground(bool foreground) {
    _foreground = foreground;
    _sync();
  }

  void _sync() {
    if (!_live) {
      _timer?.cancel();
      _timer = null;
      for (final wait in _waits) {
        wait.cancel();
      }
      _waits.clear();
    } else if (_timer == null && _runs.isEmpty && _waits.isEmpty) {
      final gap = BmMotion.skyEventGap + BmMotion.skyEventSpread * _random.nextDouble();
      _timer = Timer(gap, _fire);
    }
  }

  void _fire() {
    _timer = null;
    _play();
  }

  void _play([Offset? tap]) {
    final event = SkyEvent.next(
      _random,
      bright: ref.read(skyBrightProvider),
      sunShare: ref.read(markerShareProvider),
      tap: tap,
    );
    final controller = AnimationController(vsync: this, duration: event.duration);
    final run = (event: event, controller: controller);
    controller
      ..addStatusListener((status) {
        if (!status.isCompleted) return;
        setState(() => _runs.remove(run));
        controller.dispose();
        _sync();
      })
      ..forward();
    setState(() => _runs.add(run));
  }

  /// [at] is in the sky's box, the one this widget fills
  void tap(Offset at) {
    if (!_live || _runs.length + _waits.length >= _most) return;
    _timer?.cancel();
    _timer = null;
    final box = context.size!;
    final spot = Offset(at.dx / box.width, at.dy / box.height);
    late final Timer wait;
    wait = Timer(BmMotion.skyTapDelay, () {
      _waits.remove(wait);
      _play(spot);
    });
    _waits.add(wait);
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => _setForeground(false),
      onShow: () => _setForeground(true),
    );
    widget.collapsed.addListener(_sync);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shown = TickerMode.valuesOf(context).enabled && !MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didUpdateWidget(SkyEvents oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsed == widget.collapsed) return;
    oldWidget.collapsed.removeListener(_sync);
    widget.collapsed.addListener(_sync);
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final wait in _waits) {
      wait.cancel();
    }
    for (final run in _runs) {
      run.controller.dispose();
    }
    widget.collapsed.removeListener(_sync);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_runs.isEmpty) return const SizedBox.shrink();
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            for (final run in _runs)
              CustomPaint(
                key: ObjectKey(run.event),
                painter: SkyEventsPainter(
                  progress: run.controller,
                  event: run.event,
                  onSky: context.getColor(ThemeEnum.onSky),
                  sun: context.getColor(ThemeEnum.sun),
                  strength: context.starOpacity,

                  /// the same factor and horizon as the sky, so a glint leaves from the real sun
                  unit: ScreenUtil().radius(1),
                  horizonAboveBottom: SkyHeader.horizonAboveBottom(context).r,
                  rtl: Directionality.of(context) == TextDirection.rtl,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
