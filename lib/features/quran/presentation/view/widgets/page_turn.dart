import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/features/quran/presentation/view/widgets/page_curl.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// turns the mushaf like paper (research R7). a drag to the right or a tap on the left edge opens
/// the next page, the way an arabic book reads, in both languages. Book curls the leaf from its
/// corner over the spine and lets it go on a spring (R13), Slide a 300 ms slide, reduce motion a
/// 150 ms crossfade
class PageTurner extends StatefulWidget {
  const PageTurner({
    required this.page,
    required this.pageBuilder,
    this.book = true,
    this.card = kAlwaysDismissedAnimation,
    this.recede = kAlwaysDismissedAnimation,
    this.lift = kAlwaysDismissedAnimation,
    this.onTap,
    super.key,
  });

  /// the page shown, set here when a turn settles and from outside to jump (the scrubber)
  final ValueNotifier<int> page;
  final Widget Function(int page) pageBuilder;
  final bool book;

  /// 0 full page, 1 the card under the controls with the next page peeking (4.21)
  final Animation<double> card;

  /// 0 full page, 1 receded behind the large sheet (4.23)
  final Animation<double> recede;

  /// how far up the page goes for the ayah sheet, in pixels (4.22)
  final Animation<double> lift;

  /// a tap anywhere but the left edge
  final GestureTapUpCallback? onTap;

  @override
  State<PageTurner> createState() => _PageTurnerState();
}

class _PageTurnerState extends State<PageTurner> with SingleTickerProviderStateMixin {
  /// -1 the previous page laid over, 0 at rest, 1 the page turned away to the next
  late final _turn = AnimationController.unbounded(vsync: this)..addListener(_snap);
  double _from = 0;
  double _drag = 0;
  double _width = 1;
  double _ratio = 1;

  /// one key per page on its boundary, so a page keeps its element when its wrappers change
  final _keys = <int, GlobalKey>{};

  /// the leaf's picture while it curls, and which page it is
  final _leaf = ValueNotifier<(int, ui.Image)?>(null);

  /// while a finger is down the page before is painted out of sight, so it can be snapped
  final _parked = ValueNotifier(false);
  ui.FragmentShader? _shader;

  /// how far a page follows the finger past the first or the last page
  static const _rubber = .15;

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    CurlProgram.load().then((program) {
      if (program == null || !mounted) return;
      setState(() => _shader = program.fragmentShader());
    });
  }

  bool _can(double direction) => direction > 0
      ? widget.page.value < quranPageCount
      : direction < 0
      ? widget.page.value > 1
      : true;

  /// one picture of the leaf per turn, taken once a frame has painted it. debugLayer and
  /// debugNeedsPaint are always null and false in profile and release, they hid the curl there
  void _snap() {
    if (!widget.book || _turn.value == 0 || _reduce) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final t = _turn.value;
      if (!mounted || t == 0) return;
      final leaf = t < 0 ? widget.page.value - 1 : widget.page.value;
      if (_leaf.value?.$1 == leaf) return;
      final boundary = _keys[leaf]?.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return;
      _leaf.value?.$2.dispose();
      _leaf.value = (leaf, boundary.toImageSync(pixelRatio: _ratio));
    });
  }

  /// the real page shows again, sharp in the next frame
  void _settle() {
    _parked.value = false;
    _leaf.value?.$2.dispose();
    _leaf.value = null;
  }

  void _start(DragStartDetails details) {
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

  void _tap(TapUpDetails details) {
    if (details.localPosition.dx < _width * SizeManager.turnEdge) {
      if (_can(1)) _go(1);
      return;
    }
    widget.onTap?.call(details);
  }

  /// every move starts from where the page is now, so a grab mid turn carries on from there
  void _go(double target, {double velocity = 0}) {
    final TickerFuture run;
    if (_reduce) {
      if (target == 0) {
        _turn.value = 0;
        _settle();
        return;
      }
      run = _turn.animateTo(target, duration: BmMotion.micro, curve: Curves.linear);
    } else if (!widget.book) {
      run = _turn.animateTo(target, duration: BmMotion.pageSlide, curve: BmMotion.standardCurve);
    } else {
      run = _turn.animateWith(SpringSimulation(BmMotion.gentle, _turn.value, target, velocity));
    }

    /// only a run that ends, an interrupted one never resolves
    run.then((_) {
      if (!mounted) return;

      /// the spring stops a hair off 0, a picture still queued for this frame would curl again
      _turn.value = 0;
      if (target != 0) widget.page.value += target.toInt();
      _settle();
    });
  }

  @override
  void dispose() {
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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _start,
          onHorizontalDragUpdate: _update,
          onHorizontalDragEnd: _end,
          onTapUp: _tap,
          child: ValueListenableBuilder(
            valueListenable: widget.page,
            builder: (context, page, _) {
              _keys.removeWhere((n, _) => (n - page).abs() > 1);
              return _Pages(
                turn: _turn,
                card: widget.card,
                recede: widget.recede,
                lift: widget.lift,
                leaf: _leaf,
                parked: _parked,
                shader: _shader,
                book: widget.book && !_reduce,
                fade: _reduce,
                width: _width,
                pages: {
                  for (final n in [page - 1, page, page + 1])
                    if (n >= 1 && n <= quranPageCount)
                      n: RepaintBoundary(
                        key: _keys.putIfAbsent(n, GlobalKey.new),
                        child: widget.pageBuilder(n),
                      ),
                },
                current: page,
              );
            },
          ),
        );
      },
    );
  }
}

