import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/resources/theme_manager.dart';
import 'package:better_muslim/core/widgets/shell/nav_bar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.shell, super.key});
  final StatefulNavigationShell shell;

  /// the azkar tab, its badge says a set's window has started
  static const _azkarTab = 3;

  /// toasts read its height to sit above it
  static final navBar = GlobalKey();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.isThemeDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        /// the tabs scroll under the glass bar, their lists end above it through the bottom padding
        extendBody: true,
        body: shell,
        bottomNavigationBar: NavBar(
          key: navBar,
          index: shell.currentIndex,
          badge: ref.watch(azkarBadgeProvider) ? _azkarTab : null,

          /// tapping the open tab goes back to its first page
          onTap: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
        ),
      ),
    );
  }
}
