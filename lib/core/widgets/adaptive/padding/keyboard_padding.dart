part of 'adaptive_padding.dart';

/// the keyboard's height under a sheet's content. already logical pixels, so not scaled
class KeyboardPadding extends StatelessWidget {
  const KeyboardPadding({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _RPadding(
      /// ios can report a negative inset while the keyboard closes, and Padding asserts on it
      padding: EdgeInsets.only(bottom: math.max(0, MediaQuery.viewInsetsOf(context).bottom)),
      child: child,
    );
  }
}
