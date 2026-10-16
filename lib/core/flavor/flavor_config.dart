import 'package:better_muslim/core/flavor/flavor.dart';
import 'package:flutter/foundation.dart';

/// read once at startup from the flavor's dart_define file
@immutable
class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.sentryDsn,
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
    );
  }

  final Flavor flavor;
  final String appName;
  final String apiBaseUrl;
  final String sentryDsn;
}
