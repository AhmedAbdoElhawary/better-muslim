import 'dart:ui';

import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// with the top glow off, the bars' plain glass
const _plainOpacity = .8;

/// the bars' frosted surface: what scrolls under it shows blurred through the surface tint
class Glass extends ConsumerWidget {
  const Glass({this.border, this.child, super.key});
  final Border? border;

  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opacity = ref.watch(topGlowProvider) ? BmGlass.surfaceOpacity : _plainOpacity;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: BmGlass.blurSigma, sigmaY: BmGlass.blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.surface).withValues(alpha: opacity),
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}
