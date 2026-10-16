import 'package:better_muslim/core/app/app.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';
import 'package:better_muslim/core/monitoring/monitoring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> bootstrap(FlavorConfig config) {
  return Monitoring.start(config: config, appRunner: () => _boot(config));
}

Future<void> _boot(FlavorConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  Monitoring.installErrorHandlers();
  Monitoring.activate(config: config);

  /// the OFL needs each bundled font's license shipped with the app
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(const ProviderScope(child: App()));
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
