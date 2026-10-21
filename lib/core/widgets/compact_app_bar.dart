import 'dart:ui';

import 'package:better_muslim/core/resources/design/bm_icons.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/resources/design/bm_tokens.dart';
import 'package:better_muslim/core/resources/dimensions_manager.dart';
import 'package:better_muslim/core/resources/font_manager.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/adaptive/padding/adaptive_padding.dart';
import 'package:better_muslim/core/widgets/adaptive/text/adaptive_text.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:better_muslim/core/widgets/title_glow.dart';
import 'package:better_muslim/core/widgets/title_hero.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// with the top glow off, the bar's plain glass
const _plainOpacity = .8;

/// the components' 56 pt compact bar on a blurred surface, the back chevron only on pushed pages
class CompactAppBar extends ConsumerWidget {
  const CompactAppBar(
    this.title, {
    this.back = true,
    this.translate = true,
    this.action,
    this.titleChild,
    this.heroTag,
    this.collapsed = true,
    super.key,
  });

  /// a StringsManager key, or content like a category's name with translate false
  final String title;
  final bool back;
  final bool translate;

  /// a 44 x 44 button at the end, the calendar's today
  final Widget? action;

  /// in place of the title text, the calendar's mode switch
  final Widget? titleChild;

  /// the route the title flies in from, see TitleHero
  final String? heroTag;

  /// false on a large title page until its title arrives: no glass, no title. the title shows in
  /// the same frame the flying one hides, so only the glass fades
  final bool collapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final opacity = ref.watch(topGlowProvider) ? BmGlass.surfaceOpacity : _plainOpacity;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: collapsed ? 1 : 0,
            duration: reduce ? BmMotion.micro : BmMotion.standard,
            curve: BmMotion.standardCurve,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: BmGlass.blurSigma, sigmaY: BmGlass.blurSigma),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.getColor(ThemeEnum.surface).withValues(alpha: opacity),
                    border: Border(bottom: BorderSide(color: context.getColor(ThemeEnum.outline))),
                  ),
                ),
              ),
            ),
          ),
        ),
        SafeArea(
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
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: collapsed ? 1 : 0,

                      /// with reduce motion no title flies in, so this one fades
                      duration: reduce ? BmMotion.micro : Duration.zero,
                      child:
                          titleChild ??
                          Center(
                            child: TitleHero(
                              tag: heroTag,
                              child: SemiBoldText(
                                title,
                                translate: translate,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                              ),
                            ),
                          ),
                    ),
                  ),
                  action ?? const RSizedBox.square(dimension: SizeManager.hit),
                ],
              ),
            ),
          ),
        ),
      ],
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

/// a large title page: the header's LargeTitle follows the finger into the bar and becomes its
/// title, the bar's glass fades in under it (FR-039)
class LargeTitleScrollView extends StatefulWidget {
  const LargeTitleScrollView({required this.title, required this.slivers, super.key});

  /// a StringsManager key, the compact bar's title
  final String title;
  final List<Widget> slivers;

  @override
  State<LargeTitleScrollView> createState() => _LargeTitleScrollViewState();
}

class _LargeTitleScrollViewState extends State<LargeTitleScrollView> {
  final _controller = ScrollController();
  final _offset = ValueNotifier(0.0);
  final _collapsed = ValueNotifier(false);
  final _view = GlobalKey();

