import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/features/onboarding/model/lens_spec.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// the shader, loaded once. null where the engine can't filter with a shader (skia, tests) or the
/// load failed, the frosted glass shows then
abstract final class GlassProgram {
  static Future<ui.FragmentProgram?>? _program;

  static Future<ui.FragmentProgram?> load() => _program ??= _load();

  static Future<ui.FragmentProgram?> _load() async {
    if (!ui.ImageFilter.isShaderFilterSupported) return null;
    try {
      return await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
    } catch (error, stack) {
      await CrashReporter.instance.recordError(error, stack, context: {'reason': 'glass shader'});
      return null;
    }
  }
}

/// the refracting glass where the shader runs, the frosted one elsewhere (FR-007)
class SunGlass extends StatelessWidget {
  const SunGlass({required this.shader, required this.lens, required this.repaint, super.key});

  final ui.FragmentShader? shader;
  final ValueGetter<LensSpec> lens;
  final Listenable repaint;

  @override
  Widget build(BuildContext context) {
    final shader = this.shader;
    final glow = context.getColor(ThemeEnum.glow);
    final sun = context.getColor(ThemeEnum.sun);
    if (shader == null) {
      return FallbackGlass(lens: lens, repaint: repaint, glow: glow, sun: sun);
    }
    return LiquidGlassLayer(shader: shader, lens: lens, repaint: repaint, glow: glow, sun: sun);
  }
}

/// a full screen backdrop filter running liquid_glass.frag. a render object, not BackdropFilter:
/// two shader filters on the same FragmentShader compare equal, so BackdropFilter would never
/// repaint when only the uniforms change
class LiquidGlassLayer extends LeafRenderObjectWidget {
  const LiquidGlassLayer({
    required this.shader,
    required this.lens,
    required this.repaint,
    required this.glow,
    required this.sun,
    super.key,
  });

  final ui.FragmentShader shader;
  final ValueGetter<LensSpec> lens;
  final Listenable repaint;
  final Color glow;
  final Color sun;

  @override
  RenderLiquidGlass createRenderObject(BuildContext context) =>
      RenderLiquidGlass(shader: shader, lens: lens, repaint: repaint, glow: glow, sun: sun);

  @override
  void updateRenderObject(BuildContext context, RenderLiquidGlass renderObject) {
    renderObject
      ..shader = shader
      ..lens = lens
      ..repaint = repaint
      ..glow = glow
      ..sun = sun;
  }
}

class RenderLiquidGlass extends RenderBox {
  RenderLiquidGlass({
    required this._shader,
    required this._lens,
    required this._repaint,
    required this._glow,
    required this._sun,
  });

  ui.FragmentShader _shader;
  set shader(ui.FragmentShader value) {
    if (identical(value, _shader)) return;
    _shader = value;
    markNeedsPaint();
  }

  ValueGetter<LensSpec> _lens;
  set lens(ValueGetter<LensSpec> value) {
    _lens = value;
    markNeedsPaint();
  }

