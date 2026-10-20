import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'surfaces.dart';

const devConfig = FlavorConfig(
  flavor: Flavor.dev,
  appName: 'Better Muslim',
  apiBaseUrl: '',
  sentryDsn: '',
);

/// an in-memory store, the dev flavor, no gps and no surfaces plugin, so a widget test never
/// reaches the phone. onboarded, so the app opens on home unless a test says otherwise
List<Override> testOverrides({
  PositionSource? positionSource,
  FlavorConfig flavor = devConfig,
  bool onboarded = true,
}) => [
  _memoryDatabase(),
  flavorProvider.overrideWithValue(flavor),
  positionSourceProvider.overrideWithValue(positionSource ?? FakePositionSource()),
  onboardingProvider.overrideWith(() => OnboardingNotifier(done: onboarded)),
  surfacesChannelProvider.overrideWithValue(FakeSurfacesChannel()),
];

/// the moment every PNG shows (FR-026), on the scenario's seeded in-memory store. onboarded
/// false is a replay
Future<List<Override>> designOverrides({bool onboarded = true}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = await designScenarioStore();
  return [
    databaseProvider.overrideWith((ref) {
      ref.onDispose(db.close);
      return db;
    }),
    flavorProvider.overrideWithValue(
      const FlavorConfig(
        flavor: Flavor.dev,
        appName: 'Better Muslim',
        apiBaseUrl: '',
        sentryDsn: '',
        scenario: 'design',
      ),
    ),
    ...designScenarioOverrides(),
    onboardingProvider.overrideWith(() => OnboardingNotifier(done: onboarded)),
    surfacesChannelProvider.overrideWithValue(FakeSurfacesChannel()),
  ];
}

Override _memoryDatabase() => databaseProvider.overrideWith((ref) {
  /// every test gets its own in-memory store, so drift's shared executor warning doesn't apply
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  ref.onDispose(db.close);
  return db;
});

/// drift starts a zero timer when a watched query loses its last listener, it has to run before
/// the test ends or flutter_test fails on a pending timer
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

/// no permission and no fix unless a test gives them
class FakePositionSource implements PositionSource {
  FakePositionSource({this.granted = LocationPermission.denied, this.answer, this.position});

  LocationPermission granted;

  /// what the dialog answers, null = the dialog is never shown
  LocationPermission? answer;
  LatLng? position;
  int requests = 0;
  int fixes = 0;
  LocationAccuracy? accuracy;

  @override
  Future<LocationPermission> permission() async => granted;

  @override
  Future<LocationPermission> request() async {
    requests++;
    return granted = answer ?? granted;
  }

  @override
  Future<LatLng?> fix({LocationAccuracy accuracy = LocationAccuracy.low}) async {
    fixes++;
    this.accuracy = accuracy;
    return position;
  }
}
