import 'dart:async';
import 'dart:ui' as ui;

import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_curl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// turns the mushaf like paper (research R7). a drag to the right or a tap on the left Turn strip
/// opens the next page, the way an arabic book reads, in both languages. Book curls the leaf from its
/// corner over the spine and lets it go on a spring (R13), Slide a 300 ms slide, reduce motion a
/// 150 ms crossfade
class PageTurner extends StatefulWidget {
  const PageTurner({
    required this.page,
    required this.pageBuilder,
    this.book = true,
    this.lift = kAlwaysDismissedAnimation,
    this.onTap,
    this.onEdge,
    this.strip,
    super.key,
  });

  /// the page shown, set here when a turn settles and from outside to jump (the scrubber)
  final ValueNotifier<int> page;
  final Widget Function(int page) pageBuilder;
  final bool book;

  /// how far up the page goes for the ayah sheet, in pixels (4.22)
  final Animation<double> lift;

  /// a tap anywhere but the Turn strips
  final GestureTapUpCallback? onTap;

  /// a tap on a Turn strip, 1 the left one and -1 the right one. the page turns when it's null
  final ValueChanged<int>? onEdge;

  /// each Turn strip's width and height from the top, 44 pt down the whole page when null
  final Size? strip;

  @override
  State<PageTurner> createState() => PageTurnerState();
}

class PageTurnerState extends State<PageTurner> with SingleTickerProviderStateMixin {
  /// -1 the previous page laid over, 0 at rest, 1 the page turned away to the next
  late final _turn = AnimationController.unbounded(vsync: this)..addListener(_snap);
  double _from = 0;

  /// where the running turn goes, -1, 0 or 1
  double _target = 0;
  double _drag = 0;
  double _width = 1;
  double _ratio = 1;

  /// one key per page on its boundary, so a page keeps its element when its wrappers change
  final _keys = <int, GlobalKey>{};

  /// the pages built so far. a page measures every word, so a frame takes at most one new one.
  /// two each side, so a fast reader turns onto a page laid out a turn ago
  final _ready = <int>{};
  static const _around = 2;
  bool _warming = false;

  /// the frame a turn lands in shows the most change, it rebuilds none of the pages it kept
  final _built = <int, Widget>{};

  /// the next page's layout waits this long after a turn lands, it dropped the frames after it
  Timer? _rest;

  /// the leaf's picture while it curls, and which page it is
  final _leaf = ValueNotifier<(int, ui.Image)?>(null);

  /// while a finger is down the page before is painted out of sight, so it can be snapped
  final _parked = ValueNotifier(false);
  ui.FragmentShader? _shader;

  /// how far a page follows the finger past the first or the last page
  static const _rubber = .15;

