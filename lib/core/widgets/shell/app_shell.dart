import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isThemeDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: shell,
        bottomNavigationBar: NavBar(
          index: shell.currentIndex,

          /// tapping the open tab goes back to its first page
          onTap: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        ),
      ),
    );
  }
}
