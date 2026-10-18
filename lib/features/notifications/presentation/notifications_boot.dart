import 'dart:ui';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/location/location_controller.dart';
import 'package:better_muslim/features/notifications/data/background.dart';
import 'package:better_muslim/features/notifications/data/notification_scheduler.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// the notifications' wiring around the app: the first ask, rescheduling, taps and cleanup
class NotificationsBoot extends ConsumerStatefulWidget {
  const NotificationsBoot({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationsBoot> createState() => _NotificationsBootState();
}

class _NotificationsBootState extends ConsumerState<NotificationsBoot> {
  late final AppLifecycleListener _lifecycle;

  /// one apply at a time, two at once would cancel each other's notifications
  Future<void> _running = Future.value();

  bool get _isScenario => ref.read(flavorProvider).isDesignScenario;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _reschedule);
    _start();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final scheduler = ref.read(notificationSchedulerProvider);
    await scheduler.init();
    if (_isScenario) return;

    /// after the location dialog, never on top of it (FR-004)
    await ref.read(locationControllerProvider).firstLocate;
    final db = ref.read(databaseProvider);
    final settings = await db.watchSettings().first;
    if (!settings.notificationsAsked) {
      /// stored before asking, so a refusal or a killed app never asks again
      await db.updateSettings(const SettingsCompanion(notificationsAsked: Value(true)));
      await scheduler.askPermission();
    }
    await _reschedule();
  }

  /// the design scenario never schedules, whatever calls this (FR-013)
  Future<void> _reschedule() {
    if (_isScenario || !mounted) return _running;
    final db = ref.read(databaseProvider);
    final scheduler = ref.read(notificationSchedulerProvider);
    final phoneZone = ref.read(phoneZoneProvider);
    return _running = _running.then(
      (_) => topUp(
        db,
        scheduler: scheduler,
        locale: AppLocalizations.localeFor(PlatformDispatcher.instance.locales),
        use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
        phoneZone: phoneZone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
