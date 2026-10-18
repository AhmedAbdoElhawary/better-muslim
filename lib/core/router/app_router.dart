import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/monitoring/monitoring.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/widgets/shell/app_shell.dart';
import 'package:better_muslim/core/widgets/shell/tab_switcher.dart';
import 'package:better_muslim/features/azkar/view/azkar_page.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/more/view/more_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/prayer_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/qada_page.dart';
import 'package:better_muslim/features/quran/presentation/view/quran_page.dart';
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
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
