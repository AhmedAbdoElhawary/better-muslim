part of 'adaptive_padding.dart';

/// the keyboard's height under a sheet's content. already logical pixels, so not scaled
class KeyboardPadding extends StatelessWidget {
  const KeyboardPadding({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _RPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: child,
    );
  }
}
