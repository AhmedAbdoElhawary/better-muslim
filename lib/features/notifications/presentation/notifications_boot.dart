import 'dart:async';
import 'dart:ui';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/audio/clip_player.dart';
import 'package:better_muslim/core/azkar/azkar_progress.dart';
import 'package:better_muslim/core/azkar/azkar_window.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/core/prayer_times/day_times.dart';
import 'package:better_muslim/core/prayer_times/prayer_times_providers.dart';
import 'package:better_muslim/core/resources/strings_manager.dart';
import 'package:better_muslim/core/router/app_router.dart';
import 'package:better_muslim/core/settings/adhan_recording.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/features/notifications/data/adhan_channel.dart';
import 'package:better_muslim/features/notifications/data/alert_texts.dart';
import 'package:better_muslim/features/notifications/data/background.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:better_muslim/features/notifications/domain/alert.dart';
import 'package:better_muslim/features/notifications/domain/tap_target.dart';
import 'package:better_muslim/features/notifications/presentation/providers/adhan_providers.dart';
import 'package:drift/drift.dart' show TableUpdateQuery, Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// everything a pending notification is made from, so a change to any of them replaces them all
/// (FR-010). the language and the 12/24 hour setting are read again on every resume
final _scheduleInputsProvider = Provider((ref) {
  final place = ref.watch(
    locationProvider.select(
      (location) => (
        location?.latitude,
        location?.longitude,
        location?.placeName,
        location?.placeNameAr,
        location?.zone.name,
      ),
    ),
  );
  final choices = ref.watch(
    settingsProvider.select((settings) {
      final row = settings.value;
      return (
        row?.method,
        row?.asrMethod,
        row?.hijriAdjust,
        row?.digits,
        row?.reminderMinutes,
        row?.fajrSound,
        row?.dhuhrSound,
        row?.asrSound,
        row?.maghribSound,
        row?.ishaSound,
        row?.fajrRecording,
        row?.dhuhrRecording,
        row?.asrRecording,
        row?.maghribRecording,
        row?.ishaRecording,
        row?.azkarNudges,
      );
    }),
  );

  /// finishing a set takes back its nudge
  bool done(AzkarSet set) => ref.watch(
    azkarProgressProvider(set)
        .select((progress) => progress.total > 0 && progress.done == progress.total),
  );
  return (place, choices, done(AzkarSet.morning), done(AzkarSet.evening));
});

/// the notifications' wiring around the app: the first ask, rescheduling, taps and cleanup
class NotificationsBoot extends ConsumerStatefulWidget {
  const NotificationsBoot({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationsBoot> createState() => _NotificationsBootState();
}

class _NotificationsBootState extends ConsumerState<NotificationsBoot> {
  late final AppLifecycleListener _lifecycle;
  final _subscriptions = <StreamSubscription<Object?>>[];
  Timer? _debounce;
  Locale? _initLocale;

  /// a sheet's slider or a fast location fix changes several inputs in a row
  static const _debounceTime = Duration(milliseconds: 500);

  /// one apply at a time, two at once would cancel each other's notifications
  Future<void> _running = Future.value();

  bool get _isScenario => ref.read(flavorProvider).isDesignScenario;

  Locale get _locale => AppLocalizations.localeFor(PlatformDispatcher.instance.locales);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () async {
        /// ios keeps the mark prayed title from init
        if (_locale != _initLocale) await _init();
        await _reschedule();
        await _cleanUp();
      },
    );
    ref.listenManual(_scheduleInputsProvider, (_, _) {
      _debounce?.cancel();
      _debounce = Timer(_debounceTime, _reschedule);
    });

    /// only a change, opening the app a minute after a prayer shows no adhan screen
    ref.listenManual(periodProvider, (previous, next) {
      if (previous != null && next != null && previous != next) _onPeriod(next);
    });
    _start();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _lifecycle.dispose();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _start() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    final channel = ref.read(adhanChannelProvider);
    await _init();
    if (!mounted) return;
    _subscriptions
      ..add(channel.opened.listen(_open))
      ..add(
        ref
            .read(databaseProvider)
            .tableUpdates(const TableUpdateQuery.onTableName('prayer_log'))
            .listen((_) => _cleanUp()),
      );
    final launched = await scheduler.launchPayload() ?? await channel.launchPayload();
    if (launched != null) await _open(launched);
    if (_isScenario || !mounted) return;

    /// after the location dialog, never on top of it (FR-004)
    await ref.read(locationControllerProvider).firstLocate;
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    final settings = await db.watchSettings().first;
    if (!settings.notificationsAsked) {
      /// stored before asking, so a refusal or a killed app never asks again
      await db.updateSettings(const SettingsCompanion(notificationsAsked: Value(true)));
      if (await scheduler.askPermission()) await scheduler.askExactAlarms();
    }
    await _reschedule();
    await _cleanUp();
  }

