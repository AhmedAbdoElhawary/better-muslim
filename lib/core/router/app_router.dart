import 'dart:math' as math;

import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/database/civil_date.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/monitoring/monitoring.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/quran/ayah_key.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/resources/design/bm_motion.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/widgets/shell/app_shell.dart';
import 'package:better_muslim/core/widgets/shell/tab_switcher.dart';
import 'package:better_muslim/core/widgets/step/step_scope.dart';
import 'package:better_muslim/features/azkar/view/azkar_page.dart';
import 'package:better_muslim/features/azkar/view/azkar_set_page.dart';
import 'package:better_muslim/features/azkar/view/tasbih_page.dart';
import 'package:better_muslim/features/duas/view/dua_category_page.dart';
import 'package:better_muslim/features/duas/view/duas_page.dart';
import 'package:better_muslim/features/duas/view_model/duas_providers.dart';
import 'package:better_muslim/features/hijri_calendar/view/hijri_calendar_page.dart';
import 'package:better_muslim/features/home/view/home_page.dart';
import 'package:better_muslim/features/more/view/more_page.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_page.dart';
import 'package:better_muslim/features/notifications/presentation/view/adhan_settings_page.dart';
import 'package:better_muslim/features/notifications/presentation/view/dev_notifications_page.dart';
import 'package:better_muslim/features/notifications/presentation/view/notifications_step_page.dart';
import 'package:better_muslim/features/onboarding/view/location_step_page.dart';
import 'package:better_muslim/features/onboarding/view/welcome_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/prayer_page.dart';
import 'package:better_muslim/features/prayer/presentation/view/qada_page.dart';
import 'package:better_muslim/features/qibla/view/qibla_page.dart';
import 'package:better_muslim/features/quran/presentation/view/quran_page.dart';
import 'package:better_muslim/features/quran/presentation/view/reader_page.dart';
import 'package:better_muslim/features/quran/presentation/view/saved_page.dart';
import 'package:better_muslim/features/theme_picker/view/theme_page.dart';
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
  static const String qibla = '/qibla';
  static const String tasbih = '/azkar/tasbih';
  static const String duas = '/duas';

  /// more's pages, outside the shell with the compact bar and no tab bar
  static const String theme = '/theme';
  static const String hijriCalendar = '/hijri-calendar';
  static const String adhanSettings = '/adhan-settings';

  /// inside the azkar tab, so the tab bar stays
  static String azkarSet(AzkarSet set) => '$azkar/${set.name}';

  /// outside the shell like duas
  static String duaCategory(String id) => '$duas/$id';

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

  /// the reader outside the shell, the ayah washed when given (contracts/reader-routes.md)
  static String quranPage(int page, {AyahKey? ayah}) => Uri(
    path: '$quran/page/$page',

    /// null and not empty, an empty map leaves a trailing ?
    queryParameters: ayah == null ? null : {'ayah': '$ayah'},
  ).toString();

  static const String quranSaved = '$quran/saved';
  static const String quranNotes = '$quranSaved?tab=notes';

  /// dev builds only
  static const String devNotifications = '/dev/notifications';

  /// the first launch, each step pushed on the one before so back goes to it (FR-018)
  static const String onboarding = '/onboarding';
  static const String onboardingLocation = '/onboarding/location';
  static const String onboardingNotifications = '/onboarding/notifications';
  static const String onboardingTheme = '/onboarding/theme';

  static const _date = CivilDate();
}

/// bad params fall back to the prayer day
DateTime? _dayParam(String? value) {
  if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
  return const CivilDate().fromSql(value);
}

/// onboarding until it's finished, the adhan still covers it (contracts/onboarding-routes.md)
String? onboardingRedirect(Onboarding onboarding, String location) {
  final path = Uri.parse(location).path;
  final inOnboarding = path == Routes.onboarding || path.startsWith('${Routes.onboarding}/');
  if (!onboarding.done || onboarding.replay) {
    return inOnboarding || path == Routes.adhanPath ? null : Routes.onboarding;
  }
  return inOnboarding ? Routes.home : null;
}

