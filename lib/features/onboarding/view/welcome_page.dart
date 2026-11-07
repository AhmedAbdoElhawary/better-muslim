import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:better_muslim/core/extensions/l10n.dart';
import 'package:better_muslim/core/resources/design/bm_haptics.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/widgets/step/step_scope.dart';
import 'package:better_muslim/features/onboarding/model/lens_spec.dart';
import 'package:better_muslim/features/onboarding/model/sun_choreography.dart';
import 'package:better_muslim/features/onboarding/view/widgets/glass/liquid_glass.dart';
import 'package:better_muslim/features/onboarding/view/widgets/intro_layer.dart';
import 'package:better_muslim/features/onboarding/view/widgets/welcome_layer.dart';
import 'package:better_muslim/features/onboarding/view/widgets/welcome_sky.dart';
import 'package:better_muslim/features/onboarding/view/widgets/welcome_stars.dart';
import 'package:better_muslim/features/onboarding/view/widgets/welcome_sun.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// the first screen and 4.10 on one page, so the sun moves between them without a route change.
/// the reference's page state on 4.10's geometry (R4): the sun follows the finger, springs to
/// its rest spot, and the welcome builds out of it on b
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> with TickerProviderStateMixin {
  /// the welcome's build, 0 to 1
  late final AnimationController _build = AnimationController(vsync: this);

  /// the first screen coming in from the splash (FR-006)
  late final AnimationController _entrance = AnimationController(vsync: this);

  /// the stars fade over 1.4 s when the sun sinks back
  late final AnimationController _stars = AnimationController(vsync: this, value: 1);

  late final Ticker _ticker = createTicker(_onTick);
  final _frame = ValueNotifier(0);
  final _ready = ValueNotifier(false);
  late final AppLifecycleListener _lifecycle;

  ui.FragmentShader? _shader;
  SunChoreography? _ch;
  var _stage = SunStage.intro;

  /// the rest spot the sun springs to
  var _home = SunStage.intro;
  var _forward = false;
  var _backward = false;
  var _reduce = false;
  var _entered = false;

  Offset? _ball;
  var _velocity = Offset.zero;

  /// smoothed, drives the squash and stretch
  var _lensVelocity = Offset.zero;
  var _glow = 0.0;

  /// seconds of the flash when the sun sinks back
  var _glowPulse = 0.0;
  var _fill = 0.0;

  /// the build value the stars fly on, it only grows during a build
  var _flight = 0.0;

  /// reduce motion moves the sun to its rest spot in 300 ms instead of a spring
  Offset? _releaseFrom;
  var _releaseT = 1.0;

  int? _pointer;
  VelocityTracker? _tracker;
  var _dragging = false;
  var _finger = Offset.zero;
  var _lastFinger = Offset.zero;
  var _grabOffset = Offset.zero;
  var _grabTravel = 0.0;
  var _pastLine = false;

  /// a grab stops the build where it is, the drag down only takes it further back
  var _grabB = 1.0;

  var _lastTick = Duration.zero;

  /// the entrance's parts: the sky, then the dome rising, then the words
  static const _skyIn = Interval(0, .35);
  static const _domeAt = .15;
  static const _wordsIn = Interval(.55, 1);

  bool get _committing => _forward || _backward;

  @override
  void initState() {
    super.initState();

    /// the app leaving mid drag lets the sun spring home
    _lifecycle = AppLifecycleListener(onInactive: _drop);
    GlassProgram.load().then((program) {
      if (program != null && mounted) setState(() => _shader = program.fragmentShader());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    if (_entered) return;
    _entered = true;
    _entrance
      ..duration = _reduce ? BmMotion.standard : SunChoreography.entrance
      ..forward();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _ticker.dispose();
    _build.dispose();
    _entrance.dispose();
    _stars.dispose();
    _frame.dispose();
    _ready.dispose();
    _shader?.dispose();
    super.dispose();
  }

  Offset _restSpot(SunChoreography ch) => _home == SunStage.main ? ch.restCenter : ch.domeCenter;

  void _ensureTicking() {
    if (_ticker.isActive) return;
    _lastTick = Duration.zero;
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 1 / 60
        : ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(1 / 240, 1 / 20);
    _lastTick = elapsed;
    final ch = _ch;
    var ball = _ball;
    if (ch == null || ball == null) return;
    final rest = _restSpot(ch);

    if (_dragging) {
      /// it starts where it is and catches up with the finger, so a grab never jumps
      final keep = (1 - _grabTravel / SunChoreography.grabCatchUp).clamp(0.0, 1.0);
      final target = _finger + _grabOffset * keep;
      final next = Offset.lerp(ball, target, 1 - math.exp(-dt * 30))!;
      _velocity = (next - ball) / dt;
      ball = next;
    } else if (_entrance.isAnimating && _entrance.value < _domeAt) {
      /// the dome waits under the edge while the sky comes in
    } else if (_reduce) {
      _releaseT = math.min(1, _releaseT + dt / (BmMotion.standard.inMicroseconds / 1e6));
      ball = Offset.lerp(_releaseFrom ?? ball, rest, BmMotion.standardCurve.transform(_releaseT));
      _velocity = Offset.zero;
    } else {
      /// two sub steps keep the spring stable
      final step = dt / 2;
      for (var i = 0; i < 2; i++) {
        final pull = (rest - ball!) * SunChoreography.springK - _velocity * SunChoreography.springC;
        _velocity += pull * step;
        ball += _velocity * step;
      }
    }
    _ball = ball;
    final at = ball!;

    final lift = ch.liftAt(at.dy);
    if (_dragging && _stage == SunStage.intro && !_committing) {
      final ready = at.dy <= ch.startLine;
      if (ready != _ready.value) {
        _ready.value = ready;
        if (ready) BmHaptics.selection();
      }
    }
    if (_dragging && _stage == SunStage.main) _updateReverse(ch, at);

    var glowTarget = _dragging && _stage == SunStage.intro ? ch.glowForLift(lift) : 0.0;
    if (_glowPulse > 0) {
      _glowPulse -= dt;
      glowTarget = math.max(glowTarget, .9);
    }
    _glow += (glowTarget - _glow) * (1 - math.exp(-dt * 10));

    /// glass while held, the sun's color as it settles on the horizon (FR-008, FR-013)
    final fillTarget = !_dragging && _home == SunStage.main ? ch.fillAt(_build.value) : 0.0;
    _fill += (fillTarget - _fill) * (1 - math.exp(-dt * 12));
    _lensVelocity = Offset.lerp(_lensVelocity, _velocity, 1 - math.exp(-dt * 14))!;
    _frame.value++;

    final settled =
        !_dragging &&
        (at - rest).distance < .3 &&
        _velocity.distance < 2 &&
        _glow < .002 &&
        (_fill - fillTarget).abs() < .002 &&
        !_entrance.isAnimating;
    if (settled && !_build.isAnimating) {
      _ball = rest;
      _velocity = Offset.zero;
      _lensVelocity = Offset.zero;
      _fill = fillTarget;
      _ticker.stop();
      _frame.value++;
    }
  }

  LensSpec _lens() {
    final ch = _ch;
    final ball = _ball;
    if (ch == null || ball == null) return LensSpec.hidden;
    return ch.lensAt(
      ball,
      glow: _glow,
      velocity: _reduce ? Offset.zero : _lensVelocity,
      fill: _fill,
      opacity: 1 - _fill,

      /// settled, the tree's box hides the sun below the horizon
      clipY: _home == SunStage.main && !_dragging ? ch.horizonY : double.infinity,
    );
  }

  Offset _local(Offset global) {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? global : box.globalToLocal(global);
  }

  /// only the first finger moves the sun, flutter's drag recognizer would hand it to the newest
  void _onDown(PointerDownEvent event) {
    final ball = _ball;
    if (_pointer != null || ball == null || _backward) return;
    if (_forward) {
      _forward = false;
      setState(() => _stage = SunStage.main);
    }
    _pointer = event.pointer;
    _tracker = VelocityTracker.withKind(event.kind)..addPosition(event.timeStamp, event.position);
    _finger = _lastFinger = _local(event.position);
    _grabOffset = ball - _finger;
    _grabTravel = 0;
    _dragging = true;
    _pastLine = false;
    _grabB = _build.value;
    _build.stop();
    _ensureTicking();
  }

  void _onMove(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    _tracker?.addPosition(event.timeStamp, event.position);
    final finger = _local(event.position);
    _grabTravel += (finger - _lastFinger).distance;
    _lastFinger = _finger = finger;
  }

  void _onUp(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final velocity = _tracker?.getVelocity().pixelsPerSecond ?? Offset.zero;

    /// a tap on the sun starts the welcome like a drag does (FR-011)
    if (_grabTravel < kTouchSlop && _stage == SunStage.intro) {
      _endDrag();
      _commitForward();
      return;
    }
    _release(velocity);
  }

  void _onCancel(PointerCancelEvent event) {
    if (event.pointer == _pointer) _drop();
  }

  /// a cancelled pointer is no answer, the sun goes back to where it rests and nothing starts
  void _drop() {
    if (!_dragging) return;
    _endDrag();
    _velocity = Offset.zero;
    _ready.value = false;
    if (_stage == SunStage.main) _rebuild();
  }

  void _endDrag() {
    _pointer = null;
    _tracker = null;
    _dragging = false;
    _releaseFrom = _ball;
    _releaseT = 0;
    _ensureTicking();
  }

  void _release(Offset velocity) {
    if (!_dragging) return;
    _endDrag();
    final ch = _ch!;
    final ball = _ball!;

    /// some of the throw goes into the spring, so the landing feels physical
    final carry = velocity * SunChoreography.throwCarry;
    _velocity = carry.distance > SunChoreography.maxThrow
        ? carry / carry.distance * SunChoreography.maxThrow
        : carry;

    if (_stage == SunStage.intro) {
      _ready.value = false;
      final passed = ball.dy <= ch.startLine;

      /// the finger, on a fast flick the sun can be a frame behind
      final flick = velocity.dy < -SunChoreography.flickUp && ch.liftAt(_finger.dy) > .2;
      if (passed || flick) _commitForward();
      return;
    }

    final flick = velocity.dy > SunChoreography.flickDown && ball.dy > ch.h * .5;
    if (_reverseFraction(ch, ball) >= SunChoreography.commitFraction || flick) {
      _commitBackward();
      return;
    }

    _rebuild();
  }

  /// back onto the horizon, the welcome builds again
  void _rebuild() {
    final duration = _reduce ? BmMotion.standard : SunChoreography.rebuild * (1 - _build.value);
    if (duration > Duration.zero) {
      _build.animateTo(1, duration: duration, curve: Curves.easeOutCubic);
    }
  }

  /// the first screen to 4.10
  void _commitForward() {
    if (_committing || _stage == SunStage.main) return;
    BmHaptics.sunLetGo();
    _ready.value = false;
    setState(() {
      _forward = true;
      _home = SunStage.main;
    });
    _releaseFrom = _ball;
    _releaseT = 0;
    _flight = 0;
    _stars.value = 1;
    _ensureTicking();
    _build.value = 0;
    _build
        .animateTo(1, duration: _reduce ? BmMotion.standard : SunChoreography.build)
        .whenCompleteOrCancel(() {
          if (!mounted || !_forward) return;
          setState(() {
            _forward = false;
            _stage = SunStage.main;
          });
        });
  }

  /// a tap anywhere while it builds ends the build at once (FR-013)
  void _finishBuild(PointerDownEvent _) {
    if (_forward) _build.value = 1;
  }

  double _reverseFraction(SunChoreography ch, Offset ball) =>
      ((ball.dy - ch.reverseZoneTop) / ch.reverseZoneLength).clamp(0.0, 1.0);

  void _updateReverse(SunChoreography ch, Offset ball) {
    final r = _reverseFraction(ch, ball);
    final b = math.min(_grabB, 1 - r);
    if ((_build.value - b).abs() > 1e-4) _build.value = b;
    final past = r >= SunChoreography.commitFraction;
    if (past != _pastLine) {
      _pastLine = past;
      if (past) BmHaptics.selection();
    }
  }

  /// 4.10 back to the first screen
  void _commitBackward() {
    if (_backward) return;
    BmHaptics.sunLetGo();
    setState(() {
      _backward = true;
      _home = SunStage.intro;
    });
    _releaseFrom = _ball;
    _releaseT = 0;
    _glowPulse = _reduce ? 0 : SunChoreography.glowFlash;
    _stars.animateTo(0, duration: _reduce ? BmMotion.standard : SunChoreography.starsFade);
    final duration = _reduce
        ? BmMotion.standard
        : SunChoreography.unbuild * math.max(_build.value, .01);
    _ensureTicking();
    _build.animateTo(0, duration: duration, curve: Curves.easeOutCubic).whenCompleteOrCancel(() {
      if (!mounted) return;
      setState(() {
        _stage = SunStage.intro;
        _backward = false;
        _pastLine = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final scope = StepScope.maybeOf(context);
    final secondary = scope?.secondaryAnimation ?? kAlwaysDismissedAnimation;

    return PopScope(
      canPop: _stage == SunStage.intro && !_committing,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage == SunStage.main) _commitBackward();
      },
      child: AnnotatedRegion(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
          body: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _finishBuild,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final ch = _ch = SunChoreography(
                  constraints.biggest,
                  MediaQuery.paddingOf(context),
                  unit: ScreenUtil().radius(1),
                );
                final rest = _restSpot(ch);
                if (_ball == null) {
                  _ball = _reduce ? rest : ch.entranceStart;
                  _releaseFrom = _ball;
                  WidgetsBinding.instance.addPostFrameCallback((_) => _ensureTicking());
                } else if (!_dragging && !_ticker.isActive) {
                  _ball = rest;
                }
                final restRadius = _home == SunStage.main ? ch.restRadius : ch.domeRadius;
                return AnimatedBuilder(
                  animation: Listenable.merge([_frame, _build, _entrance, _stars, secondary]),
                  builder: (context, _) {
                    final b = _build.value;
                    if (_forward) _flight = math.max(_flight, b);
                    final ball = _ball ?? rest;

                    /// 4.11 covering it over its first 300 ms, back over all of its pop
                    final covered = secondary.status == AnimationStatus.reverse
                        ? secondary.value
                        : (secondary.value / .33).clamp(0.0, 1.0);
                    double out(WelcomePart part) => 1 - SunChoreography.covered(covered, part);
                    final shown = _reduce ? _entrance.value : _wordsIn.transform(_entrance.value);
                    final glass = _fill < .999 || _dragging;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        WelcomeSky(
                          ch: ch,
                          shown: _reduce ? _entrance.value : _skyIn.transform(_entrance.value),
                          horizon: ch.horizonIn(b) * out(WelcomePart.sky),
                          mark: ch.markIn(b) * out(WelcomePart.sky),
                        ),
                        WelcomeStars(
                          ch: ch,
                          origin: ball,
                          flight: _flight,
                          shown: _stars.value * out(WelcomePart.stars),
                        ),
                        WelcomeSun(
                          center: ball,
                          radius: ch.restRadius,
                          opacity: _fill,
                          horizonY: ch.horizonY,
                          unit: ch.unit,
                        ),
                        IntroLayer(
                          ch: ch,
                          lift: ch.liftAt(ball.dy),
                          b: b,
                          shown: shown,
                          ready: _ready,
                          onBegin: _stage == SunStage.intro && !_committing ? _commitForward : null,
                        ),
                        WelcomeLayer(
                          ch: ch,
                          b: b,
                          covered: covered,
                          interactive: _home == SunStage.main && !_backward,
                          onGetStarted: () => context.push(Routes.onboardingLocation),
                        ),
                        if (glass)
                          IgnorePointer(
                            child: SunGlass(shader: _shader, lens: _lens, repaint: _frame),
                          ),
                        if (!_backward)
                          Positioned.fromRect(
                            rect: Rect.fromCircle(center: rest, radius: restRadius + ch.grabMargin),
                            child: Semantics(
                              button: true,
                              label: context.tr(
                                _stage == SunStage.intro
                                    ? StringsManager.sunHint
                                    : StringsManager.sunBackHint,
                              ),
                              onTap: _stage == SunStage.intro && !_committing
                                  ? _commitForward
                                  : null,
                              child: Listener(
                                behavior: HitTestBehavior.opaque,
                                onPointerDown: _onDown,
                                onPointerMove: _onMove,
                                onPointerUp: _onUp,
                                onPointerCancel: _onCancel,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
