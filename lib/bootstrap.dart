import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/database/app_database.dart';
import 'package:better_muslim/core/flavor/design_scenario.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/location/location.dart';
import 'package:better_muslim/core/monitoring/monitoring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;

Future<void> bootstrap(FlavorConfig config) {
  return Monitoring.start(config: config, appRunner: () => _boot(config));
}

Future<void> _boot(FlavorConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  Monitoring.installErrorHandlers();
  Monitoring.activate(config: config);

  /// the OFL needs each bundled font's license shipped with the app
  LicenseRegistry.addLicense(_fontLicenses);

  /// GeoNames is CC BY 4.0, the credit line in More comes in milestone 9
  LicenseRegistry.addLicense(_placesLicense);

  /// latest.dart lacks zones like Europe/Oslo
  tz.initializeTimeZones();
  final db = config.isDesignScenario ? await designScenarioStore() : await AppDatabase.open();
  final phoneZone = await PhoneZone.read();
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        flavorProvider.overrideWithValue(config),
        phoneZoneProvider.overrideWith(() => PhoneZone(phoneZone)),
        if (config.isDesignScenario) ...designScenarioOverrides(),
      ],
      child: const App(),
    ),
  );
}

Stream<LicenseEntry> _fontLicenses() async* {
  const fonts = [
    'amiri',
    'amiriquran',
    'marcellus',
    'notosansarabic',
    'reemkufi',
    'schibstedgrotesk',
  ];
  for (final font in fonts) {
    final license = await rootBundle.loadString('assets/fonts/licenses/$font-OFL.txt');
    yield LicenseEntryWithLineBreaks([font], license);
  }
}

Stream<LicenseEntry> _placesLicense() async* {
  final license = await rootBundle.loadString('assets/places/LICENSE.txt');
  yield LicenseEntryWithLineBreaks(['GeoNames'], license);
}
