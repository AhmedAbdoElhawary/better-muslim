import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  /// the azkar tab, its badge says a set's window has started
  static const _azkarTab = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isThemeDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: shell,
        bottomNavigationBar: NavBar(
          index: shell.currentIndex,
          badge: ref.watch(azkarBadgeProvider) ? _azkarTab : null,

          /// tapping the open tab goes back to its first page
          onTap: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        ),
      ),
    );
  }
}