  Future<void> _init() async {
    final locale = _initLocale = _locale;
    final l10n = await AppLocalizations.load(locale);
    if (!mounted) return;
    await ref
        .read(notificationSchedulerProvider)
        .init(markPrayed: l10n.tr(StringsManager.markPrayed, const {}), onTap: _onTap);
  }

  /// the design scenario never schedules, whatever calls this (FR-013)
  Future<void> _reschedule() {
    if (_isScenario || !mounted) return _running;
    final db = ref.read(databaseProvider);
    final scheduler = ref.read(notificationSchedulerProvider);
    final phoneZone = ref.read(phoneZoneProvider);
    final locale = _locale;
    return _running = _running.then((_) async {
      /// refused stays quiet, a grant in the phone's settings is seen on the next resume
      if (!await scheduler.isAllowed()) return;
      await topUp(
        db,
        scheduler: scheduler,
        locale: locale,
        use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
        phoneZone: phoneZone,
      );
    });
  }

  /// the full adhan in front, over any screen (FR-021)
  Future<void> _onPeriod(Period period) async {
    final prayer = Prayer.values.asNameMap()[period.name];
    if (prayer == null || _isScenario) return;
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) return;
    final sound = ref.read(settingsProvider).value?.soundOf(prayer);
    final location = ref.read(locationProvider);
    final at = ref.read(todayTimesProvider)?.timeOf(prayer);
    if (sound != PrayerSound.adhan || location == null || at == null) return;
    final day = ref.read(prayerDayProvider);
    final alert = Alert(
      day: day,
      prayer: prayer,
      kind: AlertKind.adhan,
      at: at,
      sound: PrayerSound.adhan,
    );
    ref.read(routerProvider).push(Routes.adhan(prayer, day));
    _stopPreview();
    await ref.read(adhanPlayerProvider).play(alert, await _texts(location), _recordingOf(prayer));
  }

  /// mark prayed while the app runs comes here instead of the background isolate
  void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !mounted) return;
    if (response.actionId == markPrayedAction) {
      markFromPayload(payload, db: ref.read(databaseProvider));
    } else {
      _open(payload);
    }
  }

  /// the adhan screen while the adhan would still play, the prayer tab after (FR-019)
  Future<void> _open(String payload) async {
    final alert = alertFromPayload(payload);
    if (alert == null || !mounted) return;
    final player = ref.read(adhanPlayerProvider);
    final length = await player.length(alert.prayer, _recordingOf(alert.prayer));
    if (!mounted) return;
    final target = tapTarget(payload, ref.read(clockProvider)(), length);
    final router = ref.read(routerProvider);
    switch (target) {
      case AdhanTarget(:final prayer, :final day, :final from):
        router.push(Routes.adhan(prayer, day, from: from));
        _stopPreview();
        final location = ref.read(locationProvider);
        if (location != null) {
          await player.play(alert, await _texts(location), _recordingOf(prayer), from: from);
        }
      case PrayerTarget(:final day, :final prayer):
        router.go(Routes.prayerAt(day, prayer));
      case AzkarTarget(:final set):
        router.go(Routes.azkarSet(set));
      case NoTarget():
    }
  }

  /// a prayer logged anywhere takes its delivered adhan notification with it (FR-039)
  Future<void> _cleanUp() async {
    if (!mounted) return;
    final scheduler = ref.read(notificationSchedulerProvider);
    final db = ref.read(databaseProvider);
    final playing = ref.read(playbackProvider).value?.id;
    for (final id in await scheduler.activeIds()) {
      final alert = alertFromId(id);
      if (alert == null || alert.kind != AlertKind.adhan || id == playing) continue;
      if (await db.isPrayed(alert.day, alert.prayer)) await scheduler.cancel(id);
    }
  }

  AdhanRecording _recordingOf(Prayer prayer) =>
      ref.read(settingsProvider).value?.recordingOf(prayer) ?? AdhanRecording.makkah;

  /// a recording previewed in the adhan sound sheet gives way to the real adhan
  void _stopPreview() {
    if (ref.exists(clipPlayerProvider)) ref.read(clipPlayerProvider).stop();
  }

  Future<AlertTexts> _texts(Location location) => AlertTexts.load(
    locale: _locale,
    use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
    digits: ref.read(settingsProvider).value?.digits ?? Digits.eastern,
    location: location,
  );

  @override
  Widget build(BuildContext context) => widget.child;
}
