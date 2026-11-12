import 'package:material_ui/material_ui.dart';

/// no animation of its own, its callers change the value every frame
class CustomOpacity extends StatelessWidget {
  const CustomOpacity({required this.opacity, required this.child, super.key});
  final double opacity;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return Opacity(opacity: opacity, child: child);
  }
}
