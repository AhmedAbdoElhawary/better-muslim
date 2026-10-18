import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flavorProvider = Provider<FlavorConfig>(
  (ref) => throw UnimplementedError('flavorProvider is overridden in bootstrap'),
);

/// read once at startup from the flavor's dart_define file
@immutable
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.sentryDsn,
    this.scenario = '',
  });

  factory FlavorConfig.fromEnvironment({Flavor fallbackFlavor = Flavor.dev}) {
    const rawFlavor = String.fromEnvironment('FLAVOR');
    return FlavorConfig(
      flavor: Flavor.values.firstWhere(
        (flavor) => flavor.name == rawFlavor,
        orElse: () => fallbackFlavor,
      ),
      appName: const String.fromEnvironment('APP_NAME', defaultValue: 'Better Muslim'),
      // TODO(ahmed): put the server link in API_BASE_URL of each dart_define/<flavor>.json once the backend exists, empty means no backend yet.
      apiBaseUrl: const String.fromEnvironment('API_BASE_URL'),
      sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
      scenario: const String.fromEnvironment('SCENARIO'),
    );
  }

  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;
  final String sentryDsn;
  final String scenario;

  /// staging and production ignore SCENARIO, so a stray define can't freeze a real build
  bool get isDesignScenario => flavor == Flavor.dev && scenario == 'design';
}
