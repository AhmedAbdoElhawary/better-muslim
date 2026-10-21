import 'dart:async';
import 'dart:ui';

import 'package:better_muslim/core/app/app_localizations.dart';
import 'package:better_muslim/core/clock/clock.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/settings/settings.dart';
import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:better_muslim/core/surfaces/write_surfaces.dart';
import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// everything the surface data is made from, so a change to any of them writes it again (FR-002).
/// the language and the 12/24 hour setting are read again on every resume. null until the store
/// answers, the launch writes already
final _surfaceInputsProvider = Provider((ref) {
  if (!ref.watch(settingsProvider.select((settings) => settings.hasValue))) return null;
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
        row?.prayerCountdown,
        row?.language,
      );
    }),
  );
  return (place, choices);
});

/// keeps the widgets, the live activity and the android countdown in step with the app
class SurfacesBoot extends ConsumerStatefulWidget {
  const SurfacesBoot({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<SurfacesBoot> createState() => _SurfacesBootState();
}

class _SurfacesBootState extends ConsumerState<SurfacesBoot> {
  late final AppLifecycleListener _lifecycle;
  StreamSubscription<Object?>? _marks;
  Timer? _debounce;

  /// the next countdown window's start or end, ios 16.2 to 18 can only start one from an open app
  Timer? _window;

  /// a sheet's slider, a fast location fix or a restore changes several things in a row
  static const _debounceTime = Duration(milliseconds: 500);

  /// one write at a time, the plugin compares each with the file the last one left
  Future<void> _running = Future.value();

  bool get _isScenario => ref.read(flavorProvider).isDesignScenario;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _write);
    ref.listenManual(_surfaceInputsProvider, (previous, _) {
      if (previous != null) _later();
    });

    /// a mark anywhere in the app, reset prayer journey and restore all land in this table
    _marks = ref
        .read(databaseProvider)
        .tableUpdates(const TableUpdateQuery.onTableName('prayer_log'))
        .listen((_) => _later());
    _write();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _window?.cancel();
    _marks?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _later() {
    _debounce?.cancel();
    _debounce = Timer(_debounceTime, _write);
  }

  /// the design scenario never writes, whatever calls this (FR-033)
  Future<void> _write() {
    if (_isScenario || !mounted) return _running;
    final db = ref.read(databaseProvider);
    final channel = ref.read(surfacesChannelProvider);
    final phoneZone = ref.read(phoneZoneProvider);
    final clock = ref.read(clockProvider);
    return _running = _running.then((_) async {
      final next = await writeSurfaces(
        db,
        channel: channel,
        locale: AppLocalizations.localeOf(ref.read(settingsProvider).value?.language),
        use24h: PlatformDispatcher.instance.alwaysUse24HourFormat,
        phoneZone: phoneZone,
        now: clock(),
      );
      _window?.cancel();
      if (next != null && mounted) _window = Timer(next.difference(clock()), _write);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
