import 'package:flutter/widgets.dart';

/// the text widgets take theme colors only, the adhan screen's colors are its own literals
class AdhanTint extends StatelessWidget {
  const AdhanTint(this.color, {required this.child, super.key});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: DefaultTextStyle.of(context).style.copyWith(color: color),
      child: IconTheme.merge(
        data: IconThemeData(color: color),
        child: child,
      ),
    );
  }
}
