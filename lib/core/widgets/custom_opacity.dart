import 'package:flutter/material.dart';

class CustomOpacity extends StatelessWidget {
  const CustomOpacity({required this.opacity, required this.child, super.key});
  final double opacity;
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}
