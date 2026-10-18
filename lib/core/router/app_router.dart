import 'dart:math' as math;

import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/monitoring/monitoring.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/widgets/shell/app_shell.dart';
import 'package:better_muslim/core/widgets/shell/tab_switcher.dart';
import 'package:better_muslim/features/azkar/view/azkar_page.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/more/view/more_page.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/prayer_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/qada_page.dart';
import 'package:better_muslim/features/quran/presentation/view/quran_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

abstract final class Routes {
  static const String home = '/';
  static const String prayer = '/prayer';
  static const String quran = '/quran';
  static const String azkar = '/azkar';
  static const String more = '/more';
  static const String qada = '/prayer/qada';

  /// home's strip cells and notification taps open the prayer tab on a day, at a prayer
  static String prayerAt(DateTime day, Prayer prayer) => Uri(
    path: Routes.prayer,
    queryParameters: {'day': _date.toSql(day), 'prayer': prayer.name},
  ).toString();

  /// the adhan screen over everything. from = how far into the adhan, in whole seconds
  static String adhan(Prayer prayer, DateTime day, {Duration from = Duration.zero}) => Uri(
    path: adhanPath,
    queryParameters: {
      'prayer': prayer.name,
      'day': _date.toSql(day),
      if (from > Duration.zero) 'from': '${from.inSeconds}',
    },
  ).toString();

  static const String adhanPath = '/adhan';

  static const _date = CivilDate();
}

/// bad params fall back to the prayer day
DateTime? _dayParam(String? value) {
  if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  return const CivilDate().fromSql(value);
}

/// one router per ProviderScope, so tests never share a location
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    observers: Monitoring.navigatorObservers,
    routes: [
      StatefulShellRoute(
        builder: (context, state, shell) => AppShell(shell: shell),
        navigatorContainerBuilder: (context, shell, children) =>
            TabSwitcher(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.home, builder: (context, state) => const HomePage())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.prayer,
                builder: (context, state) => PrayerPage(
                  day: _dayParam(state.uri.queryParameters['day']),
                  prayer: Prayer.values.asNameMap()[state.uri.queryParameters['prayer']],
                ),
                routes: [GoRoute(path: 'qada', builder: (context, state) => const QadaPage())],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.quran, builder: (context, state) => const QuranPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.azkar, builder: (context, state) => const AzkarPage())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.more, builder: (context, state) => const MorePage())],
          ),
        ],
      ),

      /// outside the shell, so it covers the nav bar too
      GoRoute(
        path: Routes.adhanPath,
        redirect: (context, state) =>
            Prayer.values.asNameMap()[state.uri.queryParameters['prayer']] == null
            ? Routes.home
            : null,
        pageBuilder: (context, state) => _adhanPage(
          context,
          state,
          AdhanPage(
            prayer: Prayer.values.byName(state.uri.queryParameters['prayer']!),
            day: _dayParam(state.uri.queryParameters['day']) ?? ref.read(prayerDayProvider),
          ),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// MOTION 06: a circle from the sun opens the screen, a 300 ms fade with reduce motion
Page<void> _adhanPage(BuildContext context, GoRouterState state, Widget child) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: reduce ? BmMotion.standard : adhanReveal,
    reverseTransitionDuration: BmMotion.standard,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (reduce) return FadeTransition(opacity: animation, child: child);
      return ClipPath(
        clipper: _CircleReveal(
          CurvedAnimation(
            parent: animation,
            curve: Interval(0, 1 - adhanTextStart, curve: BmMotion.decelerate),
          ),
        ),
        child: child,
      );
    },
  );
}

/// css circle(0% to 150% at 50% 62%), a percentage of the box's diagonal over the square root of 2
class _CircleReveal extends CustomClipper<Path> {
  _CircleReveal(this.progress) : super(reclip: progress);

  final Animation<double> progress;

  static const _center = Alignment(0, .24);
  static const _end = 1.5;

  @override
  Path getClip(Size size) {
    final radius = progress.value * _end * size.bottomRight(Offset.zero).distance / math.sqrt2;
    return Path()..addOval(Rect.fromCircle(center: _center.alongSize(size), radius: radius));
  }

  @override
  bool shouldReclip(_CircleReveal old) => old.progress != progress;
}
