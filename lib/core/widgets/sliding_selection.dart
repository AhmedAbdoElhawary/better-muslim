import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// the highlight slides behind the picked child on the snappy spring, a new pick turns from where
/// it is
class SlidingSelection extends StatefulWidget {
  const SlidingSelection({
    required this.selected,
    required this.children,
    required this.highlight,
    required this.layout,
    this.front = false,
    super.key,
  });

  /// an index into children, null draws no highlight
  final int? selected;
  final List<Widget> children;
  final Widget highlight;

  /// lays out the children, each already wrapped so it can be measured
  final Widget Function(List<Widget> children) layout;

  /// over the children, so the calendar's ring shows on today's fill
  final bool front;

  @override
  State<SlidingSelection> createState() => _SlidingSelectionState();
}

class _SlidingSelectionState extends State<SlidingSelection> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController.unbounded(vsync: this, value: 1);
  final _stack = GlobalKey();
  final _keys = <GlobalKey>[];
  Rect? _from;
  Rect? _to;

  Rect? get _rect => _to == null ? null : Rect.lerp(_from, _to, _controller.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// the children's rects are only known after layout
  void _measure() {
    if (!mounted) return;
    final index = widget.selected;
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    final item = index == null || index >= _keys.length
        ? null
        : _keys[index].currentContext?.findRenderObject() as RenderBox?;
    if (stack == null || item == null || !item.hasSize) {
      if (_to != null) setState(() => _from = _to = null);
      return;
    }
    final target = MatrixUtils.transformRect(item.getTransformTo(stack), Offset.zero & item.size);
    if (target == _to) return;
    final current = _rect;
    _from = current ?? target;
    _to = target;
    if (current == null || MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.value = 0;

    /// the spring stops inside its tolerance, a hair before the target
    _controller
        .animateWith(SpringSimulation(BmMotion.snappy, 0, 1, 0))
        .then((_) => _controller.value = 1);
  }

  @override
  Widget build(BuildContext context) {
    while (_keys.length < widget.children.length) {
      _keys.add(GlobalKey());
    }
    _keys.length = widget.children.length;

    /// a layout change without a rebuild of this widget (a wider screen) still re-measures
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
        final highlight = AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final rect = _rect;
            if (rect == null) return const SizedBox.shrink();
            return Positioned.fromRect(rect: rect, child: child!);
          },
          child: widget.front ? IgnorePointer(child: widget.highlight) : widget.highlight,
        );
        return Stack(
          key: _stack,
          children: [
            if (!widget.front) highlight,
            widget.layout([
              for (final (index, child) in widget.children.indexed)
                KeyedSubtree(key: _keys[index], child: child),
            ]),
            if (widget.front) highlight,
          ],
        );
      },
    );
  }
}
