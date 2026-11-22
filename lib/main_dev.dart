import 'package:better_muslim/bootstrap.dart';
import 'package:better_muslim/core/flavor/flavor_config.dart';

/// flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=dart_define/dev.json
Future<void> main() => bootstrap(FlavorConfig.fromEnvironment());