  /// the header's button row and the large title, scaled like the layout
  double get _collapseAt =>
      SizeManager.hit.r + (FontSizeManager.largeTitle * LineHeightManager.largeTitle).sp;

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) return false;
    final pixels = notification.metrics.pixels;
    _offset.value = pixels;
    _collapsed.value = pixels >= _collapseAt;
    if (notification is ScrollEndNotification && !MediaQuery.disableAnimationsOf(context)) {
      _snap(pixels);
    }
    return false;
  }

  /// a scroll left half way opens or closes the title, like the iOS bar
  void _snap(double pixels) {
    if (pixels <= 0 || pixels >= _collapseAt) return;
    final to = pixels < _collapseAt / 2 ? 0.0 : _collapseAt;
    Future.microtask(() {
      if (!_controller.hasClients) return;
      _controller.animateTo(to, duration: BmMotion.standard, curve: BmMotion.standardCurve);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _offset.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _LargeTitleScope(
      offset: _offset,
      collapsed: _collapsed,
      collapseAt: _collapseAt,
      view: _view,
      child: Stack(
        key: _view,
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(controller: _controller, slivers: widget.slivers),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: ValueListenableBuilder(
              valueListenable: _collapsed,
              builder: (context, collapsed, _) => IgnorePointer(
                ignoring: !collapsed,
                child: CompactAppBar(
                  widget.title,
                  back: false,
                  heroTag: "More",
                  collapsed: collapsed,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeTitleScope extends InheritedWidget {
  const _LargeTitleScope({
    required this.offset,
    required this.collapsed,
    required this.collapseAt,
    required this.view,
    required super.child,
  });

  /// the list's scroll offset, the title and subtitles read it every frame
  final ValueNotifier<double> offset;
  final ValueNotifier<bool> collapsed;
  final double collapseAt;

  /// the view's stack, where the title measures itself and the bar
  final GlobalKey view;

  static _LargeTitleScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LargeTitleScope>();

  @override
  bool updateShouldNotify(_LargeTitleScope old) => old.collapseAt != collapseAt;
}

/// the header's large title. in a LargeTitleScrollView it shrinks and slides into the bar's center
/// as the list scrolls, taking the bar's font in the last part of the move
class LargeTitle extends StatefulWidget {
  const LargeTitle(this.title, {required this.fontSize, required this.height, super.key});

  /// a StringsManager key
  final String title;
  final double fontSize;
  final double height;

  @override
  State<LargeTitle> createState() => _LargeTitleState();
}

class _LargeTitleState extends State<LargeTitle> {
  final _box = GlobalKey();

  /// the title's center with the list at the top, and the bar title's center, in the view
  (Offset, Offset)? _ends;

  /// the bar's font comes in over this last part of the move
  static const _fontFrom = .7;

  void _measure(Duration _) {
    final scope = _LargeTitleScope.maybeOf(context);
    final view = scope?.view.currentContext?.findRenderObject() as RenderBox?;
    final box = _box.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || scope == null || view == null || box == null || !box.hasSize) return;

    /// the box is the transform's, its own transform isn't in this
    final center = box.localToGlobal(box.size.center(Offset.zero), ancestor: view);
    final rest = center + Offset(0, scope.offset.value);
    final bar = Offset(
      view.size.width / 2,
      MediaQuery.paddingOf(context).top + SizeManager.appBar.r / 2,
    );
    if ((rest, bar) != _ends) setState(() => _ends = (rest, bar));
  }

  @override
  Widget build(BuildContext context) {
    final scope = _LargeTitleScope.maybeOf(context);
    final large = RegularText(
      widget.title,
      font: FontEnum.display,
      fontSize: widget.fontSize,
      height: widget.height,
    );
    if (scope == null || MediaQuery.disableAnimationsOf(context)) return large;
    WidgetsBinding.instance.addPostFrameCallback(_measure);
    final ends = _ends;
    final small = FontSizeManager.title / widget.fontSize;
    return ValueListenableBuilder(
      valueListenable: scope.offset,
      builder: (context, offset, child) {
        final progress = (offset / scope.collapseAt).clamp(0.0, 1.0);
        final font = ((progress - _fontFrom) / (1 - _fontFrom)).clamp(0.0, 1.0);
        final scale = 1 + (small - 1) * progress;

        /// cancels the scroll and moves toward the bar, so the title is at the bar at 1
        final shift = ends == null
            ? Offset.zero
            : (ends.$2 - ends.$1) * progress + Offset(0, offset.clamp(0, double.infinity));

        /// hidden in the frame the bar's own title shows, at the same spot and size
        return ValueListenableBuilder(
          valueListenable: scope.collapsed,
          builder: (context, collapsed, child) =>
              CustomOpacity(opacity: collapsed ? 0 : 1, child: child),
          child: Transform(
            key: _box,
            alignment: Alignment.center,
            transform: Matrix4.translationValues(shift.dx, shift.dy, 0)
              ..scaleByDouble(scale, scale, 1, 1),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                TitleHero(
                  tag: "More",
                  child: CustomOpacity(opacity: 1 - font, child: child),
                ),

                /// only built once it shows, a resting title stays one text
                if (font > 0)
                  CustomOpacity(
                    opacity: font,
                    child: Transform.scale(
                      scale: 1 / scale,
                      child: SemiBoldText(widget.title, maxLines: 1),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: large,
    );
  }
}

/// a large title's subtitle, gone by half of the move (FR-039)
class LargeTitleSubtitle extends StatelessWidget {
  const LargeTitleSubtitle({required this.child, super.key});
  final Widget child;

  static const _goneAt = .5;

  @override
  Widget build(BuildContext context) {
    final scope = _LargeTitleScope.maybeOf(context);
    if (scope == null || MediaQuery.disableAnimationsOf(context)) return child;
    return ValueListenableBuilder(
      valueListenable: scope.offset,
      builder: (context, offset, child) => CustomOpacity(
        opacity: (1 - offset / (scope.collapseAt * _goneAt)).clamp(0.0, 1.0),
        child: child,
      ),
      child: child,
    );
  }
}
