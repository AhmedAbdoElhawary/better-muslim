import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:better_muslim/core/monitoring/crash_reporter.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// the curl shader, loaded once. null where the load failed (tests), the leaf slides flat then
abstract final class CurlProgram {
  static Future<ui.FragmentProgram?>? _program;

  static Future<ui.FragmentProgram?> load() => _program ??= _load();

  static Future<ui.FragmentProgram?> _load() async {
    try {
      return await ui.FragmentProgram.fromAsset('shaders/page_curl.frag');
    } catch (error, stack) {
      await CrashReporter.instance.recordError(error, stack, context: {'reason': 'curl shader'});
      return null;
    }
  }
}

/// the leaf's snapshot curled [progress] of the way from the left edge over the spine
class PageCurl extends StatelessWidget {
  const PageCurl({required this.image, required this.progress, required this.shader, super.key});

  final ui.Image image;

  /// 0 flat on the page, 1 turned away
  final double progress;
  final ui.FragmentShader? shader;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _CurlPainter(
        image: image,
        progress: progress,
        shader: shader,
        paper: context.getColor(ThemeEnum.page),
        shadow: context.getColor(ThemeEnum.gutter),
        radius: SizeManager.curlRadius.r,
        tilt: SizeManager.curlTilt.r,
      ),
    );
  }
}

class _CurlPainter extends CustomPainter {
  _CurlPainter({
    required this.image,
    required this.progress,
    required this.shader,
    required this.paper,
    required this.shadow,
    required this.radius,
    required this.tilt,
  });

  final ui.Image image;
  final double progress;
  final ui.FragmentShader? shader;
  final Color paper;
  final Color shadow;
  final double radius;
  final double tilt;

  @override
  void paint(Canvas canvas, Size size) {
    final src = Offset.zero & Size(image.width.toDouble(), image.height.toDouble());
    final shader = this.shader;
    if (shader == null) {
      canvas.drawImageRect(image, src, Offset(progress * size.width, 0) & size, Paint());
      return;
    }

    /// the corner reaches twice the width when the leaf has gone over the spine, it lifts most
    /// halfway so the fold runs on a slant
    final corner = Offset(
      2 * size.width * progress,
      size.height - tilt * math.sin(math.pi * progress),
    );
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, corner.dx)
      ..setFloat(3, corner.dy)
      ..setFloat(4, radius)
      ..setFloat(5, paper.r)
      ..setFloat(6, paper.g)
      ..setFloat(7, paper.b)
      ..setFloat(8, SizeManager.curlBackShade)
      ..setFloat(9, shadow.r)
      ..setFloat(10, shadow.g)
      ..setFloat(11, shadow.b)
      /// the fold's shadow stays on the page after the leaf has left it, so it fades before landing
      ..setFloat(
        12,
        SizeManager.curlShadow * ((1 - progress) / SizeManager.curlShadowFade).clamp(0, 1),
      )
      ..setImageSampler(0, image, filterQuality: FilterQuality.low);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_CurlPainter old) =>
      old.image != image ||
      old.progress != progress ||
      old.shader != shader ||
      old.paper != paper ||
      old.shadow != shadow ||
      old.radius != radius ||
      old.tilt != tilt;
}
