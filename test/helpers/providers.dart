import 'dart:io';

import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/position_source.dart';
import 'package:better_muslim/core/quran/quran_assets.dart';
import 'package:better_muslim/core/quran/recitation_files.dart';
import 'package:better_muslim/core/resources/design/bm_colors.dart';
import 'package:better_muslim/core/settings/onboarding.dart';
import 'package:better_muslim/core/surfaces/surfaces_channel.dart';
import 'package:better_muslim/features/quran/data/tafsir_files.dart';
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

/// an in-memory store, the dev flavor, no gps, no surfaces plugin and no app folder, so a widget
/// test never reaches the phone. onboarded, so the app opens on home unless a test says otherwise
List<Override> testOverrides({
  PositionSource? positionSource,
  FlavorConfig flavor = devConfig,
  bool onboarded = true,
  BmThemeId? theme,
}) => [
  _memoryDatabase(theme),
  flavorProvider.overrideWithValue(flavor),
  positionSourceProvider.overrideWithValue(positionSource ?? FakePositionSource()),
  onboardingProvider.overrideWith(() => OnboardingNotifier(done: onboarded)),
  surfacesChannelProvider.overrideWithValue(FakeSurfacesChannel()),
  _tafsirFiles,
];

/// the moment every PNG shows (FR-026), on the scenario's seeded in-memory store. onboarded
/// false is a replay
Future<List<Override>> designOverrides({
  bool onboarded = true,
  BmThemeId? theme,
  Override? tafsirFiles,
  Override? recitationFiles,
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = await designScenarioStore();
  if (theme != null) await db.updateSettings(SettingsCompanion(theme: Value(theme)));
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
    tafsirFiles ?? _tafsirFiles,
    recitationFiles ?? _recitationFiles,
  ];
}

/// nothing is downloaded and the phone is offline, a test that needs a tafsir overrides this
final _tafsirFiles = tafsirFilesProvider.overrideWith(
  (ref) => TafsirFiles(
    assets: () => ref.read(quranAssetsProvider.future),
    root: () async => Directory.systemTemp,
    fetch: (_) async => throw const SocketException('offline'),
    exclude: (_) async {},
  ),
);

/// nothing is downloaded and the phone is offline, in a folder of its own for each test
final _recitationFiles = recitationFilesProvider.overrideWith(
  (ref) => RecitationFiles(
    root: () async => Directory.systemTemp.createTempSync('recitations'),
    fetch: (_) async => throw const SocketException('offline'),
    exclude: (_) async {},
  ),
);

Override _memoryDatabase(BmThemeId? theme) => databaseProvider.overrideWith((ref) {
  /// every test gets its own in-memory store, so drift's shared executor warning doesn't apply
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase.forTesting(NativeDatabase.memory());

  /// queued before the first settings read, so the app never shows the default theme
  if (theme != null) db.updateSettings(SettingsCompanion(theme: Value(theme)));
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
