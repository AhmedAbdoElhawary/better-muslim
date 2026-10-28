import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/custom_opacity.dart';
import 'package:flutter/material.dart';

/// keeps every tab alive like an IndexedStack and plays motion 16: the old tab fades up and out,
/// then the new one fades up and in
class TabSwitcher extends StatefulWidget {
  const TabSwitcher({required this.index, required this.children, super.key});
  final int index;
  final List<Widget> children;

  @override
  State<TabSwitcher> createState() => _TabSwitcherState();
}

class _TabSwitcherState extends State<TabSwitcher> with SingleTickerProviderStateMixin {
  static const _outDuration = Duration(milliseconds: 120);
  static const _inDuration = BmMotion.standard;
  static const _shift = 8.0;

  late final AnimationController _controller = AnimationController(vsync: this, value: 1);
  late int _previous = widget.index;
  bool _reduceMotion = false;

  @override
  void didUpdateWidget(TabSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _previous = oldWidget.index;
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = _reduceMotion ? BmMotion.micro : _outDuration + _inDuration;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outEnd = _reduceMotion
        ? .5
        : _outDuration.inMilliseconds / (_outDuration + _inDuration).inMilliseconds;
    final shift = _reduceMotion ? 0.0 : _shift;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final out = BmMotion.accelerate.transform((t / outEnd).clamp(0, 1));
        final into = BmMotion.decelerate.transform(((t - outEnd) / (1 - outEnd)).clamp(0, 1));
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final (i, child) in widget.children.indexed)
              _TabLayer(
                visible: i == widget.index || (i == _previous && t < outEnd),
                active: i == widget.index,
                opacity: i == widget.index ? into : 1 - out,
                offset: i == widget.index ? (1 - into) * shift : -out * shift,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

/// same widgets for every tab in every state, so a tab never loses its navigator
class _TabLayer extends StatelessWidget {
  const _TabLayer({
    required this.visible,
    required this.active,
    required this.opacity,
    required this.offset,
    required this.child,
  });
  final bool visible;
  final bool active;
  final double opacity;
  final double offset;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !visible,
      child: TickerMode(
        enabled: visible,
        child: IgnorePointer(
          ignoring: !active,
          child: CustomOpacity(
            opacity: opacity,
            child: Transform.translate(offset: Offset(0, offset), child: child),
          ),
        ),
      ),
    );
  }
}
