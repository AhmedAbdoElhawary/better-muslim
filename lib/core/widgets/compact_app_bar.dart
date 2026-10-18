import 'dart:ui';

import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

const _surfaceOpacity = .8;

/// the components' 56 pt compact bar on a blurred surface, the back chevron only on pushed pages
class CompactAppBar extends StatelessWidget {
  const CompactAppBar(this.title, {this.back = true, super.key});

  /// a StringsManager key
  final String title;
  final bool back;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: BmGlass.blurSigma, sigmaY: BmGlass.blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.getColor(ThemeEnum.surface).withValues(alpha: _surfaceOpacity),
            border: Border(bottom: BorderSide(color: context.getColor(ThemeEnum.outline))),
          ),
          child: SafeArea(
            bottom: false,
            child: RSizedBox(
              height: SizeManager.appBar,
              child: HorizontalPadding(
                padding: SpaceManager.s2,
                child: Row(
                  children: [
                    if (back)
                      const BarBackButton()
                    else
                      const RSizedBox.square(dimension: SizeManager.hit),
                    Expanded(child: SemiBoldText(title, textAlign: TextAlign.center, maxLines: 1)),
                    const RSizedBox.square(dimension: SizeManager.hit),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// the bar's back chevron, 44 x 44, flipped in arabic. the qibla bar has no surface and uses it alone
class BarBackButton extends StatelessWidget {
  const BarBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Semantics(
      button: true,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: RSizedBox.square(
          dimension: SizeManager.hit,
          child: Center(
            child: Transform.flip(
              flipX: isRtl,
              child: BmIcon.ui(
                BmUiIcon.back,
                size: SizeManager.icon.r,
                color: context.getColor(ThemeEnum.text),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// a large title page: the compact bar fades in once the large title has scrolled under it
class LargeTitleScrollView extends StatefulWidget {
  const LargeTitleScrollView({required this.title, required this.slivers, super.key});

  /// a StringsManager key, the compact bar's title
  final String title;
  final List<Widget> slivers;

  @override
  State<LargeTitleScrollView> createState() => _LargeTitleScrollViewState();
}

class _LargeTitleScrollViewState extends State<LargeTitleScrollView> {
  final _collapsed = ValueNotifier(false);

  /// the header's button row and the large title, scaled like the layout
  double get _collapseAt =>
      SizeManager.hit.r + (FontSizeManager.largeTitle * LineHeightManager.largeTitle).sp;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth == 0 && notification.metrics.axis == Axis.vertical) {
      _collapsed.value = notification.metrics.pixels > _collapseAt;
    }
    return false;
  }

  @override
  void dispose() {
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: CustomScrollView(slivers: widget.slivers),
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: ValueListenableBuilder(
            valueListenable: _collapsed,
            builder: (context, collapsed, child) => IgnorePointer(
              ignoring: !collapsed,
              child: AnimatedOpacity(
                opacity: collapsed ? 1 : 0,
                duration: reduceMotion ? BmMotion.micro : BmMotion.standard,
                curve: BmMotion.standardCurve,
                child: child,
              ),
            ),
            child: CompactAppBar(widget.title, back: false),
          ),
        ),
      ],
    );
  }
}
