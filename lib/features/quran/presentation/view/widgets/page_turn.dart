import 'dart:math' as math;

import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// turns the mushaf like paper (research R7). a drag to the right or a tap on the left edge opens
/// the next page, the way an arabic book reads, in both languages. Book is a leaf on the spine
/// released on a spring, Slide a 300 ms slide, reduce motion a 150 ms crossfade
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
  late final _turn = AnimationController.unbounded(vsync: this);
  double _from = 0;
  double _drag = 0;
  double _width = 1;

  /// how far a page follows the finger past the first or the last page
  static const _rubber = .15;

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  bool _can(double direction) => direction > 0
      ? widget.page.value < quranPageCount
      : direction < 0
      ? widget.page.value > 1
      : true;

  void _start(DragStartDetails details) {
    _turn.stop();
    _from = _turn.value;
    _drag = 0;
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
      if (target == 0 || !mounted) return;
      _turn.value = 0;
      widget.page.value += target.toInt();
    });
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            builder: (context, page, _) => _Pages(
              turn: _turn,
              card: widget.card,
              recede: widget.recede,
              lift: widget.lift,
              book: widget.book && !_reduce,
              fade: _reduce,
              width: _width,
              pages: {
                for (final n in [page - 1, page, page + 1])
                  if (n >= 1 && n <= quranPageCount) n: widget.pageBuilder(n),
              },
              current: page,
            ),
          ),
        );
      },
    );
  }
}

/// the current page and its two neighbours, each in the same wrappers whatever its role, so a
/// turn never rebuilds or lays a page out again
class _Pages extends StatelessWidget {
  const _Pages({
    required this.turn,
    required this.card,
    required this.recede,
    required this.lift,
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
  final bool book;
  final bool fade;
  final double width;
  final Map<int, Widget> pages;
  final int current;

  @override
  Widget build(BuildContext context) {
    final shade = context.getColor(ThemeEnum.gutter);
    final shadow = BoxShadow(
      color: shade.withValues(alpha: .45),
      blurRadius: SizeManager.pageCardShadowBlur.r,
      offset: Offset(0, SizeManager.pageCardShadowY.r),
      spreadRadius: SizeManager.pageCardShadowSpread.r,
    );
    return AnimatedBuilder(
      animation: Listenable.merge([turn, card, recede, lift]),
      builder: (context, _) {
        final t = turn.value.clamp(-1.0, 1.0);
        final c = card.value;

        /// reduce motion only dims behind the large sheet, the page doesn't scale
        final s = fade ? 0.0 : recede.value;
        final round = math.max(c, s);
        final scale = 1 - (1 - SizeManager.pageCardScale) * c - (1 - SizeManager.pageRecede) * s;
        final lift =
            -SpaceManager.pageCardLift.r * c - this.lift.value - SpaceManager.pageRecedeLift.r * s;

        /// the leaf on top: the current page turning away, or the previous one coming back
        final leaf = t < 0 ? current - 1 : current;
        final under = t > 0 ? current + 1 : current;
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
                  child: _Placed(
                    hidden:
                        !(n == current || (n == leaf && t < 0) || (n == under && t > 0)) &&
                        !(n == current + 1 && t == 0 && c > 0),
                    transform: _transform(n, t, c, scale, lift),
                    opacity: _opacity(n, t, c),
                    radius: RadiusManager.pageCard.r * round / scale,
                    shadow: n == current && round > 0 ? shadow : null,
                    tint: _tint(n, t, shade),
                    child: child,
                  ),
                ),
          ],
        );
      },
    );
  }

  Matrix4 _transform(int n, double t, double c, double scale, double lift) {
    final card = Matrix4.identity()
      ..translateByDouble(0, lift, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);

    /// the next page peeks on the left of the card (4.21)
    if (n == current + 1 && t == 0) {
      return Matrix4.identity()
        ..translateByDouble(-(width * scale + SpaceManager.pagePeekGap.r), lift, 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    if (fade) return card;
    final leaf = t < 0 ? current - 1 : current;
    if (book) {
      if (n != leaf) return card;
      final angle = t < 0 ? (1 + t) * math.pi / 2 : t * math.pi / 2;

      /// turned on the spine at the right edge, its free edge comes toward me as it lifts
      return Matrix4.identity()
        ..setEntry(3, 2, _perspective / width)
        ..multiply(card)
        ..translateByDouble(width / 2, 0, 0, 1)
        ..rotateY(-angle)
        ..translateByDouble(-width / 2, 0, 0, 1);
    }
    final x = switch (n - current) {
      0 => t * width,
      1 => (t - 1) * width,
      _ => (t + 1) * width,
    };
    return Matrix4.identity()
      ..translateByDouble(x, 0, 0, 1)
      ..multiply(card);
  }

  /// css perspective 1400px over the 393 wide page
  static const _perspective = 393 / 1400;

  double _opacity(int n, double t, double c) {
    if (n == current + 1 && t == 0) return .9 * c;
    if (!fade) return 1;
    if (t > 0 && n == current) return 1 - t;
    if (t < 0 && n == current - 1) return -t;
    return 1;
  }

  /// the leaf darkens as it lifts, the page under it takes the leaf's shadow
  (Color, Color, double)? _tint(int n, double t, Color shade) {
    if (!book || t == 0) return null;
    final leaf = t < 0 ? current - 1 : current;
    final progress = t.abs();
    if (n == leaf) {
      final strength = t < 0 ? 1 - progress : progress;
      return (shade.withValues(alpha: 0), shade.withValues(alpha: .35 * strength), 1);
    }
    return (
      shade.withValues(alpha: .35 * math.sin(math.pi * progress)),
      shade.withValues(alpha: 0),
      .6,
    );
  }
}

class _Placed extends StatelessWidget {
  const _Placed({
    required this.hidden,
    required this.transform,
    required this.opacity,
    required this.radius,
    required this.shadow,
    required this.tint,
    required this.child,
  });

  final bool hidden;
  final Matrix4 transform;
  final double opacity;
  final double radius;
  final BoxShadow? shadow;

  /// a left to right gradient over the page, its two ends and where the second one sits
  final (Color, Color, double)? tint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tint = this.tint;
    return Offstage(
      offstage: hidden,
      child: Transform(
        transform: transform,
        alignment: Alignment.center,
        child: CustomOpacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              boxShadow: [?shadow],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              clipBehavior: radius > 0 ? Clip.antiAlias : Clip.none,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  gradient: tint == null
                      ? null
                      : LinearGradient(colors: [tint.$1, tint.$2], stops: [0, tint.$3]),
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