  /// the leaf is off the page well before the spring is still, its tail only cost frames
  static const _landed = Tolerance(distance: .005, velocity: .1);

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    CurlProgram.load().then((program) {
      if (program == null || !mounted) return;
      setState(() => _shader = program.fragmentShader());
    });
  }

  /// the reader's state reaches the pages through pageBuilder
  @override
  void didUpdateWidget(PageTurner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _built.clear();
  }

  bool _can(double direction) => direction > 0
      ? widget.page.value < quranPageCount
      : direction < 0
      ? widget.page.value > 1
      : true;

  /// one picture of the leaf per turn, taken once a frame has painted it. debugLayer is always
  /// null in profile and release, it hid the curl there. debugNeedsPaint is false there, it only
  /// keeps debug off toImageSync's assert, the next tick tries again
  void _snap() {
    if (!widget.book || _turn.value == 0 || _reduce) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final t = _turn.value;
      if (!mounted || t == 0) return;
      final leaf = t < 0 ? widget.page.value - 1 : widget.page.value;
      if (_leaf.value?.$1 == leaf) return;
      final boundary = _keys[leaf]?.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || !boundary.hasSize || boundary.debugNeedsPaint) {
        return;
      }
      final old = _leaf.value?.$2;
      _leaf.value = (leaf, boundary.toImageSync(pixelRatio: _ratio));
      old?.dispose();
    });
  }

  /// the neighbours come one per frame after the shown page, once the reader is open
  void _warm() {
    if (_warming) return;
    _warming = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _warming = false;
      if (!mounted) return;
      final page = widget.page.value;
      final next = [
        page + 1,
        page - 1,
        page + 2,
        page - 2,
      ].where((n) => n >= 1 && n <= quranPageCount && !_ready.contains(n)).firstOrNull;
      if (next == null) return;
      final far = (next - page).abs() > 1;
      if (far && (_rest?.isActive ?? false)) return;

      /// not while the reader opens or the page moves, a page's layout would drop one of their
      /// frames. a next door page missing mid turn comes anyway, a blank page is worse
      final moving = widget.lift.isAnimating || _turn.isAnimating;
      final opening = ModalRoute.of(context)?.animation?.isCompleted == false;
      if (opening || (moving && far)) {
        _warm();
        SchedulerBinding.instance.scheduleFrame();
        return;
      }
      setState(() => _ready.add(next));
    });
  }

  /// a new mushaf style lays every page out again, the ones beside it come back one per frame
  void relayout() {
    final page = widget.page.value;
    setState(() {
      _ready.removeWhere((n) => n != page);
      _built.removeWhere((n, _) => n != page);
    });
  }

  /// the real page shows again, sharp in the next frame
  void _settle() {
    _parked.value = false;
    _leaf.value?.$2.dispose();
    _leaf.value = null;
  }

  /// a turn still settling looks done, so the page moves on now and the next turn never waits.
  /// the turn shifts with it, the leaf stays where it is on screen
  void _commit() {
    if (_target == 0 || !_turn.isAnimating) return;
    final target = _target;
    _target = 0;
    _turn
      ..stop()
      ..value -= target;
    widget.page.value += target.toInt();
  }

  void _start(DragStartDetails details) {
    _commit();
    _turn.stop();
    _from = _turn.value;
    _drag = 0;
    if (widget.book && !_reduce) _parked.value = true;
  }

  void _update(DragUpdateDetails details) {
    _drag += details.delta.dx;
    if (_reduce) return;
    final value = _from + _drag / _width;
    _turn.value = _can(value.sign) ? value.clamp(-1.0, 1.0) : value * _rubber;
  }

  void _end(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    final value = _reduce ? _drag / _width : _turn.value;
    var target = 0.0;
    if (velocity.abs() > BmMotion.completeVelocity) {
      target = velocity.sign;
    } else if (value.abs() > BmMotion.completeShare) {
      target = value.sign;
    }
    _go(_can(target) ? target : 0, velocity: velocity / _width);
  }

  /// the same turn as a swipe, 1 the next page and -1 the previous
  void turn(int direction) {
    final velocity = _turn.velocity;
    _commit();
    if (!_can(direction.toDouble())) return;

    /// the page laid back is pictured before it curls, as when a finger grabs it
    if (direction < 0 && widget.book && !_reduce) _parked.value = true;
    _go(direction.toDouble(), velocity: velocity);
  }

  /// every move starts from where the page is now, so a grab mid turn carries on from there
  void _go(double target, {double velocity = 0}) {
    _target = target;
    final TickerFuture run;
    if (_reduce) {
      if (target == 0) {
        _target = 0;
        _turn.value = 0;
        _settle();
        return;
      }
      run = _turn.animateTo(target, duration: BmMotion.micro, curve: Curves.linear);
    } else if (!widget.book) {
      run = _turn.animateTo(target, duration: BmMotion.pageSlide, curve: BmMotion.standardCurve);
    } else {
      run = _turn.animateWith(
        SpringSimulation(BmMotion.gentle, _turn.value, target, velocity, tolerance: _landed),
      );
    }

    /// only a run that ends, an interrupted one never resolves
    run.then((_) {
      if (!mounted) return;

      /// the spring stops a hair off 0, a picture still queued for this frame would curl again
      _target = 0;
      _turn.value = 0;
      if (target != 0) {
        _rest?.cancel();
        _rest = Timer(BmMotion.standard, () {
          _warm();
          SchedulerBinding.instance.scheduleFrame();
        });
        widget.page.value += target.toInt();
      }
      _settle();
    });
  }

  @override
  void dispose() {
    _rest?.cancel();
    _turn.dispose();
    _leaf.value?.$2.dispose();
    _leaf.dispose();
    _parked.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ratio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth;
        final strip = widget.strip ?? Size((SizeManager.hit * 0.6).r, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _start,
          onHorizontalDragUpdate: _update,
          onHorizontalDragEnd: _end,
          onTapUp: widget.onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ValueListenableBuilder(
                valueListenable: widget.page,
                builder: (context, page, _) {
                  _keys.removeWhere((n, _) => (n - page).abs() > _around);
                  _built.removeWhere((n, _) => (n - page).abs() > _around);
                  _ready
                    ..removeWhere((n) => (n - page).abs() > _around)
                    ..add(page);
                  _warm();
                  return _Pages(
                    turn: _turn,
                    lift: widget.lift,
                    leaf: _leaf,
                    parked: _parked,
                    shader: _shader,
                    book: widget.book && !_reduce,
                    fade: _reduce,
                    width: _width,
                    pages: {
                      for (var n = page - _around; n <= page + _around; n++)
                        if (_ready.contains(n))
                          n: _built.putIfAbsent(
                            n,
                            () => RepaintBoundary(
                              key: _keys.putIfAbsent(n, GlobalKey.new),
                              child: widget.pageBuilder(n),
                            ),
                          ),
                    },
                    current: page,
                  );
                },
              ),

              /// left and right on the screen in both languages, like the swipe
              Positioned(
                left: 0,
                top: 0,
                width: strip.width,
                height: strip.height,
                child: _Strip(onTap: () => (widget.onEdge ?? turn)(1)),
              ),
              Positioned(
                right: 0,
                top: 0,
                width: strip.width,
                height: strip.height,
                child: _Strip(onTap: () => (widget.onEdge ?? turn)(-1)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// over the words, so a tap here never waits for a double tap. a swipe from it still turns
class _Strip extends StatelessWidget {
  const _Strip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: onTap,
    );
  }
}

/// the current page and the pages around it, only its two neighbours ever shown. a settled page has no transform or opacity layer
/// above it (R11), a turn adds them and the page's key keeps it from being built again
class _Pages extends StatelessWidget {
  const _Pages({
    required this.turn,
    required this.lift,
    required this.leaf,
    required this.parked,
    required this.shader,
    required this.book,
    required this.fade,
    required this.width,
    required this.pages,
    required this.current,
  });

  final Animation<double> turn;
  final Animation<double> lift;
  final ValueListenable<(int, ui.Image)?> leaf;
  final ValueListenable<bool> parked;
  final ui.FragmentShader? shader;
  final bool book;
  final bool fade;
  final double width;
  final Map<int, Widget> pages;
  final int current;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([turn, lift, leaf, parked]),
      builder: (context, _) {
        final t = turn.value.clamp(-1.0, 1.0);
        final cardTransform = Matrix4.translationValues(0, -lift.value, 0);

        /// the leaf on top: the current page turning away, or the previous one coming back
        final leaf = t < 0 ? current - 1 : current;
        final under = t > 0 ? current + 1 : current;
        final snapshot = this.leaf.value;
        final curl = book && t != 0 && snapshot?.$1 == leaf ? snapshot!.$2 : null;

        /// the real leaf waits under its curl. the previous one has no picture the first frame,
        /// so it stays hidden rather than cover the page whole
        final away = book && t != 0 && (curl != null || t < 0) ? leaf : null;
        final order = [
          for (final n in pages.keys)
            if (n != leaf) n,
          leaf,
        ];
        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            for (final n in order)
              if (pages[n] case final child?)
                KeyedSubtree(
                  key: ValueKey(n),
                  child: switch (_shown(n, t, away, under)) {
                    /// painted out of sight, so the turn back can take its picture
                    false when book && parked.value && n == current - 1 => _Placed(
                      transform: Matrix4.translationValues(-2 * width, 0, 0),
                      child: child,
                    ),
                    final shown => _Placed(
                      hidden: !shown,
                      transform: _transform(n, t, cardTransform),
                      opacity: _opacity(n, t),
                      child: child,
                    ),
                  },
                ),
            if (curl != null)
              _Placed(
                transform: cardTransform,
                child: PageCurl(image: curl, progress: t < 0 ? 1 + t : t, shader: shader),
              ),
          ],
        );
      },
    );
  }

  bool _shown(int n, double t, int? away, int under) =>
      n != away && (n == current || (n == current - 1 && t < 0) || (n == under && t > 0));

  Matrix4 _transform(int n, double t, Matrix4 card) {
    if (fade || book) return card;
    final x = switch (n - current) {
      0 => t * width,
      1 => (t - 1) * width,
      _ => (t + 1) * width,
    };
    return Matrix4.identity()
      ..translateByDouble(x, 0, 0, 1)
      ..multiply(card);
  }

  double _opacity(int n, double t) {
    if (!fade) return 1;
    if (t > 0 && n == current) return 1 - t;
    if (t < 0 && n == current - 1) return -t;
    return 1;
  }
}

/// a page in its card, only the layers it needs right now
class _Placed extends StatelessWidget {
  const _Placed({
    required this.transform,
    required this.child,
    this.hidden = false,
    this.opacity = 1,
  });

  final bool hidden;
  final Matrix4 transform;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var page = child;
    if (opacity < 1) {
      page = Opacity(opacity: opacity.clamp(0.0, 1.0), child: page);
    }
    if (!transform.isIdentity()) {
      page = Transform(transform: transform, alignment: Alignment.center, child: page);
    }
    return Offstage(offstage: hidden, child: page);
  }
}
