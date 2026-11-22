part of 'adaptive_padding.dart';

class OnlyPadding extends StatelessWidget {
  const OnlyPadding({
    this.start = 0,
    this.end = 0,
    this.top = 0,
    this.bottom = 0,
    required this.child,
    super.key,
  });
  final double start;
  final double end;
  final double top;
  final double bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _RPadding(
      padding: REdgeInsetsDirectional.only(start: start, end: end, top: top, bottom: bottom),
      child: child,
    );
  }
}