  Listenable _repaint;
  set repaint(Listenable value) {
    if (identical(value, _repaint)) return;
    if (attached) _repaint.removeListener(markNeedsPaint);
    _repaint = value;
    if (attached) _repaint.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Color _glow;
  set glow(Color value) {
    if (value == _glow) return;
    _glow = value;
    markNeedsPaint();
  }

  Color _sun;
  set sun(Color value) {
    if (value == _sun) return;
    _sun = value;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    final spec = _lens();

    /// 0 and 1 are the input size, the engine fills them (contracts/liquid-glass-shader.md)
    var i = 2;
    _shader
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height)
      ..setFloat(i++, spec.center.dx)
      ..setFloat(i++, spec.center.dy)
      ..setFloat(i++, spec.radius)
      ..setFloat(i++, spec.magnify)
      ..setFloat(i++, spec.refraction)
      ..setFloat(i++, spec.chroma)
      ..setFloat(i++, spec.glow)
      ..setFloat(i++, spec.opacity)
      ..setFloat(i++, spec.velocity.dx)
      ..setFloat(i++, spec.velocity.dy)
      ..setFloat(i++, spec.shadow)
      ..setFloat(i++, spec.specular)
      ..setFloat(i++, spec.rimLight)
      ..setFloat(i++, _glow.r)
      ..setFloat(i++, _glow.g)
      ..setFloat(i++, _glow.b)
      ..setFloat(i++, spec.fill)
      ..setFloat(i++, _sun.r)
      ..setFloat(i++, _sun.g)
      ..setFloat(i++, _sun.b)
      ..setFloat(i++, spec.clipY.isFinite ? spec.clipY : size.height * 2);

    /// a new layer every paint, the engine copies the uniforms at that moment
    context.pushLayer(
      BackdropFilterLayer(filter: ui.ImageFilter.shader(_shader)),
      (context, offset) {},
      offset,
    );
  }
}

/// a frosted disc with the same size, rim, glow arc, fill and clip, where the shader can't run
class FallbackGlass extends StatelessWidget {
  const FallbackGlass({
    required this.lens,
    required this.repaint,
    required this.glow,
    required this.sun,
    super.key,
  });

  final ValueGetter<LensSpec> lens;
  final Listenable repaint;
  final Color glow;
  final Color sun;

  static const _frostSigma = 1.5;

  @override
  Widget build(BuildContext context) {
    final bright = context.getColor(ThemeEnum.onSkyBright);
    return AnimatedBuilder(
      animation: repaint,
      builder: (context, _) {
        final spec = lens();
        if (spec.radius < .5 || spec.opacity <= 0) return const SizedBox.shrink();
        return ClipRect(
          clipper: _AboveClip(spec.clipY),
          child: Stack(
            children: [
              Positioned.fromRect(
                rect: spec.bounds,
                child: Opacity(
                  opacity: spec.opacity,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: _frostSigma, sigmaY: _frostSigma),
                      child: CustomPaint(
                        painter: _FallbackLensPainter(spec, bright: bright, glow: glow, sun: sun),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AboveClip extends CustomClipper<Rect> {
  _AboveClip(this.y);

  final double y;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(0, 0, size.width, math.min(y, size.height));

  @override
  bool shouldReclip(_AboveClip old) => old.y != y;
}

class _FallbackLensPainter extends CustomPainter {
  _FallbackLensPainter(this.spec, {required this.bright, required this.glow, required this.sun});

  final LensSpec spec;
  final Color bright;
  final Color glow;
  final Color sun;

  /// the reference's white at 8, 3, 30 and 80%, on the sky's own bright color
  static const _frost = [.08, .03, .30];
  static const _rim = .80;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = ui.Gradient.radial(
          c.translate(0, -r * .3),
          r,
          [for (final alpha in _frost) bright.withValues(alpha: alpha)],
          const [0, .6, 1],
        ),
    );
    if (spec.fill > 0) {
      canvas.drawCircle(c, r, Paint()..color = sun.withValues(alpha: spec.fill));
    }

    if (spec.glow > .01) {
      canvas.drawArc(
        rect.deflate(r * .24),
        math.pi * .12,
        math.pi * .76,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .12
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .05)
          ..shader = ui.Gradient.sweep(
            c,
            [
              Color.lerp(glow, sun, .5)!.withValues(alpha: spec.glow),
              glow.withValues(alpha: spec.glow),
              Color.lerp(glow, sun, .5)!.withValues(alpha: spec.glow),
            ],
            const [.1, .25, .4],
          ),
      );
    }

    canvas.drawCircle(
      c,
      r - SizeManager.divider * .75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = SizeManager.divider * 1.5
        ..color = bright.withValues(alpha: _rim),
    );
  }

  @override
  bool shouldRepaint(_FallbackLensPainter old) => true;
}