/// one router per ProviderScope, so tests never share a location
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    observers: Monitoring.navigatorObservers,
    redirect: (context, state) =>
        onboardingRedirect(ref.read(onboardingProvider), state.uri.toString()),
    routes: [
      StatefulShellRoute(
        /// home fades in over the theme step on apply. a cold start has nothing to fade from
        pageBuilder: (context, state, shell) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: BmMotion.standard,
          child: AppShell(shell: shell),
          transitionsBuilder: (context, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
        navigatorContainerBuilder: (context, shell, children) =>
            TabSwitcher(index: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                pageBuilder: (context, state) => _page(state, const HomePage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.prayer,
                pageBuilder: (context, state) => _page(
                  state,
                  PrayerPage(
                    day: _dayParam(state.uri.queryParameters['day']),
                    prayer: Prayer.values.asNameMap()[state.uri.queryParameters['prayer']],
                  ),
                ),
                routes: [
                  GoRoute(
                    path: 'qada',
                    pageBuilder: (context, state) => _page(state, const QadaPage()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.quran,
                pageBuilder: (context, state) => _page(state, const QuranPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.azkar,
                pageBuilder: (context, state) => _page(state, const AzkarPage()),
                routes: [
                  GoRoute(
                    path: 'tasbih',
                    pageBuilder: (context, state) => _page(state, const TasbihPage()),
                  ),
                  GoRoute(
                    path: ':set',
                    redirect: (context, state) =>
                        AzkarSet.values.asNameMap()[state.pathParameters['set']] == null
                        ? Routes.azkar
                        : null,
                    builder: (context, state) =>
                        AzkarSetPage(AzkarSet.values.byName(state.pathParameters['set']!)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.more,
                pageBuilder: (context, state) => _page(state, const MorePage()),
              ),
            ],
          ),
        ],
      ),

      /// outside the shell, the qibla tree has no tab bar
      GoRoute(path: Routes.qibla, pageBuilder: (context, state) => _page(state, const QiblaPage())),

      /// outside the shell, the 4.14 tree has no tab bar
      GoRoute(
        path: Routes.duas,
        pageBuilder: (context, state) => _page(state, const DuasPage()),
        routes: [
          GoRoute(
            path: ':id',
            redirect: (context, state) {
              final categories = ref.read(duasContentProvider).value;
              final id = state.pathParameters['id'];
              if (categories == null || categories.any((category) => category.id == id)) {
                return null;
              }
              return Routes.duas;
            },
            pageBuilder: (context, state) =>
                _page(state, DuaCategoryPage(state.pathParameters['id']!)),
          ),
        ],
      ),

      /// outside the shell, the reader and saved have no tab bar
      GoRoute(
        path: '${Routes.quran}/page/:page',
        redirect: (context, state) {
          final page = int.tryParse(state.pathParameters['page']!);
          return page == null || page < 1 || page > quranPageCount ? Routes.quran : null;
        },
        pageBuilder: (context, state) => _page(
          state,
          ReaderPage(
            page: int.parse(state.pathParameters['page']!),
            ayah: AyahKey.tryParse(state.uri.queryParameters['ayah']),
          ),
        ),
      ),
      GoRoute(
        path: Routes.quranSaved,
        pageBuilder: (context, state) =>
            _page(state, SavedPage(notes: state.uri.queryParameters['tab'] == 'notes')),
      ),

      GoRoute(path: Routes.theme, pageBuilder: (context, state) => _page(state, const ThemePage())),
      GoRoute(
        path: Routes.adhanSettings,
        pageBuilder: (context, state) => _page(state, const AdhanSettingsPage()),
      ),
      GoRoute(
        path: Routes.hijriCalendar,
        pageBuilder: (context, state) => _page(state, const HijriCalendarPage()),
      ),

      /// staging and production don't have the route at all (FR-041)
      if (ref.read(flavorProvider).flavor.isDev)
        GoRoute(
          path: Routes.devNotifications,
          pageBuilder: (context, state) => _page(state, const DevNotificationsPage()),
        ),

      /// the first route on a new install, so it has no transition of its own. its scope gives the
      /// welcome the steps' secondary animation (FR-015)
      GoRoute(
        path: Routes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          child: const WelcomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              StepScope(animation: animation, secondaryAnimation: secondaryAnimation, child: child),
        ),
        routes: [
          GoRoute(
            path: 'location',
            pageBuilder: (context, state) => _stepPage(context, state, const LocationStepPage()),
          ),
          GoRoute(
            path: 'notifications',
            pageBuilder: (context, state) =>
                _stepPage(context, state, const NotificationsStepPage()),
          ),
          GoRoute(
            path: 'theme',
            pageBuilder: (context, state) =>
                _stepPage(context, state, const ThemePage(onboarding: true)),
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
  ref.listen(onboardingProvider, (_, _) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});

/// a step's build is its route's transition (R8): 900 ms in, 150 ms out, 300 ms crossfade with
/// reduce motion
Page<void> _stepPage(BuildContext context, GoRouterState state, Widget child) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return CustomTransitionPage(
    key: state.pageKey,
    transitionDuration: reduce ? BmMotion.standard : stepBuild,
    reverseTransitionDuration: reduce ? BmMotion.standard : BmMotion.micro,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        StepScope(animation: animation, secondaryAnimation: secondaryAnimation, child: child),
  );
}

const stepBuild = Duration(milliseconds: 900);

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

/// go_router 18 looks for material_ui's app, not ours, so a plain builder gets no transition
Page<void> _page(GoRouterState state, Widget child) =>
    MaterialPage(key: state.pageKey, child: child);
