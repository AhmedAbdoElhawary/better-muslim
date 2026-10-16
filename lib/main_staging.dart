import 'package:better_muslim/bootstrap.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';

/// flutter run --flavor staging -t lib/main_staging.dart --dart-define-from-file=dart_define/staging.json
Future<void> main() => bootstrap(FlavorConfig.fromEnvironment());