/// the current page and its two neighbours. a settled page has no transform or opacity layer
/// above it (R11), a turn adds them and the page's key keeps it from being built again
class _Pages extends StatelessWidget {
  const _Pages({
    required this.turn,
    required this.card,
    required this.recede,
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
  final Animation<double> card;
  final Animation<double> recede;
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
    final shadow = BoxShadow(
      color: context.getColor(ThemeEnum.gutter).withValues(alpha: .45),
      blurRadius: SizeManager.pageCardShadowBlur.r,
      offset: Offset(0, SizeManager.pageCardShadowY.r),
      spreadRadius: SizeManager.pageCardShadowSpread.r,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([turn, card, recede, lift, leaf, parked]),
      builder: (context, _) {
        final t = turn.value.clamp(-1.0, 1.0);
        final c = card.value;

        /// reduce motion only dims behind the large sheet, the page doesn't scale
        final s = fade ? 0.0 : recede.value;
        final round = math.max(c, s);
        final scale = 1 - (1 - SizeManager.pageCardScale) * c - (1 - SizeManager.pageRecede) * s;
        final lift =
            -SpaceManager.pageCardLift.r * c - this.lift.value - SpaceManager.pageRecedeLift.r * s;
        final cardTransform = Matrix4.identity()
          ..translateByDouble(0, lift, 0, 1)
          ..scaleByDouble(scale, scale, 1, 1);
        final radius = RadiusManager.pageCard.r * round / scale;

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
                  child: switch (_shown(n, t, c, away, under)) {
                    /// painted out of sight, so the turn back can take its picture
                    false when book && parked.value && n == current - 1 => _Placed(
                      transform: Matrix4.translationValues(-2 * width, 0, 0),
                      child: child,
                    ),
                    final shown => _Placed(
                      hidden: !shown,
                      transform: _transform(n, t, c, cardTransform),
                      opacity: _opacity(n, t, c),
                      radius: radius,
                      shadow: n == current && radius > 0 ? shadow : null,
                      child: child,
                    ),
                  },
                ),
            if (curl != null)
              _Placed(
                transform: cardTransform,
                radius: radius,
                child: PageCurl(image: curl, progress: t < 0 ? 1 + t : t, shader: shader),
              ),
          ],
        );
      },
    );
  }

  bool _shown(int n, double t, double c, int? away, int under) =>
      n != away &&
      (n == current ||
          (n == current - 1 && t < 0) ||
          (n == under && t > 0) ||
          (n == current + 1 && t == 0 && c > 0));

  Matrix4 _transform(int n, double t, double c, Matrix4 card) {
    final scale = card.entry(0, 0);
    final lift = card.entry(1, 3);

    /// the next page peeks on the left of the card (4.21)
    if (n == current + 1 && t == 0) {
      return Matrix4.identity()
        ..translateByDouble(-(width * scale + SpaceManager.pagePeekGap.r), lift, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
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

  double _opacity(int n, double t, double c) {
    if (n == current + 1 && t == 0) return .9 * c;
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
    this.radius = 0,
    this.shadow,
  });

  final bool hidden;
  final Matrix4 transform;
  final double opacity;
  final double radius;
  final BoxShadow? shadow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var page = child;
    if (radius > 0 || shadow != null) {
      page = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [?shadow],
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(radius), child: page),
      );
    }
    if (opacity < 1) {
      page = Opacity(opacity: opacity.clamp(0.0, 1.0), child: page);
    }
    if (!transform.isIdentity()) {
      page = Transform(transform: transform, alignment: Alignment.center, child: page);
    }
    return Offstage(offstage: hidden, child: page);
  }
}
